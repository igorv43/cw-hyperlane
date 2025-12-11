# Check and Fix IGP Configuration

## Problem

When trying to transfer, you get an error:
```
spendable balance is smaller than 902968231127779000uluna: insufficient funds
```

This indicates the IGP (Interchain Gas Paymaster) is calculating an incorrect gas cost, likely due to misconfigured IGP Oracle.

## Step 1: Check IGP Oracle Configuration

Query the IGP Oracle to see the current configuration for BSC Testnet (domain 97):

```bash
# IGP Oracle address (replace with your actual address)
IGP_ORACLE="terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"

# Query configuration for BSC Testnet (domain 97)
terrad query wasm contract-state smart ${IGP_ORACLE} \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":97}}}' \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443"
```

**Expected output (correct configuration):**
```json
{
  "data": {
    "token_exchange_rate": "1805936462255558",
    "gas_price": "50000000"
  }
}
```

If the values are incorrect or missing, you need to update the IGP Oracle configuration.

## Step 2: Check IGP Routes

Verify that the IGP is configured to use the Oracle:

```bash
# IGP address (replace with your actual address)
IGP="terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9"

# Query routes
terrad query wasm contract-state smart ${IGP} \
  '{"router":{"get_route":{"domain":97}}}' \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443"
```

**Expected output:**
```
terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg
```

This should match your IGP Oracle address.

## Step 3: Fix IGP Oracle Configuration

If the configuration is incorrect, you need to update it via governance proposal.

### Correct Configuration for BSC Testnet (Domain 97)

```json
{
  "set_remote_gas_data_configs": {
    "configs": [
      {
        "remote_domain": 97,
        "token_exchange_rate": "1805936462255558",
        "gas_price": "50000000"
      }
    ]
  }
}
```

**Parameters:**
- `remote_domain`: `97` (BSC Testnet)
- `token_exchange_rate`: `"1805936462255558"` (LUNC:BNB exchange rate)
- `gas_price`: `"50000000"` (0.05 Gwei on BSC Testnet)

### Create Governance Proposal

Create a proposal JSON file `fix-igp-oracle.json`:

```json
{
  "messages": [
    {
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      "sender": "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze",
      "contract": "terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg",
      "msg": {
        "set_remote_gas_data_configs": {
          "configs": [
            {
              "remote_domain": 97,
              "token_exchange_rate": "1805936462255558",
              "gas_price": "50000000"
            }
          ]
        }
      },
      "funds": []
    }
  ],
  "metadata": "ipfs://QmYourMetadataHash",
  "deposit": "10000000uluna",
  "title": "Fix IGP Oracle Configuration for BSC Testnet",
  "summary": "Update IGP Oracle gas data configuration for domain 97 (BSC Testnet) to correct exchange rate and gas price"
}
```

Then submit the proposal (see governance documentation for details).

## Step 4: Alternative - Use Fee Hook Only (Temporary Workaround)

If you cannot update the IGP Oracle immediately, you could temporarily disable the IGP hook and use only the fee hook. However, this is **NOT recommended** for production as it means cross-chain gas won't be paid properly.

**⚠️ This is only a temporary workaround and should not be used in production.**

## Verification After Fix

After updating the IGP Oracle configuration, verify it's correct:

```bash
# Query again
terrad query wasm contract-state smart ${IGP_ORACLE} \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":97}}}' \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443"
```

Then try the transfer again. The gas cost should be much lower (around 283215 uluna for the hook fee, plus a small amount for IGP gas).

## Expected Gas Cost Calculation

With correct IGP Oracle configuration:
- **Hook Fee**: 283215 uluna (fixed fee)
- **IGP Gas**: ~100000 gas × 50000000 gas_price × 1805936462255558 exchange_rate / 10^18 ≈ small amount
- **Total**: Should be around 283215-300000 uluna (not 902 trillion!)

## Troubleshooting

### Error: "oracle not found" or "route not found"

**Problem:** IGP is not configured to use the Oracle for domain 97.

**Solution:** Set the IGP route for domain 97 to point to the IGP Oracle address.

### Error: Configuration returns very high values

**Problem:** The `token_exchange_rate` or `gas_price` values are incorrect.

**Solution:** Update the IGP Oracle configuration with correct values (see Step 3).

### Error: IGP Oracle address not found

**Problem:** You don't know your IGP Oracle address.

**Solution:** Check your deployment context file or query the IGP contract to find the Oracle address.

