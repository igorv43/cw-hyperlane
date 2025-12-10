# Enroll Remote Router: BSC Testnet → Terra Classic

This guide shows how to enroll the Terra Classic warp route as a remote router on the BSC Testnet warp route contract.

## Overview

After linking Terra Classic → BSC, you need to enroll the Terra Classic router on the BSC side so that BSC knows where to send messages to Terra Classic.

**✅ Tested and Working:** The interactive Safe CLI method (Option 1) has been successfully tested. The complete step-by-step process is documented below with actual output examples.

## Prerequisites

- BSC Testnet warp route: `0x63B2f9C469F422De8069Ef6FE382672F16a367d3`
- Terra Classic warp route: `terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8`
- Terra Classic domain: `1325`
- Safe address on BSC Testnet (owner of the BSC warp route)

## Step 1: Convert Terra Classic Address to Hex Format

The Terra Classic bech32 address needs to be converted to a 32-byte hex format for the EVM contract.

**Terra Classic Address:**
```
terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8
```

**Converted Hex (32 bytes):**
```
0x0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02
```

### How to Convert (Optional - for verification)

You can verify the conversion using Node.js:

```bash
node -e "
const { fromBech32 } = require('@cosmjs/encoding');
const addr = 'terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8';
const { data } = fromBech32(addr);
const hexed = Buffer.from(data).toString('hex');
const padded = hexed.padStart(64, '0');
console.log('Hex (32 bytes):', '0x' + padded);
"
```

Or use the cw-hpl CLI:

```bash
yarn cw-hpl wallet bech32-to-hex terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8
```

## Step 2: Generate Calldata

Generate the calldata for the `enrollRemoteRouter` function:

```bash
cast calldata "enrollRemoteRouter(uint32,bytes32)" \
  1325 \
  0x0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02
```

**Expected output:**
```
0xb49c53a7000000000000000000000000000000000000000000000000000000000000052d0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02
```

## Step 3: Execute via Safe CLI

### Option 1: Using Safe CLI (Recommended - Interactive Mode)

The Safe CLI provides an interactive mode that guides you through the process. This is the recommended method.

#### Step 3.1: Open Safe Account (if not already open)

```bash
safe account open tbnb:0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee --name "BSC Testnet Safe"
```

#### Step 3.2: Create Transaction (Interactive Mode)

Simply run:

```bash
safe tx create
```

The CLI will prompt you for each parameter:

1. **Select Safe**: Choose your Safe (e.g., "BSC Testnet Safe")
2. **To address**: Enter `tbnb:0x63B2f9C469F422De8069Ef6FE382672F16a367d3` (supports EIP-3770 format)
3. **Value in wei**: Enter `0` (no ETH/BNB transfer)
4. **Transaction data (hex)**: Enter the calldata:
   ```
   0xb49c53a7000000000000000000000000000000000000000000000000000000000000052d0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02
   ```
5. **Operation type**: Choose `Call`
6. **Transaction nonce**: Leave empty for default (or use recommended nonce)

**Expected output:**
```
✓ Transaction created successfully!

  Safe TX Hash: 0xd7a8a7d5cf62122f542cf3177b4056d6cfdd872baa231a2129ec89060473cc3d

◇  Would you like to sign this transaction now?
  Yes
```

#### Step 3.3: Sign Transaction

When prompted "Would you like to sign this transaction now?", choose **Yes**.

Enter your wallet password when prompted.

**Expected output:**
```
✓ Signature added (1/1 required)
✓ Transaction is ready to execute!

◇  What would you like to do?
  Execute transaction on-chain
```

#### Step 3.4: Execute Transaction

When prompted "What would you like to do?", choose **Execute transaction on-chain**.

Confirm execution when asked "Execute this transaction on-chain?" by choosing **Yes**.

Enter your wallet password again when prompted.

**Expected output:**
```
✓ Transaction Executed Successfully!

Tx Hash:  0x3f7b24274642a96d3202b3b71f00521464510dc97cc3b035ace863922b0152aa

Transaction confirmed on-chain
```

#### Complete Interactive Flow Example

Here's the complete interactive flow:

