# Quick Start: Terra Classic ↔ Solana Warp Route

This guide provides quick commands to set up a complete warp route between Terra Classic and Solana Testnet.

## Prerequisites

- Terra Classic account with owner permissions
- Solana keypair with owner permissions
- `cw-hyperlane` CLI installed
- `hyperlane-sealevel-client` compiled

## Quick Setup Steps

### 1. Deploy Warp Route on Terra Classic

```bash
cd ~/cw-hyperlane

# Create warp route config
cat > example/warp/uluna-solana.json << EOF
{
  "type": "native",
  "mode": "collateral",
  "id": "wwwwlunc",
  "owner": "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze",
  "config": {
    "collateral": {
      "denom": "uluna"
    }
  }
}
EOF

# Deploy warp route
yarn cw-hpl warp create ./example/warp/uluna-solana.json -n terraclassic
```

**Note**: Save the Terra Classic warp route address from the output. You can also find it in `context/terraclassic.json`:

```bash
cat context/terraclassic.json | jq '.deployments.warp.native[] | select(.id == "wwwwlunc")'
```

---

### 2. Deploy Warp Route on Solana

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Build programs first (if not already built)
cargo build-sbf

# Create token config
mkdir -p environments/testnet/warp-routes/lunc-solana-v2
cat > environments/testnet/warp-routes/lunc-solana-v2/token-config.json << 'EOF'
{
  "solanatestnet": {
    "type": "synthetic",
    "name": "Luna Classic",
    "symbol": "wwwwwLUNC",
    "decimals": 6,
    "totalSupply": "0",
    "interchainGasPaymaster": "9SQVtTNsbipdMzumhzi6X8GwojiSMwBfqAhS7FgyTcqy",
    "uri": "https://raw.githubusercontent.com/igorv43/cw-hyperlane/refs/heads/main/warp/solana/metadata.json"
  }
}
EOF

# Deploy warp route
cd client
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  warp-route deploy \
  --warp-route-name lunc-solana-v2 \
  --environment testnet \
  --environments-dir ../environments \
  --token-config-file ../environments/testnet/warp-routes/lunc-solana-v2/token-config.json \
  --built-so-dir ../target/deploy \
  --registry ~/.hyperlane/registry \
  --ata-payer-funding-amount 5000000
```

**Note**: Save the Solana Program ID from the output. It will also be saved in `environments/testnet/warp-routes/lunc-solana-v2/program-ids.json`.

---

### 3. Configure ISM on Solana

```bash
# Use the ready-made script
/home/lunc/cw-hyperlane/script/configurar-ism-lunc-solana-v2-manual.sh
```

**Or manually:**

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variables
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
WARP_ROUTE_PROGRAM_ID="HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw"
DOMAIN="1325"
VALIDATOR="242d8a855a8c932dec51f7999ae7d1e48b10c95e"
THRESHOLD="1"
CONTEXT="lunc-solana-v2-ism"

# Deploy and configure ISM
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id deploy \
  --environment testnet \
  --environments-dir ../environments \
  --chain solanatestnet \
  --context "$CONTEXT" \
  --registry ~/.hyperlane/registry

# Get ISM Program ID from output, then:
ISM_PROGRAM_ID="5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh"

# Initialize ISM
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id init \
  --program-id "$ISM_PROGRAM_ID"

# Configure validators
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id set-validators-and-threshold \
  --program-id "$ISM_PROGRAM_ID" \
  --domain "$DOMAIN" \
  --validators "$VALIDATOR" \
  --threshold "$THRESHOLD"

# Associate ISM with warp route
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token set-interchain-security-module \
  --program-id "$WARP_ROUTE_PROGRAM_ID" \
  --ism "$ISM_PROGRAM_ID"
```

---

### 4. Link Solana → Terra Classic

```bash
# Use the ready-made script
/home/lunc/cw-hyperlane/script/vincular-remote-router-solana-lunc-solana-v2.sh
```

**Or manually:**

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variables
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
WARP_ROUTE_PROGRAM_ID="HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw"
TERRA_DOMAIN="1325"
TERRA_WARP_HEX="0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b"

# Enroll remote router
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token enroll-remote-router \
  --program-id "$WARP_ROUTE_PROGRAM_ID" \
  "$TERRA_DOMAIN" \
  "$TERRA_WARP_HEX"
