# Complete Guide: Deploy Synthetic Warp Route on Solana

This guide provides step-by-step instructions for deploying a synthetic warp route on Solana Testnet and configuring the ISM with validators.

## Your Deployment Details

- **Program ID**: `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`
- **Mint Account**: `DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA`
- **Token**:
  - Name: `Luna Classic`
  - Symbol: `wwwwLUNC`
  - Decimals: `6`
  - Type: `synthetic`
- **ISM**:
  - Type: `messageIdMultisigIsm`
  - Validator: `242d8a855a8c932dec51f7999ae7d1e48b10c95e`
  - Threshold: `1`

---

## Prerequisites

1. **Solana CLI 1.14.20** installed and configured
2. **Rust 1.75.0** installed and configured
3. **Hyperlane Sealevel Client** compiled
4. **Solana Testnet account** with sufficient SOL balance (at least 0.01 SOL)
5. **Core Program IDs** file created (see Step 0)

---

## Step 0: Create Core Program IDs File

The `hyperlane-sealevel-client` requires core program IDs (Mailbox, IGP, etc.) to initialize the warp route.

### 0.1. Create Directory Structure

```bash
mkdir -p ~/hyperlane-monorepo/rust/sealevel/environments/testnet/solanatestnet/core
```

### 0.2. Create Core Program IDs File

```bash
cat > ~/hyperlane-monorepo/rust/sealevel/environments/testnet/solanatestnet/core/program-ids.json << 'EOF'
{
  "mailbox": "75HBBLae3ddeneJVrZeyrDfv6vb7SMC3aCpBucSXS5aR",
  "validator_announce": "8qNYSi9EP1xSnRjtMpyof88A26GBbdcrsa61uSaHiwx3",
  "multisig_ism_message_id": "4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k",
  "igp_program_id": "5p7Hii6CJL4xGBYYTGEQmH9LnUSZteFJUu9AVLDExZX2",
  "overhead_igp_account": "hBHAApi5ZoeCYHqDdCKkCzVKmBdwywdT3hMqe327eZB",
  "igp_account": "9SQVtTNsbipdMzumhzi6X8GwojiSMwBfqAhS7FgyTcqy"
}
EOF
```

### 0.3. Create Chain Metadata File

```bash
mkdir -p ~/.hyperlane/registry/chains
cat > ~/.hyperlane/registry/chains/metadata.yaml << 'EOF'
solanatestnet:
  chainId: 101
  domainId: 1399811149
  name: solanatestnet
  nativeToken:
    decimals: 9
    name: SOL
    symbol: SOL
  protocol: sealevel
  rpcUrls:
    - http: https://api.testnet.solana.com
  blocks:
    confirmations: 1
    estimateBlockTime: 1
  isTestnet: true
EOF
```

---

## Step 1: Prepare Token Configuration

### 1.1. Create Configuration Directory

```bash
cd ~/hyperlane-monorepo/rust/sealevel
mkdir -p environments/testnet/warp-routes/lunc-solana
```

### 1.2. Create Token Configuration File

**⚠️ IMPORTANT**: The `token-config.json` must be in the correct format with the chain name as the key:

```bash
cat > environments/testnet/warp-routes/lunc-solana/token-config.json << 'EOF'
{
  "solanatestnet": {
    "type": "synthetic",
    "name": "Luna Classic",
    "symbol": "wwwwLUNC",
    "decimals": 6,
    "totalSupply": "0"
  }
}
EOF
```

**Note**: Do NOT include `foreignDeployment` in the initial configuration. The `program-ids.json` file will be used to reference the existing Program ID.

### 1.3. Verify File Created

```bash
cat environments/testnet/warp-routes/lunc-solana/token-config.json
```

---

## Step 2: Deploy Program (If Not Already Deployed)

If you haven't deployed the program yet, compile and deploy it:

### 2.1. Compile the Program

```bash
cd ~/hyperlane-monorepo/rust/sealevel
cargo build-sbf --manifest-path programs/hyperlane-sealevel-token/Cargo.toml
```

### 2.2. Deploy to Solana Testnet

```bash
solana program deploy target/deploy/hyperlane_sealevel_token.so \
  --url testnet \
  --keypair /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json
```

**Note**: Save the Program ID returned by this command. In this case, it's `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`.

---

## Step 3: Initialize the Synthetic Warp Route

### 3.1. Verify Keypair

```bash
# Verify keypair exists
ls -lh /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json

# Verify address and balance
solana address --keypair /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json
solana balance EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd --url https://api.testnet.solana.com
```

**⚠️ IMPORTANT**: Ensure you have at least 0.01 SOL in your account for transaction fees and ATA payer funding.

### 3.2. Create Program IDs File

If you already deployed the program, create the `program-ids.json` file:

