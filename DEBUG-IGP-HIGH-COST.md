# Debug IGP High Gas Cost Issue

## Problem

IGP Oracle configuration is correct, but IGP is still calculating a very high gas cost (`902968231127779000uluna`).

## Possible Causes

1. **IGP route not configured** - IGP doesn't know where to find the Oracle
2. **Default gas usage too high** - IGP using incorrect default gas value
3. **IGP not querying Oracle** - IGP falling back to default calculation

## Step 1: Verify IGP Route Configuration

Check if IGP is configured to use the Oracle for domain 97:

```bash
# IGP address
IGP="terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9"

# Query route for domain 97
terrad query wasm contract-state smart ${IGP} \
  '{"router":{"get_route":{"domain":97}}}' \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443"
```

**Expected:** Should return the IGP Oracle address:
```
terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg
```

**If it returns empty or different address:** The route is not configured correctly.

## Step 2: Check IGP Default Gas

Query the IGP contract to see the default gas:

```bash
# Query IGP default gas
terrad query wasm contract-state smart ${IGP} \
  '{"igp":{"default_gas":{}}}' \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443"
```

**Expected:** Should be around `100000` (not millions or billions).

If it's very high, that could explain the high cost calculation.

## Step 2.5: Check Gas for Domain 97

Query the specific gas configuration for domain 97:

```bash
# Query gas for domain 97
terrad query wasm contract-state smart ${IGP} \
  '{"igp":{"gas_for_domain":{"domain":97}}}' \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443"
```

This shows the actual gas amount being used for calculations for BSC Testnet.

## Step 3: Verify IGP Can Query Oracle

Test if IGP can successfully query the Oracle:

```bash
# This is more complex - you may need to check the IGP contract code
# or test via a direct query to see if the route works
```

## Step 4: Fix IGP Route (If Not Configured)

If the route is not configured, you need to set it via governance:

```json
{
  "router": {
    "set_routes": {
      "set": [
        {
          "domain": 97,
          "route": "terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"
        }
      ]
    }
  }
}
```

Execute this on the IGP contract address.

## Step 5: Check Hook Configuration

The issue might also be in how the hooks are configured. Verify the default hook includes IGP:

```bash
# Mailbox address
MAILBOX="terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf"

# Query default hook
terrad query wasm contract-state smart ${MAILBOX} \
  '{"hook":{"default_hook":{}}}' \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443"
```

The default hook should be an aggregate hook that includes the IGP.

## Calculation Check

With correct configuration:
- `default_gas_usage`: 100000
- `gas_price`: 50000000
- `token_exchange_rate`: 1805936462255558

Cost = (100000 × 50000000 × 1805936462255558) / 10^18
     = 9029682311277790000 / 10^18
     = 9029682311277790000 / 1000000000000000000
     = 9.02968231127779 uluna

Wait, that doesn't match. Let me recalculate...

Actually, the issue might be that the calculation is:
Cost = (gas_usage × gas_price × exchange_rate) / (10^18 for exchange_rate scaling)

But if the exchange_rate is already scaled, and gas_price is in wei/gwei, the calculation might be different.

The value `902968231127779000` suggests the calculation might be:
- Using wrong units
- Missing division by scaling factor
- Using exchange_rate directly without proper scaling

## Temporary Workaround

If you need to test transfers immediately, you could:

1. **Temporarily reduce exchange_rate** (not recommended for production)
2. **Use a different hook configuration** without IGP (not recommended)
3. **Fix the IGP route configuration** (recommended)

## Next Steps

1. Run the queries above to check IGP route and default_gas_usage
2. If route is missing, create governance proposal to set it
3. If default_gas_usage is too high, it might need to be adjusted
4. Verify the hook configuration includes IGP correctly