```

---

### 5. Link Terra Classic → Solana

```bash
# Use the ready-made script
/home/lunc/cw-hyperlane/script/vincular-terra-to-solana-lunc-solana-v2.sh
```

**Or manually:**

```bash
# Convert Solana Program ID to hex (32 bytes, no 0x prefix)
python3 << EOF
import base58
import binascii

solana_address = "HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw"
decoded = base58.b58decode(solana_address)
hex_address = binascii.hexlify(decoded).decode('utf-8')
hex_padded = hex_address.zfill(64)
print(hex_padded)
EOF

# Variables
TERRA_WARP="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"
SOLANA_DOMAIN="1399811150"
SOLANA_WARP_HEX="f35ac96952cd5f87be0a99b173927e2fe0a814079ceb9ce8f5237f775fc940fa"

# Enroll remote router
terrad tx wasm execute "$TERRA_WARP" \
  "{\"router\":{\"set_route\":{\"set\":{\"domain\":$SOLANA_DOMAIN,\"route\":\"$SOLANA_WARP_HEX\"}}}}" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

---

## Transfer Tokens

### Transfer: Terra Classic → Solana

#### Step 1: Convert Solana Address to Hex Format

The Solana recipient address (base58) must be converted to a 32-byte hex format (64 hex characters, no 0x prefix).

```bash
# Convert Solana address to hex
SOLANA_RECIPIENT="YOUR_SOLANA_ADDRESS"  # Base58 address

SOLANA_RECIPIENT_HEX=$(python3 << EOF
import base58
import binascii

solana_address = "${SOLANA_RECIPIENT}"
decoded = base58.b58decode(solana_address)
hex_address = binascii.hexlify(decoded).decode('utf-8')
hex_padded = hex_address.zfill(64)
print(hex_padded)  # 64 hex characters, no 0x
EOF
)

echo "Solana recipient hex: ${SOLANA_RECIPIENT_HEX}"
```

#### Step 2: Calculate IGP Gas Payment

```bash
# Query IGP for gas payment
IGP="terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9"
GAS_AMOUNT="200000"  # Estimated gas for Solana

IGP_GAS=$(terrad query wasm contract-state smart ${IGP} \
  '{"igp":{"quote_gas_payment":{"dest_domain":1399811150,"gas_amount":"'${GAS_AMOUNT}'"}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq -r '.data.gas_needed')

echo "IGP Gas needed: ${IGP_GAS} uluna"
```

#### Step 3: Execute Transfer

**Option 1: Using terrad CLI**

```bash
# Configuration
TERRA_WARP="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"
SOLANA_DOMAIN="1399811150"
TRANSFER_AMOUNT="10000000"  # 10 LUNC (in uluna)
HOOK_FEE="283215"  # Required hook fee for cross-chain gas
KEY_NAME="hypelane-val-testnet"
CHAIN_ID="rebel-2"
NODE="https://rpc.luncblaze.com:443"

# Calculate total: transfer amount + hook fee + IGP gas
TOTAL_AMOUNT=$((TRANSFER_AMOUNT + HOOK_FEE + IGP_GAS))

# Execute transfer
terrad tx wasm execute ${TERRA_WARP} \
  "{\"transfer_remote\":{\"dest_domain\":${SOLANA_DOMAIN},\"recipient\":\"${SOLANA_RECIPIENT_HEX}\",\"amount\":\"${TRANSFER_AMOUNT}\"}}" \
  --from ${KEY_NAME} \
  --keyring-backend file \
  --chain-id ${CHAIN_ID} \
  --node ${NODE} \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --amount ${TOTAL_AMOUNT}uluna \
  --yes
```

**Option 2: Using cw-hpl CLI (Limited)**

**⚠️ Note**: The `cw-hpl warp transfer` command currently uses the signer address as the recipient. For custom recipients, use `terrad` directly (Option 1).

If you want to transfer to your own address (signer), you can use:

```bash
yarn cw-hpl warp transfer \
  --asset-type native \
  --asset-id wwwwlunc \
  --target-domain 1399811150 \
  --amount 10000000 \
  -n terraclassic
```

**Note**: This will transfer to your signer address on Solana. For custom recipients, use `terrad` (Option 1) with the converted hex address.

#### Step 4: Verify Receipt on Solana

```bash
# Get mint address from warp route
SOLANA_MINT="3yhG9dDHVX6K1duf8znEcaJcuTiKSLYvfBD4xy6akxfu"  # From lunc-solana-v2

# Check balance
spl-token balance ${SOLANA_MINT} \
  --owner YOUR_SOLANA_KEYPAIR.json \
  --url https://api.testnet.solana.com

# Or check via Solana Explorer
echo "https://explorer.solana.com/address/${SOLANA_MINT}?cluster=testnet"
```

