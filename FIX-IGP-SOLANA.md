# Fix IGP Oracle Configuration for Solana Testnet

## Problem

When trying to transfer tokens from Terra Classic to Solana Testnet, you get an error:

```
spendable balance is smaller than 576750000000uluna: insufficient funds
```

This indicates the IGP (Interchain Gas Paymaster) is calculating an incorrect gas cost (~576.75 LUNC), which is way too high.

## Root Cause

The IGP Oracle is configured with incorrect values for Solana Testnet (domain 1399811150):
- **Current token_exchange_rate**: `57675000000000000` (INCORRECT)
- **Current gas_price**: `1`
- **Result**: ~576.75 LUNC per transfer (MASSIVELY OVERPRICED)

## Solution

Update the IGP Oracle configuration via governance proposal to use correct values following the same logic as BSC (from `IGP-COMPLETE-GUIDE.md`):
- **New token_exchange_rate**: `27470093900000`
- **New gas_price**: `1`
- **Expected result**: ~549.40 LUNC per transfer (with 20% margin)

## Calculation

Following **exactly** the same logic as BSC from `IGP-COMPLETE-GUIDE.md`:

### Step 1: Determine Gas Cost at Destination

```
gas_limit = 200,000 compute units
gas_price = 1 lamport per compute unit
destination_tx_cost_sol = 200,000 × 1 / 10^9 = 0.0002 SOL
```

### Step 2: Convert to USD

```
SOL_PRICE_USD = 138.93 (current price)
destination_tx_cost_usd = 0.0002 × 138.93 = $0.027786
```

### Step 3: Convert to Origin Token (LUNC)

```
LUNC_PRICE_USD = 0.00006069
origin_fee_lunc = 0.027786 / 0.00006069 = 457.83 LUNC
origin_fee_uluna = 457.83 × 1,000,000 = 457,834,898 uluna
```

### Step 4: Add Margin for Relayers (20%)

```
margem = 1.20
origin_fee_uluna_com_margem = 457,834,898 × 1.20 = 549,401,878 uluna
```

### Step 5: Calculate Exchange Rate for Oracle

```
# Formula: exchange_rate = (gas_needed × 10^10) / (gas_amount × gas_price)
TOKEN_EXCHANGE_RATE_SCALE = 10^10  # NOT 10^18!
exchange_rate = (549,401,878 × 10^10) / (200,000 × 1)
exchange_rate = 27,470,093,900,000
```

### Verification

```
gas_needed = (gas_amount × gas_price × exchange_rate) / 10^10
gas_needed = (200,000 × 1 × 27,470,093,900,000) / 10^10
gas_needed = 549,401,878 uluna = 549.40 LUNC ✅
```

## Step-by-Step Fix

### Step 1: Create Governance Proposal

Use the provided script:

```bash
cd /home/lunc/cw-hyperlane
bash script/update-igp-oracle-solana.sh
```

This will create `proposal-igp-oracle-solana-update.json` with the correct configuration.

### Step 2: Submit the Proposal

```bash
terrad tx gov submit-proposal proposal-igp-oracle-solana-update.json \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 28.5uluna \
  --yes
```

**Note**: The proposal includes a deposit of 1,000,000 uluna (1 LUNC), which meets the minimum deposit requirement.

### Step 3: Vote on the Proposal

After the proposal enters the voting period, vote:

```bash
# Replace <PROPOSAL_ID> with the actual proposal ID
terrad tx gov vote <PROPOSAL_ID> yes \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --gas-prices 28.5uluna \
  --yes
```

### Step 4: Verify the Update

After the proposal passes and executes, verify the configuration:

```bash
IGP_ORACLE="terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"

# Query the Oracle configuration
terrad query wasm contract-state smart ${IGP_ORACLE} \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":1399811150}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

**Expected output:**
```json
{
  "data": {
    "token_exchange_rate": "27470093900000",
    "gas_price": "1"
  }
}
```

### Step 5: Verify IGP Calculation

Check that the IGP now calculates the correct gas cost:

```bash
IGP="terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9"

terrad query wasm contract-state smart ${IGP} \
  '{"igp":{"quote_gas_payment":{"dest_domain":1399811150,"gas_amount":"200000"}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

**Expected output:**
```
data:
  gas_needed: "549401878"  # ~549.40 LUNC ✅
```

## Comparison

| Configuration | token_exchange_rate | gas_price | Cost per Transfer |
|--------------|---------------------|-----------|-------------------|
| **Current (WRONG)** | 57675000000000000 | 1 | ~576.75 LUNC |
| **New (CORRECT)** | 27470093900000 | 1 | ~549.40 LUNC |

**Improvement**: Correct calculation following `IGP-COMPLETE-GUIDE.md` formula. Uses `TOKEN_EXCHANGE_RATE_SCALE = 10^10` (not 10^18).

## After Fix

Once the IGP Oracle is updated, transfers from Terra Classic to Solana will work correctly:

```bash
# Transfer should now work with reasonable gas cost
TERRA_WARP="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"
SOLANA_DOMAIN="1399811150"
TRANSFER_AMOUNT="10000000"  # 10 LUNC
HOOK_FEE="283215"
IGP_GAS="549401878"  # ~549.40 LUNC (after fix, with 20% margin)
TOTAL_AMOUNT=$((TRANSFER_AMOUNT + HOOK_FEE + IGP_GAS))

terrad tx wasm execute ${TERRA_WARP} \
  "{\"transfer_remote\":{\"dest_domain\":${SOLANA_DOMAIN},\"recipient\":\"${SOLANA_RECIPIENT_HEX}\",\"amount\":\"${TRANSFER_AMOUNT}\"}}" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --amount ${TOTAL_AMOUNT}uluna \
  --yes
```

## Related Documents

- **[CHECK-IGP-CONFIG.md](./CHECK-IGP-CONFIG.md)** - How to check IGP configuration
- **[UPDATE-IGP-ORACLE-GOVERNANCE.md](./UPDATE-IGP-ORACLE-GOVERNANCE.md)** - General guide for updating IGP Oracle
- **[IGP-GAS-CALCULATION-SOURCES.md](./IGP-GAS-CALCULATION-SOURCES.md)** - IGP gas calculation formula and sources
- **[TRANSFER-ULUNA-TERRA-TO-BSC.md](./TRANSFER-ULUNA-TERRA-TO-BSC.md)** - BSC transfer guide (working example)

## Notes

- The IGP Oracle owner is the governance module (`terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n`), so updates must go through governance
- **IMPORTANT**: The gas cost calculation uses: `cost = (gas_amount × gas_price × exchange_rate) / 10^10` (NOT 10^18!)
- The `TOKEN_EXCHANGE_RATE_SCALE = 10^10` as per `IGP-COMPLETE-GUIDE.md`
- If Solana gas prices, SOL price, or LUNC price change significantly, the exchange_rate may need to be updated again
- The calculation includes a 20% margin for relayers
- Current values based on: SOL @ $138.93, LUNC @ $0.00006069, gas_limit 200k

