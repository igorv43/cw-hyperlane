# Transfer uluna: Terra Classic → BSC Testnet

This guide shows how to transfer uluna tokens from Terra Classic Testnet to BSC Testnet using the warp route.

## Prerequisites

- Terra Classic warp route: `terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8`
- BSC Testnet domain: `97`
- BSC recipient address: `0x63B2f9C469F422De8069Ef6FE382672F16a367d3` (or your desired recipient)
- Both warp routes must be linked (see `LINK-ULUNA-WARP-BSC.md`)

## Step 1: Convert BSC Address to Hyperlane Format

The BSC recipient address must be converted to a 32-byte hex format (64 hex characters) with left padding.

**BSC Address:**
```
0x63B2f9C469F422De8069Ef6FE382672F16a367d3
```

**Converted Format (64 hex characters):**
```
00000000000000000000000063b2f9c469f422de8069ef6fe382672f16a367d3
```

### Conversion Method

You can convert the address using Node.js:

```bash
node -e "
const addr = '0x63B2f9C469F422De8069Ef6FE382672F16a367d3';
const hex = addr.replace('0x', '').toLowerCase();
const padded = hex.padStart(64, '0');
console.log('Recipient format:', padded);
"
```

**Output:**
```
00000000000000000000000063b2f9c469f422de8069ef6fe382672f16a367d3
```

## Step 2: Execute Transfer via terrad

**⚠️ Important:** The warp route hook requires an additional fee payment of `283215 uluna` for cross-chain gas. You must include this in the `--amount` parameter.

### Option 1: Direct Command

```bash
# Configuration
TERRA_WARP="terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8"
BSC_RECIPIENT="00000000000000000000000063b2f9c469f422de8069ef6fe382672f16a367d3"
DEST_DOMAIN=97
AMOUNT="1"  # Amount in uluna (1 uluna = 0.000001 LUNA)
HOOK_FEE="283215"  # Required hook fee for cross-chain gas payment
KEY_NAME="hypelane-val-testnet"
CHAIN_ID="rebel-2"
NODE="https://rpc.luncblaze.com:443"

# Calculate total: transfer amount + hook fee
TOTAL_AMOUNT=$((AMOUNT + HOOK_FEE))  # 1 + 283215 = 283216

# Execute transfer
# Note: --amount must be a single value (transfer amount + hook fee summed)
# ⚠️ terrad does NOT accept comma-separated values of the same denomination
terrad tx wasm execute ${TERRA_WARP} \
  "{\"transfer_remote\":{\"dest_domain\":${DEST_DOMAIN},\"recipient\":\"${BSC_RECIPIENT}\",\"amount\":\"${AMOUNT}\"}}" \
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

### Option 2: Using JSON File

Create a file `transfer-msg.json`:

```json
{
  "transfer_remote": {
    "dest_domain": 97,
    "recipient": "00000000000000000000000063b2f9c469f422de8069ef6fe382672f16a367d3",
    "amount": "1"
  }
}
```

Then execute:

```bash
# Include hook fee: 1uluna (transfer) + 283215uluna (hook fee) = 283216uluna
terrad tx wasm execute terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8 \
  "$(cat transfer-msg.json)" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --amount 74273215uluna \
  --yes
```

### Option 3: Using Script

See `script/transfer-uluna-terra-to-bsc.sh` for an automated script.

## Step 3: Verify Transaction

After execution, verify the transaction:

```bash
# Get transaction hash from output
TX_HASH="<YOUR_TX_HASH>"

# Query transaction
terrad query tx ${TX_HASH} \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443"
```

## Complete Example

Here's a complete example with all parameters:

```bash
#!/bin/bash

# Configuration
TERRA_WARP="terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8"
BSC_ADDRESS="0x63B2f9C469F422De8069Ef6FE382672F16a367d3"
DEST_DOMAIN=97
AMOUNT="1000000"  # 1 LUNA (1,000,000 uluna)
HOOK_FEE="283215"  # Required hook fee for cross-chain gas payment
KEY_NAME="hypelane-val-testnet"
CHAIN_ID="rebel-2"
NODE="https://rpc.luncblaze.com:443"

