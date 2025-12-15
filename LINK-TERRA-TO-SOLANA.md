# Link Terra Classic → Solana Warp Route

This guide shows how to enroll the Solana warp route as a remote router on the Terra Classic warp route contract.

## Overview

After deploying warp routes on both Terra Classic and Solana, you need to link them bidirectionally:
1. **Terra Classic → Solana** (this guide)
2. **Solana → Terra Classic** (already done - see [ENROLL-REMOTE-ROUTER-SOLANA.md](./ENROLL-REMOTE-ROUTER-SOLANA.md))

## Prerequisites

- Terra Classic warp route: `terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml` (wwwwlunc)
- **Solana warp route Program ID (V2)**: `HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw`
- **Solana warp route Program ID (V1 - Reference)**: `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`
- Solana domain: `1399811150` (Solana Testnet)
- Terra Classic account with owner permissions (owner of the Terra Classic warp route)

## Step 1: Convert Solana Program ID to Hex Format

The Solana Program ID (base58) needs to be converted to a 32-byte hex format for the Terra Classic contract.

**Solana Program ID (base58) - Warp Route V2:**
```
HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw
```

**Converted Hex (32 bytes, without 0x prefix) - Warp Route V2:**
```
f35ac96952cd5f87be0a99b173927e2fe0a814079ceb9ce8f5237f775fc940fa
```

### How to Convert

#### Method 1: Using Python (Recommended)

```bash
python3 << EOF
import base58
import binascii

solana_address = "HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw"  # Warp Route V2
decoded = base58.b58decode(solana_address)
hex_address = binascii.hexlify(decoded).decode('utf-8')
# Pad to 64 characters (32 bytes)
hex_padded = hex_address.zfill(64)
print(f"Hex (32 bytes, no 0x): {hex_padded}")
EOF
```

**Expected output:**
```
Hex (32 bytes, no 0x): f35ac96952cd5f87be0a99b173927e2fe0a814079ceb9ce8f5237f775fc940fa  # Warp Route V2
```

#### Method 2: Using Node.js

```bash
node -e "
const bs58 = require('bs58');
const solanaAddress = 'HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw';  // Warp Route V2
const decoded = bs58.decode(solanaAddress);
const hex = Buffer.from(decoded).toString('hex');
const padded = hex.padStart(64, '0');
console.log('Hex (32 bytes, no 0x):', padded);
"
```

**Note**: You may need to install `bs58`: `npm install bs58`

#### Method 3: Using Online Tool

You can use an online base58 to hex converter, but make sure to pad to 64 characters (32 bytes).

## Step 2: Enroll Remote Router on Terra Classic

On Terra Classic, enroll the Solana warp route as a remote router using `terrad`:

```bash
# Variables
TERRA_WARP="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"
SOLANA_DOMAIN="1399811150"
SOLANA_WARP_HEX="f35ac96952cd5f87be0a99b173927e2fe0a814079ceb9ce8f5237f775fc940fa"  # Warp Route V2

# Set route (link remote router)
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

**⚠️ IMPORTANT**: 
- The `router` parameter must be **64 hex characters** (32 bytes), **without** the `0x` prefix
- The domain for Solana Testnet is `1399811150`
- Make sure you have enough `uluna` for fees (12,000,000 uluna = 0.012 LUNC)

**Expected Output:**
```
code: 0
txhash: <TRANSACTION_HASH>
```

## Step 3: Verify Enrollment

After execution, verify that the router was enrolled:

```bash
# Query the enrolled router for domain 1399811150
terrad query wasm contract-state smart "$TERRA_WARP" \
  '{"router":{"get_route":{"domain":1399811150}}}' \
  --node "https://rpc.luncblaze.com:443"
```

**Expected output:**
```json
{
  "data": {
    "route": "3e39de1edbc0495cee651b3e046f63d01ff9436932bb520e8c0cb4ba5c5c7f1d"
  }
}
```

Or query all routes:

```bash
terrad query wasm contract-state smart "$TERRA_WARP" \
  '{"router":{"list_routes":{}}}' \
  --node "https://rpc.luncblaze.com:443"
```

**Expected output:**
```json
{
  "data": {
    "routes": [
      {
        "domain": 1399811150,
        "route": "3e39de1edbc0495cee651b3e046f63d01ff9436932bb520e8c0cb4ba5c5c7f1d"
      }
    ]
  }
}
```

## Complete Command Reference

### Full Command (One-liner)

```bash
TERRA_WARP="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml" && \
SOLANA_DOMAIN="1399811150" && \
SOLANA_WARP_HEX="f35ac96952cd5f87be0a99b173927e2fe0a814079ceb9ce8f5237f775fc940fa"  # Warp Route V2 && \
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

### Using Script

#### Script para lunc-solana-v2 (Recomendado)

Use o script pronto para o warp route `lunc-solana-v2`:

```bash
/home/lunc/cw-hyperlane/script/vincular-terra-to-solana-lunc-solana-v2.sh
```

Este script:
- ✅ Verifica as informações antes de executar
- ✅ Mostra o comando que será executado
- ✅ Vincula o Remote Router
- ✅ Verifica a vinculação automaticamente

#### Script Genérico (Referência)

Se precisar criar um script customizado:

