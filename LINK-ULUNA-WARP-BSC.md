# Link uluna Warp Route: Terra Classic ↔ BSC Testnet

This guide shows how to link the uluna native warp route between Terra Classic Testnet and BSC Testnet.

## Prerequisites

- uluna warp route deployed on Terra Classic Testnet: `terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8`
  - [View on Terra Classic Explorer](https://finder.terra-classic.hexxagon.dev/testnet/address/terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8)
- uluna warp route deployed on BSC Testnet: `0x63B2f9C469F422De8069Ef6FE382672F16a367d3`
- Both warp routes must be deployed before linking

## Step 1: Link Terra Classic → BSC Testnet

This command links the Terra Classic warp route to the BSC Testnet warp route.

```bash
yarn cw-hpl warp link \
  --asset-type native \
  --asset-id uluna \
  --target-domain 97 \
  --warp-address 0x63B2f9C469F422De8069Ef6FE382672F16a367d3 \
  -n terraclassic
```

**Parameters:**
- `--asset-type native`: Native token (uluna)
- `--asset-id uluna`: Asset identifier
- `--target-domain 97`: BSC Testnet domain ID (not 96!)
- `--warp-address 0x63B2f9C469F422De8069Ef6FE382672F16a367d3`: BSC warp route address
- `-n terraclassic`: Network (Terra Classic)

**Important Notes:**
- The `yarn cw-hpl warp link` command automatically converts the BSC address to the correct hex format (64 characters, padded)
- Domain must be **97** for BSC Testnet (not 96)
- The Terra Classic warp route contract address will be read from the context file (created when you ran `yarn cw-hpl warp create`)

## Step 2: Verify the Route Format

The route address in the execution message should be the BSC address converted to hex with padding:

**BSC Address:** `0x63B2f9C469F422De8069Ef6FE382672F16a367d3`

**Correct Route Format (64 hex characters):**
```
00000000000000000000000063b2f9c469f422de8069ef6fe382672f16a367d3
```

**Verification:**
```bash
# Convert address to correct format
node -e "
const addr = '0x63B2f9C469F422De8069Ef6FE382672F16a367d3';
const hex = addr.replace('0x', '').toLowerCase();
const padded = hex.padStart(64, '0');
console.log('Route format:', padded);
"
```

## Step 3: Link BSC Testnet → Terra Classic

After linking Terra → BSC, you need to link BSC → Terra using the Hyperlane CLI:

```bash
# Get Terra Classic warp route address first
# (from the output of: yarn cw-hpl warp create ./example/warp/uluna.json -n terraclassic)
TERRA_WARP_ADDRESS="terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8"

# Link BSC → Terra Classic
hyperlane warp link \
  --warp 0x63B2f9C469F422De8069Ef6FE382672F16a367d3 \
  --destination terraclassic \
  --destination-warp ${TERRA_WARP_ADDRESS} \
  --private-key $BSC_PRIVATE_KEY
```

## Manual Execution (If Needed)

If you need to execute the link manually via governance or direct execution:

### Option 1: Using the Script

```bash
# Make sure TERRA_WARP_ADDRESS is set correctly in the script
./script/link-uluna-warp-terrad.sh
```

### Option 2: Direct terrad Command

**Message format:**
```json
{
  "router": {
    "set_route": {
      "set": {
        "domain": 97,
        "route": "00000000000000000000000063b2f9c469f422de8069ef6fe382672f16a367d3"
      }
    }
  }
}
```

**Execute via terrad:**
```bash
# Terra Classic warp route address
TERRA_WARP="terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8"

terrad tx wasm execute ${TERRA_WARP} \
  '{"router":{"set_route":{"set":{"domain":97,"route":"00000000000000000000000063b2f9c469f422de8069ef6fe382672f16a367d3"}}}}' \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

**⚠️ Important:** 
- The route must be exactly 64 hexadecimal characters
- Format: `00000000000000000000000063b2f9c469f422de8069ef6fe382672f16a367d3`
- This is the BSC address `0x63B2f9C469F422De8069Ef6FE382672F16a367d3` converted to hex (lowercase, no 0x, padded to 64 chars)

## Verification

After linking, verify the route is set:

```bash
# Query route on Terra Classic
TERRA_WARP="terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8"

terrad query wasm contract-state smart ${TERRA_WARP} \
  '{"router":{"route":{"domain":97}}}' \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443"
```

## Common Issues

### Issue: Route address format incorrect

**Problem:** The route in the execution message doesn't match the BSC address.

**Solution:** The route must be:
- 64 hexadecimal characters (32 bytes)
- Lowercase
- Padded with zeros on the left
- Format: `00000000000000000000000063b2f9c469f422de8069ef6fe382672f16a367d3`

### Issue: Domain incorrect

**Problem:** Using domain 96 instead of 97.

**Solution:** BSC Testnet domain is **97**, not 96.

### Issue: Contract address not found

**Problem:** Terra Classic warp route contract not found in context.

**Solution:** Make sure you ran `yarn cw-hpl warp create ./example/warp/uluna.json -n terraclassic` first.

## Next Steps

After successfully linking both directions:

1. **Test Transfer Terra → BSC:**
   ```bash
   yarn cw-hpl warp transfer \
     --asset-type native \
     --asset-id uluna \
     --amount 1000000 \
     --recipient 0xYOUR_BSC_ADDRESS \
     --target-domain 97 \
     -n terraclassic
   ```

2. **Test Transfer BSC → Terra:**
   ```bash
   hyperlane warp transfer \
     --warp 0x63B2f9C469F422De8069Ef6FE382672F16a367d3 \
     --amount 1000000 \
     --recipient terra1YOUR_TERRA_ADDRESS \
     --destination terraclassic \
     --private-key $BSC_PRIVATE_KEY
   ```

