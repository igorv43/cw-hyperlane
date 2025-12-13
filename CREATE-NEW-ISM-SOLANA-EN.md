# Create New ISM on Solana and Associate with Warp Route

## Problem

The existing ISM (`4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k`) has a different owner (`6DjHX6Ezjpq3zZMZ8KsqyoFYo1zPSDoiZmLLkxD4xKXS`), so you cannot configure validators on it.

**Solution**: Just like on BSC, you need to create a **new ISM**, configure it with your validators, and associate it with the warp route.

---

## Step 1: Compile ISM Program (If Needed)

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Compile the ISM Multisig Message ID program
cargo build-sbf --manifest-path programs/ism/multisig-ism-message-id/Cargo.toml

# Verify compilation
ls -lh target/deploy/hyperlane_sealevel_multisig_ism_message_id.so
```

---

## Step 2: Deploy New ISM

**⚠️ IMPORTANT**: The `hyperlane-sealevel-client` uses `--use-rpc` which is not supported by Solana CLI 1.14.20. We need to deploy manually.

### Option 1: Manual Deploy (Recommended)

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Deploy the ISM program (this will return a new Program ID)
solana program deploy target/deploy/hyperlane_sealevel_multisig_ism_message_id.so \
  --url https://api.testnet.solana.com \
  --keypair /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json
```

**Expected Output:**
```
Program Id: 8eFJPnNRz9byTu7NYc9NdsCMHQWfD37PZnhN8fZcahJS
```

**⚠️ IMPORTANT**: Note the new Program ID returned. You'll need it in the next steps.

**Save the Program ID:**
```bash
NEW_ISM_PROGRAM_ID="8eFJPnNRz9byTu7NYc9NdsCMHQWfD37PZnhN8fZcahJS"
```

**Note**: Make sure you have at least 1.5 SOL in your account for the deploy. If you need more SOL:
```bash
solana airdrop 2 EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd --url https://api.testnet.solana.com
```

### Option 2: Using hyperlane-sealevel-client (May Fail)

If you want to try using the client (it may fail due to `--use-rpc` issue):

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variables
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
CHAIN="solanatestnet"
CONTEXT="lunc-solana-ism"
BUILT_SO_DIR="../target/deploy"
REGISTRY_DIR="$HOME/.hyperlane/registry"
ENVIRONMENTS_DIR="../environments"

# Deploy ISM (may fail with --use-rpc error)
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id deploy \
  --environment testnet \
  --environments-dir "$ENVIRONMENTS_DIR" \
  --built-so-dir "$BUILT_SO_DIR" \
  --chain "$CHAIN" \
  --context "$CONTEXT" \
  --registry "$REGISTRY_DIR"
```

---

## Step 3: Initialize the ISM

After deploying, you need to initialize the ISM to become the owner:

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Initialize the ISM (use the Program ID from Step 2)
NEW_ISM_PROGRAM_ID="8eFJPnNRz9byTu7NYc9NdsCMHQWfD37PZnhN8fZcahJS"

cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id init \
  --program-id "$NEW_ISM_PROGRAM_ID"
```

**Expected Output:**
```
==== Instructions: ====
Instruction 0: Set compute unit limit to 1400000
Instruction 1: No description provided
Transaction signature: <TX_SIGNATURE>
```

## Step 4: Verify Owner

Verify that you are the owner:

```bash
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id "$NEW_ISM_PROGRAM_ID"
```

**Expected Output:**
```
Access control: AccessControlData {
    bump_seed: 253,
    owner: Some(
        EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd,  # You are the owner!
    ),
}
```

## Step 5: Configure Validators in New ISM

Now that you're the owner of the new ISM, you can configure validators:

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variables
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
ISM_PROGRAM_ID="$NEW_ISM_PROGRAM_ID"  # Use the new Program ID
DOMAIN="1325"  # Terra Classic domain
VALIDATOR="242d8a855a8c932dec51f7999ae7d1e48b10c95e"  # Terra Classic validator (hex)
THRESHOLD="1"

# Configure validators
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id set-validators-and-threshold \
  --program-id "$ISM_PROGRAM_ID" \
  --domain "$DOMAIN" \
  --validators "$VALIDATOR" \
  --threshold "$THRESHOLD"
```

**Expected Output:**
```
Set for remote domain 1325 validators and threshold: ValidatorsAndThreshold { validators: [0x242d8a855a8c932dec51f7999ae7d1e48b10c95e], threshold: 1 }
Transaction signature: <TX_SIGNATURE>
```

---

## Step 6: Verify Validators Configuration

```bash
# Verify validators were configured correctly
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id "$ISM_PROGRAM_ID" \
  --domains "$DOMAIN"
```

**Expected Output:**
```
Access control: AccessControlData {
    bump_seed: 255,
    owner: Some(
        EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd,  # You are the owner!
    ),
}
Querying domain data for origin domain: 1325
Domain data for 1325:
DomainDataAccount {
    validators: [
        "242d8a855a8c932dec51f7999ae7d1e48b10c95e"
    ],
    threshold: 1,
}
```

---

## Step 7: Associate New ISM with Warp Route

Now associate the new ISM with your warp route:

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variables
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
WARP_ROUTE_PROGRAM_ID="5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
NEW_ISM_PROGRAM_ID="$NEW_ISM_PROGRAM_ID"  # Use the new ISM Program ID

# Associate new ISM with warp route
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token set-interchain-security-module \
  --program-id "$WARP_ROUTE_PROGRAM_ID" \
  --ism "$NEW_ISM_PROGRAM_ID"
```

