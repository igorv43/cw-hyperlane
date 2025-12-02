# 📘 Complete Guide: Hyperlane Deployment and Configuration on Terra Classic

This guide documents the complete process of deploying and configuring Hyperlane contracts on Terra Classic (LUNC).

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Verify Available Contracts](#verify-available-contracts)
3. [Deploy Contracts (Upload)](#deploy-contracts-upload)
4. [Contract Instantiation](#contract-instantiation)
5. [Configuration via Governance](#configuration-via-governance)
6. [Execution Verification](#execution-verification)
7. [Contract Addresses and Hexed](#contract-addresses-and-hexed)
8. [Troubleshooting](#troubleshooting)

---

## 🔧 Prerequisites

### System Requirements

- **Node.js**: v18+ or v20+
- **Yarn**: v4.1.0+
- **Terra Classic Node**: LocalTerra or access to a public RPC
- **Wallet**: Configured private key

### Environment Variables

```bash
export PRIVATE_KEY="your_hexadecimal_private_key"
```

### Dependencies Installation

```bash
cd cw-hyperlane
yarn install
```

---

## 1️⃣ Verify Available Contracts

Before deploying, check which contracts are available in the remote repository:

```bash
yarn cw-hpl upload remote-list -n terraclassic
```

**Expected output:**
```
Listing available contracts from remote repository...
- hpl_mailbox
- hpl_validator_announce
- hpl_ism_aggregate
- hpl_ism_multisig
- hpl_ism_pausable
- hpl_ism_routing
- hpl_igp
- hpl_igp_oracle
- hpl_hook_aggregate
- hpl_hook_fee
- hpl_hook_merkle
- hpl_hook_pausable
- hpl_hook_routing
- hpl_hook_routing_custom
- hpl_hook_routing_fallback
- hpl_test_mock_hook
- hpl_test_mock_ism
- hpl_test_mock_msg_receiver
- hpl_warp_cw20
- hpl_warp_native
```

### 📦 Available Releases

Compiled WASM contracts are available on GitHub Releases:

- **Latest Release**: [v0.0.6-rc8](https://github.com/many-things/cw-hyperlane/releases/tag/v0.0.6-rc8)
- **Direct Download**: https://github.com/many-things/cw-hyperlane/releases/download/v0.0.6-rc8/cw-hyperlane-v0.0.6-rc8.zip
- **All Versions**: https://github.com/many-things/cw-hyperlane/releases

### Manual Download (Optional)

If you prefer to download manually:

```bash
# Download the release
wget https://github.com/many-things/cw-hyperlane/releases/download/v0.0.6-rc8/cw-hyperlane-v0.0.6-rc8.zip

# Extract
unzip cw-hyperlane-v0.0.6-rc8.zip -d artifacts/

# Verify checksums
cat artifacts/checksums.txt
```

> **⚠️ Security:**
> 
> - ✅ **Always download** from official GitHub releases
> - ✅ **Verify** checksums before uploading
> - ✅ **Compare** blockchain hashes with official hashes
> - ❌ **Never use** WASM binaries from untrusted sources

---

## 2️⃣ Deploy Contracts (Upload)

### Upload to Blockchain

Execute the command to upload all contracts of the specified version:

```bash
yarn cw-hpl upload remote v0.0.6-rc8 -n terraclassic
```

**What this command does:**
- 📥 **Downloads WASM files** from GitHub release:
  - URL: https://github.com/many-things/cw-hyperlane/releases/download/v0.0.6-rc8/cw-hyperlane-v0.0.6-rc8.zip
  - Version: `v0.0.6-rc8`
  - Contains: 20 compiled contracts (.wasm) + checksums.txt
- 📤 Uploads to Terra Classic blockchain
- 💾 Stores the `code_id` of each contract
- 📝 Saves IDs in the context file (`context/terraclassic.json`)

> **📦 Release Contents:**
> The ZIP file contains all compiled WASM contracts and a `checksums.txt` file with SHA-256 hashes for integrity verification.

**Expected output:**
```
Uploading contracts to terraclassic...
✓ hpl_mailbox uploaded: code_id 1
✓ hpl_validator_announce uploaded: code_id 2
✓ hpl_ism_aggregate uploaded: code_id 3
✓ hpl_ism_multisig uploaded: code_id 4
✓ hpl_ism_pausable uploaded: code_id 5
✓ hpl_ism_routing uploaded: code_id 6
✓ hpl_igp uploaded: code_id 7
✓ hpl_hook_aggregate uploaded: code_id 8
✓ hpl_hook_fee uploaded: code_id 9
✓ hpl_hook_merkle uploaded: code_id 10
✓ hpl_hook_pausable uploaded: code_id 11
✓ hpl_hook_routing uploaded: code_id 12
✓ hpl_hook_routing_custom uploaded: code_id 13
✓ hpl_hook_routing_fallback uploaded: code_id 14
✓ hpl_test_mock_hook uploaded: code_id 15
✓ hpl_test_mock_ism uploaded: code_id 16
✓ hpl_test_mock_msg_receiver uploaded: code_id 17
✓ hpl_igp_oracle uploaded: code_id 18
✓ hpl_warp_cw20 uploaded: code_id 19
✓ hpl_warp_native uploaded: code_id 20

All contracts uploaded successfully!
```

### Contract Hashes (For Auditing)

During upload, each contract generates a **SHA-256 hash** of the WASM file. These hashes are **crucial for auditing** and ensure there has been no tampering with the binaries:

| Contract | SHA-256 Hash | Code ID (LocalTerra) | TX Hash (Mainnet Example) |
|----------|--------------|----------------------|---------------------------|
| **hpl_mailbox** | `12e1eb4266faba3cc99ccf40dd5e65aed3e03a8f9133c4b28fb57b2195863525` | 1 | CE57EE3112A0E763B81F6646A73F6E8558FA563C6B7AC130A629BA03F0E7D981 |
| **hpl_validator_announce** | `87cf4cbe4f5b6b3c7a278b4ae0ae980d96c04192f07aa70cc80bd7996b31c6a8` | 2 | 3423021865EFB45A7E603EC1934B671F0BF61CF693622B7D495B3F4FA9C810B8 |
| **hpl_ism_aggregate** | `fae4d22afede6578ce8b4dbfaa185d43a303b8707386a924232aa24632d00f7b` | 3 | A91910622861998F1D2758132E4D514CB9AB6A479D0E31B2F238C28E9551962D |
| **hpl_ism_multisig** | `d1f4705e19414e724d3721edad347003934775313922b7ca183ca6fa64a9e076` | 4 | 1C85143E0EBE5BC92DADE8373EF8A2D968409B255EA3E92A3BC910F0F4707221 |
| **hpl_ism_pausable** | `a6e8cc30b5abf13a032c8cb70128fcd88305eea8133fd2163299cf60298e0e7f` | 5 | D7FCD891ECBCE204F5F91B690884500C493C598D41D4FB92BB380C3168D6B529 |
| **hpl_ism_routing** | `a0b29c373cb5428ef6e8a99908e0e94b62d719c65434d133b14b4674ee937202` | 6 | 6A4FF7090F661E7E5BF04782E812145D4439953170CCA09604A5A5AA42873D69 |
| **hpl_igp** | `99e42faf05c446170167bdf0521eaaeebe33658972d056c4d0dc607d99186044` | 7 | 4068C5CE6C45DDA52F84AA171ECE66198E12C36E542B05C637FE590D3346F91B |
| **hpl_hook_aggregate** | `2ee718217253630b087594a92a6770f8d040a99b087e38deafef2e4685b23e8f` | 8 | B647037852D7D3F16F79F8081520A396904F042DCB5EBCC7488467F68BC1DBF0 |
| **hpl_hook_fee** | `8beeb594aa33ae3ce29f169ac73e2c11c80a7753a2c92518e344b86f701d50fd` | 9 | D05A0532EE4544293B5EA2F99AD0F681B0731CE321BAF832E18F020B4BD7EE2B |
| **hpl_hook_merkle** | `1de731062f05b83aaf44e4abb37f566bb02f0cd7c6ecf58d375cbce25ff53076` | 10 | A2248F5E37310B2C17C6FB9A6BC9E7466C5F3FD1D1C6A6769A8F461FF23A67BF |
| **hpl_hook_pausable** | `8ea810f57c31bd754ba21ac87cfc361f1d6cc55974eefd8ad2308b69bd63d6bf` | 11 | CF6053838160CEB4E820DCB72E9C6ECEE564975859F4BDB91367B33654125168 |
| **hpl_hook_routing** | `cbf712a3ed6881e267ad3b7a82df362c02ae9cb98b68e12c316005d928f611cf` | 12 | 9E66F5B8322F817C6307E3AC8A27B7AAB27B5112A11DAAB12DC25AAC9C1910E6 |
| **hpl_hook_routing_custom** | `f2ffb3a6444da867d7cd81726cb0362ac3cc7ba2e8eef11dcb50f96e6725d09a` | 13 | 7AB3107966F2B0D2EA9446183A175B6F53087B4B7D007FFC3BAB2FCC1668BAD3 |
| **hpl_hook_routing_fallback** | `d701bb43e1aea05ae8bdb3fcbe68b449b6e6d9448420b229a651ed9628a3d309` | 14 | 19545E011C1194AF3F262DAF85E33C16493EEFD20DE00EC718234FFDB6646677 |
| **hpl_test_mock_hook** | `15b7b62a78ce535239443228a0dc625408941182d1b09b338b55d778101e7913` | 15 | 0AAF8A18DA0CDFC79B24E58EFAC2FCD3A8410C495F69FC748494C4ADAC5BD1A0 |
| **hpl_test_mock_ism** | `a5d07479b6d246402438b6e8a5f31adaafa18c2cd769b6dc821f21428ad560ab` | 16 | E93B9A40A0662209B9B10B23DEB05D843DBFFC06DCF8E412DD65635AF1FD4DB8 |
| **hpl_test_mock_msg_receiver** | `35862c951117b77514f959692741d9cabc21ce7c463b9682965fce983140f0c1` | 17 | 60617D659BAED0D48BF952201BA081BCCEA3D0AF3F3CE3F71EDE06D1C5FB24D9 |
| **hpl_igp_oracle** | `a628d5e0e6d8df3b41c60a50aeaee58734ae21b03d443383ebe4a203f1c86609` | 18 | 6E9AF7B37F49BD4EBAA3DF68775B3C3BCFEDF6AAEEACB0DC757B424D0395DD59 |
| **hpl_warp_cw20** | `a97d87804fae105d95b916d1aee72f555dd431ece752a646627cf1ac21aa716d` | 19 | 2AE69E1B45D6CC91120E890611B40E72C16B3085C2A75825459FBEE37EA41A05 |
| **hpl_warp_native** | `5aa1b379e6524a3c2440b61c08c6012cc831403fae0c825b966ceabecfdb172b` | 20 | E7E0C847F1DF98B1A978700579EE060C1DF25F57A2791355005FD30AAE105FE6 |

#### 🔒 Integrity Verification

The SHA-256 hashes above allow you to **verify the integrity** of the contracts:

1. **WASM Hash**: Calculated locally before upload
2. **Code ID**: Unique identifier on the blockchain after upload
3. **TX Hash**: Upload transaction hash on the blockchain

**Method 1: Verify against blockchain**

```bash
# Download WASM from code ID (example: hpl_mailbox with code_id 1)
terrad query wasm code 1 download.wasm --node http://localhost:26657

# Calculate SHA-256 hash
sha256sum download.wasm

# Compare with hash from table above
# For hpl_mailbox should be: 12e1eb4266faba3cc99ccf40dd5e65aed3e03a8f9133c4b28fb57b2195863525
```

**Method 2: Verify against official release**

```bash
# Download official release
wget https://github.com/many-things/cw-hyperlane/releases/download/v0.0.6-rc8/cw-hyperlane-v0.0.6-rc8.zip
unzip cw-hyperlane-v0.0.6-rc8.zip

# Verify all checksums
sha256sum -c checksums.txt

# Or verify a specific contract
sha256sum hpl_mailbox.wasm
# Output: 12e1eb4266faba3cc99ccf40dd5e65aed3e03a8f9133c4b28fb57b2195863525
```

> **✅ checksums.txt File**
> 
> The release includes a `checksums.txt` file with all official hashes. This file is the trusted source for contract auditing.

> **📝 Note about Code IDs:**
> - **LocalTerra**: Code IDs are sequential 1-20
> - **Mainnet/Testnet**: Code IDs depend on how many contracts have already been uploaded (ex: 10588-10607)
> - TX Hashes in the table are examples from a real mainnet deployment
> - Always check `context/terraclassic.json` for the correct code IDs of your environment

#### 📊 Data Meaning

- **SHA-256 Hash**: Unique fingerprint of the compiled WASM file
- **Code ID**: Sequential number assigned by the blockchain when storing the code
- **TX Hash**: Identifier of the transaction that performed the upload
- **[NEW]**: Indicates it's a new upload (not an update)
- **[SUCCESS]**: Confirms the upload was successful

### Verify Code IDs

The `code_id` values are saved in:
```bash
cat context/terraclassic.json
```

**Example content:**
```json
{
  "artifacts": {
    "hpl_mailbox": 1,
    "hpl_validator_announce": 2,
    "hpl_ism_aggregate": 3,
    "hpl_ism_multisig": 4,
    "hpl_ism_pausable": 5,
    "hpl_ism_routing": 6,
    "hpl_igp": 7,
    "hpl_hook_aggregate": 8,
    "hpl_hook_fee": 9,
    "hpl_hook_merkle": 10,
    "hpl_hook_pausable": 11,
    "hpl_hook_routing": 12,
    "hpl_hook_routing_custom": 13,
    "hpl_hook_routing_fallback": 14,
    "hpl_test_mock_hook": 15,
    "hpl_test_mock_ism": 16,
    "hpl_test_mock_msg_receiver": 17,
    "hpl_igp_oracle": 18,
    "hpl_warp_cw20": 19,
    "hpl_warp_native": 20
  }
}
```

### Identifying the Governance Module

To check the governance module address on your network:

```bash
# View governance information
terrad query gov params --node http://localhost:26657

# The governance module usually has the address:
# terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n (Terra Classic)
```

To verify if a contract is controlled by governance:

```bash
# Check the admin of an instantiated contract
terrad query wasm contract-state smart <CONTRACT_ADDRESS> \
  '{"ownable":{"owner":{}}}' \
  --node http://localhost:26657

# If the owner is terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n
# it means only governance can alter the contract
```

### Contract Integrity Verification

For auditors and validators, it's possible to verify that the contracts on the blockchain exactly match the official binaries:

```bash
# 1. Download WASM from a specific contract
terrad query wasm code <CODE_ID> contract.wasm --node http://localhost:26657

# 2. Calculate SHA-256 hash
sha256sum contract.wasm

# 3. Compare with the hash table above
```

**Practical example:**
```bash
# Verify hpl_mailbox (code_id 1 on LocalTerra)
terrad query wasm code 1 mailbox.wasm --node http://localhost:26657
sha256sum mailbox.wasm
# Expected output: 12e1eb4266faba3cc99ccf40dd5e65aed3e03a8f9133c4b28fb57b2195863525

# If the hash is identical, the contract hasn't been altered ✅
```

---

## 3️⃣ Contract Instantiation

### Script: `CustomInstantiateWasm.ts`

This script instantiates all contracts on the blockchain with their initial configurations.

#### Run Instantiation

```bash
cd /home/lunc/cw-hyperlane
PRIVATE_KEY="your_hex_key" ts-node script/CustomInstantiateWasm.ts
```

#### Script Configuration

The script is configured with:
- **RPC**: `http://localhost:26657`
- **Chain ID**: `localterra`
- **Admin/Owner**: `terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n` ⚠️
- **Gas Price**: `28.5uluna`

### 📋 Instantiated Contracts - Detailed Explanation

The script instantiates **11 contracts** in the following order:

---

#### 1. 📮 MAILBOX - Main Cross-Chain Messaging Contract

**Function:** The Mailbox is the central contract that manages sending and receiving cross-chain messages. It coordinates ISMs, Hooks, and maintains the message nonce.

**Instantiation Parameters:**
```json
{
  "hrp": "terra",
  "domain": 1325,
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n"
}
```

**Parameter Explanation:**
- `hrp` (string): Human-readable part of the Bech32 address - chain prefix (ex: "terra" for Terra Classic)
- `domain` (u32): Unique chain domain ID in the Hyperlane protocol. Terra Classic = 1325
- `owner` (string): Address that will have admin control of the contract (governance module)

**Code ID:** `1`

---

#### 2. 📢 VALIDATOR ANNOUNCE - Validator Registry

**Function:** Allows validators to announce their endpoints and locations so relayers can discover how to obtain signatures.

**Instantiation Parameters:**
```json
{
  "hrp": "terra",
  "mailbox": "terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au"
}
```

**Parameter Explanation:**
- `hrp` (string): Bech32 chain prefix
- `mailbox` (string): Mailbox address associated with this announcer

**Code ID:** `2`

---

#### 3. 🔐 ISM MULTISIG - Interchain Security Module (Multisig)

**Function:** ISM that validates messages using signatures from multiple validators. Requires a minimum threshold of signatures to approve a message.

**Instantiation Parameters:**
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n"
}
```

**Parameter Explanation:**
- `owner` (string): Address that can configure validators and threshold (governance module)

**Note:** Validators and threshold will be configured later via governance.

**Code ID:** `4`

---

#### 4. 🗺️ ISM ROUTING - ISM Router

**Function:** Allows using different ISMs for different domains (chains). Useful for having customized security policies per source chain.

**Instantiation Parameters:**
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "isms": [
    {
      "domain": 1,
      "address": "terra1e7sgpxr50rlxarvjt07n0pxgxre5fcgannucx37309446x5pwacs8qhryp"
    },
    {
      "domain": 56,
      "address": "terra1m9wuxnx2vkv9duapcu9xfdnm9v5cv6eg35yzxmhgeuvch4y24aws8r49c9"
    },
    {
      "domain": 1399811149,
      "address": "terra13l8gwanf37938wgfv5yktmfzxjwaj4ysn4gl96vj78xcqqxlcrgsll77zu"
    }
  ]
}
```

**Parameter Explanation:**
- `owner` (string): Address that can add/remove ISM routes
- `isms` (array): List of domain → ISM mappings
  - `domain` (u32): Source chain domain ID
    - Domain 1 = Ethereum
    - Domain 56 = BSC (Binance Smart Chain)
    - Domain 1399811149 = Solana
  - `address` (string): ISM address to be used for messages from this domain

**Note:** Each chain has its own ISM Multisig with specific validators and threshold.

**Code ID:** `6`

---

#### 5. 🌳 HOOK MERKLE - Merkle Tree for Proofs

**Function:** Maintains a Merkle tree of sent messages. This allows efficient inclusion proofs for message validation on the destination chain.

**Instantiation Parameters:**
```json
{
  "mailbox": "terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au"
}
```

**Parameter Explanation:**
- `mailbox` (string): Mailbox address associated with this hook

**Code ID:** `10`

---

#### 6. ⛽ IGP - Interchain Gas Paymaster

**Function:** Manages gas payments for message execution on the destination chain. Users pay gas on the source chain, and relayers are reimbursed on the destination chain.

**Instantiation Parameters:**
```json
{
  "hrp": "terra",
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "gas_token": "uluna",
  "beneficiary": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "default_gas_usage": "100000"
}
```

**Parameter Explanation:**
- `hrp` (string): Bech32 prefix
- `owner` (string): Contract admin
- `gas_token` (string): Token used for gas payment (micro-luna = uluna)
- `beneficiary` (string): Address that receives accumulated fees
- `default_gas_usage` (string): Default estimated gas amount for execution (100000 = 100k gas units)

**Code ID:** `7`

---

#### 7. 🔮 IGP ORACLE - Gas Price Oracle

**Function:** Provides token exchange rates and gas prices for remote chains. Essential for calculating how much gas to charge at origin to cover destination costs.

**Instantiation Parameters:**
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n"
}
```

**Parameter Explanation:**
- `owner` (string): Address that can update exchange rates and gas prices

**Note:** Exchange rates and gas prices will be configured via governance.

**Code ID:** `18`

---

#### 8. 🔗 HOOK AGGREGATE #1 - Aggregator (Merkle + IGP)

**Function:** Combines multiple hooks into one. This first aggregator executes:
- **Hook Merkle**: registers message in Merkle tree
- **IGP**: processes gas payment

**Instantiation Parameters:**
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "hooks": [
    "terra1zlwdkv49rmsug0pnwu6fmwnl267lfr34smmfyer9dvakpnk29whqfs47n2",
    "terra1wn625s4jcmvk0szpl85rj5azkfc6suyvf75q6vrddscjdphtve8stalnth"
  ]
}
```

**Parameter Explanation:**
- `owner` (string): Contract admin
- `hooks` (array): List of hook addresses to be executed in sequence
  - Hook 1: Merkle Tree
  - Hook 2: IGP

**Note:** This hook will be set as `default_hook` in the Mailbox.

**Code ID:** `8`

---

#### 9. ⏸️ HOOK PAUSABLE - Hook with Pause Capability

**Function:** Allows pausing message sending in case of emergency. Useful for maintenance or responding to security incidents.

**Instantiation Parameters:**
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "paused": false
}
```

**Parameter Explanation:**
- `owner` (string): Address that can pause/unpause
- `paused` (boolean): Initial state (false = not paused, true = paused)

**Code ID:** `11`

---

#### 10. 💰 HOOK FEE - Fixed Fee Hook

**Function:** Charges a fixed fee per message sent. Can be used for:
- Protocol monetization
- Spam prevention
- Operations funding

**Instantiation Parameters:**
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "fee": {
    "denom": "uluna",
    "amount": "283215"
  }
}
```

**Parameter Explanation:**
- `owner` (string): Contract admin
- `fee` (object): Fee configuration
  - `denom` (string): Token denomination (micro-luna = uluna)
  - `amount` (string): Fee amount (283215 uluna = 0.283215 LUNC)

**Note:** Fee of 0.283215 LUNC per message sent.

**Code ID:** `9`

---

#### 11. 🔗 HOOK AGGREGATE #2 - Aggregator (Pausable + Fee)

**Function:** Second aggregator that combines:
- **Hook Pausable**: allows pausing message sending
- **Hook Fee**: charges fee per message

**Instantiation Parameters:**
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "hooks": [
    "terra1g4xlpqy29m50j5y69reguae328tc9y83l4299pf2wmjn0xczq5jsnem6vt",
    "terra1g6kht9c5s4jwn4akfjt3zmsfh4nvguewaegjeavpz3f0q9uylrqsge6knl"
  ]
}
```

**Parameter Explanation:**
- `owner` (string): Contract admin
- `hooks` (array): List of hooks
  - Hook 1: Pausable
  - Hook 2: Fee

**Note:** This hook will be set as `required_hook` in the Mailbox.

**Code ID:** `8`

---

### 🔄 Architecture Summary

```
┌─────────────────────────────────────────────────────────────┐
│                         MAILBOX                              │
│  (Central Contract - Manages Send/Receive)                   │
└─────────────┬───────────────────────────────┬────────────────┘
              │                               │
    ┌─────────▼─────────┐         ┌──────────▼──────────┐
    │  Default ISM      │         │   Hooks             │
    │  (ISM Routing)    │         │                     │
    │                   │         │  Required Hook:     │
    │  Routes to:       │         │  - Pausable         │
    │  - ISM Multisig   │         │  - Fee              │
    │    (domain 56)    │         │                     │
    └───────────────────┘         │  Default Hook:      │
                                  │  - Merkle           │
                                  │  - IGP ──► Oracle   │
                                  └─────────────────────┘
```

**Send Flow:**
1. User calls `dispatch()` on Mailbox
2. **Required Hook** is executed (Pausable checks if not paused, Fee charges fee)
3. **Default Hook** is executed (Merkle registers, IGP processes payment via Oracle)
4. Message is emitted as event

**Receive Flow:**
1. Relayer submits message + metadata
2. Mailbox queries **Default ISM** (ISM Routing)
3. ISM Routing directs to **ISM Multisig** (if origin = BSC)
4. ISM Multisig validates signatures (2/6 threshold)
5. If valid, message is processed

> **🔒 IMPORTANT - Governance Module:**
> 
> The address `terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n` is the blockchain's **governance module**.
> 
> **Security Implications:**
> - ✅ **After instantiation**, only governance can alter configurations
> - ✅ **No individual person** has control over the contracts
> - ✅ **All changes** must pass through community voting
> - ✅ **Decentralization guaranteed** from the very first moment
> - 🔐 **Contracts are immutable** except for approved governance proposals
> 
> **How it works:**
> 1. Contracts are instantiated with `admin` = governance module
> 2. Any alteration requires a governance proposal
> 3. The community votes on the proposal (yes/no)
> 4. If approved, governance executes the changes automatically
> 
> This ensures the protocol is **truly decentralized** and **community-controlled**.

> **⚠️ Important Note about Code IDs:**
> 
> Code IDs vary depending on the environment:
> 
> - **LocalTerra (Development)**: 1-20 (sequential from chain start)
> - **Testnet Columbus**: Variable numbers (ex: 1000+)
> - **Mainnet Terra Classic**: High numbers (ex: 10588-10607) as many contracts already exist
> 
> **Always check** `context/terraclassic.json` after upload to confirm the correct code IDs for your environment before instantiating contracts!

#### Execution Output

```bash
Wallet loaded via private key: terra1lmwng9g3gws5c9v0awxdankjl6a2psfhm8pc8z
Connecting to RPC: http://localhost:26657
Gas rate configured: 28.5uluna

Instantiating hpl_mailbox (code_id 1)...
{
  type: 'hpl_mailbox',
  address: 'terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au',
  hexed: 'ade4a5f5803a439835c636395a8d648dee57b2fc90d98dc17fa887159b69638b'
}
-------------------------------------

Instantiating hpl_validator_announce (code_id 2)...
{
  type: 'hpl_validator_announce',
  address: 'terra1nc5tatafv6eyq7llkr2gv50ff9e22mnf70qgjlv737ktmt4eswrquka9l6',
  hexed: '9e28beafa966b2407bffb0d48651e94972a56e69f3c0897d9e8facbdaeb98386'
}
-------------------------------------

[... more contracts ...]

✓ All contracts instantiated successfully!
```

---

---

## 4️⃣ Configuration via Governance

### Script: `submit-proposal.ts`

After instantiation, contracts need to be configured. Since the **owner/admin is the governance module**, all configurations must be done through **governance proposals**.

> **🔐 Why Governance?**
> 
> Contracts were instantiated with the governance module as admin. This means:
> - ❌ **No one can** alter contracts directly
> - ✅ **Only approved proposals** by the community can make changes
> - 🗳️ **Transparent voting** on all changes
> - 🔒 **Maximum security** against malicious alterations

### 📝 Execution Messages - Detailed Explanation

The governance proposal executes **8 messages** to configure the Hyperlane system with support for **3 chains** (Ethereum, BSC, and Solana):

---

#### MESSAGE 1: Configure ISM Multisig Validators for Ethereum

**Objective:** Defines the set of validators that will sign messages from domain 1 (Ethereum). The threshold of 6 means at least 6 of 9 validators must sign for a message to be considered valid.

**Target Contract:** ISM Multisig (`terra1e7sgpxr50rlxarvjt07n0pxgxre5fcgannucx37309446x5pwacs8qhryp`)

**Executed Message:**
```json
{
  "set_validators": {
    "domain": 1,
    "threshold": 6,
    "validators": [
      "03c842db86a6a3e524d4a6615390c1ea8e2b9541",
      "94438a7de38d4548ae54df5c6010c4ebc5239eae",
      "5450447aee7b544c462c9352bef7cad049b0c2dc",
      "b3ac35d3988bca8c2ffd195b1c6bee18536b317b",
      "b683b742b378632a5f73a2a5a45801b3489bba44",
      "3786083ca59dc806d894104e65a13a70c2b39276",
      "4f977a59fdc2d9e39f6d780a84d5b4add1495a36",
      "29d783efb698f9a2d3045ef4314af1f5674f52c5",
      "36a669703ad0e11a0382b098574903d2084be22c"
    ]
  }
}
```

**Parameter Explanation:**
- `domain` (u32): Ethereum domain ID in Hyperlane protocol (1 = Ethereum)
- `threshold` (u8): Minimum number of signatures required (6 of 9 validators)
- `validators` (HexBinary array): Array of 9 hexadecimal addresses (20 bytes each) of validators

**Security:** With 6/9 threshold, the system tolerates up to 3 validators offline or malicious while still validating messages.

---

#### MESSAGE 2: Configure ISM Multisig Validators for BSC

**Objective:** Defines the set of validators that will sign messages from domain 56 (BSC). The threshold of 2 means at least 2 of 6 validators must sign for a message to be considered valid.

**Target Contract:** ISM Multisig (`terra1m9wuxnx2vkv9duapcu9xfdnm9v5cv6eg35yzxmhgeuvch4y24aws8r49c9`)

**Executed Message:**
```json
{
  "set_validators": {
    "domain": 56,
    "threshold": 2,
    "validators": [
      "570af9b7b36568c8877eebba6c6727aa9dab7268",
      "5450447aee7b544c462c9352bef7cad049b0c2dc",
      "0d4c1394a255568ec0ecd11795b28d1bda183ca4",
      "24c1506142b2c859aee36474e59ace09784f71e8",
      "c67789546a7a983bf06453425231ab71c119153f",
      "2d74f6edfd08261c927ddb6cb37af57ab89f0eff"
    ]
  }
}
```

**Parameter Explanation:**
- `domain` (u32): BSC domain ID in Hyperlane protocol (56 = BSC/Binance Smart Chain)
- `threshold` (u8): Minimum number of signatures required (2 of 6 validators)
- `validators` (HexBinary array): Array of 6 hexadecimal addresses (20 bytes each) of validators

**Security:** With 2/6 threshold, the system tolerates up to 4 validators offline while still validating messages.

---

#### MESSAGE 3: Configure ISM Multisig Validators for Solana

**Objective:** Defines the set of validators that will sign messages from domain 1399811149 (Solana). The threshold of 3 means at least 3 of 5 validators must sign for a message to be considered valid.

**Target Contract:** ISM Multisig (`terra13l8gwanf37938wgfv5yktmfzxjwaj4ysn4gl96vj78xcqqxlcrgsll77zu`)

**Executed Message:**
```json
{
  "set_validators": {
    "domain": 1399811149,
    "threshold": 3,
    "validators": [
      "28464752829b3ea59a497fca0bdff575c534c3ff",
      "2b7514a2f77bd86bbf093fe6bb67d8611f51c659",
      "cb6bcbd0de155072a7ff486d9d7286b0f71dcc2d",
      "4f977a59fdc2d9e39f6d780a84d5b4add1495a36",
      "5450447aee7b544c462c9352bef7cad049b0c2dc"
    ]
  }
}
```

**Parameter Explanation:**
- `domain` (u32): Solana domain ID in Hyperlane protocol (1399811149 = Solana)
- `threshold` (u8): Minimum number of signatures required (3 of 5 validators)
- `validators` (HexBinary array): Array of 5 hexadecimal addresses (20 bytes each) of validators

**Security:** With 3/5 threshold, the system tolerates up to 2 validators offline or malicious while still validating messages.

---

#### MESSAGE 4: Configure Remote Gas Data in IGP Oracle (All Chains)

**Objective:** Defines token exchange rates and gas prices for domains 1 (Ethereum), 56 (BSC), and 1399811149 (Solana). This allows IGP to calculate how much gas to charge on the source chain (Terra) to cover execution costs on the destination chains.

**Target Contract:** IGP Oracle (`terra1jx8m47zzxnfnkc79hs60m269n3wtg8z2c7f3vj4m4xf0zkq060nsxqkswz`)

**Executed Message:**
```json
{
  "set_remote_gas_data_configs": {
    "configs": [
      {
        "remote_domain": 1,
        "token_exchange_rate": "1",
        "gas_price": "50000000"
      },
      {
        "remote_domain": 56,
        "token_exchange_rate": "1",
        "gas_price": "50000000"
      },
      {
        "remote_domain": 1399811149,
        "token_exchange_rate": "1",
        "gas_price": "50000000"
      }
    ]
  }
}
```

**Parameter Explanation:**
- `remote_domain` (u32): Remote chain domain ID
  - Domain 1 = Ethereum
  - Domain 56 = BSC
  - Domain 1399811149 = Solana
- `token_exchange_rate` (Uint128): Exchange rate between LUNC and destination chain token (1:1 in this case, adjustable)
- `gas_price` (Uint128): Gas price on destination chain (50 Gwei simplified)

**Cost Calculation:**
```
Cost = (gas_used_on_destination × gas_price × token_exchange_rate)
```

**Example:** If a transaction uses 200k gas:
```
Cost = 200000 × 50000000 × 1 = 10000000000000 units
```

**Note:** These values should be updated periodically to reflect actual market prices for each chain.

---

#### MESSAGE 5: Set IGP Routes to Oracle (All Chains)

**Objective:** Configures IGP to use IGP Oracle when calculating gas costs for domains 1 (Ethereum), 56 (BSC), and 1399811149 (Solana). These routes connect IGP to the Oracle that provides updated price and exchange rate data.

**Target Contract:** IGP (`terra1av3qg7rrtwu2anudw8u7d2ncv4f0826yxrndw9esvrp4jdnsmyjqqs62u0`)

**Executed Message:**
```json
{
  "router": {
    "set_routes": {
      "set": [
        {
          "domain": 1,
          "route": "terra1jx8m47zzxnfnkc79hs60m269n3wtg8z2c7f3vj4m4xf0zkq060nsxqkswz"
        },
        {
          "domain": 56,
          "route": "terra1jx8m47zzxnfnkc79hs60m269n3wtg8z2c7f3vj4m4xf0zkq060nsxqkswz"
        },
        {
          "domain": 1399811149,
          "route": "terra1jx8m47zzxnfnkc79hs60m269n3wtg8z2c7f3vj4m4xf0zkq060nsxqkswz"
        }
      ]
    }
  }
}
```

**Parameter Explanation:**
- `domain` (u32): Remote chain domain ID
  - Domain 1 = Ethereum
  - Domain 56 = BSC
  - Domain 1399811149 = Solana
- `route` (string): IGP Oracle address that provides gas data (same Oracle for all chains)

**Operation Flow:**
1. IGP receives gas payment from user
2. IGP queries Oracle via configured route for the destination chain
3. Oracle returns gas price and chain-specific exchange rate
4. IGP calculates total cost
5. IGP validates if payment is sufficient

---

#### MESSAGE 6: Set Default ISM in Mailbox

**Objective:** Configures the default ISM (Interchain Security Module) that will be used by the Mailbox to validate received messages. ISM Routing allows using different validation strategies per source domain.

**Target Contract:** Mailbox (`terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au`)

**Executed Message:**
```json
{
  "set_default_ism": {
    "ism": "terra1466nf3zuxpya8q9emxukd7vftaf6h4psr0a07srl5zw74zh84yjqxl5qul"
  }
}
```

**Parameter Explanation:**
- `ism` (string): ISM Routing address (which internally routes to appropriate ISM Multisig based on source chain)

**Validation Flow:**
```
Message received
    ↓
Mailbox queries default ISM (ISM Routing)
    ↓
ISM Routing checks origin and directs to appropriate ISM Multisig:
    ├─► Origin = Ethereum (domain 1) → ISM Multisig ETH (6/9 threshold)
    ├─► Origin = BSC (domain 56) → ISM Multisig BSC (2/6 threshold)
    └─► Origin = Solana (domain 1399811149) → ISM Multisig SOL (3/5 threshold)
    ↓
ISM Multisig validates signatures according to threshold
    ↓
If valid: message is processed
If invalid: message is rejected
```

**Security:** ISM Routing allows different security policies for each chain, increasing flexibility without compromising security.

---

#### MESSAGE 7: Set Default Hook in Mailbox

**Objective:** Configures the default Hook that will be executed when sending messages. Hook Aggregate #1 combines Merkle Tree Hook (for proofs) and IGP (for payment).

**Target Contract:** Mailbox (`terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au`)

**Executed Message:**
```json
{
  "set_default_hook": {
    "hook": "terra1vguuxez2h5ekltfj9gjd62fs5k4rl2zy5hfrncasykzw08rezpfsf33f8z"
  }
}
```

**Parameter Explanation:**
- `hook` (string): Hook Aggregate #1 address (Merkle + IGP)

**Default Hook Components:**
1. **Hook Merkle**: Adds message to Merkle tree for inclusion proofs
2. **IGP Hook**: Processes gas payment for execution on destination chain

**Send Flow:**
```
dispatch() called
    ↓
Default hook executed
    ↓
Hook Merkle: registers message in tree
    ↓
IGP: validates and processes gas payment
    ↓
Message emitted as event
```

**Benefits:**
- **Merkle**: Allows cryptographic proofs that message was sent
- **IGP**: Ensures relayers will be paid to execute the message

---

#### MESSAGE 8: Set Required Hook in Mailbox

**Objective:** Configures the mandatory Hook that will ALWAYS be executed when sending messages, regardless of custom hooks specified by the sender. Hook Aggregate #2 combines Hook Pausable (emergency) and Hook Fee (monetization).

**Target Contract:** Mailbox (`terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au`)

**Executed Message:**
```json
{
  "set_required_hook": {
    "hook": "terra1qmk0v725sdg5ecu6xfh5pt0fv0nfzrstarue2maum3snzk2zrt5qtm9ukq"
  }
}
```

**Parameter Explanation:**
- `hook` (string): Hook Aggregate #2 address (Pausable + Fee)

**Required Hook Components:**
1. **Hook Pausable**: Allows pausing message sending in case of emergency/maintenance
2. **Hook Fee**: Charges fixed fee of 0.283215 LUNC per message (anti-spam/monetization)

**Send Flow (complete order):**
```
dispatch() called
    ↓
Required hook executed (CANNOT be bypassed)
    ├─► Pausable: checks if system is not paused
    └─► Fee: charges 0.283215 LUNC
    ↓
Default hook executed
    ├─► Merkle: registers in tree
    └─► IGP: processes gas payment
    ↓
Message sent
```

**IMPORTANT:** 
- Required hook is executed **BEFORE** default hook
- Required hook **CANNOT be bypassed** by sender
- If system is paused, ALL messages are blocked
- Fee is charged for ALL messages without exception

---

### 📊 Configuration Summary

After execution of this proposal, the Hyperlane system will be configured to:

| Component | Configuration | Benefit |
|-----------|---------------|---------|
| **🔐 Security** | Validate messages using multisig:<br>- Ethereum: 6/9 validators<br>- BSC: 2/6 validators<br>- Solana: 3/5 validators | Multi-chain fault and attack resistance |
| **⛽ Payment** | Calculate costs via IGP + Oracle (3 chains) | Relayers properly compensated |
| **🌳 Proofs** | Maintain Merkle tree | Cryptographic proofs of sending |
| **⏸️ Control** | Emergency pause via Hook Pausable | Quick incident response |
| **💰 Monetization** | Fee of 0.283215 LUNC via Hook Fee | Spam prevention + funding |

**Final Status:**
- ✅ System ready to send/receive messages Terra ↔ Ethereum
- ✅ System ready to send/receive messages Terra ↔ BSC
- ✅ System ready to send/receive messages Terra ↔ Solana
- ✅ Security validation configured (multisig per chain)
- ✅ Gas payment configured for all chains (Oracle + IGP)
- ✅ Protections activated (Pausable + Fee)

---

### 🏗️ Final System Architecture

After complete configuration, the Hyperlane system will have the following architecture:

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           MAILBOX (Core)                                  │
│          terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au│
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  Default ISM: ISM Routing                                                │
│    ├─► Domain 1 (Ethereum) → ISM Multisig (6/9 validators)              │
│    ├─► Domain 56 (BSC) → ISM Multisig (2/6 validators)                  │
│    └─► Domain 1399811149 (Solana) → ISM Multisig (3/5 validators)       │
│                                                                           │
│  Default Hook: Hook Aggregate #1                                         │
│    ├─► Hook Merkle (inclusion proofs)                                   │
│    └─► IGP (payment) → Oracle (Ethereum/BSC/Solana prices)              │
│                                                                           │
│  Required Hook: Hook Aggregate #2                                        │
│    ├─► Hook Pausable (emergency control)                                │
│    └─► Hook Fee (0.283215 LUNC per message)                             │
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

**Complete Message Send Flow (Terra → BSC):**

```
1. User calls dispatch(dest=56, recipient, body)
         ↓
2. Required Hook (MANDATORY)
   ├─► Pausable: checks if not paused ✓
   └─► Fee: charges 0.283215 LUNC ✓
         ↓
3. Default Hook (DEFAULT)
   ├─► Merkle: adds msg to tree ✓
   └─► IGP: validates gas payment ✓
       └─► Oracle: queries BSC price ✓
         ↓
4. Mailbox emits MessageDispatched event
         ↓
5. Relayer detects event
         ↓
6. Relayer submits message on BSC
```

**Complete Message Receive Flow (BSC → Terra):**

```
1. Relayer submits process(message, metadata)
         ↓
2. Mailbox extracts origin_domain = 56
         ↓
3. Mailbox queries Default ISM (ISM Routing)
         ↓
4. ISM Routing directs to ISM Multisig
         ↓
5. ISM Multisig validates metadata (signatures)
   ├─► Verifies there are 2+ valid signatures
   ├─► Verifies signatures are from enrolled validators
   └─► Returns valid=true or valid=false
         ↓
6. If valid=true:
   └─► Mailbox calls handle() on recipient contract
         ↓
7. Message processed ✓
```

**Critical Security Points:**

| Layer | Protection | How It Works |
|-------|------------|--------------|
| **Hook Pausable** | Emergency pause | Governance can pause sends instantly |
| **Hook Fee** | Anti-spam | Fee of 0.283215 LUNC makes attacks expensive |
| **ISM Multisig** | Distributed validation | 2/6 validators = no single point of failure |
| **IGP Oracle** | Updated prices | Prevents involuntary gas subsidy |
| **Merkle Tree** | Verifiable proofs | Impossible to falsify send history |
| **Governance** | Decentralized control | No entity can alter alone |

---

### Mode 1: Create Governance Proposal

```bash
cd /home/lunc/cw-hyperlane
PRIVATE_KEY="your_hex_key" ts-node script/submit-proposal.ts
```

**Output:**
- Generates `proposal.json` and `exec_msgs.json`
- Shows CLI command to submit
- Displays all 6 messages with complete JSON details

### Mode 2: Direct Execution (without governance)

```bash
cd /home/lunc/cw-hyperlane
PRIVATE_KEY="your_hex_key" MODE=direct ts-node script/submit-proposal.ts
```

Executes configurations directly from your wallet.

> **⚠️ WARNING:**
> 
> **Direct Mode** only works if you are the owner of the contracts. Since contracts were instantiated with the **governance module** as owner, this mode will **NOT work** in production.
> 
> **Use Direct Mode only for:**
> - 🧪 Testing in development environment
> - 🔧 Contracts instantiated with your wallet as owner
> - 📝 Configuration validation before creating proposal
> 
> **In production, ALWAYS use Governance Mode** (Mode 1).

---

### Submit Proposal via CLI

After generating `proposal.json`, submit the proposal:

```bash
terrad tx gov submit-proposal proposal.json \
  --from teste01 \
  --chain-id localterra \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 28.5uluna \
  --node http://localhost:26657 \
  -y
```

### Vote on Proposal

```bash
terrad tx gov vote 1 yes \
  --from teste01 \
  --chain-id localterra \
  --gas-prices 28.5uluna \
  --gas auto \
  --gas-adjustment 2.0 \
  --node http://localhost:26657 \
  -y
```

### Check Proposal Status

```bash
# View status
terrad query gov proposal 1 --node http://localhost:26657 | grep "status"

# View votes
terrad query gov tally 1 --node http://localhost:26657

# View complete details
terrad query gov proposal 1 --node http://localhost:26657
```

**Possible statuses:**
- `PROPOSAL_STATUS_VOTING_PERIOD` - In voting ⏳
- `PROPOSAL_STATUS_PASSED` - Approved ✅
- `PROPOSAL_STATUS_REJECTED` - Rejected ❌
- `PROPOSAL_STATUS_FAILED` - Failed execution ⚠️

---

## 5️⃣ Execution Verification

### Queries to Verify Configurations

After the proposal is approved (`PROPOSAL_STATUS_PASSED`), verify if configurations were applied.

> **📋 About the Queries**
> 
> Each query below verifies a specific configuration applied by the governance proposal. It's **essential** to run all 6 queries to confirm the system is correctly configured before using in production.

---

#### 1. ✅ ISM Multisig - Configured Validators

**What it verifies:** Confirms that 6 validators were registered in ISM Multisig for domain 56 (BSC) with threshold of 2 signatures.

**Query:**
```bash
terrad query wasm contract-state smart terra1zwv6feuzhy6a9wekh96cd57lsarmqlwxdypdsplw6zhfncqw6ftqynf7kp \
  '{"multisig_ism":{"enrolled_validators":{"domain":56}}}' \
  --node http://localhost:26657
```

**Expected:**
```yaml
data:
  threshold: 2                              # Minimum of 2 signatures required
  validators:                               # List of 6 validators (20-byte hex addresses)
  - 570af9b7b36568c8877eebba6c6727aa9dab7268  # Validator 1
  - 5450447aee7b544c462c9352bef7cad049b0c2dc  # Validator 2
  - 0d4c1394a255568ec0ecd11795b28d1bda183ca4  # Validator 3
  - 24c1506142b2c859aee36474e59ace09784f71e8  # Validator 4
  - c67789546a7a983bf06453425231ab71c119153f  # Validator 5
  - 2d74f6edfd08261c927ddb6cb37af57ab89f0eff  # Validator 6
```

**Field Explanation:**
- `threshold`: Minimum number of validators that must sign to validate a message (2 of 6)
- `validators`: Array of hexadecimal addresses of authorized validators (each 20 bytes)

**Security:** System tolerates up to 4 validators offline/malicious. Requires compromising 5+ validators to attack.

---

#### 2. ✅ IGP Oracle - Configured Gas Price

**What it verifies:** Confirms Oracle has gas price and exchange rate data configured for BSC (domain 56).

**Query:**
```bash
terrad query wasm contract-state smart terra1lnyecncq9akyk8nk0qlppgrq6yxktr68483ahryn457x9ap4ty2shupdsz \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":56}}}' \
  --node http://localhost:26657
```

**Expected:**
```yaml
data:
  gas_price: "50000000"       # Gas price on BSC (50 Gwei simplified)
  exchange_rate: "1"          # LUNC:BNB exchange rate (1:1)
```

**Field Explanation:**
- `gas_price` (Uint128): Gas price on destination chain (BSC) in native units
  - Value `50000000` represents approximately 50 Gwei on BSC
  - This value should be periodically updated to reflect actual prices
- `exchange_rate` (Uint128): Conversion rate between local token (LUNC) and remote token (BNB)
  - Value `1` means 1:1 parity (1 LUNC = 1 BNB in value)
  - In practice, should reflect actual market rates

**Cost Calculation:**
```
Cost in LUNC = (gas_units × gas_price × exchange_rate)

Example: Transaction using 200k gas on BSC
Cost = 200000 × 50000000 × 1 = 10,000,000,000,000 units
```

**Important:** These values should be updated via governance as market prices change.

---

#### 3. ✅ IGP - Configured Route

**What it verifies:** Confirms IGP knows which Oracle to query for gas data from domain 56 (BSC).

**Query:**
```bash
terrad query wasm contract-state smart terra1wn625s4jcmvk0szpl85rj5azkfc6suyvf75q6vrddscjdphtve8stalnth \
  '{"router":{"get_route":{"domain":56}}}' \
  --node http://localhost:26657
```

**Expected:**
```yaml
data:
  route: terra1lnyecncq9akyk8nk0qlppgrq6yxktr68483ahryn457x9ap4ty2shupdsz  # IGP Oracle address
```

**Field Explanation:**
- `route` (string): Oracle contract address that provides gas data for the specified domain
  - This address should match the instantiated IGP Oracle
  - IGP will query this contract when processing payments for BSC-bound messages

**Operation Flow:**
```
1. User sends message to BSC with payment
2. IGP receives payment
3. IGP queries route (Oracle) for domain 56
4. Oracle returns: gas_price + exchange_rate
5. IGP calculates: required_cost = gas × gas_price × exchange_rate
6. IGP validates: payment_received >= required_cost
7. If valid: approves message send
```

**Important:** If route not configured, IGP cannot calculate costs for BSC.

---

#### 4. ✅ Mailbox - Default ISM

**What it verifies:** Confirms Mailbox has an ISM configured to validate received messages.

**Query:**
```bash
terrad query wasm contract-state smart terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au \
  '{"mailbox":{"default_ism":{}}}' \
  --node http://localhost:26657
```

**Expected:**
```yaml
data:
  default_ism: terra1466nf3zuxpya8q9emxukd7vftaf6h4psr0a07srl5zw74zh84yjqxl5qul  # ISM Routing address
```

**Field Explanation:**
- `default_ism` (string): ISM contract address that will be used to validate received messages
  - This address should match the instantiated ISM Routing
  - ISM Routing internally routes to ISM Multisig when origin is BSC (domain 56)

**Validation Flow:**
```
1. Relayer submits received message from BSC
2. Mailbox extracts origin_domain = 56
3. Mailbox calls default_ism.verify(message, metadata)
4. ISM Routing verifies origin = 56
5. ISM Routing delegates to ISM Multisig
6. ISM Multisig validates 2+ signatures from 6 validators
7. Returns valid=true or valid=false
8. If valid=true: Mailbox processes message
   If valid=false: Mailbox rejects message
```

**Security:** ISM is the critical security layer. Without it, any message would be accepted without validation.

---

#### 5. ✅ Mailbox - Default Hook

**What it verifies:** Confirms Mailbox has a Hook configured to process message sends.

**Query:**
```bash
terrad query wasm contract-state smart terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au \
  '{"mailbox":{"default_hook":{}}}' \
  --node http://localhost:26657
```

**Expected:**
```yaml
data:
  default_hook: terra1vguuxez2h5ekltfj9gjd62fs5k4rl2zy5hfrncasykzw08rezpfsf33f8z  # Hook Aggregate #1 address
```

**Field Explanation:**
- `default_hook` (string): Hook Aggregate #1 address (Merkle + IGP)
  - This hook is automatically executed when sending messages (if user doesn't specify another)
  - Combines two hooks: Merkle Tree (for proofs) and IGP (for payment)

**Hook Components:**
1. **Merkle Hook** (`terra1zlwdkv49rmsug0pnwu6fmwnl267lfr34smmfyer9dvakpnk29whqfs47n2`):
   - Adds message hash to Merkle tree
   - Allows creating cryptographic proofs that message was sent
   - Essential for validation on destination chain

2. **IGP Hook** (`terra1wn625s4jcmvk0szpl85rj5azkfc6suyvf75q6vrddscjdphtve8stalnth`):
   - Validates user paid sufficient gas
   - Queries Oracle to calculate cost
   - Records payment for relayer reimbursement

**Execution Flow:**
```
dispatch() called
    ↓
default_hook.post_dispatch() executed
    ├─► Merkle: add_to_tree(message_id)
    └─► IGP: validate_payment(dest_domain, gas_amount)
        └─► Oracle: get_gas_price(domain=56)
    ↓
If all valid: message emitted as event
```

**Important:** Without default_hook, messages wouldn't have verifiable proofs or gas payment.

---

#### 6. ✅ Mailbox - Required Hook

**What it verifies:** Confirms Mailbox has a mandatory Hook that will ALWAYS be executed when sending messages.

**Query:**
```bash
terrad query wasm contract-state smart terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au \
  '{"mailbox":{"required_hook":{}}}' \
  --node http://localhost:26657
```

**Expected:**
```yaml
data:
  required_hook: terra1qmk0v725sdg5ecu6xfh5pt0fv0nfzrstarue2maum3snzk2zrt5qtm9ukq  # Hook Aggregate #2 address
```

**Field Explanation:**
- `required_hook` (string): Hook Aggregate #2 address (Pausable + Fee)
  - This hook is **ALWAYS** executed, regardless of user preferences
  - Combines two critical hooks: Pausable (emergency) and Fee (anti-spam)
  - Executed **BEFORE** default_hook

**Hook Components:**
1. **Pausable Hook** (`terra1g4xlpqy29m50j5y69reguae328tc9y83l4299pf2wmjn0xczq5jsnem6vt`):
   - Allows pausing entire system in case of emergency
   - Controlled by governance
   - If paused, ALL messages are instantly blocked

2. **Fee Hook** (`terra1g6kht9c5s4jwn4akfjt3zmsfh4nvguewaegjeavpz3f0q9uylrqsge6knl`):
   - Charges fixed fee of **0.283215 LUNC** per message
   - Prevents spam (makes attacks expensive)
   - Generates revenue for protocol maintenance

**Complete Execution Order:**
```
dispatch() called by user
    ↓
1️⃣ REQUIRED HOOK (CANNOT be bypassed)
   ├─► Pausable: is_paused()? If yes, REVERT
   └─► Fee: transfer(0.283215 LUNC) from sender to beneficiary
    ↓
2️⃣ DEFAULT HOOK (or user's custom hook)
   ├─► Merkle: add_to_tree()
   └─► IGP: validate_payment()
    ↓
3️⃣ Mailbox emits MessageDispatched event
```

**Critical Difference:**
- **Required Hook**: ALWAYS executed, CANNOT be replaced
- **Default Hook**: Executed by default, BUT can be replaced by user

**Security:**
- **Pausable**: Allows immediate response to detected vulnerabilities
- **Fee**: Makes spam attacks economically unfeasible (each msg = 0.283215 LUNC)

**Important:** The required_hook is the protocol's last line of defense. Even if other hooks fail, this one always executes.

---

### 📊 Verification Summary Table

| # | Component | Address | What It Verifies | Expected Status |
|---|-----------|---------|------------------|-----------------|
| 1 | **ISM Multisig** | `terra1zwv6...` | 6 validators + threshold 2 | ✅ 2/6 configured |
| 2 | **IGP Oracle** | `terra1lnye...` | BSC gas price + exchange rate | ✅ 50M + rate 1 |
| 3 | **IGP** | `terra1wn62...` | Route to Oracle (domain 56) | ✅ Route configured |
| 4 | **Mailbox ISM** | `terra14hj...` | ISM Routing as default | ✅ ISM Routing set |
| 5 | **Mailbox Hook Default** | `terra14hj...` | Hook Agg #1 (Merkle+IGP) | ✅ Hooks configured |
| 6 | **Mailbox Hook Required** | `terra14hj...` | Hook Agg #2 (Pause+Fee) | ✅ 0.283215 LUNC |

**Result Interpretation:**

| If Query Returns... | Means... | Action Needed |
|---------------------|----------|---------------|
| ✅ **Expected values** | Configuration applied correctly | None - system ready |
| ❌ **Different values** | Proposal didn't execute correctly | Investigate proposal logs |
| ⚠️ **"not found" error** | Configuration not applied | Check proposal status |
| 🔄 **"null" or empty** | Field not initialized | Re-execute proposal |

---

### Complete Verification Script

Save this script as `verify-deployment.sh`:

```bash
#!/bin/bash

echo "=========================================="
echo "  HYPERLANE DEPLOYMENT VERIFICATION"
echo "=========================================="
echo ""

echo "✅ 1. ISM Multisig - Validators (domain 56):"
terrad query wasm contract-state smart terra1zwv6feuzhy6a9wekh96cd57lsarmqlwxdypdsplw6zhfncqw6ftqynf7kp \
  '{"multisig_ism":{"enrolled_validators":{"domain":56}}}' \
  --node http://localhost:26657
echo ""

echo "✅ 2. IGP Oracle - Gas Price (domain 56):"
terrad query wasm contract-state smart terra1lnyecncq9akyk8nk0qlppgrq6yxktr68483ahryn457x9ap4ty2shupdsz \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":56}}}' \
  --node http://localhost:26657
echo ""

echo "✅ 3. IGP - Route (domain 56):"
terrad query wasm contract-state smart terra1wn625s4jcmvk0szpl85rj5azkfc6suyvf75q6vrddscjdphtve8stalnth \
  '{"router":{"get_route":{"domain":56}}}' \
  --node http://localhost:26657
echo ""

echo "✅ 4. Mailbox - Default ISM:"
terrad query wasm contract-state smart terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au \
  '{"mailbox":{"default_ism":{}}}' \
  --node http://localhost:26657
echo ""

echo "✅ 5. Mailbox - Default Hook:"
terrad query wasm contract-state smart terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au \
  '{"mailbox":{"default_hook":{}}}' \
  --node http://localhost:26657
echo ""

echo "✅ 6. Mailbox - Required Hook:"
terrad query wasm contract-state smart terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au \
  '{"mailbox":{"required_hook":{}}}' \
  --node http://localhost:26657
echo ""

echo "=========================================="
echo "  ✅ Verification Complete!"
echo "=========================================="
```

Execute:
```bash
chmod +x verify-deployment.sh
./verify-deployment.sh
```

---

## 6️⃣ Contract Addresses and Hexed

### Address Table

| Contract | Address (Bech32) | Hexed (32 bytes) |
|----------|------------------|------------------|
| **Mailbox** | `terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au` | `ade4a5f5803a439835c636395a8d648dee57b2fc90d98dc17fa887159b69638b` |
| **Validator Announce** | `terra1nc5tatafv6eyq7llkr2gv50ff9e22mnf70qgjlv737ktmt4eswrquka9l6` | `9e28beafa966b2407bffb0d48651e94972a56e69f3c0897d9e8facbdaeb98386` |
| **ISM Multisig** | `terra1zwv6feuzhy6a9wekh96cd57lsarmqlwxdypdsplw6zhfncqw6ftqynf7kp` | `1399a4e782b935d2bb36b97586d3df8747b07dc66902d807eed0ae99e00ed256` |
| **ISM Routing** | `terra1466nf3zuxpya8q9emxukd7vftaf6h4psr0a07srl5zw74zh84yjqxl5qul` | `aeb534c45c3049d380b9d9b966f9895f53abd4301bfaff407fa09dea8ae7a924` |
| **Hook Merkle** | `terra1zlwdkv49rmsug0pnwu6fmwnl267lfr34smmfyer9dvakpnk29whqfs47n2` | `17dcdb32a51ee1c43c3377349dba7f56bdf48e3586f69264656b3b60ceca2bae` |
| **IGP** | `terra1wn625s4jcmvk0szpl85rj5azkfc6suyvf75q6vrddscjdphtve8stalnth` | `74f4aa42b2c6d967c041f9e83953a2b271a8708c4fa80d306d6c312686eb664f` |
| **IGP Oracle** | `terra1lnyecncq9akyk8nk0qlppgrq6yxktr68483ahryn457x9ap4ty2shupdsz` | `fcc99c4f002f6c4b1e76783e10a060d10d658f47a9e3db8c93ad3c62f4355915` |
| **Hook Aggregate 1** | `terra1vguuxez2h5ekltfj9gjd62fs5k4rl2zy5hfrncasykzw08rezpfsf33f8z` | `6239c3644abd336fad322a24dd2930a5aa3fa844a5d239e3b02584e79c791053` |
| **Hook Pausable** | `terra1g4xlpqy29m50j5y69reguae328tc9y83l4299pf2wmjn0xczq5jsnem6vt` | `454df0808a2ee8f9509a28f28e773151d78290f1fd5452852a76e5379b020525` |
| **Hook Fee** | `terra1g6kht9c5s4jwn4akfjt3zmsfh4nvguewaegjeavpz3f0q9uylrqsge6knl` | `46ad7597148564e9d7b64c97116e09bd66c4732eee512cf5811452f01784f8c1` |
| **Hook Aggregate 2** | `terra1qmk0v725sdg5ecu6xfh5pt0fv0nfzrstarue2maum3snzk2zrt5qtm9ukq` | `06ecf6795483514ce39a326f40ade963e6910e0be8f9956fbcdc613159421ae8` |

### Complete JSON

```json
{
  "hpl_mailbox": "terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au",
  "hpl_validator_announce": "terra1nc5tatafv6eyq7llkr2gv50ff9e22mnf70qgjlv737ktmt4eswrquka9l6",
  "hpl_ism_multisig": "terra1zwv6feuzhy6a9wekh96cd57lsarmqlwxdypdsplw6zhfncqw6ftqynf7kp",
  "hpl_ism_routing": "terra1466nf3zuxpya8q9emxukd7vftaf6h4psr0a07srl5zw74zh84yjqxl5qul",
  "hpl_hook_merkle": "terra1zlwdkv49rmsug0pnwu6fmwnl267lfr34smmfyer9dvakpnk29whqfs47n2",
  "hpl_igp": "terra1wn625s4jcmvk0szpl85rj5azkfc6suyvf75q6vrddscjdphtve8stalnth",
  "hpl_igp_oracle": "terra1lnyecncq9akyk8nk0qlppgrq6yxktr68483ahryn457x9ap4ty2shupdsz",
  "hpl_hook_aggregate": "terra1qmk0v725sdg5ecu6xfh5pt0fv0nfzrstarue2maum3snzk2zrt5qtm9ukq",
  "hpl_hook_pausable": "terra1g4xlpqy29m50j5y69reguae328tc9y83l4299pf2wmjn0xczq5jsnem6vt",
  "hpl_hook_fee": "terra1g6kht9c5s4jwn4akfjt3zmsfh4nvguewaegjeavpz3f0q9uylrqsge6knl"
}
```

### Using the Addresses

**For Relayer:**
```yaml
mailbox: "0xade4a5f5803a439835c636395a8d648dee57b2fc90d98dc17fa887159b69638b"
validatorAnnounce: "0x9e28beafa966b2407bffb0d48651e94972a56e69f3c0897d9e8facbdaeb98386"
```

**For Validators:**
```yaml
mailbox: "0xade4a5f5803a439835c636395a8d648dee57b2fc90d98dc17fa887159b69638b"
merkleTreeHook: "0x17dcdb32a51ee1c43c3377349dba7f56bdf48e3586f69264656b3b60ceca2bae"
```

---

## 7️⃣ Troubleshooting

### Error: "insufficient fees"

**Problem:** Gas fee too low.

**Solution:** Increase gas price:
```bash
--gas-prices 28.5uluna
--gas-adjustment 2.0
```

### Error: "out of gas"

**Problem:** Estimated gas limit too low.

**Solution:** Use fixed gas or increase adjustment:
```bash
--gas 1000000
# or
--gas-adjustment 2.5
```

### Error: "contract not found"

**Problem:** Contract was not instantiated or incorrect address.

**Solution:** Verify the address:
```bash
terrad query wasm contract <ADDRESS> --node http://localhost:26657
```

### Proposal doesn't execute automatically

**Problem:** Voting period hasn't ended yet.

**Solution:** Wait for `voting_end_time`:
```bash
terrad query gov proposal 1 --node http://localhost:26657 | grep voting_end_time
```

### Query returns schema error

**Problem:** Incorrect query for the contract.

**Solution:** Use the queries documented in [Execution Verification](#5️⃣-execution-verification) section.

---

## 📚 Additional Resources

### Official Documentation

- [Hyperlane Docs](https://docs.hyperlane.xyz/)
- [Terra Classic Docs](https://docs.terra.money/)
- [CosmWasm Docs](https://docs.cosmwasm.com/)

### Repository and Releases

- **GitHub Repository**: https://github.com/many-things/cw-hyperlane
- **Releases**: https://github.com/many-things/cw-hyperlane/releases
- **Latest Release (v0.0.6-rc8)**:
  - Tag: https://github.com/many-things/cw-hyperlane/releases/tag/v0.0.6-rc8
  - Download: https://github.com/many-things/cw-hyperlane/releases/download/v0.0.6-rc8/cw-hyperlane-v0.0.6-rc8.zip
  - Checksums: Included in ZIP file

### Configuration Files

- `script/CustomInstantiateWasm.ts` - Instantiation script
- `script/submit-proposal.ts` - Governance configuration script
- `config.yaml` - Network configuration
- `context/terraclassic.json` - Deployment context

### Useful Scripts

```bash
# List available contracts
yarn cw-hpl upload remote-list -n terraclassic

# Upload contracts
yarn cw-hpl upload remote v0.0.6-rc8 -n terraclassic

# Instantiate contracts
ts-node script/CustomInstantiateWasm.ts

# Create governance proposal
ts-node script/submit-proposal.ts

# Execute configurations directly
MODE=direct ts-node script/submit-proposal.ts
```

---

## ✅ Deployment Checklist

### Pre-Deploy
- [ ] Verify available contracts (`yarn cw-hpl upload remote-list`)
- [ ] Download and verify WASM checksums
- [ ] Confirm admin/owner will be governance module

### Deploy
- [ ] Upload contracts (`yarn cw-hpl upload remote`)
- [ ] Verify code IDs in `context/terraclassic.json`
- [ ] Instantiate contracts (`CustomInstantiateWasm.ts`)
- [ ] **CRITICAL**: Verify owner is governance module
- [ ] Save contract addresses

### Configuration
- [ ] Create configuration proposal (`submit-proposal.ts`)
- [ ] Vote on proposal (obtain quorum)
- [ ] Wait for proposal approval
- [ ] Verify status = `PROPOSAL_STATUS_PASSED`
- [ ] Verify applied configurations (all 6 queries)

### Security Verification
- [ ] ✅ Confirm all contracts have governance as owner
- [ ] ✅ Verify no one can alter contracts directly
- [ ] ✅ Validate contract hashes on blockchain
- [ ] ✅ Compare addresses with official documentation

### Post-Deploy
- [ ] Configure relayer with hexed addresses
- [ ] Configure validators
- [ ] Test message sending
- [ ] Document all addresses and code IDs
- [ ] Publish information for auditing

---

## 🔒 Security and Governance

### On-Chain Governance Model

Hyperlane contracts are **community-governed** through Terra Classic's governance module:

#### Security Features

1. **Decentralized Control**
   - ✅ No single entity controls the contracts
   - ✅ Admin/Owner = Governance Module
   - ✅ All changes require voting

2. **Change Process**
   ```
   Proposal → Voting Period → Approval → Automatic Execution
   ```

3. **Total Transparency**
   - 📊 All proposals are public
   - 🗳️ All votes are recorded on blockchain
   - 📝 Complete change history
   - 🔍 Auditable by anyone

4. **Attack Protection**
   - 🛡️ Impossible to alter contracts without community approval
   - 🛡️ Voting period allows analysis and discussion
   - 🛡️ Quorum and threshold prevent manipulation
   - 🛡️ Community veto for malicious proposals

### Ownership Verification

**Always verify** that contracts are under governance control:

```bash
# Verify owner of each contract
for contract in \
  terra14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9ssrc8au \
  terra1zwv6feuzhy6a9wekh96cd57lsarmqlwxdypdsplw6zhfncqw6ftqynf7kp \
  terra1466nf3zuxpya8q9emxukd7vftaf6h4psr0a07srl5zw74zh84yjqxl5qul
do
  echo "Verifying: $contract"
  terrad query wasm contract-state smart $contract \
    '{"ownable":{"owner":{}}}' \
    --node http://localhost:26657
done

# All should return:
# owner: terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n
```

### For Auditors

When auditing this deployment, verify:

1. ✅ **WASM Hashes** match official releases
2. ✅ **Owner/Admin** is the governance module
3. ✅ **Code IDs** are correctly documented
4. ✅ **Configurations** were applied via governance
5. ✅ **No backdoors** or privileged functions beyond governance

---

## 📞 Support

For issues or questions:
1. Check execution logs
2. Consult troubleshooting above
3. Review official Hyperlane documentation
4. Verify contracts on blockchain using queries
5. Confirm ownership is correct (governance module)

---

**Last update:** 2025-11-25  
**Contract Version:** v0.0.6-rc8  
**Chain:** Terra Classic (LocalTerra)  
**Governance:** Terra Classic On-Chain Governance  
**Admin/Owner:** `terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n` (Governance Module)