```bash
#!/bin/bash

# Variables
TERRA_WARP="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"
SOLANA_DOMAIN="1399811150"
SOLANA_WARP_HEX="f35ac96952cd5f87be0a99b173927e2fe0a814079ceb9ce8f5237f775fc940fa"  # Warp Route V2
KEY_NAME="hypelane-val-testnet"
CHAIN_ID="rebel-2"
RPC_NODE="https://rpc.luncblaze.com:443"
FEES="12000000uluna"

# Execute
terrad tx wasm execute "$TERRA_WARP" \
  "{\"router\":{\"set_route\":{\"set\":{\"domain\":$SOLANA_DOMAIN,\"route\":\"$SOLANA_WARP_HEX\"}}}}" \
  --from "$KEY_NAME" \
  --keyring-backend file \
  --chain-id "$CHAIN_ID" \
  --node "$RPC_NODE" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees "$FEES" \
  --yes
```

Make it executable and run:
```bash
chmod +x link-terra-to-solana.sh
./link-terra-to-solana.sh
```

## Function Signature

The `router.set_route` function in the Terra Classic warp route contract:

```json
{
  "router": {
    "set_route": {
      "set": {
        "domain": 1399811150,
        "route": "3e39de1edbc0495cee651b3e046f63d01ff9436932bb520e8c0cb4ba5c5c7f1d"
      }
    }
  }
}
```

**Parameters:**
- `domain`: Solana domain ID (1399811150)
- `router`: Solana Program ID in hex format (32 bytes, 64 hex characters, without 0x prefix)

## Important Notes

1. **Domain ID**: Solana Testnet domain is `1399811150` (as configured in your setup)
2. **Address Format**: The Solana Program ID must be:
   - Converted from base58 to hex
   - Padded to 64 characters (32 bytes)
   - Provided **without** the `0x` prefix in the JSON message
3. **Ownership**: The account executing the transaction must be the owner of the Terra Classic warp route contract
4. **Bidirectional**: After enrolling on Terra Classic, make sure Solana → Terra Classic is also linked (see [ENROLL-REMOTE-ROUTER-SOLANA.md](./ENROLL-REMOTE-ROUTER-SOLANA.md))

## Troubleshooting

### Error: "insufficient funds"

**Problem**: Your account doesn't have enough `uluna` for fees.

**Solution**: Check your balance and adjust fees:
```bash
terrad query bank balances $(terrad keys show hypelane-val-testnet -a --keyring-backend file) \
  --node "https://rpc.luncblaze.com:443"
```

If needed, reduce fees (minimum recommended: 1000000uluna):
```bash
--fees 1000000uluna
```

### Error: "unauthorized"

**Problem**: Your account is not the owner of the warp route contract.

**Solution**: Verify ownership:
```bash
terrad query wasm contract-state smart "$TERRA_WARP" \
  '{"owner":{}}' \
  --node "https://rpc.luncblaze.com:443"
```

### Error: "invalid router format"

**Problem**: The router address format is incorrect.

**Solution**: 
- Ensure the hex string is exactly 64 characters (32 bytes)
- Remove the `0x` prefix if present
- Verify the base58 to hex conversion is correct

### Error: "route already exists"

**Problem**: The route for this domain is already enrolled.

**Solution**: This is not an error - the route is already configured. You can verify with:
```bash
terrad query wasm contract-state smart "$TERRA_WARP" \
  '{"router":{"get_route":{"domain":1399811150}}}' \
  --node "https://rpc.luncblaze.com:443"
```

## Example: lunc-solana-v2 (Configured)

**✅ Remote Router vinculado com sucesso para o warp route `lunc-solana-v2`:**

- **Terra Classic Warp Route**: `terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml`
- **Solana Warp Route Program ID**: `HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw`
- **Solana Router (Hex)**: `f35ac96952cd5f87be0a99b173927e2fe0a814079ceb9ce8f5237f775fc940fa`
- **Transaction Hash**: `0630750886AC1FE214234BDB5B891DE1299883169C37130BB9C62E2EC64930F9`
- **Status**: ✅ Transação enviada e confirmada (Terra Classic → Solana)

**Script usado**: `script/vincular-terra-to-solana-lunc-solana-v2.sh`

**Verificar vinculação:**
```bash
terrad query wasm contract-state smart terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml \
  '{"router":{"get_route":{"domain":1399811150}}}' \
  --node "https://rpc.luncblaze.com:443"
```

**Saída esperada (após confirmação):**
```json
{
  "data": {
    "route": "f35ac96952cd5f87be0a99b173927e2fe0a814079ceb9ce8f5237f775fc940fa"
  }
}
```

**⚠️ Nota**: Se a rota aparecer como `null` na verificação imediata, aguarde alguns segundos para a transação ser confirmada no blockchain e execute a query novamente.

## Next Steps

After successfully enrolling the remote router:

1. **Verify both directions are linked:**
   - Terra Classic → Solana: Verify route on Terra Classic (this guide) ✅
   - Solana → Terra Classic: Verify router enrollment on Solana (see [ENROLL-REMOTE-ROUTER-SOLANA.md](./ENROLL-REMOTE-ROUTER-SOLANA.md)) ✅

2. **Test cross-chain transfer:**
   - Transfer from Terra Classic to Solana
   - Transfer from Solana to Terra Classic

## References

- [ENROLL-REMOTE-ROUTER-SOLANA.md](./ENROLL-REMOTE-ROUTER-SOLANA.md) - Solana → Terra Classic linking
- [WARP-ROUTE-TERRA-SOLANA-EN.md](./WARP-ROUTE-TERRA-SOLANA-EN.md) - Complete Terra Classic ↔ Solana guide
- [LINK-ULUNA-WARP-BSC.md](./LINK-ULUNA-WARP-BSC.md) - BSC linking example

