# How to Find the Mint Account of Solana Warp Route

This guide shows how to locate the mint account (token address) of the synthetic warp route on Solana Testnet.

## Warp Route LUNC → Solana Mint Account

**Mint Account**: `DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA`

**Explorer**: [View on Solana Explorer](https://explorer.solana.com/address/DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA?cluster=testnet)

---

## Methods to Locate the Mint Account

### Method 1: Using `hyperlane-sealevel-client` (Recommended)

The `token query synthetic` command returns all warp route information, including the mint account.

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variables
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
PROGRAM_ID="5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"

# Query synthetic token
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id "$PROGRAM_ID" \
  synthetic
```

**Expected Output:**
```json
{
  "mint": "DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA",
  "mint_bump": 255,
  "decimals": 6,
  "name": "Luna Classic",
  "symbol": "wwwwLUNC",
  "total_supply": "0",
  ...
}
```

**Extract only the mint:**
```bash
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id "$PROGRAM_ID" \
  synthetic | jq -r '.mint'
```

**Output:**
```
DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA
```

---

### Method 2: Check Deployment Output

When you run `warp-route deploy`, the mint account is displayed in the output (if the token is created for the first time):

```bash
# During initial deployment, you'll see:
Creating token DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA ...
Address: DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA
Decimals: 6
```

**⚠️ Note**: If the token already exists, the output will show `Warp route token already exists, skipping init` and won't display the mint account. In this case, use Method 1.

---

### Method 3: Using `spl-token` CLI

If you have the warp route Program ID, you can verify the mint account using the PDA (Program Derived Address):

```bash
# Install spl-token CLI (if not already installed)
cargo install spl-token-cli

# Check mint information
MINT_ACCOUNT="DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA"

spl-token supply "$MINT_ACCOUNT" --url https://api.testnet.solana.com
spl-token display "$MINT_ACCOUNT" --url https://api.testnet.solana.com
```

**Expected Output:**
```
Supply: 0
Decimals: 6
```

---

### Method 4: Using Solana CLI

```bash
# Check the mint account
MINT_ACCOUNT="DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA"

solana account "$MINT_ACCOUNT" \
  --url https://api.testnet.solana.com \
  --output json | jq
```

**Expected Output:**
```json
{
  "account": {
    "data": [...],
    "executable": false,
    "lamports": 1461600,
    "owner": "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb",
    "rentEpoch": 18446744073709551615
  }
}
```

**Note**: The `owner` should be `TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb` (Token-2022 Program) for synthetic tokens.

---

### Method 5: Check on Solana Explorer

1. Visit: https://explorer.solana.com/address/DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA?cluster=testnet
2. Verify the information:
   - **Account Type**: Token Mint
   - **Mint Authority**: The mint account itself (self-custody)
   - **Supply**: 0 (initial)
   - **Decimals**: 6

---

## Script to Extract Mint Account

Create a script to make it easier:

```bash
#!/bin/bash
# Script: get-mint-account.sh

KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
PROGRAM_ID="5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"

cd ~/hyperlane-monorepo/rust/sealevel/client

echo "🔍 Searching for warp route mint account..."
echo ""

MINT_ACCOUNT=$(cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id "$PROGRAM_ID" \
  synthetic 2>/dev/null | jq -r '.mint')

if [ -z "$MINT_ACCOUNT" ] || [ "$MINT_ACCOUNT" = "null" ]; then
  echo "❌ Error: Could not find mint account"
  exit 1
fi

echo "✅ Mint Account found:"
echo "   $MINT_ACCOUNT"
echo ""
echo "🔗 Useful links:"
echo "   Explorer: https://explorer.solana.com/address/$MINT_ACCOUNT?cluster=testnet"
echo ""
echo "📋 Complete information:"
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id "$PROGRAM_ID" \
  synthetic | jq
```

**Usage:**
```bash
chmod +x get-mint-account.sh
./get-mint-account.sh
```

---

## Verify Mint Information

### 1. Supply (Total Amount)

```bash
MINT_ACCOUNT="DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA"

spl-token supply "$MINT_ACCOUNT" --url https://api.testnet.solana.com
```

### 2. Metadata (Name, Symbol, etc.)

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id "5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x" \
  synthetic | jq '{name, symbol, decimals, total_supply, mint}'
```

**Output:**
```json
{
  "name": "Luna Classic",
  "symbol": "wwwwLUNC",
  "decimals": 6,
  "total_supply": "0",
  "mint": "DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA"
}
```

### 3. Check on Explorer

Visit the direct link:
- **Testnet**: https://explorer.solana.com/address/DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA?cluster=testnet

---

## Current Mint Account Information

| Property | Value |
|----------|-------|
| **Mint Address** | `DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA` |
| **Name** | Luna Classic |
| **Symbol** | wwwwLUNC |
| **Decimals** | 6 |
| **Total Supply** | 0 (initial) |
| **Mint Authority** | Self (the mint account itself) |
| **Program** | Token-2022 (`TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb`) |
| **Warp Route Program ID** | `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x` |

---

## Troubleshooting

### Error: "Failed to query token"

**Cause**: The warp route may not be initialized or the Program ID is incorrect.

**Solution**:
1. Verify the Program ID is correct:
   ```bash
   solana program show 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x --url https://api.testnet.solana.com
   ```

2. Check if the token was initialized:
   ```bash
   # If the token wasn't initialized, run the deploy again
   cd ~/hyperlane-monorepo/rust/sealevel/client
   cargo run -- -k "$KEYPAIR" -u https://api.testnet.solana.com warp-route deploy ...
   ```

### Error: "Account not found"

**Cause**: The mint account may not exist or the address is incorrect.

**Solution**: Use Method 1 to get the correct mint account from the warp route.

---

## References

- [Solana Explorer - Mint Account](https://explorer.solana.com/address/DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA?cluster=testnet)
- [WARP-ROUTE-TERRA-SOLANA-EN.md](./WARP-ROUTE-TERRA-SOLANA-EN.md) - Complete warp route guide
- [Hyperlane Solana Documentation](https://docs.hyperlane.xyz/docs/guides/warp-routes/svm/svm-warp-route-guide)

