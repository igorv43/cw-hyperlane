# How to Find Terra Classic Warp Route Contract Address

## Problem

Error: `address terra1d0rjs8lhq675dxt4z435gnpf76t7pj0avv07jcsxrq970ty5tr8s5r2qz0: no such contract`

This means the contract address is incorrect or the contract doesn't exist.

## Solution: Find the Correct Contract Address

### Method 1: From Transaction Hash (If you have it)

If you have the transaction hash from when you instantiated the uluna warp route:

```bash
TX_HASH="<YOUR_TX_HASH>"

# Get contract address from transaction
terrad query tx ${TX_HASH} \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --output json | jq -r '.logs[0].events[] | select(.type == "instantiate") | .attributes[] | select(.key == "_contract_address") | .value'
```

### Method 2: Check Context File

The `yarn cw-hpl warp create` command saves the contract address in the context file:

```bash
# Check context file
cat context/terraclassic.json | jq '.deployments.warp.native[] | select(.id == "uluna")'
```

### Method 3: Query All Contracts from Your Address

If you know the address that created the contract:

```bash
# Query all contracts created by your address
CREATOR="terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze"

# This is more complex - you may need to check block explorer
# Or use the transaction hash method above
```

### Method 4: Use yarn cw-hpl warp link (Recommended)

The `yarn cw-hpl warp link` command automatically finds the contract address from the context:

```bash
# This will use the contract address from context/terraclassic.json
yarn cw-hpl warp link \
  --asset-type native \
  --asset-id uluna \
  --target-domain 97 \
  --warp-address 0x63B2f9C469F422De8069Ef6FE382672F16a367d3 \
  -n terraclassic
```

**This is the easiest method** - it reads the contract address from the context file automatically.

## Verify Contract Exists

Once you have the contract address, verify it exists:

```bash
CONTRACT_ADDRESS="<CONTRACT_ADDRESS>"

# Query contract info
terrad query wasm contract ${CONTRACT_ADDRESS} \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443"
```

If the contract exists, you'll see the contract information. If not, you'll get an error.

## If Contract Doesn't Exist

If the contract doesn't exist, you need to create it first:

```bash
# Create uluna warp route
yarn cw-hpl warp create ./example/warp/uluna.json -n terraclassic
```

This will:
1. Instantiate the contract
2. Save the address in `context/terraclassic.json`
3. Then you can use `yarn cw-hpl warp link` which will automatically use the correct address

