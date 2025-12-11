# Fix IGP Exchange Rate - High Gas Cost Issue

## Problem Identified

The IGP is calculating `902968231127779000` uluna for 100000 gas on domain 97, which is causing the transfer to fail with "insufficient funds".

**Root Cause:** The `token_exchange_rate` value of `1805936462255558` is too high, causing the gas cost calculation to be extremely high.

## Current Configuration

- `gas_amount`: 100000
- `gas_price`: 50000000 (0.05 Gwei)
- `token_exchange_rate`: 1805936462255558
- **Calculated cost**: 902968231127779000 uluna (902 trillion uluna!)

## Solution: Update Exchange Rate

The exchange rate needs to be recalculated to a more reasonable value.

### Recommended Exchange Rate Calculation

The exchange rate must be calculated to result in the correct gas cost in uluna.

**Step 1: Calculate actual gas cost**
- Gas used: 100000
- Gas price: 50000000 wei (0.05 Gwei)
- Cost in BNB: 0.000005 BNB
- Cost in USD: 0.000005 × $300 = $0.0015
- Cost in LUNC: $0.0015 / $0.00006069 = 24.72 LUNC
- **Cost in uluna: 24,715,768 uluna**

**Step 2: Calculate exchange rate**
IGP formula: `cost_uluna = (gas × gas_price × exchange_rate) / 10^18`

Therefore:
```
exchange_rate = (cost_uluna × 10^18) / (gas × gas_price)
```

**With current BNB price ($897.88):**
- Cost in uluna: 73,990,000 uluna (for 0.000005 BNB = $0.0044894)
- Exchange rate: (73,990,000 × 10^18) / (100000 × 50000000) = 14798000000000

**Recommended value:** `14798000000000` (much lower than current `1805936462255558`)

**Note:** This exchange_rate is based on current BNB price ($897.88). If BNB price changes significantly, you'll need to update it again.

### Gas Cost Calculation

With correct exchange rate (`14798000000000`) and current BNB price ($897.88):
- Gas used: 100000
- Gas price: 50000000 wei (0.05 Gwei)
- Exchange rate: 14798000000000
- **Cost in uluna: 73,990,000 uluna** (~74 LUNC)

This covers:
- Cost in BNB: 0.000005 BNB
- Cost in USD: $0.0044894 (0.000005 BNB × $897.88)
- Cost in LUNC: 73.99 LUNC

Plus hook fee (283215 uluna), **total: ~74,273,215 uluna (~74.27 LUNC = $0.0045)**

### Alternative: Use 1:1 Exchange Rate for Testing

For testing purposes, you could use a 1:1 exchange rate:

```
exchange_rate = 1 × 10^18 = 1000000000000000000
```

But this might still be too high. A better test value would be:

```
exchange_rate = 1000000000000000  (1 × 10^15)
```

## Update IGP Oracle Configuration

Create a governance proposal to update the exchange rate:

```json
{
  "set_remote_gas_data_configs": {
    "configs": [
      {
        "remote_domain": 97,
        "token_exchange_rate": "14798000000000",
        "gas_price": "50000000"
      }
    ]
  }
}
```

**Note:** This exchange_rate is calculated for BNB @ $897.88. Update it if BNB price changes significantly.

Execute this on the IGP Oracle contract:
- **Contract**: `terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg`

## Expected Result After Fix

With the corrected exchange rate:
- `gas_amount`: 100000
- `gas_price`: 50000000
- `token_exchange_rate`: 202300000000
- **Calculated cost**: ~24,715,769 uluna (~24.72 LUNC)

This covers the BSC gas cost:
- 0.000005 BNB × $300 = $0.0015
- $0.0015 / $0.00006069 = 24.72 LUNC = 24,715,769 uluna

Plus the hook fee of 283215 uluna, **total: ~25,000,000 uluna (25 LUNC)** instead of 902 trillion!

## Verification After Update

After updating the exchange rate, verify the new calculation:

```bash
IGP="terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9"

terrad query wasm contract-state smart ${IGP} \
  '{"igp":{"quote_gas_payment":{"dest_domain":97,"gas_amount":"100000"}}}' \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443"
```

The result should be **73,990,000 uluna** (~74 LUNC = $0.0044894) instead of 902 trillion uluna or $1512.01.

**Note:** This is based on current BNB price ($897.88). The exchange_rate should be updated when BNB price changes significantly.

## Governance Proposal Example

See `GOVERNANCE-OPERATIONS-TESTNET.md` for how to create a governance proposal to update the IGP Oracle configuration.

