# Hyperlane Warp Routes - Terra Classic Testnet

This guide provides step-by-step instructions for creating Warp Routes to connect Terra Classic Testnet with other blockchain networks (BSC Testnet, Solana Testnet) using the Hyperlane CLI.

## Table of Contents

- [What are Warp Routes?](#what-are-warp-routes)
- [Prerequisites](#prerequisites)
- [Installing Hyperlane CLI](#installing-hyperlane-cli)
- [Understanding Warp Configuration](#understanding-warp-configuration)
- [Creating Warp Routes](#creating-warp-routes)
- [Examples](#examples)
- [Verification](#verification)

---

## What are Warp Routes?

Warp Routes are token bridges that enable the transfer of tokens between different blockchain networks through Hyperlane. They can:
- Bridge native tokens (e.g., LUNC from Terra Classic)
- Bridge ERC20/CW20 tokens
- Create synthetic representations of tokens on destination chains
- Support both fungible and non-fungible tokens (NFTs)

---

## Prerequisites

Before you begin, ensure you have:

1. **Node.js and npm/yarn installed** (v18 or higher recommended)
   ```bash
   node --version  # Should be v18.0.0 or higher
   npm --version
   ```

2. **Private keys** for accounts with funds on:
   - Terra Classic Testnet (for Terra side deployment)
   - BSC Testnet (for BSC side deployment)
   - Solana Testnet (for Solana side deployment)

3. **Testnet tokens**:
   - LUNC for Terra Classic Testnet
   - BNB for BSC Testnet
   - SOL for Solana Testnet

4. **Hyperlane contracts deployed** (see `TESTNET-ARTIFACTS.md`)

5. **Hyperlane Agent Config File**: The Hyperlane CLI requires an `agent-config.json` file that contains the addresses of Hyperlane contracts on BSC Testnet. This file tells the CLI where to find the Mailbox, ISM, and other contracts.

   **⚠️ IMPORTANT**: If you get the error `No addresses found for chain bscTestnet`, you need to:
   - Ensure Hyperlane contracts are deployed on BSC Testnet
   - Create or update an `agent-config.json` file with BSC Testnet contract addresses
   - Point the CLI to this config file using `--agent-config` flag or place it in the default location

---

## Installing Hyperlane CLI

The Hyperlane CLI is required to deploy Warp Routes on EVM chains (BSC, Ethereum, etc.) and other non-Cosmos chains.

### Step 1: Install via npm (Global Installation)

```bash
npm install -g @hyperlane-xyz/cli
```

### Step 2: Verify Installation

```bash
hyperlane --version
```

Expected output:
```
@hyperlane-xyz/cli/X.X.X
```

### Step 3: Check Available Commands

```bash
hyperlane --help
```

### Alternative: Install via npx (No Installation Required)

If you prefer not to install globally, you can use `npx`:

```bash
npx @hyperlane-xyz/cli --version
```

---

## Understanding Warp Configuration

Warp Routes require a configuration file (`warp-config.yaml`) that defines the token parameters and security settings for each chain.

### Configuration File Structure

```yaml
chainName:
  isNft: false                    # Token type (false = fungible, true = NFT)
  type: synthetic|collateral|native  # Token type
  name: "Token Name"              # Full token name
  symbol: "SYMBOL"                # Token symbol (ticker)
  decimals: 18                    # Token decimals
  owner: "0x..."                  # Owner address (controls the warp contract)
  interchainSecurityModule:       # Security configuration
    type: messageIdMultisigIsm    # ISM type
    validators:                   # Validator addresses
      - "0x..."
      - "0x..."
    threshold: 2                  # Minimum signatures required
```

### Attribute Explanations

| Attribute | Description | Example Values |
|-----------|-------------|----------------|
| **chainName** | The network identifier where the warp will be deployed | `bscTestnet`, `sepolia`, `solanatestnet` |
| **isNft** | Whether the token is an NFT (true) or fungible token (false) | `false` (for fungible tokens), `true` (for NFTs) |
| **type** | Token representation type:<br>• `synthetic`: Newly minted wrapped token on destination<br>• `collateral`: Locks original token, mints wrapped version<br>• `native`: Uses the chain's native token | `synthetic`, `collateral`, `native` |
| **name** | Full name of the token | `"Terra Classic LUNC"`, `"Wrapped LUNC"` |
| **symbol** | Token ticker symbol | `"LUNC"`, `"wLUNC"`, `"TAZ"` |
| **decimals** | Number of decimal places | `6` (for LUNC), `18` (for most ERC20) |
| **owner** | Address that controls the warp contract (can update settings) | `"0xDcaB3BD2B290B5DCC1430905f88544B5f394b4eA"` |
| **interchainSecurityModule.type** | Type of security module:<br>• `messageIdMultisigIsm`: Requires validator signatures | `messageIdMultisigIsm` |
| **validators** | Array of validator addresses (hexadecimal format without 0x prefix) | See examples below |
| **threshold** | Minimum number of validator signatures required to verify messages | `2` (for 2-of-3), `1` (for 1-of-1) |

---

## Creating Warp Routes

### Example 1: BSC Testnet Warp Route

This example creates a synthetic LUNC token on BSC Testnet.

#### Step 1: Create Configuration File

```bash
cat > warp-bsc-testnet.yaml << 'EOF'
bscTestnet:
  isNft: false
  type: synthetic
  name: "Wrapped Terra Classic LUNC"
  symbol: "wLUNC"
  decimals: 6
  owner: "0xYOUR_BSC_ADDRESS_HERE"
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "242d8a855a8c932dec51f7999ae7d1e48b10c95e"
      - "f620f5e3d25a3ae848fec74bccae5de3edcd8796"
      - "1f030345963c54ff8229720dd3a711c15c554aeb"
    threshold: 2
EOF
```

**Configuration Details**:
- **Chain**: BSC Testnet (Domain 97)
- **Token Type**: Synthetic (new wrapped token will be created on BSC)
- **Decimals**: 6 (same as LUNC on Terra Classic)
- **Validators**: 3 validators from Terra Classic testnet ISM configuration
- **Threshold**: 2 of 3 validators must sign

**⚠️ IMPORTANT**: Replace `0xYOUR_BSC_ADDRESS_HERE` with your actual BSC address!

#### Step 2: Deploy Warp Route

```bash
hyperlane warp deploy \
  --config warp-bsc-testnet.yaml \
  --private-key 0xYOUR_BSC_PRIVATE_KEY_HERE
```

**⚠️ SECURITY WARNING**: 
- The private key shown is for **BSC Testnet**
- **NEVER** share or commit your private key to version control
- Use environment variables for production: `--private-key $BSC_PRIVATE_KEY`

#### Step 3: Save Deployment Output

The CLI will output the deployed contract address. Save this information:

```
Deployed warp route on bscTestnet:
  Token: 0xABCDEF1234567890...
  Router: 0x1234567890ABCDEF...
```

---

### Example 2: Solana Testnet Warp Route

This example creates a synthetic LUNC token on Solana Testnet.

⚠️ **NOTE**: Solana deployment using Hyperlane CLI follows a different process. Refer to the official Hyperlane Solana documentation for specific instructions.

#### Step 1: Create Configuration File

```bash
cat > warp-solana-testnet.yaml << 'EOF'
solanatestnet:
  isNft: false
  type: synthetic
  name: "Wrapped Terra Classic LUNC"
  symbol: "wLUNC"
  decimals: 6
  owner: "YOUR_SOLANA_ADDRESS_HERE"
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "d4ce8fa138d4e083fc0e480cca0dbfa4f5f30bd5"
    threshold: 1
EOF
```

**Configuration Details**:
- **Chain**: Solana Testnet (Domain 1399811150)
- **Token Type**: Synthetic
- **Decimals**: 6
- **Validators**: 1 validator from Terra Classic testnet Solana ISM
- **Threshold**: 1 of 1 validator must sign

---

### Example 3: Multiple Chains Configuration

You can configure warp routes for multiple chains in a single file:

```bash
cat > warp-multi-chain.yaml << 'EOF'
# BSC Testnet Configuration
bscTestnet:
  isNft: false
  type: synthetic
  name: "Wrapped Terra Classic LUNC"
  symbol: "wLUNC"
  decimals: 6
  owner: "0xYOUR_BSC_ADDRESS"
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "242d8a855a8c932dec51f7999ae7d1e48b10c95e"
      - "f620f5e3d25a3ae848fec74bccae5de3edcd8796"
      - "1f030345963c54ff8229720dd3a711c15c554aeb"
    threshold: 2

# Solana Testnet Configuration
solanatestnet:
  isNft: false
  type: synthetic
  name: "Wrapped Terra Classic LUNC"
  symbol: "wLUNC"
  decimals: 6
  owner: "YOUR_SOLANA_ADDRESS"
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "d4ce8fa138d4e083fc0e480cca0dbfa4f5f30bd5"
    threshold: 1
EOF
```

Deploy to specific chain:

```bash
# Deploy only to BSC Testnet
hyperlane warp deploy \
  --config warp-multi-chain.yaml \
  --chain bscTestnet \
  --private-key $BSC_PRIVATE_KEY

# Deploy to Solana Testnet (requires different approach - see Solana documentation)
# Solana deployment uses a different process than EVM chains
```

---

## Example 4: CW20 Collateral Bridge (Terra Classic → BSC)

This example creates a collateral bridge for an existing CW20 token on Terra Classic to BSC Testnet.

### What is a Collateral Bridge?

A **collateral bridge** locks the original tokens on the source chain (Terra Classic) and mints wrapped tokens on the destination chain (BSC). When users want to return tokens:
- Wrapped tokens are burned on BSC
- Original tokens are unlocked on Terra Classic

This is different from **synthetic** where new tokens are created on both sides.

### Step 1: Create CW20 Collateral Configuration (Terra Classic Side)

Create a configuration file for the Terra Classic side:

```bash
cat > warp-cw20-terra.json << 'EOF'
{
  "type": "cw20",
  "mode": "collateral",
  "id": "TAZ",
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "config": {
    "collateral": {
      "address": "terra183xn8lhryp5cg0uauk7k2j6upagqvym79ayfeadkhkawmtaj6wtqq2g7h3"
    }
  }
}
EOF
```

**Configuration Attributes Explained**:

| Attribute | Description | Example Value |
|-----------|-------------|---------------|
| **type** | Token standard on source chain | `"cw20"` (CosmWasm token standard) |
| **mode** | Bridge mode: `collateral` locks original, mints wrapped | `"collateral"` |
| **id** | Token identifier/symbol | `"TAZ"` (your token symbol) |
| **owner** | Address that controls the warp contract on Terra Classic | `"terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n"` (governance module) |
| **config.collateral.address** | CW20 token contract address on Terra Classic | `"terra183xn8lhryp5cg0uauk7k2j6upagqvym79ayfeadkhkawmtaj6wtqq2g7h3"` |

**⚠️ IMPORTANT**: 
- The `owner` should be the governance module address for production
- The `collateral.address` must be a valid deployed CW20 contract on Terra Classic Testnet

### Step 2: Deploy Warp Route on Terra Classic

```bash
# Deploy CW20 collateral warp on Terra Classic
yarn cw-hpl warp create ./warp-cw20-terra.json -n terraclassic
```

**Expected Output**:
```
Deploying warp route for CW20 token TAZ...
✓ Warp contract deployed at: terra1xyz...
✓ Token TAZ can now be bridged to other chains
```

Save the deployed warp contract address for the next step.

### Step 3: Create BSC Testnet Configuration (Destination Side)

Create configuration for the synthetic wrapped token on BSC:

```bash
cat > warp-cw20-bsc.yaml << 'EOF'
bscTestnet:
  isNft: false
  type: synthetic
  name: "Wrapped TAZ Token"
  symbol: "wTAZ"
  decimals: 6
  owner: "0xYOUR_BSC_ADDRESS_HERE"
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "242d8a855a8c932dec51f7999ae7d1e48b10c95e"
      - "f620f5e3d25a3ae848fec74bccae5de3edcd8796"
      - "1f030345963c54ff8229720dd3a711c15c554aeb"
    threshold: 2
EOF
```

**Configuration Details**:
- **type**: `synthetic` on BSC (wrapped version will be created)
- **symbol**: `wTAZ` (wrapped TAZ) - prefix with 'w' to indicate wrapped
- **decimals**: Must match the original CW20 token decimals
- **validators**: Same validators from Terra Classic ISM for BSC (domain 97)

### Step 4: Deploy Warp Route on BSC Testnet

```bash
hyperlane warp deploy \
  --config warp-cw20-bsc.yaml \
  --private-key $BSC_PRIVATE_KEY
```

**Expected Output**:
```
Deploying warp route on bscTestnet...
✓ Token contract deployed at: 0xABCDEF...
✓ Router contract deployed at: 0x123456...
```

Save both contract addresses.

### Step 5: Link the Warp Routes (Bi-directional)

#### Link Terra Classic → BSC

```bash
# Link Terra Classic warp to BSC warp
yarn cw-hpl warp link \
  --asset-type cw20 \
  --asset-id terra183xn8lhryp5cg0uauk7k2j6upagqvym79ayfeadkhkawmtaj6wtqq2g7h3 \
  --target-domain 97 \
  --warp-address 0xBSC_WARP_ADDRESS \
  -n terraclassic
```

#### Link BSC → Terra Classic

```bash
# Link BSC warp back to Terra Classic warp
hyperlane warp link \
  --warp 0xBSC_WARP_ADDRESS \
  --destination terraclassic \
  --destination-warp terra1TERRA_WARP_ADDRESS \
  --private-key $BSC_PRIVATE_KEY
```

### Step 6: Test the Bridge

#### Test Transfer: Terra Classic → BSC

```bash
# Transfer TAZ tokens from Terra Classic to BSC
yarn cw-hpl warp transfer \
  --asset-type cw20 \
  --asset-id terra183xn8lhryp5cg0uauk7k2j6upagqvym79ayfeadkhkawmtaj6wtqq2g7h3 \
  --amount 1000000 \
  --recipient 0xYOUR_BSC_ADDRESS \
  --target-domain 97 \
  -n terraclassic
```

**What happens**:
1. TAZ tokens are locked in the collateral contract on Terra Classic
2. Message is sent via Hyperlane
3. wTAZ tokens are minted on BSC to your address

#### Test Transfer: BSC → Terra Classic

```bash
# Transfer wTAZ tokens from BSC back to Terra Classic
hyperlane warp transfer \
  --warp 0xBSC_WARP_ADDRESS \
  --amount 1000000 \
  --recipient terra1YOUR_TERRA_ADDRESS \
  --destination terraclassic \
  --private-key $BSC_PRIVATE_KEY
```

**What happens**:
1. wTAZ tokens are burned on BSC
2. Message is sent via Hyperlane
3. Original TAZ tokens are unlocked on Terra Classic to your address

### Complete Example with Real Addresses

Here's a complete example with the addresses provided:

**Terra Classic Warp Configuration**:
```json
{
  "type": "cw20",
  "mode": "collateral",
  "id": "TAZ",
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "config": {
    "collateral": {
      "address": "terra183xn8lhryp5cg0uauk7k2j6upagqvym79ayfeadkhkawmtaj6wtqq2g7h3"
    }
  }
}
```

**Deployment Commands**:

```bash
# 1. Deploy on Terra Classic
yarn cw-hpl warp create ./warp-cw20-terra.json -n terraclassic

# 2. Deploy on BSC (after creating warp-cw20-bsc.yaml)
hyperlane warp deploy --config warp-cw20-bsc.yaml --private-key $BSC_PRIVATE_KEY

# 3. Link Terra -> BSC
yarn cw-hpl warp link \
  --asset-type cw20 \
  --asset-id terra183xn8lhryp5cg0uauk7k2j6upagqvym79ayfeadkhkawmtaj6wtqq2g7h3 \
  --target-domain 97 \
  --warp-address 0xBSC_WARP_ADDRESS \
  -n terraclassic

# 4. Link BSC -> Terra
hyperlane warp link \
  --warp 0xBSC_WARP_ADDRESS \
  --destination terraclassic \
  --destination-warp terra1TERRA_WARP_ADDRESS \
  --private-key $BSC_PRIVATE_KEY
```

### Verification

**Check TAZ Token on Terra Classic**:
```bash
terrad query wasm contract terra183xn8lhryp5cg0uauk7k2j6upagqvym79ayfeadkhkawmtaj6wtqq2g7h3 \
  --node https://rpc.luncblaze.com:443 \
  --chain-id rebel-2
```

**Check wTAZ Token on BSC**:
```bash
# Query token info on BSC
cast call 0xBSC_TOKEN_ADDRESS "symbol()(string)" --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
cast call 0xBSC_TOKEN_ADDRESS "decimals()(uint8)" --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

**Check Locked Balance in Collateral Contract**:
```bash
terrad query wasm contract-state smart terra1WARP_ADDRESS \
  '{"balance": {"address": "terra183xn8lhryp5cg0uauk7k2j6upagqvym79ayfeadkhkawmtaj6wtqq2g7h3"}}' \
  --node https://rpc.luncblaze.com:443 \
  --chain-id rebel-2
```

### Important Considerations

1. **Owner Address**: 
   - Use governance module address (`terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n`) for production
   - This ensures only governance can modify the bridge

2. **Token Decimals**:
   - Must be consistent across chains
   - Query the original CW20 token to get correct decimals
   - Use same decimals on BSC synthetic token

3. **Security**:
   - Collateral contract holds real tokens
   - Ensure validators are trusted
   - Monitor locked balance regularly

4. **Liquidity**:
   - Collateral bridge requires initial token supply
   - Ensure enough tokens for bridging operations

---

## Complete Deployment Flow

### 1. Prepare Environment

```bash
# Set environment variables (recommended for security)
export BSC_PRIVATE_KEY="your_bsc_private_key_here"
export TERRA_PRIVATE_KEY="your_terra_private_key_here"

# Verify you have funds
# BSC: Check balance at https://testnet.bscscan.com/
# Terra: Check balance at https://finder.terra.money/testnet/
```

### 2. Create Warp Configuration

```bash
# Create configuration for BSC Testnet
cat > warp-bsc-testnet.yaml << EOF
bscTestnet:
  isNft: false
  type: synthetic
  name: "Wrapped Terra Classic LUNC"
  symbol: "wLUNC"
  decimals: 6
  owner: "YOUR_BSC_ADDRESS"
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "242d8a855a8c932dec51f7999ae7d1e48b10c95e"
      - "f620f5e3d25a3ae848fec74bccae5de3edcd8796"
      - "1f030345963c54ff8229720dd3a711c15c554aeb"
    threshold: 2
EOF
```

### 3. Deploy Warp Route on BSC Testnet

```bash
hyperlane warp deploy \
  --config warp-bsc-testnet.yaml \
  --private-key $BSC_PRIVATE_KEY
```

### 4. Deploy Warp Route on Terra Classic Testnet

For Terra Classic (Cosmos-based), use the Hyperlane CosmWasm tools:

```bash
# Using the cw-hyperlane repository tools
yarn cw-hpl warp create ./warp-terra-config.json -n terraclassic
```

Example `warp-terra-config.json`:

```json
{
  "type": "native",
  "denom": "uluna",
  "decimals": 6,
  "symbol": "LUNC",
  "name": "Terra Classic LUNC"
}
```

### 5. Link Warp Routes (Bi-directional)

After deploying on both chains, link them together:

#### Link BSC → Terra Classic

```bash
# From BSC side, link to Terra Classic warp
hyperlane warp link \
  --warp $BSC_WARP_ADDRESS \
  --destination terraclassic \
  --destination-warp $TERRA_WARP_ADDRESS \
  --private-key $BSC_PRIVATE_KEY
```

#### Link Terra Classic → BSC

```bash
# From Terra Classic side, link to BSC warp
yarn cw-hpl warp link \
  --asset-type native \
  --asset-id uluna \
  --target-domain 97 \
  --warp-address $BSC_WARP_ADDRESS \
  -n terraclassic
```

---

## Verification

### Verify Warp Deployment on BSC

```bash
# Check contract on BSC Testnet explorer
# https://testnet.bscscan.com/address/YOUR_WARP_ADDRESS

# Query warp route info using Hyperlane CLI
hyperlane warp read \
  --address $BSC_WARP_ADDRESS \
  --chain bscTestnet
```

### Verify Warp Deployment on Terra Classic

```bash
# Query contract using terrad
terrad query wasm contract $TERRA_WARP_ADDRESS \
  --node https://rpc.luncblaze.com:443 \
  --chain-id rebel-2
```

---

## Testing Warp Route

### Test Transfer: Terra Classic → BSC Testnet

```bash
# Transfer LUNC from Terra Classic to BSC
yarn cw-hpl warp transfer \
  --asset-type native \
  --asset-id uluna \
  --amount 1000000 \
  --recipient 0xYOUR_BSC_ADDRESS \
  --target-domain 97 \
  -n terraclassic
```

### Test Transfer: BSC Testnet → Terra Classic

```bash
# Transfer wLUNC from BSC back to Terra Classic
hyperlane warp transfer \
  --warp $BSC_WARP_ADDRESS \
  --amount 1000000 \
  --recipient terraADDRESS \
  --destination terraclassic \
  --private-key $BSC_PRIVATE_KEY
```

---

## Validator Configuration Reference

### BSC Testnet (Domain 97)

From `config-testnet.yaml`:

```yaml
validators:
  - "242d8a855a8c932dec51f7999ae7d1e48b10c95e"
  - "f620f5e3d25a3ae848fec74bccae5de3edcd8796"
  - "1f030345963c54ff8229720dd3a711c15c554aeb"
threshold: 2  # 2 of 3
```

### Solana Testnet (Domain 1399811150)

From `config-testnet.yaml`:

```yaml
validators:
  - "d4ce8fa138d4e083fc0e480cca0dbfa4f5f30bd5"
threshold: 1  # 1 of 1
```

---

## Important Notes

### Private Keys

**⚠️ CRITICAL SECURITY WARNINGS**:

1. **BSC Private Key**: The examples use a BSC testnet private key
   - Format: 64-character hexadecimal (with or without `0x` prefix)
   - Example: `0x95badbee842392bde45a3f4e0e83e83f5f2e8133824268d220cf58097a507bf6`

2. **Terra Private Key**: For Terra Classic operations
   - Format: 64-character hexadecimal (without `0x` prefix)
   - Example: `a5123190601045e1266e57c5d5b1a77f0897b39ea63ed2c761946686939c3cb6`

3. **NEVER commit private keys to Git**
4. **NEVER share private keys publicly**
5. **Use environment variables** in production:
   ```bash
   export BSC_PRIVATE_KEY="your_key_here"
   hyperlane warp deploy --config warp.yaml --private-key $BSC_PRIVATE_KEY
   ```

### Chain Identifiers

Different chains use different naming conventions:

| Network | Hyperlane CLI Name | Domain | Notes |
|---------|-------------------|--------|-------|
| BSC Testnet | `bscTestnet` | 97 | Use in warp-config.yaml |
| Solana Testnet | `solanatestnet` | 1399811150 | Special deployment process |
| Terra Classic Testnet | `terraclassic` | 1325 | Use CosmWasm tools |

### Token Decimals

Ensure decimals match across chains:
- **LUNC**: 6 decimals
- **Most ERC20**: 18 decimals
- **Adjust as needed** for your specific token

### Owner Address

The `owner` address in the warp config:
- Controls the warp contract
- Can update security settings
- Can pause/unpause the warp
- Should be a **secure multisig or governance address** in production

---

## Troubleshooting

### Issue: Command not found

```bash
hyperlane: command not found
```

**Solution**: Install Hyperlane CLI globally:
```bash
npm install -g @hyperlane-xyz/cli
```

Or use npx:
```bash
npx @hyperlane-xyz/cli warp deploy --config warp.yaml
```

### Issue: Insufficient funds

```
Error: insufficient funds for gas
```

**Solution**: Ensure your account has enough testnet tokens:
- **BSC Testnet BNB**: https://testnet.binance.org/faucet-smart
- **Solana Testnet SOL**: https://faucet.solana.com/
- **Terra Classic Testnet LUNC**: Ask in community channels

### Issue: Invalid validator address

```
Error: invalid validator address format
```

**Solution**: Ensure validator addresses are:
- 40-character hexadecimal strings
- Without `0x` prefix in YAML
- Lowercase letters

### Issue: No addresses found for chain bscTestnet

```
Error: No addresses found for chain bscTestnet
```

**Cause**: The Hyperlane CLI cannot find the Hyperlane contract addresses on BSC Testnet. This happens when:
1. Hyperlane contracts are not deployed on BSC Testnet
2. The `agent-config.json` file is missing or doesn't contain BSC Testnet addresses
3. The CLI cannot locate the config file

**Solution**: You need to create an `agent-config.json` file with BSC Testnet contract addresses.

#### Step 1: Verify Hyperlane Contracts on BSC Testnet

First, ensure that Hyperlane contracts are deployed on BSC Testnet. You need:
- Mailbox contract address
- ValidatorAnnounce contract address
- ISM contracts addresses
- IGP contract addresses
- Hook contract addresses

If contracts are not deployed, you need to deploy them first using the Hyperlane deployment tools.

#### Step 2: Create agent-config.json

Create a file named `agent-config.json` in your working directory or in `~/.hyperlane/`:

```bash
cat > agent-config.json << 'EOF'
{
  "chains": {
    "bscTestnet": {
      "name": "bscTestnet",
      "chainId": 97,
      "domainId": 97,
      "protocol": "ethereum",
      "isTestnet": true,
      "displayName": "BSC Testnet",
      "nativeToken": {
        "symbol": "BNB",
        "name": "Binance Coin",
        "decimals": 18
      },
      "rpcUrls": [
        {
          "http": "https://data-seed-prebsc-1-s1.binance.org:8545"
        },
        {
          "http": "https://data-seed-prebsc-2-s1.binance.org:8545"
        }
      ],
      "blockExplorers": [
        {
          "name": "BscScan",
          "url": "https://testnet.bscscan.com",
          "apiUrl": "https://api-testnet.bscscan.com/api",
          "family": "etherscan"
        }
      ],
      "blocks": {
        "confirmations": 1,
        "estimateBlockTime": 3,
        "reorgPeriod": 1
      },
      "mailbox": "0xYOUR_BSC_MAILBOX_ADDRESS",
      "validatorAnnounce": "0xYOUR_BSC_VALIDATOR_ANNOUNCE_ADDRESS",
      "interchainGasPaymaster": "0xYOUR_BSC_IGP_ADDRESS",
      "merkleTreeHook": "0xYOUR_BSC_MERKLE_HOOK_ADDRESS",
      "interchainSecurityModule": "0xYOUR_BSC_ISM_ADDRESS",
      "messageIdMultisigIsmFactory": "0xYOUR_BSC_MESSAGE_ID_MULTISIG_ISM_FACTORY",
      "merkleRootMultisigIsmFactory": "0xYOUR_BSC_MERKLE_ROOT_MULTISIG_ISM_FACTORY"
    }
  }
}
EOF
```

**⚠️ IMPORTANT**: Replace all `0xYOUR_BSC_*_ADDRESS` placeholders with actual contract addresses from your BSC Testnet deployment.

#### Step 3: Use the Config File

You can specify the config file location in two ways:

**Option A: Use `--agent-config` flag**
```bash
hyperlane warp deploy \
  --config warp-bsc-testnet.yaml \
  --agent-config ./agent-config.json \
  --private-key 0xYOUR_PRIVATE_KEY
```

**Option B: Place in default location**
The CLI looks for config files in:
- `./agent-config.json` (current directory)
- `~/.hyperlane/agent-config.json` (home directory)

If you place the file in one of these locations, you don't need the `--agent-config` flag.

#### Step 4: Verify Config File

You can verify your config file is being read correctly:

```bash
hyperlane config show --agent-config ./agent-config.json
```

This should display the chain configuration including BSC Testnet.

**Note**: If you don't have Hyperlane contracts deployed on BSC Testnet yet, you'll need to deploy them first. The Hyperlane CLI can help with this, or you can use the official Hyperlane deployment scripts.

---

## Resources

- **Hyperlane Documentation**: https://docs.hyperlane.xyz/
- **Hyperlane CLI GitHub**: https://github.com/hyperlane-xyz/hyperlane-monorepo/tree/main/typescript/cli
- **BSC Testnet Explorer**: https://testnet.bscscan.com/
- **Terra Classic Testnet Explorer**: https://finder.terra.money/testnet/
- **Testnet Artifacts**: See `TESTNET-ARTIFACTS.md`
- **Governance Guide**: See `GOVERNANCE-OPERATIONS-TESTNET.md`

---

## Next Steps

After successfully deploying warp routes:

1. **Test Transfers**: Perform test transfers in both directions
2. **Monitor Relayers**: Ensure relayers are processing messages
3. **Update Documentation**: Document deployed addresses
4. **Community Testing**: Invite community members to test
5. **Security Audit**: Consider auditing before mainnet deployment
6. **Mainnet Planning**: Plan mainnet deployment with production validators

