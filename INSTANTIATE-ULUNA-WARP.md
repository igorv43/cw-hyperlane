# Instantiate uluna Native Warp Route on Terra Classic Testnet

This guide shows how to instantiate the uluna native warp route contract on Terra Classic Testnet using `terrad`.

**✅ This guide has been tested and verified to work successfully.**

## Quick Start (Tested Command)

If you already have a key in your keyring (e.g., `hypelane-val-testnet`), you can use this command directly:

```bash
# 1. Create message file
cat > uluna-msg.json << 'EOF'
{
  "token": {
    "collateral": {
      "denom": "uluna"
    }
  },
  "hrp": "terra",
  "owner": "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze",
  "mailbox": "terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf"
}
EOF

# 2. Execute (replace 'hypelane-val-testnet' with your key name)
terrad tx wasm instantiate 2000 \
  "$(cat uluna-msg.json)" \
  --label "cw-hpl: hpl_warp_native" \
  --admin "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

**Critical Requirements:**
- ✅ Key must be in keyring (use `--from <key-name>`)
- ✅ RPC URL must include port: `https://rpc.luncblaze.com:443`
- ✅ Fees must be sufficient: `12000000uluna` (0.012 LUNC minimum)

## Prerequisites

- `terrad` CLI installed and configured
- Wallet with funds on Terra Classic Testnet (rebel-2)
- Wallet address: `terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze` (or your own)
- **Key added to terrad keyring** (see [Adding Key to Keyring](#adding-key-to-keyring) below)

## Adding Key to Keyring

Before executing the instantiation command, you need to add your key to the terrad keyring.

### Option 1: Add Key Using Mnemonic (Recommended)

```bash
# Add key with a name
terrad keys add uluna-warp --recover --keyring-backend file

# You will be prompted to:
# 1. Enter your bip39 mnemonic phrase
# 2. Enter and confirm a keyring passphrase
```

### Option 2: Add Key Using Private Key

If you have the private key in hexadecimal format:

```bash
# Method 1: Interactive
echo "YOUR_PRIVATE_KEY_HEX" | terrad keys add uluna-warp --recover --keyring-backend file

# Method 2: Using script
./script/add-key-terrad.sh
```

### Option 3: Check Existing Keys

```bash
# List all keys
terrad keys list --keyring-backend file

# Or try other backends
terrad keys list --keyring-backend os
```

### Verify Key Address

After adding the key, verify it matches your expected address:

```bash
terrad keys show uluna-warp --keyring-backend file --address
```

**Note:** If your address is `terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze`, make sure the key you add corresponds to this address.

## Contract Details

- **Code ID**: `2000` (hpl_warp_native)
- **Label**: `cw-hpl: hpl_warp_native`
- **Mailbox Address**: `terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf`
- **Owner**: `terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze`
- **Admin**: `terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze`

## Method 1: Using the Script

```bash
# Make sure you're in the project root
cd /home/lunc/cw-hyperlane

# Execute the script
./script/instantiate-uluna-warp.sh
```

**Note:** The script will prompt you to add a key if it's not found in the keyring.

## Method 2: Direct terrad Command

### Step 1: Create the instantiation message file

```bash
cat > /tmp/uluna-instantiate-msg.json << 'EOF'
{
  "token": {
    "collateral": {
      "denom": "uluna"
    }
  },
  "hrp": "terra",
  "owner": "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze",
  "mailbox": "terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf"
}
EOF
```

### Step 2: Execute the instantiation

**Important:** 
- Replace `hypelane-val-testnet` with the name of your key in the keyring
- The RPC URL must include the port `:443`
- Fees must be at least **12,000,000 uluna** (0.012 LUNC)

```bash
# Command that works (tested and verified)
terrad tx wasm instantiate 2000 \
  "$(cat /tmp/uluna-instantiate-msg.json)" \
  --label "cw-hpl: hpl_warp_native" \
  --admin "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

**Key Points:**
- `--node "https://rpc.luncblaze.com:443"` - Port `:443` is **required**
- `--fees 12000000uluna` - Minimum 12,000,000 uluna (0.012 LUNC) required
- `--from hypelane-val-testnet` - Use your key name from keyring (or add a new key)
- Gas estimate: ~357,093 (auto-calculated)

### Step 3: Check transaction status

After execution, you'll receive a transaction hash. Check its status:

```bash
terrad query tx <TX_HASH> \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443"
```

## Method 3: Using JSON File Directly

### Step 1: Save the instantiation message

```bash
cat > uluna-instantiate-msg.json << 'EOF'
{
  "token": {
    "collateral": {
      "denom": "uluna"
    }
  },
  "hrp": "terra",
  "owner": "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze",
  "mailbox": "terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf"
}
EOF
```

### Step 2: Execute with file reference

**Important:** 
- Replace `hypelane-val-testnet` with the name of your key in the keyring
- The RPC URL must include the port `:443`
- Fees must be at least **12,000,000 uluna** (0.012 LUNC)

```bash
# Command that works (tested and verified)
terrad tx wasm instantiate 2000 \
  "$(cat uluna-instantiate-msg.json)" \
  --label "cw-hpl: hpl_warp_native" \
  --admin "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

## Get the Contract Address

After successful instantiation, get the contract address:

```bash
# Query the transaction to get the contract address
terrad query tx <TX_HASH> \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --output json | jq -r '.logs[0].events[] | select(.type == "instantiate") | .attributes[] | select(.key == "_contract_address") | .value'
```

Or check the transaction on a block explorer:
- Findterra: https://finder.terra.money/classic/testnet
- LUNC Blaze: https://testnet.luncblaze.com

## Verify the Contract

Once you have the contract address, verify it:

```bash
CONTRACT_ADDRESS="<your_contract_address>"

# Query contract info
terrad query wasm contract ${CONTRACT_ADDRESS} \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443"

# Query contract state
terrad query wasm contract-state all ${CONTRACT_ADDRESS} \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443"
```

## Expected Output

After successful instantiation, you should see:

```
gas estimate: 357093
code: 0
txhash: <TRANSACTION_HASH>
...
```

**Success indicators:**
- `code: 0` - Transaction successful
- `gas estimate: 357093` - Gas was estimated correctly
- Transaction hash is returned

The contract address will be in the transaction logs. You can extract it using:

```bash
# Query transaction to get contract address
terrad query tx <TX_HASH> \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --output json | jq -r '.logs[0].events[] | select(.type == "instantiate") | .attributes[] | select(.key == "_contract_address") | .value'
```

Or check the transaction on a block explorer:
- Findterra: https://finder.terra.money/classic/testnet
- LUNC Blaze: https://testnet.luncblaze.com

## Troubleshooting

### Error: "insufficient fees"

The error shows the required fees. For uluna warp route instantiation, you need at least **12,000,000 uluna** (0.012 LUNC):

```bash
--fees 12000000uluna
```

**Why:** Gas estimate is ~357,093, and with gas price of 28.5uluna:
- `357,093 × 28.5 = 10,177,150 uluna` (minimum required)
- Using 12,000,000 uluna provides a safe margin

### Error: "out of gas"

Increase gas adjustment:

```bash
--gas-adjustment 2.0
```

### Error: "account sequence mismatch"

Wait a few seconds and try again, or check your account sequence:

```bash
terrad query account terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443"
```

### Error: "missing port in address"

The RPC URL must include the port. Use:

```bash
--node "https://rpc.luncblaze.com:443"
```

Not:
```bash
--node "https://rpc.luncblaze.com"  # ❌ Missing port
```

## Summary of Working Command

The following command has been tested and verified to work:

```bash
# 1. Create message file
cat > uluna-msg.json << 'EOF'
{
  "token": {
    "collateral": {
      "denom": "uluna"
    }
  },
  "hrp": "terra",
  "owner": "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze",
  "mailbox": "terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf"
}
EOF

# 2. Execute instantiation
terrad tx wasm instantiate 2000 \
  "$(cat uluna-msg.json)" \
  --label "cw-hpl: hpl_warp_native" \
  --admin "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

**Critical Requirements:**
- ✅ Key must be in keyring: `hypelane-val-testnet` (or your key name)
- ✅ RPC URL must include port: `https://rpc.luncblaze.com:443`
- ✅ Fees must be sufficient: `12000000uluna` (0.012 LUNC minimum)
- ✅ Gas estimate: ~357,093 (auto-calculated)

## Next Steps

After successfully instantiating the uluna warp route:

1. **Save the contract address** in your configuration
2. **Link the warp route** to other chains (BSC Testnet, etc.)
3. **Test transfers** using the warp route

For more information, see:
- [WARP-ROUTES-TESTNET.md](./WARP-ROUTES-TESTNET.md)
- [DEPLOYMENT-TERRACLASSIC.md](./DEPLOYMENT-TERRACLASSIC.md)