```bash
$ safe tx create

┌  Create Safe Transaction
│
◇  Select Safe to create transaction for
│  BSC Testnet Safe (tbnb:0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee)
│
◇  To address (supports EIP-3770 format: shortName:address)
│  tbnb:0x63B2f9C469F422De8069Ef6FE382672F16a367d3
│
◇  Value in wei (0 for token transfer)
│  0
│
◇  Transaction data (hex)
│  0xb49c53a7000000000000000000000000000000000000000000000000000000000000052d0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02
│
◇  Operation type
│  Call
│
✓ Transaction created successfully!
  Safe TX Hash: 0xd7a8a7d5cf62122f542cf3177b4056d6cfdd872baa231a2129ec89060473cc3d
│
◇  Would you like to sign this transaction now?
│  Yes
│
✓ Signature added (1/1 required)
✓ Transaction is ready to execute!
│
◇  What would you like to do?
│  Execute transaction on-chain
│
✓ Transaction Executed Successfully!
Tx Hash:  0x3f7b24274642a96d3202b3b71f00521464510dc97cc3b035ace863922b0152aa
```

### Option 2: Using Safe CLI (Non-Interactive Mode)

If you prefer to provide all parameters at once:

```bash
# Make sure you have the Safe open
safe account open tbnb:0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee --name "BSC Testnet Safe"

# Create transaction
safe tx create \
  --to tbnb:0x63B2f9C469F422De8069Ef6FE382672F16a367d3 \
  --value 0 \
  --data 0xb49c53a7000000000000000000000000000000000000000000000000000000000000052d0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02
```

**Parameters:**
- `--to`: BSC warp route contract address (EIP-3770 format: `tbnb:0x...`)
- `--value`: 0 (no ETH/BNB transfer)
- `--data`: Calldata from Step 2

### Option 2: Using cast (If Safe CLI has issues)

If you encounter `GS013` error with Safe CLI, use `cast` directly:

#### Step 1: Approve Hash on-chain

```bash
# Get the Safe TX hash from safe tx status
SAFE_TX_HASH="0x..."  # From safe tx status output

# Approve hash
cast send 0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee \
  "approveHash(bytes32)" \
  ${SAFE_TX_HASH} \
  --private-key 0xYOUR_PRIVATE_KEY \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545 \
  --legacy \
  --gas-price 100000000
```

#### Step 2: Execute Transaction

```bash
cast send 0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee \
  "execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)" \
  0x63B2f9C469F422De8069Ef6FE382672F16a367d3 \
  0 \
  0xb49c53a7000000000000000000000000000000000000000000000000000000000000052d0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02 \
  0 \
  200000 \
  0 \
  100000000 \
  0x0000000000000000000000000000000000000000 \
  0x0000000000000000000000000000000000000000 \
  0x \
  --private-key 0xYOUR_PRIVATE_KEY \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545 \
  --legacy \
  --gas-price 100000000
```

**Note:** The signature format `0x` is used because the hash was already approved via `approveHash`.

## Step 4: Verify Enrollment

After execution, verify that the router was enrolled:

```bash
# Query the enrolled router for domain 1325
cast call 0x63B2f9C469F422De8069Ef6FE382672F16a367d3 \
  "routers(uint32)(bytes32)" \
  1325 \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

**Expected output:**
```
0x0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02
```

This should match the Terra Classic warp route address in hex format.

## Complete Command Reference

### Full Command (Safe CLI - Interactive Mode - ✅ Tested and Working)

This is the complete step-by-step process that was successfully tested:

```bash
# 1. Generate calldata (optional - for reference)
cast calldata "enrollRemoteRouter(uint32,bytes32)" \
  1325 \
  0x0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02

# Output: 0xb49c53a7000000000000000000000000000000000000000000000000000000000000052d0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02

# 2. Open Safe account (if not already open)
safe account open tbnb:0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee --name "BSC Testnet Safe"

# 3. Create transaction (interactive mode)
safe tx create