# Convert BSC address to Hyperlane format
BSC_RECIPIENT=$(node -e "
const addr = '${BSC_ADDRESS}';
const hex = addr.replace('0x', '').toLowerCase();
const padded = hex.padStart(64, '0');
console.log(padded);
")

echo "Transferring ${AMOUNT} uluna to BSC Testnet..."
echo "Recipient: ${BSC_ADDRESS}"
echo "Recipient (formatted): ${BSC_RECIPIENT}"
echo "Hook fee: ${HOOK_FEE} uluna"
echo "Total amount: $((AMOUNT + HOOK_FEE)) uluna"
echo ""

# Calculate total: transfer amount + hook fee
TOTAL_AMOUNT=$((AMOUNT + HOOK_FEE))

# Execute transfer
# Include both transfer amount and hook fee (summed into single value)
terrad tx wasm execute ${TERRA_WARP} \
  "{\"transfer_remote\":{\"dest_domain\":${DEST_DOMAIN},\"recipient\":\"${BSC_RECIPIENT}\",\"amount\":\"${AMOUNT}\"}}" \
  --from ${KEY_NAME} \
  --keyring-backend file \
  --chain-id ${CHAIN_ID} \
  --node ${NODE} \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --amount ${TOTAL_AMOUNT}uluna \
  --yes

echo ""
echo "✅ Transaction submitted!"
echo "Check status with: terrad query tx <TX_HASH> --chain-id ${CHAIN_ID} --node ${NODE}"
```

## Message Format

The execute message format is:

```json
{
  "transfer_remote": {
    "dest_domain": 97,
    "recipient": "00000000000000000000000063b2f9c469f422de8069ef6fe382672f16a367d3",
    "amount": "1"
  }
}
```

**Parameters:**
- `dest_domain`: BSC Testnet domain ID (97)
- `recipient`: BSC address in hex format (64 characters, padded)
- `amount`: Amount in uluna (as string)

**Important Notes:**
- The `recipient` must be exactly 64 hexadecimal characters (32 bytes)
- The address is padded with zeros on the left
- The amount is specified in `uluna` (1 LUNA = 1,000,000 uluna)
- **Hook Fee Required:** You must include `283215 uluna` additional fee for the hook payment
- The `--amount` flag must include both: transfer amount + hook fee (summed)
  - Example: `--amount 283216uluna` (1 + 283215 = 283216)
  - ⚠️ **Note:** `terrad` does not accept comma-separated values of the same denomination

## Using yarn cw-hpl warp transfer (Alternative)

You can also use the cw-hpl CLI:

```bash
yarn cw-hpl warp transfer \
  --asset-type native \
  --asset-id uluna \
  --target-domain 97 \
  --recipient 0x63B2f9C469F422De8069Ef6FE382672F16a367d3 \
  --amount 1000000 \
  -n terraclassic
```

This command automatically:
- Converts the recipient address to the correct format
- Handles the transaction execution
- Uses the warp route from the context file

## Troubleshooting

### Error: "spendable balance is smaller than 902968231127779000uluna"

**Problem:** The IGP (Interchain Gas Paymaster) is calculating an incorrect gas cost due to misconfigured IGP Oracle.

**Solution:** 
1. Check IGP Oracle configuration (see `CHECK-IGP-CONFIG.md`)
2. Verify the `token_exchange_rate` and `gas_price` for domain 97 are correct
3. Update IGP Oracle configuration via governance if needed

**Expected values for BSC Testnet (domain 97):**
- `token_exchange_rate`: `"14798000000000"` (calculado para resultar em 74 LUNC = $0.0044894)
- `gas_price`: `"50000000"`

**Cálculo do exchange_rate (BNB @ $897.88):**
- Custo necessário: 73,990,000 uluna (para pagar 0.000005 BNB de gas)
- Fórmula: `(73,990,000 × 10^18) / (100000 × 50000000) = 14798000000000`

**Nota:** O exchange_rate precisa ser atualizado quando o preço do BNB muda significativamente.

### Error: "insufficient hook payment" or "insufficient funds"

**Problem:** Not enough uluna to cover the transfer amount, hook fee, and transaction fees.

**Solution:** Make sure you have enough balance:
- Transfer amount: e.g., `1uluna`
- Hook fee: `283215uluna` (required for cross-chain gas payment)
- Transaction fees: `12000000uluna` (minimum)
- **Total needed:** Transfer amount + Hook fee + Transaction fees
  - Example: `1 + 283215 + 12000000 = 12283216 uluna` minimum

### Error: "route not found"

**Problem:** The warp route is not linked to the destination domain.

**Solution:** Make sure you've linked the routes (see `LINK-ULUNA-WARP-BSC.md`):
- Terra Classic → BSC: Route must be set
- BSC → Terra Classic: Router must be enrolled

### Error: "recipient format incorrect"

**Problem:** The recipient address is not in the correct format.

**Solution:** The recipient must be:
- Exactly 64 hexadecimal characters
- Lowercase
- Padded with zeros on the left
- Format: `00000000000000000000000063b2f9c469f422de8069ef6fe382672f16a367d3`

## Next Steps

After a successful transfer:

1. **Wait for relayers** to process the cross-chain message (usually a few minutes)
2. **Check BSC balance** to verify the tokens arrived
3. **Test reverse transfer** from BSC to Terra Classic