```bash
mkdir -p ~/hyperlane-monorepo/rust/sealevel/environments/testnet/warp-routes/lunc-solana
cat > ~/hyperlane-monorepo/rust/sealevel/environments/testnet/warp-routes/lunc-solana/program-ids.json << 'EOF'
{
  "solanatestnet": {
    "hex": "0x3e39de1edbc0495cee651b3e046f63d01ff9436932bb520e8c0cb4ba5c5c7f1d",
    "base58": "5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
  }
}
EOF
```

### 3.3. Deploy/Initialize the Warp Route

**⚠️ CRITICAL**: Execute from `~/hyperlane-monorepo/rust/sealevel/client` directory and use **relative paths** (`../` not `../../`).

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variables
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
WARP_ROUTE_NAME="lunc-solana"

# ⚠️ IMPORTANT: Relative paths from client/
# Use ../ (one level up), NOT ../../ (two levels)
ENVIRONMENTS_DIR="../environments"
TOKEN_CONFIG="../environments/testnet/warp-routes/lunc-solana/token-config.json"
BUILT_SO_DIR="../target/deploy"
REGISTRY_DIR="$HOME/.hyperlane/registry"

# Deploy/Initialize synthetic warp route
# NOTE: -k and -u are global arguments and must come BEFORE the subcommand
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  warp-route deploy \
  --warp-route-name "$WARP_ROUTE_NAME" \
  --environment testnet \
  --environments-dir "$ENVIRONMENTS_DIR" \
  --token-config-file "$TOKEN_CONFIG" \
  --built-so-dir "$BUILT_SO_DIR" \
  --registry "$REGISTRY_DIR" \
  --ata-payer-funding-amount 5000000
```

**Note**: The `--ata-payer-funding-amount` is set to `5000000` (0.005 SOL). Adjust based on your account balance. The minimum recommended is `5000000` lamports.

### 3.4. Expected Output

The command will:
1. ✅ Verify configuration
2. ✅ Install `spl-token-cli` if needed
3. ✅ Read existing Program ID from `program-ids.json`
4. ✅ Initialize the synthetic token (create Mint Account)
5. ✅ Create metadata for the token
6. ✅ Transfer mint authority to the mint account
7. ✅ Fund the ATA payer
8. ✅ Configure IGP
9. ✅ Write `program-ids.json` with the Program ID

**Success Output**:
```
Recovered existing program id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x
Initializing Warp Route program: domain_id: 1399811149, mailbox: 75HBBLae3ddeneJVrZeyrDfv6vb7SMC3aCpBucSXS5aR, ...
Creating token DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA ...
Address: DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA
Decimals: 9
Signature: ...
initialized metadata pointer. Status: exit status: 0
initialized metadata. Status: exit status: 0
Transferring authority: mint to the mint account DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA
Set the mint authority to the mint account. Status: exit status: 0
```

---

## Step 4: Configure ISM Validators

**⚠️ IMPORTANT**: The existing ISM (`4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k`) has a different owner. You need to **create a new ISM** and associate it with the warp route. See [CREATE-NEW-ISM-SOLANA-EN.md](./CREATE-NEW-ISM-SOLANA-EN.md) for complete instructions.

### Option 1: Create New ISM (Recommended)

If you're not the owner of the existing ISM, create a new one:

```bash
# 1. Deploy new ISM
cd ~/hyperlane-monorepo/rust/sealevel/client
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id deploy \
  --environment testnet \
  --environments-dir ../environments \
  --built-so-dir ../target/deploy \
  --chain solanatestnet \
  --context lunc-solana-ism \
  --registry ~/.hyperlane/registry

# 2. Configure validators (use the new Program ID)
NEW_ISM_PROGRAM_ID="<NEW_PROGRAM_ID>"
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id set-validators-and-threshold \
  --program-id "$NEW_ISM_PROGRAM_ID" \
  --domain 1325 \
  --validators 242d8a855a8c932dec51f7999ae7d1e48b10c95e \
  --threshold 1

# 3. Associate ISM with warp route
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token set-interchain-security-module \
  --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x \
  --ism "$NEW_ISM_PROGRAM_ID"
```

### Option 2: Configure Existing ISM (If You Are the Owner)

After the warp route is deployed, configure the ISM validators.

### 4.1. Find the ISM Program ID

The ISM program ID is typically the same as the Multisig ISM Message ID from the core program IDs:
- **ISM Program ID**: `4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k`

### 4.2. Configure Validators

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variables
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"
DOMAIN="1325"  # Terra Classic domain
VALIDATOR="242d8a855a8c932dec51f7999ae7d1e48b10c95e"  # Terra Classic validator
THRESHOLD="1"

# Configure validators
# ⚠️ IMPORTANT: Use "multisig-ism-message-id" (with hyphens), not "ism multisig-message-id"
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id set-validators-and-threshold \
  --program-id "$ISM_PROGRAM_ID" \
  --domain "$DOMAIN" \
  --validators "$VALIDATOR" \
  --threshold "$THRESHOLD"
```

