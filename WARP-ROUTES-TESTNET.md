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
- [Managing Validators on Existing Warp Routes](#managing-validators-on-existing-warp-routes)
- [Creating a Multisig Safe Wallet](#creating-a-multisig-safe-wallet-recommended-for-production)

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

   **Note**: The official Hyperlane contracts are already deployed on BSC Testnet by the Hyperlane team. The Hyperlane CLI automatically uses the official contract addresses from the [Hyperlane Registry](https://github.com/hyperlane-xyz/hyperlane-registry/tree/main/chains/bsctestnet).

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
| **chainName** | The network identifier where the warp will be deployed | `bsctestnet`, `sepolia`, `solanatestnet` |
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
bsctestnet:
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
Deployed warp route on bsctestnet:
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
bsctestnet:
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
  --chain bsctestnet \
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
bsctestnet:
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
Deploying warp route on bsctestnet...
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
bsctestnet:
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
  --chain bsctestnet
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
| BSC Testnet | `bsctestnet` | 97 | Use in warp-config.yaml |
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

## Creating a Multisig Safe Wallet (Recommended for Production)

For production deployments, it's **highly recommended** to use a multisig wallet (Safe) as the owner address instead of a single private key. This provides better security and requires multiple signatures for critical operations.

### What is Safe?

Safe (formerly Gnosis Safe) is a smart contract wallet that requires multiple signatures to execute transactions. It's the industry standard for managing funds and contracts securely.

### Prerequisites

- Python 3.7 or higher
- pip (Python package manager)
- BNB tokens in the deployer account (for gas fees)
- Owner addresses ready (the accounts that will control the multisig)

### Step 1: Install Safe CLI

```bash
pip install safe-cli
```

**Note**: If you encounter dependency warnings, they are usually safe to ignore. The CLI will still function correctly.

### Step 2: Prepare Owner Addresses

Collect the addresses of all accounts that will be owners of the multisig:

```bash
# Example owner addresses (replace with your actual addresses)
OWNER1="0x867f9CE9F0D7218b016351CB6122406E6D247a5e"
OWNER2="0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA"
OWNER3="0xANOTHER_OWNER_ADDRESS"  # Add more as needed
```

### Step 3: Create the Multisig Safe

**For BSC Testnet:**

```bash
safe-creator \
  https://data-seed-prebsc-1-s1.binance.org:8545 \
  0xYOUR_DEPLOYER_PRIVATE_KEY \
  --owners 0xOWNER1 0xOWNER2 0xOWNER3 \
  --threshold 2
```

**For BSC Mainnet:**

```bash
safe-creator \
  https://bsc-dataseed.binance.org \
  0xYOUR_DEPLOYER_PRIVATE_KEY \
  --owners 0xOWNER1 0xOWNER2 0xOWNER3 \
  --threshold 2
```

**Parameters:**
- **First argument**: RPC URL for the network
- **Second argument**: Private key of the deployer account (must have BNB for gas)
- `--owners`: List of owner addresses (space-separated)
- `--threshold`: Minimum number of signatures required (e.g., `2` means 2 out of 3 owners must sign)

### Step 4: Confirm Deployment

The CLI will show you:
- Network information
- Deployer address and balance
- Safe configuration (owners, threshold)
- Predicted Safe address

You'll be prompted twice:
1. `Do you want to continue? [y/N]:` - Confirm the configuration
2. `Safe will be deployed on 0x..., would you like to proceed? [y/N]:` - Confirm deployment

### Example Output

```
Network BNB_SMART_CHAIN_TESTNET - Sender 0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA - Balance: 0.100000Ξ
Creating new Safe with owners=['0x867f9CE9F0D7218b016351CB6122406E6D247a5e', '0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA'] threshold=1
Safe-master-copy=0x29fcB43b46531BcA003ddC8FCB67FFE91900C762 version=1.4.1
Fallback-handler=0xfd0732Dc9E303f09fCEf3a7388Ad10A83459Ec99
Proxy factory=0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67

Do you want to continue? [y/N]: y
Safe will be deployed on 0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee, would you like to proceed? [y/N]: y

Sent tx with tx-hash=0xf74c6109158ab607d7312a7ddfc7a541d1465fabe25b8ce57018fe7d9201cb72
Safe=0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee is being created
```

### Step 5: Save the Safe Address

After deployment, save the Safe address. This is the address you'll use as the `owner` in your warp route configuration:

```bash
# Save the Safe address
SAFE_ADDRESS="0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee"

# Use it in your warp config
cat > warp-bsc-testnet.yaml << EOF
bsctestnet:
  isNft: false
  type: synthetic
  name: "Wrapped Terra Classic LUNC"
  symbol: "wLUNC"
  decimals: 6
  owner: "${SAFE_ADDRESS}"  # ✅ Using Safe multisig address
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "0x8804770d6a346210c0fd011258fdf3ab0a5bb0d0"
    threshold: 1
EOF
```

### Threshold Recommendations

Choose your threshold based on security needs:

| Owners | Recommended Threshold | Use Case |
|--------|----------------------|----------|
| 2 | 2 | Maximum security (both must sign) |
| 3 | 2 | Balanced (2 of 3) |
| 3 | 1 | Lower security (any can sign) |
| 5 | 3 | Production standard (3 of 5) |
| 7 | 4 | High security (4 of 7) |

**Best Practice**: For production, use at least 3 owners with a threshold of 2 or higher.

### Using the Safe Address

Once deployed, use the Safe address as the `owner` in your warp route configuration. All operations that require owner permissions will need to be executed through the Safe multisig interface.

**Important Notes:**
1. **Gas Fees**: The deployer account pays for the Safe deployment. Ensure it has sufficient BNB.
2. **Owner Addresses**: All owner addresses must be valid Ethereum addresses (checksummed or lowercase).
3. **Threshold**: Cannot exceed the number of owners.
4. **Network**: The same Safe CLI works for both testnet and mainnet - just change the RPC URL.
5. **Safe Interface**: After deployment, you can manage the Safe using the Safe web interface at:
   - Testnet: https://safe-testnet.safe.global/
   - Mainnet: https://app.safe.global/

### Verifying the Safe

After deployment, verify the Safe on the block explorer:

```bash
# BSC Testnet
https://testnet.bscscan.com/address/0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee

# Or use the Safe interface
https://safe-testnet.safe.global/
```

### Using Safe CLI for Governance Operations

Once your Safe multisig is deployed and set as the owner of your warp routes, all governance operations must be executed through the Safe. This ensures that multiple signatures are required for critical changes.

**⚠️ IMPORTANT**: The commands below are based on Safe CLI documentation. Please verify the exact syntax with the latest Safe CLI documentation as syntax may vary by version.

#### Understanding the Safe Transaction Flow

1. **Propose**: An owner creates a transaction proposal
2. **Confirm**: Other owners confirm the proposal (until threshold is reached)
3. **Execute**: Once threshold is met, any owner can execute the transaction

#### Step 1: Creating a Transaction Proposal

When you want to make a change (e.g., update validators), an owner creates a proposal:

```bash
# Example: Propose updating the ISM
safe-cli propose \
  --safe 0xYOUR_SAFE_ADDRESS \
  --to 0xWARP_ROUTE_ADDRESS \
  --value 0 \
  --data "0x..." \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

**Note**: The `--data` field contains the encoded function call. You may need to use tools like `cast` (from Foundry) to encode the function call.

#### Step 2: Owners Confirm the Proposal

Each owner (except the proposer) needs to confirm the transaction:

```bash
safe-cli confirm \
  --safe 0xYOUR_SAFE_ADDRESS \
  --tx <TX_HASH_OF_THE_PROPOSAL> \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

**Getting the TX_HASH**: 
- The TX_HASH is returned when the proposal is created
- You can also find it in the Safe interface under "Queue" or "History"
- Or check the block explorer for transactions to your Safe address

**Example:**
```bash
# Owner 1 confirms
safe-cli confirm \
  --safe 0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee \
  --tx 0xf74c6109158ab607d7312a7ddfc7a541d1465fabe25b8ce57018fe7d9201cb72 \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545

# Owner 2 confirms (if threshold is 2)
safe-cli confirm \
  --safe 0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee \
  --tx 0xf74c6109158ab607d7312a7ddfc7a541d1465fabe25b8ce57018fe7d9201cb72 \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

#### Step 3: Execute the Transaction (After Threshold is Reached)

Once enough owners have confirmed (threshold reached), any owner can execute:

```bash
safe-cli execute \
  --safe 0xYOUR_SAFE_ADDRESS \
  --tx <TX_HASH_OF_THE_PROPOSAL> \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

**Example:**
```bash
safe-cli execute \
  --safe 0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee \
  --tx 0xf74c6109158ab607d7312a7ddfc7a541d1465fabe25b8ce57018fe7d9201cb72 \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

### Common Governance Operations via Safe

After transferring ownership to the Safe multisig, all governance operations must be done through Safe. Below are common operations:

#### 1. Add or Update ISM (Interchain Security Module)

**⚠️ Note**: The exact method name and parameters may vary. Verify the correct function signature for your warp route contract.

```bash
# Example: Update ISM on a warp route
safe-cli call \
  --safe 0xYOUR_SAFE_ADDRESS \
  --to 0xWARP_ROUTE_ADDRESS \
  --method setInterchainSecurityModule \
  --args 0xNEW_ISM_ADDRESS \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

**Alternative using propose/confirm/execute flow:**

```bash
# Step 1: Propose
safe-cli propose \
  --safe 0xYOUR_SAFE_ADDRESS \
  --to 0xWARP_ROUTE_ADDRESS \
  --value 0 \
  --data $(cast calldata "setInterchainSecurityModule(address)" 0xNEW_ISM_ADDRESS) \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545

# Step 2: Owners confirm (repeat until threshold)
safe-cli confirm \
  --safe 0xYOUR_SAFE_ADDRESS \
  --tx <TX_HASH> \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545

# Step 3: Execute
safe-cli execute \
  --safe 0xYOUR_SAFE_ADDRESS \
  --tx <TX_HASH> \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

#### 2. Update Validators

**⚠️ Note**: The method name `setRequiredValidators` may not be correct for Hyperlane warp routes. Verify the actual function name in your contract. Warp routes typically use ISM configuration rather than direct validator management.

```bash
# Example: Update validators (verify method name)
safe-cli call \
  --safe 0xYOUR_SAFE_ADDRESS \
  --to 0xWARP_ROUTE_ADDRESS \
  --method setRequiredValidators \
  --args "[0xVAL1,0xVAL2,0xVAL3]" \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

**Important**: For Hyperlane warp routes, validator management is typically done through the ISM configuration, not directly on the warp route contract. You may need to:
1. Update the ISM contract itself (if you control it)
2. Or use `hyperlane warp apply` with a private key that has permission through the Safe

#### 3. Pause/Unpause Warp Route

```bash
# Pause
safe-cli call \
  --safe 0xYOUR_SAFE_ADDRESS \
  --to 0xWARP_ROUTE_ADDRESS \
  --method pause \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545

# Unpause
safe-cli call \
  --safe 0xYOUR_SAFE_ADDRESS \
  --to 0xWARP_ROUTE_ADDRESS \
  --method unpause \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
```

### Using Python Scripts (Alternative to Safe CLI)

**⚠️ IMPORTANT**: If `safe-cli` is not working (e.g., ImportError with EtherscanClient), you can use Python scripts directly with `safe-eth-py` library.

#### Prerequisites

Install required Python libraries:

```bash
# Install system-wide
pip3 install safe-eth-py web3 eth-account

# Or in a virtual environment (recommended)
python3 -m venv safe-env
source safe-env/bin/activate
pip install safe-eth-py web3 eth-account
```

**Note**: If you're using a virtual environment, activate it before running the scripts:
```bash
source safe-env/bin/activate
python3 script/safe-propose-direct.py ...
```

#### Step 1: Create a Transaction Proposal

Use the Python script to create a proposal:

```bash
# Encode the function call first using cast
CALLDATA=$(cast calldata "setInterchainSecurityModule(address)" 0xNEW_ISM_ADDRESS)

# Create proposal using Python script
python3 script/safe-propose-direct.py \
  0xYOUR_PRIVATE_KEY \
  0xWARP_ROUTE_ADDRESS \
  $CALLDATA
```

**Output**: The script will return:
- `TX_HASH`: Transaction hash for the proposal
- `Safe TX Hash`: Hash that other owners need to confirm

#### Step 2: Owners Confirm the Proposal

Each owner confirms using their private key:

```bash
python3 script/safe-confirm.py \
  0xOWNER_PRIVATE_KEY \
  <SAFE_TX_HASH>
```

**Example**:
```bash
# Owner 1 confirms
python3 script/safe-confirm.py \
  0xPRIVATE_KEY_1 \
  0xabc123def456...

# Owner 2 confirms (if threshold is 2)
python3 script/safe-confirm.py \
  0xPRIVATE_KEY_2 \
  0xabc123def456...
```

The script will show:
- Current approvals count
- Whether threshold is reached
- Instructions to execute when ready

#### Step 3: Execute the Transaction

Once threshold is reached, execute the transaction:

**Note**: Executing Safe transactions via script is complex as it requires collecting all signatures. For execution, you have two options:

1. **Use Safe Web Interface** (if available):
   - Go to https://app.safe.global/
   - Connect wallet
   - Execute pending transaction

2. **Use safe-eth-py directly** (advanced):
   ```python
   from safe_eth_py import Safe
   from eth_account import Account
   
   safe = Safe("0xYOUR_SAFE_ADDRESS", "RPC_URL")
   account = Account.from_key("0xPRIVATE_KEY")
   
   # Get pending transaction
   safe_tx = safe.get_transaction(safe_tx_hash)
   
   # Execute (requires all signatures)
   tx_hash = safe_tx.execute(account.key)
   ```

#### Available Scripts

The following scripts are available in `script/` directory:

- **`safe-propose-direct.py`**: Create transaction proposals using `safe-eth-py`
- **`safe-confirm.py`**: Confirm pending proposals
- **`safe-execute.py`**: Placeholder (execution is complex, see notes above)

#### Example: Complete Workflow

```bash
# 1. Encode function call
CALLDATA=$(cast calldata "setValidators(address[],uint8)" \
  "[0xVAL1,0xVAL2,0xVAL3]" 2)

# 2. Owner 1 creates proposal
python3 script/safe-propose-direct.py \
  0xOWNER1_PRIVATE_KEY \
  0xWARP_ROUTE_ADDRESS \
  $CALLDATA

# Output: Safe TX Hash = 0xabc123...

# 3. Owner 2 confirms
python3 script/safe-confirm.py \
  0xOWNER2_PRIVATE_KEY \
  0xabc123...

# 4. If threshold=2, transaction is ready to execute
# Use Safe web interface or safe-eth-py directly
```

### Using Safe Web Interface (Alternative)

**⚠️ NOTE**: The testnet Safe interface URL may not be available. Use the Python scripts above instead.

If the Safe web interface is available:

1. **Go to Safe Interface**:
   - Testnet: https://app.safe.global/ (may not work for testnet)
   - Mainnet: https://app.safe.global/

2. **Connect your wallet** (one of the owners)

3. **Create transaction**:
   - Click "New Transaction"
   - Enter the contract address
   - Enter the function data
   - Submit

4. **Other owners confirm**:
   - Each owner connects their wallet
   - Confirms the pending transaction

5. **Execute**:
   - Once threshold is reached, any owner can execute

### Important Notes

1. **Verify Function Names**: The exact function names (`setInterchainSecurityModule`, `setRequiredValidators`, etc.) may vary. Always verify against your actual contract ABI.

2. **Encode Function Calls**: For complex operations, you may need to encode function calls. Use tools like:
   - `cast` from Foundry: `cast calldata "functionName(type1,type2)" arg1 arg2`
   - Online ABI encoders
   - Web3 libraries

3. **RPC URLs**: Always use the correct RPC URL for your network:
   - BSC Testnet: `https://data-seed-prebsc-1-s1.binance.org:8545`
   - BSC Mainnet: `https://bsc-dataseed.binance.org`

4. **Private Keys**: Each owner needs their private key to confirm/execute transactions. Store these securely.

5. **Gas Fees**: The executing account pays for gas fees. Ensure sufficient BNB balance.

6. **Testing**: **⚠️ These commands have not been fully tested**. Please verify the syntax with the latest Safe CLI documentation and test on testnet before using in production.

### Getting Help

- **Safe CLI Documentation**: Check the official Safe CLI repository
- **Safe Interface**: Use the web interface as a reference for correct function calls
- **Contract ABI**: Review your warp route contract ABI to find correct function names and parameters

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

### Issue: No addresses found for chain bsctestnet

```
Error: No addresses found for chain bsctestnet
```

**Cause**: The Hyperlane CLI cannot find the Hyperlane contract addresses on BSC Testnet. This usually happens when:
1. The chain name in your `warp-bsc-testnet.yaml` file is incorrect
2. The Hyperlane CLI version is outdated

**Solution**: 

1. **Verify the chain name**: Make sure your `warp-bsc-testnet.yaml` uses `bsctestnet` (all lowercase), not `bscTestnet`:

```yaml
bsctestnet:  # ✅ Correct (all lowercase)
  isNft: false
  type: synthetic
  # ...
```

2. **Update Hyperlane CLI**: Ensure you're using the latest version:

```bash
npm install -g @hyperlane-xyz/cli@latest
```

3. **Verify official contracts**: The Hyperlane CLI automatically uses the official contract addresses from the [Hyperlane Registry](https://github.com/hyperlane-xyz/hyperlane-registry/tree/main/chains/bsctestnet). No additional configuration files are needed.

---

## Managing Validators on Existing Warp Routes

After deploying a warp route, you may need to add or remove validators from the Interchain Security Module (ISM). The `hyperlane warp apply` command allows you to update validator configurations for existing warp routes.

### Understanding warp.json

The `warp.json` file is a registry of deployed warp route tokens. It lists all the tokens that have been deployed across different chains, allowing you to reference them when applying validator changes.

### Creating warp.json

Create a `warp.json` file that lists your deployed tokens:

```bash
cat > warp/warp.json << 'EOF'
{
  "tokens": [
    {
      "chainName": "bsctestnet",
      "standard": "ERC20",
      "addressOrDenom": "0xc298796dDed03429F308a164a41B4D95e2f6061D",
      "name": "Wrapped Terra Classic LUNC",
      "symbol": "wLUNC",
      "decimals": 6
    },
    {
      "chainName": "bsctestnet",
      "standard": "ERC20",
      "addressOrDenom": "0xANOTHER_TOKEN_ADDRESS",
      "name": "ZTCC Token",
      "symbol": "ZTCC",
      "decimals": 6
    }
  ]
}
EOF
```

**File Structure:**
- `tokens`: Array of token objects
- `chainName`: The chain where the token is deployed (e.g., `bsctestnet`, `sepolia`)
- `standard`: Token standard (`ERC20` for EVM chains, `CW20` for Cosmos chains)
- `addressOrDenom`: The contract address (EVM) or denom (Cosmos) of the deployed warp token
- `name`: Full token name
- `symbol`: Token symbol
- `decimals`: Number of decimal places

### Using hyperlane warp apply

The `hyperlane warp apply` command applies validator configuration changes to existing warp routes. It uses:
- `--config`: Your warp configuration file (same as used for deployment)
- `--warp`: Path to the `warp.json` file containing deployed tokens

**Basic Command:**
```bash
hyperlane warp apply \
  --config warp-bsc-testnet.yaml \
  --warp ./warp/warp.json
```

### Adding Validators

To add validators to an existing warp route, update your `warp-bsc-testnet.yaml` configuration file with the new validators:

```yaml
bsctestnet:
  isNft: false
  type: synthetic
  name: "Wrapped Terra Classic LUNC"
  symbol: "wLUNC"
  decimals: 6
  owner: "0xYOUR_BSC_ADDRESS"
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "0x8804770d6a346210c0fd011258fdf3ab0a5bb0d0"  # Existing validator
      - "0xNEW_VALIDATOR_ADDRESS_1"                    # New validator
      - "0xNEW_VALIDATOR_ADDRESS_2"                    # New validator
    threshold: 2  # Update threshold if needed (e.g., 2 of 3)
```

Then apply the changes:

```bash
hyperlane warp apply \
  --config warp-bsc-testnet.yaml \
  --warp ./warp/warp.json \
  --private-key 0xYOUR_PRIVATE_KEY
```

### Removing Validators

To remove validators, simply remove them from the `validators` array in your config file:

```yaml
bsctestnet:
  # ... other config ...
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "0x8804770d6a346210c0fd011258fdf3ab0a5bb0d0"  # Keep this one
      # Removed: "0xOLD_VALIDATOR_ADDRESS"
    threshold: 1  # Update threshold (e.g., 1 of 1)
```

Then apply:

```bash
hyperlane warp apply \
  --config warp-bsc-testnet.yaml \
  --warp ./warp/warp.json \
  --private-key 0xYOUR_PRIVATE_KEY
```

### Updating Threshold

You can also update the threshold (minimum number of signatures required) without changing validators:

```yaml
bsctestnet:
  # ... other config ...
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "0x8804770d6a346210c0fd011258fdf3ab0a5bb0d0"
      - "0xf620f5e3d25a3ae848fec74bccae5de3edcd8796"
      - "1f030345963c54ff8229720dd3a711c15c554aeb"
    threshold: 3  # Changed from 2 to 3 (now requires all 3 validators)
```

### Complete Example

**1. Create warp.json with your deployed token:**

```bash
mkdir -p warp
cat > warp/warp.json << 'EOF'
{
  "tokens": [
    {
      "chainName": "bsctestnet",
      "standard": "ERC20",
      "addressOrDenom": "0xc298796dDed03429F308a164a41B4D95e2f6061D",
      "name": "Wrapped Terra Classic LUNC",
      "symbol": "wLUNC",
      "decimals": 6
    }
  ]
}
EOF
```

**2. Update your config file with new validators:**

```bash
cat > warp-bsc-testnet.yaml << 'EOF'
bsctestnet:
  isNft: false
  type: synthetic
  name: "Wrapped Terra Classic LUNC"
  symbol: "wLUNC"
  decimals: 6
  owner: "0xa047DCd69249fd082B4797c29e5D80781Cb7f5ee"
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "0x8804770d6a346210c0fd011258fdf3ab0a5bb0d0"
      - "0xNEW_VALIDATOR_ADDRESS"
    threshold: 2
EOF
```

**3. Apply the changes:**

```bash
hyperlane warp apply \
  --config warp-bsc-testnet.yaml \
  --warp ./warp/warp.json \
  --private-key 0xYOUR_PRIVATE_KEY
```

### Important Notes

1. **Token Address**: The `addressOrDenom` in `warp.json` must match the actual deployed warp token contract address on the chain.

2. **Chain Name**: Use the correct chain name format:
   - `bsctestnet` (all lowercase) for BSC Testnet
   - `sepolia` for Ethereum Sepolia
   - `solanatestnet` for Solana Testnet

3. **Threshold**: Always ensure the threshold is valid for the number of validators:
   - If you have 3 validators, threshold can be 1, 2, or 3
   - Threshold cannot exceed the number of validators

4. **Private Key**: The private key must be for an account that has permission to update the warp route (typically the owner address).

5. **Multiple Tokens**: You can list multiple tokens in `warp.json` if you have deployed multiple warp routes. The `hyperlane warp apply` command will apply changes to all matching tokens.

### Verifying Changes

After applying validator changes, verify them:

```bash
# Check the ISM configuration on the warp route
hyperlane warp read \
  --address 0xc298796dDed03429F308a164a41B4D95e2f6061D \
  --chain bsctestnet
```

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