**Note**: Wait a few minutes for relayers to process the cross-chain message before checking balance.

---

### Transfer: Solana → Terra Classic

#### Step 1: Convert Terra Classic Address to Hex Format

The Terra Classic recipient address (bech32) must be converted to a 32-byte hex format.

```bash
# Convert Terra Classic address to hex
TERRA_RECIPIENT="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"

TERRA_RECIPIENT_HEX=$(node -e "
const { fromBech32 } = require('@cosmjs/encoding');
const addr = '${TERRA_RECIPIENT}';
const { data } = fromBech32(addr);
const hexed = Buffer.from(data).toString('hex');
const padded = hexed.padStart(64, '0');
console.log(padded);  // 64 hex characters, no 0x
")

echo "Terra Classic recipient hex: ${TERRA_RECIPIENT_HEX}"
```

**Or using cw-hpl CLI:**

```bash
yarn cw-hpl wallet bech32-to-hex ${TERRA_RECIPIENT}
```

**Note**: The recipient can be provided with or without `0x` prefix. The client will handle both formats.

#### Step 2: Execute Transfer

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Configuration
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
WARP_ROUTE_PROGRAM_ID="HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw"
TERRA_DOMAIN="1325"
TRANSFER_AMOUNT="10000000"  # 10 LUNC (in smallest units, 6 decimals)

# Execute transfer
cargo run -- \
  -k ${KEYPAIR} \
  -u https://api.testnet.solana.com \
  token transfer-remote \
  --program-id ${WARP_ROUTE_PROGRAM_ID} \
  ${KEYPAIR} \
  ${TRANSFER_AMOUNT} \
  ${TERRA_DOMAIN} \
  ${TERRA_RECIPIENT_HEX} \
  synthetic
```

**Parameters:**
- `${TRANSFER_AMOUNT}`: Amount in smallest units (6 decimals = 10 LUNC = 10000000)
- `${TERRA_DOMAIN}`: Terra Classic domain ID (1325)
- `${TERRA_RECIPIENT_HEX}`: Terra Classic address in hex (32 bytes, 64 hex characters, no 0x)
- `synthetic`: Token type on source chain (Solana)
- `--program-id`: Warp route Program ID

#### Step 3: Verify Receipt on Terra Classic

```bash
# Check balance
terrad query bank balances ${TERRA_RECIPIENT} \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443

# Or check via Terra Classic Finder
echo "https://finder.terra-classic.hexxagon.dev/testnet/address/${TERRA_RECIPIENT}"
```

**Note**: Wait a few minutes for relayers to process the cross-chain message before checking balance.

---

## Verify Configuration

### Verify ISM on Solana

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  token query \
  --program-id HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw \
  synthetic
```

**Expected output:**
```
interchain_security_module: Some(
    5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh,
)
remote_routers: {
    1325: 0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b,
}
```

### Verify Remote Router on Terra Classic

```bash
terrad query wasm contract-state smart terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml \
  '{"router":{"get_route":{"domain":1399811150}}}' \
  --node "https://rpc.luncblaze.com:443"
```

**Expected output:**
```json
{
  "data": {
    "route": "f35ac96952cd5f87be0a99b173927e2fe0a814079ceb9ce8f5237f775fc940fa"
  }
}
```

---

## Example Configuration (lunc-solana-v2)

**Terra Classic:**
- Warp Route: `terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml`
- Domain: 1325

**Solana:**
- Program ID: `HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw`
- ISM Program ID: `5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh`
- Domain: 1399811150

**Status:** ✅ Fully configured and linked bidirectionally

---

## Ready-Made Scripts

All scripts are available in `/home/lunc/cw-hyperlane/script/`:

1. **Deploy Warp Route on Solana:**
   - `criar-novo-warp-solana.sh`

2. **Configure ISM:**
   - `configurar-ism-lunc-solana-v2-manual.sh` (recommended)

3. **Link Remote Routers:**
   - `vincular-remote-router-solana-lunc-solana-v2.sh` (Solana → Terra Classic)
   - `vincular-terra-to-solana-lunc-solana-v2.sh` (Terra Classic → Solana)

---

## Troubleshooting

### ISM Deployment Error: `--use-rpc`

**Problem**: `solana program deploy` fails with `--use-rpc` error.

**Solution**: Use manual deploy (see script `configurar-ism-lunc-solana-v2-manual.sh`).