# Follow the interactive prompts:
# - Select Safe: "BSC Testnet Safe (tbnb:0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee)"
# - To address: "tbnb:0x63B2f9C469F422De8069Ef6FE382672F16a367d3"
# - Value: "0"
# - Transaction data: "0xb49c53a7000000000000000000000000000000000000000000000000000000000000052d0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02"
# - Operation type: "Call"
# - Transaction nonce: (leave empty or use recommended)

# 4. When asked "Would you like to sign this transaction now?", choose "Yes"
#    Enter wallet password when prompted

# 5. When asked "What would you like to do?", choose "Execute transaction on-chain"
#    Confirm execution: "Yes"
#    Enter wallet password again when prompted

# Expected result:
# ✓ Transaction Executed Successfully!
# Tx Hash: 0x3f7b24274642a96d3202b3b71f00521464510dc97cc3b035ace863922b0152aa
```

### Full Command (Safe CLI - Non-Interactive Mode)

```bash
# 1. Generate calldata
CALLDATA=$(cast calldata "enrollRemoteRouter(uint32,bytes32)" \
  1325 \
  0x0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02)

# 2. Create Safe transaction
safe tx create \
  --to tbnb:0x63B2f9C469F422De8069Ef6FE382672F16a367d3 \
  --value 0 \
  --data ${CALLDATA}

# 3. Sign (when prompted, choose "Yes")

# 4. Execute (if threshold met)
safe tx execute
```

### Full Command (cast - for GS013 errors)

```bash
# 1. Generate calldata
CALLDATA=$(cast calldata "enrollRemoteRouter(uint32,bytes32)" \
  1325 \
  0x0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02)

# 2. Create transaction via Safe CLI to get Safe TX hash
safe tx create \
  --to 0x63B2f9C469F422De8069Ef6FE382672F16a367d3 \
  --value 0 \
  --data ${CALLDATA}

# 3. Get Safe TX hash from safe tx status
SAFE_TX_HASH="0x..."  # From safe tx status

# 4. Approve hash
cast send 0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee \
  "approveHash(bytes32)" \
  ${SAFE_TX_HASH} \
  --private-key 0xYOUR_PRIVATE_KEY \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545 \
  --legacy \
  --gas-price 100000000

# 5. Execute
cast send 0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee \
  "execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)" \
  0x63B2f9C469F422De8069Ef6FE382672F16a367d3 \
  0 \
  ${CALLDATA} \
  0 \
  200000 \
  0 \
  100000000 \
  0x0000000000000000000000000000000000000000 \
  0x0000000000000000000000000000000000000000 \
  0x \
  --private-key 0xYOUR_PRIVATE_KEY \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545 \
  --legacy \
  --gas-price 100000000
```

## Function Signature

The `enrollRemoteRouter` function signature:

```solidity
function enrollRemoteRouter(uint32 _domain, bytes32 _router) external;
```

**Parameters:**
- `_domain`: Terra Classic domain ID (1325)
- `_router`: Terra Classic warp route address in hex format (32 bytes)

## Important Notes

1. **Domain ID**: Terra Classic domain is `1325` (not to be confused with other networks)
2. **Address Format**: The Terra Classic address must be converted from bech32 to 32-byte hex format
3. **Ownership**: The Safe must be the owner of the BSC warp route contract
4. **Bidirectional**: After enrolling on BSC, make sure Terra Classic → BSC is also linked (see `LINK-ULUNA-WARP-BSC.md`)

## Troubleshooting

### Error: "execution reverted"

**Possible causes:**
- The Safe is not the owner of the BSC warp route contract
- The domain ID is incorrect
- The router address format is incorrect

**Solution:**
- Verify Safe ownership: `cast call 0x63B2f9C469F422De8069Ef6FE382672F16a367d3 "owner()(address)" --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545`
- Double-check domain ID (should be 1325)
- Verify router address conversion

### Error: GS013

**Solution:** Use the `cast` method with `approveHash` first, then `execTransaction` (see Option 2 above).

## Next Steps

After successfully enrolling the remote router:

1. **Verify both directions are linked:**
   - Terra Classic → BSC: Check route on Terra Classic
   - BSC → Terra Classic: Verify router enrollment on BSC

2. **Test cross-chain transfer:**
   - Transfer from Terra Classic to BSC
   - Transfer from BSC to Terra Classic

