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
  "token": {
    "denom": "uluna"
  },
  "hypNative": {
    "targetNetworks": [
      {
        "domain": 1399811150,
        "type": "sealevel",
        "name": "solanatestnet"
      }
    ]
  }
}
EOF

# Deploy warp route
yarn cw-hpl warp create ./example/warp/uluna-solana.json -n terraclassic
```

**Note**: Save the Terra Classic warp route address from the output.

---

### 2. Deploy Warp Route on Solana

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Create token config
mkdir -p environments/testnet/warp-routes/lunc-solana-v2
cat > environments/testnet/warp-routes/lunc-solana-v2/token-config.json << 'EOF'
{
  "type": "synthetic",
  "name": "LUNC",
  "symbol": "LUNC",
  "decimals": 6,
  "collateral": {
    "type": "native",
    "chain": "terraclassic",
    "denom": "uluna",
    "decimals": 6
  }
}
EOF

# Deploy warp route
cd client
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  token deploy \
  --warp-route-name lunc-solana-v2 \
  --environment testnet \
  --environments-dir ../environments \
  --token-config-file ../environments/testnet/warp-routes/lunc-solana-v2/token-config.json \
  --registry ~/.hyperlane/registry
```

**Note**: Save the Solana Program ID from the output.

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

---

## Complete Documentation

For detailed information, see:

- **[LUNC-SOLANA-V2-COMPLETE-INFO.md](./LUNC-SOLANA-V2-COMPLETE-INFO.md)** - Complete information about lunc-solana-v2
- **[WARP-ROUTE-TERRA-SOLANA.md](./WARP-ROUTE-TERRA-SOLANA.md)** - Complete Terra Classic ↔ Solana guide
- **[ISM-SOLANA-DEPLOYED-INFO.md](./ISM-SOLANA-DEPLOYED-INFO.md)** - ISM deployment information
- **[VINCULAR-REMOTE-ROUTER-SOLANA.md](./VINCULAR-REMOTE-ROUTER-SOLANA.md)** - Remote router linking guide (Solana → Terra Classic)
- **[LINK-TERRA-TO-SOLANA.md](./LINK-TERRA-TO-SOLANA.md)** - Remote router linking guide (Terra Classic → Solana)
- **[CONFIGURAR-ISM-SOLANA-WARP.md](./CONFIGURAR-ISM-SOLANA-WARP.md)** - ISM configuration guide

---

## Quick Reference

| Step | Command/Script |
|------|----------------|
| Deploy Terra Classic Warp | `yarn cw-hpl warp create ./example/warp/uluna-solana.json -n terraclassic` |
| Deploy Solana Warp | `cargo run -- ... token deploy --warp-route-name lunc-solana-v2 ...` |
| Configure ISM | `script/configurar-ism-lunc-solana-v2-manual.sh` |
| Link Solana → Terra | `script/vincular-remote-router-solana-lunc-solana-v2.sh` |
| Link Terra → Solana | `script/vincular-terra-to-solana-lunc-solana-v2.sh` |

---

**Last Updated**: After successful bidirectional linking of lunc-solana-v2