### Remote Router Shows `null`

**Problem**: Query shows `route: null` immediately after transaction.

**Solution**: Wait a few seconds for blockchain confirmation and query again.

### Insufficient Funds

**Problem**: Terra Classic transaction fails due to insufficient fees.

**Solution**: Check balance and adjust fees:
```bash
terrad query bank balances $(terrad keys show hypelane-val-testnet -a --keyring-backend file) \
  --node "https://rpc.luncblaze.com:443"
```

### Transfer Errors

#### Error: "insufficient hook payment" or "insufficient funds"

**Problem**: Not enough uluna to cover transfer amount, hook fee, IGP gas, and transaction fees.

**Solution**: Make sure you have enough balance:
- Transfer amount: e.g., `10000000uluna` (10 LUNC)
- Hook fee: `283215uluna` (required for cross-chain gas payment)
- IGP gas: Variable (query IGP for exact amount)
- Transaction fees: `12000000uluna` (minimum)
- **Total needed**: Transfer + Hook fee + IGP gas + Transaction fees

#### Error: "route not found"

**Problem**: The warp route is not linked to the destination domain.

**Solution**: Make sure you've linked the routes:
- Terra Classic → Solana: Route must be set (see Step 5)
- Solana → Terra Classic: Router must be enrolled (see Step 4)

#### Error: "recipient format incorrect"

**Problem**: The recipient address is not in the correct format.

**Solution**: 
- **Terra Classic → Solana**: Recipient must be 64 hex characters (no 0x), converted from Solana base58 address
- **Solana → Terra Classic**: Recipient must be 64 hex characters (no 0x), converted from Terra Classic bech32 address

#### Error: "spendable balance is smaller than..."

**Problem**: The IGP (Interchain Gas Paymaster) is calculating an incorrect gas cost.

**Solution**: 
1. Check IGP Oracle configuration
2. Verify the `token_exchange_rate` and `gas_price` for domain 1399811150 (Solana) are correct
3. Update IGP Oracle configuration via governance if needed

---

## Complete Documentation

For detailed information, see:

- **[LUNC-SOLANA-V2-COMPLETE-INFO.md](./LUNC-SOLANA-V2-COMPLETE-INFO.md)** - Complete information about lunc-solana-v2
- **[WARP-ROUTE-TERRA-SOLANA.md](./WARP-ROUTE-TERRA-SOLANA.md)** - Complete Terra Classic ↔ Solana guide
- **[ISM-SOLANA-DEPLOYED-INFO.md](./ISM-SOLANA-DEPLOYED-INFO.md)** - ISM deployment information
- **[VINCULAR-REMOTE-ROUTER-SOLANA.md](./VINCULAR-REMOTE-ROUTER-SOLANA.md)** - Remote router linking guide (Solana → Terra Classic)
- **[LINK-TERRA-TO-SOLANA.md](./LINK-TERRA-TO-SOLANA.md)** - Remote router linking guide (Terra Classic → Solana)
- **[CONFIGURAR-ISM-SOLANA-WARP.md](./CONFIGURAR-ISM-SOLANA-WARP.md)** - ISM configuration guide
- **[TRANSFER-ULUNA-TERRA-TO-BSC.md](./TRANSFER-ULUNA-TERRA-TO-BSC.md)** - Transfer guide (Terra Classic → BSC, similar process)
- **[WARP-ROUTE-TERRA-SOLANA.md](./WARP-ROUTE-TERRA-SOLANA.md)** - Complete transfer guide with detailed examples

---

## Quick Reference

| Step | Command/Script |
|------|----------------|
| Deploy Terra Classic Warp | `yarn cw-hpl warp create ./example/warp/uluna-solana.json -n terraclassic` |
| Deploy Solana Warp | `cargo run -- ... warp-route deploy --warp-route-name lunc-solana-v2 ...` |
| Configure ISM | `script/configurar-ism-lunc-solana-v2-manual.sh` |
| Link Solana → Terra | `script/vincular-remote-router-solana-lunc-solana-v2.sh` |
| Link Terra → Solana | `script/vincular-terra-to-solana-lunc-solana-v2.sh` |
| Transfer Terra → Solana | `yarn cw-hpl warp transfer --asset-type native --asset-id wwwwlunc --target-domain 1399811150 ...` |
| Transfer Solana → Terra | `cargo run -- ... token transfer-remote ... 1325 ...` |

---

**Last Updated**: After successful bidirectional linking of lunc-solana-v2