### 4.3. Verify Validators Configuration

```bash
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  ism multisig-message-id get-validators-and-threshold \
  --program-id "$ISM_PROGRAM_ID" \
  --domain "$DOMAIN"
```

---

## Step 5: Link Warp Routes

After deploying both the Terra Classic native warp route and the Solana synthetic warp route, link them together.

### 5.1. Link Terra Classic → Solana

On Terra Classic, enroll the Solana warp route as a remote router:

```bash
# Terra Classic warp route address
TERRA_WARP="terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8"

# Solana Program ID (32-byte hex format)
SOLANA_WARP_HEX="0x3e39de1edbc0495cee651b3e046f63d01ff9436932bb520e8c0cb4ba5c5c7f1d"

# Solana domain
SOLANA_DOMAIN="1399811149"

# Link using terrad
terrad tx wasm execute "$TERRA_WARP" \
  "{\"enroll_remote_router\":{\"domain\":$SOLANA_DOMAIN,\"router\":\"$SOLANA_WARP_HEX\"}}" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

### 5.2. Link Solana → Terra Classic

On Solana, enroll the Terra Classic warp route as a remote router:

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Terra Classic warp route address (32-byte hex)
TERRA_WARP_HEX="0x0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02"
TERRA_DOMAIN="1325"

# Link using sealevel client
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token enroll-remote-router \
  --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x \
  --domain "$TERRA_DOMAIN" \
  --router "$TERRA_WARP_HEX"
```

---

## Step 6: Test Transfer

### 6.1. Transfer from Terra Classic to Solana

```bash
# Transfer 1 LUNC (1000000 uluna) from Terra Classic to Solana
AMOUNT="1000000"
HOOK_FEE="283215"
TOTAL_AMOUNT=$((AMOUNT + HOOK_FEE))

# Solana recipient address (32-byte hex, padded)
RECIPIENT="000000000000000000000000EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd"

terrad tx wasm execute terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8 \
  "{\"transfer_remote\":{\"dest_domain\":1399811149,\"recipient\":\"$RECIPIENT\",\"amount\":\"$AMOUNT\"}}" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --amount "${TOTAL_AMOUNT}uluna" \
  --yes
```

### 6.2. Check Balance on Solana

```bash
# Check token balance
spl-token accounts --owner EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd \
  --url https://api.testnet.solana.com
```

---

## Troubleshooting

### Error: `--use-rpc` not supported

**Problem**: Solana CLI 1.14.20 doesn't support the `--use-rpc` flag.

**Solution**: Use `program-ids.json` to reference the existing Program ID instead of trying to deploy again. Do NOT use `foreignDeployment` in `token-config.json` initially.

### Error: Insufficient lamports

**Problem**: Account doesn't have enough SOL to fund the ATA payer.

**Solution**: 
1. Check balance: `solana balance <address> --url https://api.testnet.solana.com`
2. Reduce `--ata-payer-funding-amount` (minimum: 5000000 lamports)
3. Or add more SOL to your account

### Error: `Failed to read JSON from file`

**Problem**: Missing `core/program-ids.json` file.

**Solution**: Create the file as described in Step 0.2.

### Error: `No such file or directory` for token-config.json

**Problem**: Incorrect relative paths.

**Solution**: 
- Execute from `~/hyperlane-monorepo/rust/sealevel/client`
- Use `../environments` (not `../../environments`)
- Use `../target/deploy` (not `../../target/deploy`)

### Error: `Warp route token already exists`

**Status**: This is normal if you've already initialized the token. The command will skip initialization and proceed with other configurations.

---

## Summary

After completing all steps, you will have:

1. ✅ **Program Deployed**: `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`
2. ✅ **Mint Account Created**: `DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA`
3. ✅ **Token Initialized**: "Luna Classic" (wwwwLUNC) with 6 decimals
4. ✅ **ISM Configured**: Validators set for Terra Classic domain
5. ✅ **Warp Routes Linked**: Terra Classic ↔ Solana bidirectional link
6. ✅ **Ready for Transfers**: Can send LUNC from Terra Classic to Solana

---

## References

- [Hyperlane Solana Warp Route Guide](https://docs.hyperlane.xyz/docs/guides/warp-routes/svm/svm-warp-route-guide)
- [Extending Warp Routes](https://docs.hyperlane.xyz/docs/guides/warp-routes/evm/extending-warp-routes)
- [Hyperlane Sealevel Client](https://github.com/hyperlane-xyz/hyperlane-monorepo/tree/main/rust/sealevel/client)

