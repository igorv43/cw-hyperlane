# Complete Guide: Terra Classic ↔ Solana Warp Route

This guide provides step-by-step instructions for creating a Warp Route between Terra Classic Testnet (Native LUNC) and Solana Testnet (Synthetic LUNC), enabling bidirectional cross-chain transfers.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Warp Route Architecture](#warp-route-architecture)
4. [Step 1: Deploy on Terra Classic](#step-1-deploy-on-terra-classic)
5. [Step 2: Deploy on Solana](#step-2-deploy-on-solana)
6. [Step 3: Configure ISM Validators](#step-3-configure-ism-validators)
7. [Step 4: Bidirectional Linking](#step-4-bidirectional-linking)
8. [Step 5: Test Transfers](#step-5-test-transfers)
9. [Troubleshooting](#troubleshooting)
10. [References](#references)

---

## Overview

### Warp Route Type

- **Terra Classic**: Native LUNC (Collateral)
- **Solana**: Synthetic LUNC (Synthetic token created on Solana)

### Transfer Flow

1. **Terra Classic → Solana**:
   - User sends native LUNC on Terra Classic
   - LUNC is locked in the warp route contract
   - Synthetic LUNC token is minted on Solana

2. **Solana → Terra Classic**:
   - User burns synthetic LUNC token on Solana
   - Native LUNC is unlocked and sent on Terra Classic

### Required Tools

- **Terra Classic**: `cw-hyperlane` CLI (TypeScript/Node.js)
- **Solana**: `hyperlane-sealevel-client` (Rust)

---

## Prerequisites

### 1. Tool Installation

#### Terra Classic CLI (cw-hyperlane)

```bash
# Should already be installed in the project
cd /home/lunc/cw-hyperlane
yarn install
```

#### Solana CLI and Hyperlane Sealevel Client

```bash
# Install Solana CLI 1.14.20
sh -c "$(curl -sSfL https://release.solana.com/v1.14.20/install)"

# Add to PATH
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# Verify installation
solana --version  # Should show: solana-cli 1.14.20
solana config set --url https://api.testnet.solana.com

# Clone hyperlane-monorepo to use sealevel client
git clone https://github.com/hyperlane-xyz/hyperlane-monorepo
cd hyperlane-monorepo
```

#### Rust 1.75.0

```bash
# Install Rust 1.75.0
rustup install 1.75.0
rustup default 1.75.0

# Set override for sealevel directory
cd ~/hyperlane-monorepo/rust/sealevel
rustup override set 1.75.0

# Verify
rustc --version  # Should show: rustc 1.75.0
```

### 2. Key Configuration

#### Terra Classic

```bash
# Verify key is configured
terrad keys list --keyring-backend file

# If needed, add key
terrad keys add hypelane-val-testnet --keyring-backend file
```

#### Solana

```bash
# Generate new key for Solana (if needed)
solana-keygen new --outfile ~/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json

# Verify address and balance
solana address --keypair ~/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json
solana balance EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd --url https://api.testnet.solana.com

# Get test SOL (if needed)
solana airdrop 1 EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd --url https://api.testnet.solana.com
```

### 3. Verify Hyperlane Contracts

Ensure Hyperlane contracts are deployed:

- **Terra Classic**: See `TESTNET-ARTIFACTS.md`
- **Solana**: Check [Hyperlane Registry](https://github.com/hyperlane-xyz/hyperlane-registry/tree/main/chains/solanatestnet)

### 4. Chain Information

| Chain | Domain ID | RPC Endpoint | Explorer |
|-------|-----------|--------------|----------|
| Terra Classic Testnet | `1325` | `https://rpc.luncblaze.com:443` | https://finder.terra-classic.hexxagon.dev/testnet |
| Solana Testnet | `1399811149` | `https://api.testnet.solana.com` | https://explorer.solana.com/?cluster=testnet |

**Note**: Solana Testnet domain ID is `1399811149`, not `1399811150`.

---

## Warp Route Architecture

### Components

1. **Terra Classic Side**:
   - Warp Route Contract (Native Collateral)
   - Address: `terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8`
   - Type: `native` + `collateral`
   - ISM: Can be configured on warp route or use Mailbox default

2. **Solana Side**:
   - Warp Route Program (Synthetic)
   - Program ID: `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`
   - Mint Account: `DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA`
   - Type: `synthetic` (Token-2022)
   - ISM: Uses ISM configured in Solana Mailbox (not configurable in warp route during deployment)

### ISM Differences Between Chains

| Aspect | Terra Classic | BSC (EVM) | Solana (SVM) |
|--------|--------------|-----------|--------------|
| **ISM Configuration** | Optional via `--ism` flag | In YAML file (`interchainSecurityModule`) | Not configurable in warp route |
| **Default ISM** | Uses Mailbox ISM if not specified | Can have own ISM in YAML | Always uses Mailbox ISM |
| **Architecture** | ISM can be per warp route | ISM can be per warp route | ISM is managed by Mailbox |
| **Config Format** | JSON (cw-hyperlane) | YAML (Hyperlane CLI) | JSON (sealevel client) |
| **Post-Deploy ISM** | Can set via `terrad tx wasm execute` | Can set via contract call | Can set via `sealevel client` |

### Data Flow

```
Terra Classic                    Solana
     │                              │
     │ 1. transfer_remote           │
     ├─────────────────────────────>│
     │                              │ 2. Mint synthetic token
     │                              │
     │ 3. Message via Hyperlane     │
     │<─────────────────────────────┤
     │                              │
     │ 4. Unlock native LUNC        │
     │                              │
```

---

## Step 1: Deploy on Terra Classic

### 1.1. Create Configuration File

Create the configuration file for the native warp route:

```bash
cat > example/warp/uluna-solana.json << EOF
{
  "type": "native",
  "mode": "collateral",
  "id": "uluna",
  "owner": "<signer>",
  "config": {
    "collateral": {
      "denom": "uluna"
    }
  }
}
EOF
```

### 1.2. Deploy Warp Route

```bash
# Deploy warp route on Terra Classic
yarn cw-hpl warp create ./example/warp/uluna-solana.json -n terraclassic
```

**Expected Output:**
```
[INFO] Deploying native warp route...
[INFO] Warp route deployed at: terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8
[INFO] Address: terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8
[INFO] Hex Address: 0x0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02
```

**Save the contract address:**
```bash
TERRA_WARP_ADDRESS="terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8"
TERRA_WARP_HEX="0x0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02"
```

### 1.3. Verify Deployment

```bash
# Verify contract on explorer
echo "https://finder.terra-classic.hexxagon.dev/testnet/address/${TERRA_WARP_ADDRESS}"

# Verify in context
cat context/terraclassic.json | jq '.deployments.warp.native[] | select(.id == "uluna")'
```

---

## Step 2: Deploy on Solana

### 2.1. Prepare Rust Environment

```bash
# Install Rust 1.75.0 (if needed)
rustup install 1.75.0
rustup default 1.75.0

# Set override for sealevel directory
cd ~/hyperlane-monorepo/rust/sealevel
rustup override set 1.75.0

# Verify installation
rustc --version  # Should show: rustc 1.75.0
cargo --version
```

### 2.2. Build Sealevel Programs

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Build synthetic token program
cargo build-sbf --manifest-path programs/hyperlane-sealevel-token/Cargo.toml

# Compiled program will be at:
# target/deploy/hyperlane_sealevel_token.so
```

**Note:** The `cargo build-sbf` command compiles Solana Sealevel programs. For tests, debug build is sufficient.

### 2.3. Create Core Program IDs File

**⚠️ CRITICAL**: The `hyperlane-sealevel-client` requires core program IDs (Mailbox, IGP, etc.) to initialize the warp route.

```bash
mkdir -p ~/hyperlane-monorepo/rust/sealevel/environments/testnet/solanatestnet/core

cat > ~/hyperlane-monorepo/rust/sealevel/environments/testnet/solanatestnet/core/program-ids.json << 'EOF'
{
  "mailbox": "75HBBLae3ddeneJVrZeyrDfv6vb7SMC3aCpBucSXS5aR",
  "validator_announce": "8qNYSi9EP1xSnRjtMpyof88A26GBbdcrsa61uSaHiwx3",
  "multisig_ism_message_id": "4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k",
  "igp_program_id": "5p7Hii6CJL4xGBYYTGEQmH9LnUSZteFJUu9AVLDExZX2",
  "overhead_igp_account": "hBHAApi5ZoeCYHqDdCKkCzVKmBdwywdT3hMqe327eZB",
  "igp_account": "9SQVtTNsbipdMzumhzi6X8GwojiSMwBfqAhS7FgyTcqy"
}
EOF
```

### 2.4. Create Chain Metadata File

```bash
mkdir -p ~/.hyperlane/registry/chains

cat > ~/.hyperlane/registry/chains/metadata.yaml << 'EOF'
solanatestnet:
  chainId: 101
  domainId: 1399811149
  name: solanatestnet
  nativeToken:
    decimals: 9
    name: SOL
    symbol: SOL
  protocol: sealevel
  rpcUrls:
    - http: https://api.testnet.solana.com
  blocks:
    confirmations: 1
    estimateBlockTime: 1
  isTestnet: true
EOF
```

### 2.5. Prepare Token Configuration

**⚠️ IMPORTANT**: The `token-config.json` must be in the correct format with the chain name as the key.

#### Complete Token Configuration Structure

The `token-config.json` supports the following fields:

**Required Fields:**
- `type`: Token type - `"native"`, `"synthetic"`, or `"collateral"`
- `decimals`: Number of decimals (0-9 for Solana, max 9)

**For Synthetic Tokens:**
- `name`: Token name (required for synthetic)
- `symbol`: Token symbol (required for synthetic)
- `totalSupply`: Initial total supply as string (e.g., `"0"`)
- `uri`: (Optional) URI to metadata JSON file

**For Collateral Tokens:**
- `token`: Mint address of the collateral token

**Optional Fields (All Token Types):**
- `remoteDecimals`: Decimals on remote chain (defaults to `decimals` if not specified)
- `interchainGasPaymaster`: IGP account Pubkey (optional, uses default if not specified)
- `interchainSecurityModule`: ISM program Pubkey (optional, uses Mailbox default ISM if not specified)
- `mailbox`: Mailbox program Pubkey (optional, uses core program IDs if not specified)
- `owner`: Owner Pubkey (optional, defaults to deployer)
- `foreignDeployment`: Program ID if program is already deployed (optional)

#### Example: Complete Configuration for Testnet

```bash
# Create configuration directory
mkdir -p ~/hyperlane-monorepo/rust/sealevel/environments/testnet/warp-routes/lunc-solana

# Create token configuration file with all available fields
cat > ~/hyperlane-monorepo/rust/sealevel/environments/testnet/warp-routes/lunc-solana/token-config.json << 'EOF'
{
  "solanatestnet": {
    "type": "synthetic",
    "name": "Luna Classic",
    "symbol": "wwwwLUNC",
    "decimals": 6,
    "totalSupply": "0",
    "interchainGasPaymaster": "9SQVtTNsbipdMzumhzi6X8GwojiSMwBfqAhS7FgyTcqy",
    "uri": "https://raw.githubusercontent.com/igorv43/cw-hyperlane/main/warp/solana/metadata.json"
  }
}
EOF
```

**Current Testnet Configuration (Minimal):**
```json
{
  "solanatestnet": {
    "type": "synthetic",
    "name": "Luna Classic",
    "symbol": "wwwwLUNC",
    "decimals": 6,
    "totalSupply": "0",
    "uri": "https://raw.githubusercontent.com/igorv43/cw-hyperlane/main/warp/solana/metadata.json"
  }
}
```

**IGP Account on Solana Testnet:**
- **IGP Program ID**: `5p7Hii6CJL4xGBYYTGEQmH9LnUSZteFJUu9AVLDExZX2`
- **IGP Account**: `9SQVtTNsbipdMzumhzi6X8GwojiSMwBfqAhS7FgyTcqy`
- **Overhead IGP Account**: `hBHAApi5ZoeCYHqDdCKkCzVKmBdwywdT3hMqe327eZB`

**Note**: The `interchainGasPaymaster` field should point to the IGP account (`9SQVtTNsbipdMzumhzi6X8GwojiSMwBfqAhS7FgyTcqy`), not the program ID.

#### Example: Native Token Configuration

```json
{
  "solanamainnet": {
    "type": "native",
    "decimals": 9,
    "interchainGasPaymaster": "AkeHBbE5JkwVppujCQQ6WuxsVsJtruBAjUo6fDCFp6fF"
  }
}
```

#### Example: Synthetic Token with Metadata URI

```json
{
  "eclipsemainnet": {
    "type": "synthetic",
    "decimals": 9,
    "name": "Solana",
    "symbol": "SOL",
    "uri": "https://github.com/hyperlane-xyz/hyperlane-registry/blob/b661127dd3dce5ea98b78ae0051fbd10c384b173/deployments/warp_routes/SOL/eclipse/metadata.json",
    "interchainGasPaymaster": "3Wp4qKkgf4tjXz1soGyTSndCgBPLZFSrZkiDZ8Qp9EEj"
  }
}
```

#### Metadata JSON Structure

When using `uri` for synthetic tokens, the metadata JSON should follow this structure:

```json
{
  "name": "Solana",
  "symbol": "SOL",
  "description": "Warp Route SOL on Eclipse",
  "image": "https://raw.githubusercontent.com/github/explore/14191328e15689ba52d5c10e18b43417bf79b2ef/topics/solana/solana.png",
  "attributes": []
}
```

**Metadata Fields:**
- `name`: Token name (must match `name` in token-config.json)
- `symbol`: Token symbol (must match `symbol` in token-config.json)
- `description`: Token description (required)
- `image`: URL to token image/logo (required, must return valid image)
- `attributes`: Array of key-value pairs (optional)

**Example Metadata for LUNC on Solana Testnet:**

The metadata file is located at: `warp/solana/metadata.json`

```json
{
  "name": "LUNA CLASSIC",
  "symbol": "wwwwLUNC",
  "description": "Warp Route LUNC",
  "image": "https://raw.githubusercontent.com/classic-terra/assets/refs/heads/master/icon/svg/LUNC.svg",
  "attributes": []
}
```

**File Location**: `/home/lunc/cw-hyperlane/warp/solana/metadata.json`

**URI in token-config.json**: `https://raw.githubusercontent.com/igorv43/cw-hyperlane/main/warp/solana/metadata.json`

**Note**: Make sure to push the `warp/solana/metadata.json` file to your GitHub repository so the URI is accessible.

**⚠️ IMPORTANT**: 
- Do NOT include `foreignDeployment` in the initial configuration if you want the client to initialize the token.
- Use `program-ids.json` to reference the existing Program ID if the program is already deployed.
- The `interchainGasPaymaster` should be the IGP account address, not the program ID.

### 2.6. Deploy Program (If Not Already Deployed)

If you haven't deployed the program yet:

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Deploy to Solana Testnet
solana program deploy target/deploy/hyperlane_sealevel_token.so \
  --url testnet \
  --keypair /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json
```

**Note**: Save the Program ID returned. In this case: `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`

### 2.7. Create Program IDs File

Create the `program-ids.json` file to reference the existing Program ID:

```bash
mkdir -p ~/hyperlane-monorepo/rust/sealevel/environments/testnet/warp-routes/lunc-solana

cat > ~/hyperlane-monorepo/rust/sealevel/environments/testnet/warp-routes/lunc-solana/program-ids.json << 'EOF'
{
  "solanatestnet": {
    "hex": "0x3e39de1edbc0495cee651b3e046f63d01ff9436932bb520e8c0cb4ba5c5c7f1d",
    "base58": "5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
  }
}
EOF
```

### 2.8. Deploy/Initialize the Warp Route

**⚠️ CRITICAL**: Execute from `~/hyperlane-monorepo/rust/sealevel/client` directory and use **relative paths** (`../` not `../../`).

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variables
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
WARP_ROUTE_NAME="lunc-solana"

# ⚠️ IMPORTANT: Relative paths from client/
# Use ../ (one level up), NOT ../../ (two levels)
ENVIRONMENTS_DIR="../environments"
TOKEN_CONFIG="../environments/testnet/warp-routes/lunc-solana/token-config.json"
BUILT_SO_DIR="../target/deploy"
REGISTRY_DIR="$HOME/.hyperlane/registry"

# Deploy/Initialize synthetic warp route
# NOTE: -k and -u are global arguments and must come BEFORE the subcommand
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  warp-route deploy \
  --warp-route-name "$WARP_ROUTE_NAME" \
  --environment testnet \
  --environments-dir "$ENVIRONMENTS_DIR" \
  --token-config-file "$TOKEN_CONFIG" \
  --built-so-dir "$BUILT_SO_DIR" \
  --registry "$REGISTRY_DIR" \
  --ata-payer-funding-amount 5000000
```

**Note**: The `--ata-payer-funding-amount` is set to `5000000` (0.005 SOL). Adjust based on your account balance. Ensure you have at least 0.01 SOL in your account.

**Expected Output:**
```
Recovered existing program id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x
Initializing Warp Route program: domain_id: 1399811149, mailbox: 75HBBLae3ddeneJVrZeyrDfv6vb7SMC3aCpBucSXS5aR, ...
Creating token DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA ...
Address: DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA
Decimals: 9
Signature: ...
initialized metadata pointer. Status: exit status: 0
initialized metadata. Status: exit status: 0
Transferring authority: mint to the mint account DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA
Set the mint authority to the mint account. Status: exit status: 0
```

**Save the information:**
```bash
SOLANA_PROGRAM_ID="5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
SOLANA_MINT_ACCOUNT="DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA"
```

### 2.9. Verify Deployment on Solana

```bash
# Verify the program
solana program show ${SOLANA_PROGRAM_ID} --url https://api.testnet.solana.com

# Verify the token mint
spl-token supply ${SOLANA_MINT_ACCOUNT} --url https://api.testnet.solana.com
```

---

## Step 3: Configure ISM Validators

### 3.1. Create New ISM (Recommended)

**⚠️ IMPORTANT**: The existing ISM (`4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k`) has a different owner. You need to **create a new ISM** and associate it with the warp route.

**Note**: The `hyperlane-sealevel-client` uses `--use-rpc` which is not supported by Solana CLI 1.14.20. We need to deploy manually.

```bash
# 1. Deploy new ISM (manual, without --use-rpc)
cd ~/hyperlane-monorepo/rust/sealevel
solana program deploy target/deploy/hyperlane_sealevel_multisig_ism_message_id.so \
  --url https://api.testnet.solana.com \
  --keypair /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json

# Save the Program ID returned (example: 8eFJPnNRz9byTu7NYc9NdsCMHQWfD37PZnhN8fZcahJS)
NEW_ISM_PROGRAM_ID="8eFJPnNRz9byTu7NYc9NdsCMHQWfD37PZnhN8fZcahJS"

# 2. Initialize the ISM
cd ~/hyperlane-monorepo/rust/sealevel/client
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id init \
  --program-id "$NEW_ISM_PROGRAM_ID"

# 3. Configure validators
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id set-validators-and-threshold \
  --program-id "$NEW_ISM_PROGRAM_ID" \
  --domain 1325 \
  --validators 242d8a855a8c932dec51f7999ae7d1e48b10c95e \
  --threshold 1

# 4. Associate ISM with warp route
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  token set-interchain-security-module \
  --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x \
  --ism "$NEW_ISM_PROGRAM_ID"
```

**📖 Complete Guide**: See [CREATE-NEW-ISM-SOLANA-EN.md](./CREATE-NEW-ISM-SOLANA-EN.md) for detailed instructions.

**✅ Successfully Deployed ISM**: `8eFJPnNRz9byTu7NYc9NdsCMHQWfD37PZnhN8fZcahJS`

### 3.2. Configure Validators on Existing ISM (If You Are the Owner)

The Solana ISM needs validators configured for Terra Classic domain (1325):

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variables
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"
DOMAIN="1325"  # Terra Classic domain
VALIDATOR="242d8a855a8c932dec51f7999ae7d1e48b10c95e"  # Terra Classic validator (hex)
THRESHOLD="1"

# Configure validators
# ⚠️ IMPORTANT: Use "multisig-ism-message-id" (with hyphens), not "ism multisig-message-id"
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id set-validators-and-threshold \
  --program-id "$ISM_PROGRAM_ID" \
  --domain "$DOMAIN" \
  --validators "$VALIDATOR" \
  --threshold "$THRESHOLD"
```

### 3.2. Verify Validators Configuration

```bash
# Get validators and threshold for a domain
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id "$ISM_PROGRAM_ID" \
  --domains "$DOMAIN"
```

**Expected Output:**
```
Querying domain data for origin domain: 1325
Domain data for 1325:
DomainDataAccount {
    validators: [
        "242d8a855a8c932dec51f7999ae7d1e48b10c95e"
    ],
    threshold: 1,
}
```

### 3.3. Configure ISM on Solana Warp Route (Optional)

**⚠️ IMPORTANT**: By default, the Solana warp route uses the ISM configured in the Solana Mailbox. You can optionally set a custom ISM:

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Program ID of the warp route
WARP_ROUTE_PROGRAM_ID="5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"

# ISM Program ID (Multisig ISM Message ID)
ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"

# Set custom ISM (optional)
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token set-interchain-security-module \
  --program-id "$WARP_ROUTE_PROGRAM_ID" \
  --ism "$ISM_PROGRAM_ID"
```

**Note**: In most cases, you don't need to do this. The warp route already uses the Mailbox's default ISM automatically.

---

## Step 4: Bidirectional Linking

### 4.1. Convert Addresses to Hex Format (32 bytes)

#### Convert Terra Classic Address (Bech32) to Hex

The Solana warp route needs the Terra Classic address in hex format (32 bytes):

```bash
# Method 1: Use hex address from context file (recommended)
TERRA_WARP_ADDRESS="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"
TERRA_WARP_HEX="0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b"

# Method 2: Convert manually using cw-hpl CLI
yarn cw-hpl wallet convert-cosmos-to-eth ${TERRA_WARP_ADDRESS}
```

#### Convert Solana Program ID (Base58) to Hex

For Terra Classic → Solana transfers, the Solana Program ID needs to be converted:

```bash
# Solana Program ID (base58)
SOLANA_PROGRAM_ID="5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"

# Convert to hex (32 bytes) using Python
python3 << EOF
import base58
import binascii

solana_address = "${SOLANA_PROGRAM_ID}"
decoded = base58.b58decode(solana_address)
hex_address = binascii.hexlify(decoded).decode('utf-8')
# Pad to 64 characters (32 bytes)
hex_padded = hex_address.zfill(64)
print(f"0x{hex_padded}")
EOF
```

**Result**: `0x3e39de1edbc0495cee651b3e046f63d01ff9436932bb520e8c0cb4ba5c5c7f1d`

**Important:**
- Terra Classic → Solana: Recipient must be hex (32 bytes, 64 characters, without 0x in JSON)
- Solana → Terra Classic: Recipient must be hex (32 bytes, 64 characters, without 0x in JSON)

### 4.2. Link Terra Classic → Solana

On Terra Classic, enroll the Solana warp route as a remote router:

```bash
# Terra Classic warp route address
TERRA_WARP="terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8"

# Solana Program ID (32-byte hex format, without 0x)
SOLANA_WARP_HEX="3e39de1edbc0495cee651b3e046f63d01ff9436932bb520e8c0cb4ba5c5c7f1d"

# Solana domain
SOLANA_DOMAIN="1399811149"

# Link using terrad
terrad tx wasm execute "$TERRA_WARP" \
  "{\"enroll_remote_router\":{\"domain\":$SOLANA_DOMAIN,\"router\":\"$SOLANA_WARP_HEX\"}}" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

### 4.3. Link Solana → Terra Classic

On Solana, enroll the Terra Classic warp route as a remote router:

**⚠️ IMPORTANT**: Unlike BSC/EVM chains, Solana does **NOT** use Safe. You interact directly with the Solana program using the `hyperlane-sealevel-client`.

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variables
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
WARP_ROUTE_PROGRAM_ID="5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
TERRA_DOMAIN="1325"

# Terra Classic warp route address
# Option 1: Use hex format (with or without 0x prefix)
TERRA_WARP_HEX="0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b"

# Option 2: Use bech32 format (will be auto-converted to H256)
TERRA_WARP_BECH32="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"

# Link using sealevel client
# ⚠️ IMPORTANT: -k and -u are global arguments and must come BEFORE the subcommand
# ⚠️ IMPORTANT: domain and router are POSITIONAL arguments, not flags
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token enroll-remote-router \
  --program-id "$WARP_ROUTE_PROGRAM_ID" \
  "$TERRA_DOMAIN" \
  "$TERRA_WARP_HEX"
```

**Alternative: Using Bech32 Address Directly**

The `hyperlane-sealevel-client` can automatically convert bech32 addresses to H256:

```bash
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token enroll-remote-router \
  --program-id "$WARP_ROUTE_PROGRAM_ID" \
  "$TERRA_DOMAIN" \
  "$TERRA_WARP_BECH32"
```

**Expected Output:**
```
==== Instructions: ====
Instruction 0: Set compute unit limit to 1400000
Instruction 1: Enroll remote router for domain 1325: 0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b
Transaction signature: <TX_SIGNATURE>
```

**📖 Complete Guide**: See [ENROLL-REMOTE-ROUTER-SOLANA.md](./ENROLL-REMOTE-ROUTER-SOLANA.md) for detailed instructions and troubleshooting.

### 4.4. Verify Links

#### Verify on Terra Classic

```bash
# Verify configured route
terrad query wasm contract-state smart ${TERRA_WARP_ADDRESS} \
  '{"router":{"get_route":{"domain":1399811149}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq -r '.data.route'
```

#### Verify on Solana

```bash
# Query program to verify remote router
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x \
  synthetic
```

---

## Step 5: Test Transfers

### 5.1. Transfer: Terra Classic → Solana

#### Using terrad CLI

```bash
# 1. Calculate IGP gas payment first
IGP="terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9"
GAS_AMOUNT="200000"  # Estimated gas for Solana

IGP_GAS=$(terrad query wasm contract-state smart ${IGP} \
  '{"igp":{"quote_gas_payment":{"dest_domain":1399811149,"gas_amount":"'${GAS_AMOUNT}'"}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq -r '.data.gas_needed')

echo "IGP Gas needed: ${IGP_GAS} uluna ($(echo "scale=2; ${IGP_GAS}/1000000" | bc) LUNC)"

# 2. Convert Solana address to hex format (32 bytes)
SOLANA_RECIPIENT="EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd"  # Your Solana address (base58)

# Convert using Python
SOLANA_RECIPIENT_HEX=$(python3 << EOF
import base58
import binascii
solana_address = "${SOLANA_RECIPIENT}"
decoded = base58.b58decode(solana_address)
hex_address = binascii.hexlify(decoded).decode('utf-8')
hex_padded = hex_address.zfill(64)
print(hex_padded)  # Without 0x, just 64 hex characters
EOF
)

echo "Solana recipient hex: ${SOLANA_RECIPIENT_HEX}"

# 3. Calculate values
TRANSFER_AMOUNT="10000000"  # 10 LUNC in uluna
HOOK_FEE="283215"  # Fixed hook fee
TOTAL_AMOUNT=$((TRANSFER_AMOUNT + HOOK_FEE + IGP_GAS))

# 4. Execute transfer
terrad tx wasm execute terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8 \
  "{\"transfer_remote\":{\"dest_domain\":1399811149,\"recipient\":\"${SOLANA_RECIPIENT_HEX}\",\"amount\":\"${TRANSFER_AMOUNT}\"}}" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 28.5uluna \
  --amount ${TOTAL_AMOUNT}uluna \
  --yes
```

#### Using cw-hpl CLI

```bash
yarn cw-hpl warp transfer \
  --asset-type native \
  --asset-id uluna \
  --target-domain 1399811149 \
  --recipient ${SOLANA_RECIPIENT_HEX} \
  --amount 10000000 \
  -n terraclassic
```

### 5.2. Verify Receipt on Solana

```bash
# Verify synthetic token balance
spl-token balance ${SOLANA_MINT_ACCOUNT} \
  --owner ~/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  --url https://api.testnet.solana.com

# Or verify on explorer
echo "https://explorer.solana.com/address/${SOLANA_MINT_ACCOUNT}?cluster=testnet"
```

### 5.3. Transfer: Solana → Terra Classic

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Convert Terra Classic address to hex (32 bytes)
TERRA_RECIPIENT="terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze"  # Your Terra Classic address
TERRA_RECIPIENT_HEX="..."  # Converted to hex (32 bytes, without 0x)

# Execute transfer
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token transfer-remote \
  "$KEYPAIR" \
  10000000 \
  1325 \
  "$TERRA_RECIPIENT_HEX" \
  synthetic \
  --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x
```

**Parameters:**
- `10000000`: Amount in smallest units (6 decimals = 10 LUNC)
- `1325`: Terra Classic domain ID
- `TERRA_RECIPIENT_HEX`: Terra Classic address in hex (32 bytes, without 0x)
- `synthetic`: Token type at origin (Solana)
- `--program-id`: Warp route Program ID

### 5.4. Verify Receipt on Terra Classic

```bash
# Verify balance
terrad query bank balances ${TERRA_RECIPIENT} \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443

# Verify on explorer
echo "https://finder.terra-classic.hexxagon.dev/testnet/address/${TERRA_RECIPIENT}"
```

---

## Troubleshooting

### Problem 1: `--use-rpc` Error

**Symptom**: Error when deploying: `error: Found argument '--use-rpc' which wasn't expected`

**Solution**: Use `program-ids.json` to reference existing Program ID instead of trying to deploy again. See [FIX-SOLANA-DEPLOY-USE-RPC-EN.md](./FIX-SOLANA-DEPLOY-USE-RPC-EN.md).

### Problem 2: Insufficient Lamports

**Symptom**: Error "Transfer: insufficient lamports"

**Solution**: 
1. Check balance: `solana balance <address> --url https://api.testnet.solana.com`
2. Reduce `--ata-payer-funding-amount` (minimum: 5000000 lamports)
3. Or add more SOL to your account

### Problem 3: `Failed to read JSON from file`

**Symptom**: Error when reading `core/program-ids.json`

**Solution**: Create the file as described in Step 2.3.

### Problem 4: `No such file or directory` for token-config.json

**Symptom**: Incorrect relative paths

**Solution**: 
- Execute from `~/hyperlane-monorepo/rust/sealevel/client`
- Use `../environments` (not `../../environments`)
- Use `../target/deploy` (not `../../target/deploy`)

### Problem 5: Error Converting Solana Address to Hex

**Symptom**: Error when trying to link or transfer.

**Solution:**
```bash
# Install Python dependencies (if needed)
pip3 install base58

# Convert Solana address (base58) to hex
python3 << EOF
import base58
import binascii

solana_address = "YOUR_SOLANA_ADDRESS"
decoded = base58.b58decode(solana_address)
hex_address = binascii.hexlify(decoded).decode('utf-8')
# Pad to 64 characters (32 bytes)
hex_padded = hex_address.zfill(64)
print(hex_padded)  # For use in transfer_remote (without 0x)
EOF
```

**Note:** For `transfer_remote` on Terra Classic, use only the 64 hex characters (without `0x`).

### Problem 6: IGP Gas Payment Insufficient

**Symptom**: Error "insufficient hook payment" or "insufficient funds".

**Solution:**
1. Check IGP Oracle configuration for domain 1399811149:
```bash
IGP_ORACLE="terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"
terrad query wasm contract-state smart ${IGP_ORACLE} \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":1399811149}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

2. Recalculate IGP gas payment (see `IGP-COMPLETE-GUIDE.md`)

3. Increase `--amount` to include IGP gas payment

### Problem 7: Token Not Appearing on Solana

**Symptom**: Transfer seems successful, but token doesn't appear.

**Solution:**
1. Verify if ATA (Associated Token Account) was created:
```bash
# Create ATA if needed
spl-token create-account ${SOLANA_MINT_ACCOUNT} \
  --owner ~/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  --url https://api.testnet.solana.com
```

2. Verify if relayer processed the message:
   - Check on [Hyperlane Explorer](https://explorer.hyperlane.xyz/)
   - Wait a few minutes for processing

---

## References

### Official Documentation

- [Hyperlane Solana Warp Route Guide](https://docs.hyperlane.xyz/docs/guides/warp-routes/svm/svm-warp-route-guide)
- [Extending Warp Routes](https://docs.hyperlane.xyz/docs/guides/warp-routes/evm/extending-warp-routes)
- [Hyperlane Registry - Solana Testnet](https://github.com/hyperlane-xyz/hyperlane-registry/tree/main/chains/solanatestnet)

### Repositories

- [Hyperlane Monorepo](https://github.com/hyperlane-xyz/hyperlane-monorepo)
- [cw-hyperlane](https://github.com/many-things/cw-hyperlane)

### Explorers

- [Hyperlane Explorer](https://explorer.hyperlane.xyz/)
- [Terra Classic Finder](https://finder.terra-classic.hexxagon.dev/testnet)
- [Solana Explorer](https://explorer.solana.com/?cluster=testnet)

### Tools

- [Solana CLI Documentation](https://docs.solana.com/cli)
- [SPL Token CLI](https://spl.solana.com/token)

---

## Summary of Main Commands

### Terra Classic

```bash
# Deploy
yarn cw-hpl warp create ./example/warp/uluna-solana.json -n terraclassic

# Link
yarn cw-hpl warp link \
  --asset-type native \
  --asset-id uluna \
  --target-domain 1399811149 \
  --warp-address ${SOLANA_PROGRAM_ID_HEX} \
  -n terraclassic

# Transfer
yarn cw-hpl warp transfer \
  --asset-type native \
  --asset-id uluna \
  --target-domain 1399811149 \
  --recipient ${SOLANA_RECIPIENT_HEX} \
  --amount 10000000 \
  -n terraclassic
```

### Solana

```bash
# Deploy/Initialize
cd ~/hyperlane-monorepo/rust/sealevel/client
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  warp-route deploy \
  --warp-route-name lunc-solana \
  --environment testnet \
  --environments-dir ../environments \
  --token-config-file ../environments/testnet/warp-routes/lunc-solana/token-config.json \
  --built-so-dir ../target/deploy \
  --registry ~/.hyperlane/registry \
  --ata-payer-funding-amount 5000000

# Enroll Remote Router
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token enroll-remote-router \
  --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x \
  --domain 1325 \
  --router 0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02

# Transfer
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token transfer-remote \
  "$KEYPAIR" \
  10000000 \
  1325 \
  ${TERRA_RECIPIENT_HEX} \
  synthetic \
  --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x
```

---

## Deployment Summary

After completing all steps, you will have:

1. ✅ **Terra Classic Warp Route**: `terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8`
2. ✅ **Solana Program Deployed**: `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`
3. ✅ **Solana Mint Account**: `DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA`
4. ✅ **Token Initialized**: "Luna Classic" (wwwwLUNC) with 6 decimals
5. ✅ **ISM Configured**: Validators set for Terra Classic domain
6. ✅ **Warp Routes Linked**: Terra Classic ↔ Solana bidirectional link
7. ✅ **Ready for Transfers**: Can send LUNC from Terra Classic to Solana and vice versa

---

**Last Updated:** December 2025