**Expected Output:**
```
Set ISM to Some(<NEW_ISM_PROGRAM_ID>)
Transaction signature: <TX_SIGNATURE>
```

---

## Step 8: Verify ISM Configured on Warp Route

```bash
# Verify which ISM is configured on the warp route
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id "$WARP_ROUTE_PROGRAM_ID" \
  synthetic
```

Look for `interchain_security_module` in the output - it should show the new ISM Program ID.

---

## Command Summary

```bash
# 1. Deploy new ISM (manual, without --use-rpc)
cd ~/hyperlane-monorepo/rust/sealevel
solana program deploy target/deploy/hyperlane_sealevel_multisig_ism_message_id.so \
  --url https://api.testnet.solana.com \
  --keypair /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json

# Save the Program ID returned
NEW_ISM_PROGRAM_ID="8eFJPnNRz9byTu7NYc9NdsCMHQWfD37PZnhN8fZcahJS"

# 2. Initialize the ISM
cd ~/hyperlane-monorepo/rust/sealevel/client
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id init \
  --program-id "$NEW_ISM_PROGRAM_ID"

# 3. Configure validators
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id set-validators-and-threshold \
  --program-id "$NEW_ISM_PROGRAM_ID" \
  --domain 1325 \
  --validators 242d8a855a8c932dec51f7999ae7d1e48b10c95e \
  --threshold 1

# 4. Associate ISM with warp route
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  token set-interchain-security-module \
  --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x \
  --ism "$NEW_ISM_PROGRAM_ID"
```

---

## Difference: BSC vs Solana

| Aspect | BSC (EVM) | Solana (SVM) |
|--------|-----------|--------------|
| **Create New ISM** | Deploy via Hyperlane CLI or Factory | Deploy via `multisig-ism-message-id deploy` |
| **Configure Validators** | `terrad tx wasm execute` (if owner) or Governance | `multisig-ism-message-id set-validators-and-threshold` (if owner) |
| **Associate with Warp Route** | `setInterchainSecurityModule` via Safe/Contract | `token set-interchain-security-module` via sealevel client |
| **Owner** | Can be your account or governance | You become owner on deploy |

---

## Important Notes

1. **You become owner automatically**: When you deploy the ISM, you automatically become the owner (the payer is the owner).

2. **No governance needed**: Since you're the owner, you can configure validators directly without needing a governance proposal.

3. **Warp Route Owner**: You need to be the owner of the warp route to associate a new ISM. Verify you're the owner of the warp route before trying to associate the ISM.

4. **ISM Program ID**: The new ISM Program ID will be saved in:
   ```
   ~/hyperlane-monorepo/rust/sealevel/environments/testnet/multisig-ism-message-id/solanatestnet/lunc-solana-ism/program-ids.json
   ```

---

## Troubleshooting

### Error: "Owner not signer" when associating ISM with warp route

**Problem**: You're not the owner of the warp route.

**Solution**: Verify the warp route owner:
```bash
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x \
  synthetic
```

Look for `owner` in the output. If it's not you, you'll need to use the owner's keypair or transfer ownership.

### Error: "Program account not found" on deploy

**Problem**: Program wasn't compiled or path is incorrect.

**Solution**: 
1. Compile the program: `cargo build-sbf --manifest-path programs/ism/multisig-ism-message-id/Cargo.toml`
2. Verify the path: `--built-so-dir ../target/deploy`

### Error: "Found argument '--use-rpc' which wasn't expected" when using `multisig-ism-message-id deploy`

**Problem**: The `hyperlane-sealevel-client` tries to use `--use-rpc` which is not supported by Solana CLI 1.14.20.

**Solution**: Deploy manually using `solana program deploy` without the `--use-rpc` flag:

```bash
cd ~/hyperlane-monorepo/rust/sealevel
solana program deploy target/deploy/hyperlane_sealevel_multisig_ism_message_id.so \
  --url https://api.testnet.solana.com \
  --keypair /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json
```

Then initialize the ISM separately using `multisig-ism-message-id init`.

### Error: "Account has insufficient funds"

**Problem**: Your Solana account doesn't have enough SOL for the deploy (needs ~1.5 SOL).

**Solution**: Request airdrop:
```bash
solana airdrop 2 EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd --url https://api.testnet.solana.com
```

If airdrop fails due to rate limit, wait a few minutes and try again, or use a Solana faucet: https://faucet.solana.com/

---

## References

- [CONFIGURE-ISM-SOLANA-WARP-EN.md](./CONFIGURE-ISM-SOLANA-WARP-EN.md)
- [CONFIGURE-ISM-VALIDATORS-SOLANA-EN.md](./CONFIGURE-ISM-VALIDATORS-SOLANA-EN.md)
- [Hyperlane Sealevel Client](https://github.com/hyperlane-xyz/hyperlane-monorepo/tree/main/rust/sealevel/client)

