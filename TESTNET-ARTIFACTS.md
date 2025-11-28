# Terra Classic Testnet - Hyperlane Contract Artifacts

This document contains all contract artifacts deployed on Terra Classic Testnet.

## Network Information

- **Network**: Terra Classic Testnet
- **Chain ID**: rebel-2
- **Domain**: 1325
- **Deployment Date**: November 28, 2025

## Governance Module Account

In Terra Classic, contract instantiation is performed through governance proposals. To submit a governance proposal, you need to know the governance module account address.

### How to Query the Governance Module Account

You can query the governance module account address using the Terra Classic CLI or REST API.

**Method 1: Using REST/LCD endpoint (Recommended - Simplest)**

```bash
# Query using REST API directly - This is the easiest and most reliable method
curl -s https://lcd.luncblaze.com/cosmos/auth/v1beta1/module_accounts/gov | jq -r '.account.base_account.address'
```

**Expected output:**
```
terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n
```

**Method 2: Using terrad CLI with RPC endpoint**

```bash
# Query all module accounts
terrad query auth module-accounts \
  --node https://rpc.luncblaze.com:443 \
  --chain-id rebel-2

# Query specific governance module account
terrad query auth module-account gov \
  --node https://rpc.luncblaze.com:443 \
  --chain-id rebel-2 \
  --output json | jq -r '.account.base_account.address'
```

**Method 3: Using gRPC endpoint**

```bash
# Using gRPC
terrad query auth module-account gov \
  --grpc-addr grpc.terra-classic.hexxagon.dev:443 \
  --chain-id rebel-2 \
  --output json | jq -r '.account.base_account.address'
```

### Governance Module Account Address

The governance module account address for Terra Classic Testnet is:

```
terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n
```

**Important Notes:**
- This address is controlled by the governance module and can only execute transactions approved through governance proposals.
- This is the address that should be set as `admin` when instantiating contracts via governance.
- This address is the same for both testnet and mainnet in Terra Classic.

### Using in Governance Proposals

When creating a governance proposal to instantiate a contract, use this module account as the contract admin:

```json
{
  "admin": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "code_id": 1981,
  "label": "Hyperlane Mailbox",
  "msg": {
    "hrp": "terra",
    "domain": 1325,
    "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n"
  }
}
```

## Uploaded Contracts

### Core Contracts

| Contract Name | Code ID | Checksum | Transaction Hash |
|--------------|---------|----------|------------------|
| hpl_mailbox | 1981 | `12e1eb4266faba3cc99ccf40dd5e65aed3e03a8f9133c4b28fb57b2195863525` | `E5D465100CDAE4A8E9CF91996D0F79CDB0818FE959A9DE26AB0731001A0FE74A` |
| hpl_validator_announce | 1982 | `87cf4cbe4f5b6b3c7a278b4ae0ae980d96c04192f07aa70cc80bd7996b31c6a8` | `781048E6DB6ADF70F132F7823F729BE185C994A4FF93051EB0CD8D5DEE44653A` |

### ISM (Interchain Security Module) Contracts

| Contract Name | Code ID | Checksum | Transaction Hash |
|--------------|---------|----------|------------------|
| hpl_ism_aggregate | 1983 | `fae4d22afede6578ce8b4dbfaa185d43a303b8707386a924232aa24632d00f7b` | `5C66E34A32812F4AB9EA4927FA775160FD3855D5396A931D05B53D90EBCCE34A` |
| hpl_ism_multisig | 1984 | `d1f4705e19414e724d3721edad347003934775313922b7ca183ca6fa64a9e076` | `CE0EF5E9C74B6AFD7A4DFFEA72F09CDC9641B7580EA66201EA4E3B59929771E8` |
| hpl_ism_pausable | 1985 | `a6e8cc30b5abf13a032c8cb70128fcd88305eea8133fd2163299cf60298e0e7f` | `3D188F0BFB7A96C37586A33EDB8B2FA1FBC6CC60CAEB444BA27BDB9DA9D7BD3E` |
| hpl_ism_routing | 1986 | `a0b29c373cb5428ef6e8a99908e0e94b62d719c65434d133b14b4674ee937202` | `F0DEA9FEEE0923A159181A06AF7392F4906931AC86F8E4F491B5444F9CBB77B9` |

### IGP (Interchain Gas Paymaster) Contracts

| Contract Name | Code ID | Checksum | Transaction Hash |
|--------------|---------|----------|------------------|
| hpl_igp | 1987 | `99e42faf05c446170167bdf0521eaaeebe33658972d056c4d0dc607d99186044` | `7BB862772DE9769E21FEDDC2A32EF928A1E752B433549F353D70B146C2EC5051` |
| hpl_igp_oracle | 1998 | `a628d5e0e6d8df3b41c60a50aeaee58734ae21b03d443383ebe4a203f1c86609` | `A65B92159B6CD64F6BE58B7E8626B066F6F386AB6C540F05FAC0B76E64889765` |

### Hook Contracts

| Contract Name | Code ID | Checksum | Transaction Hash |
|--------------|---------|----------|------------------|
| hpl_hook_aggregate | 1988 | `2ee718217253630b087594a92a6770f8d040a99b087e38deafef2e4685b23e8f` | `9C7C6C2399F7F687D75F7CFDEC2D5D442C3A7F36BB3A7690042658A5F8198188` |
| hpl_hook_fee | 1989 | `8beeb594aa33ae3ce29f169ac73e2c11c80a7753a2c92518e344b86f701d50fd` | `6E43F59DB33637770BDC482177847AE87BA36CC143E06E02651F48C390F39B42` |
| hpl_hook_merkle | 1990 | `1de731062f05b83aaf44e4abb37f566bb02f0cd7c6ecf58d375cbce25ff53076` | `B466AE86528BA0F01AFE06FF0D5275AEA73399DE3E064CCABC8500A2F0487194` |
| hpl_hook_pausable | 1991 | `8ea810f57c31bd754ba21ac87cfc361f1d6cc55974eefd8ad2308b69bd63d6bf` | `D9454A2C9D58E81791134D9F06D58652A3A3592DFDD84F8781668169FAF70C5D` |
| hpl_hook_routing | 1992 | `cbf712a3ed6881e267ad3b7a82df362c02ae9cb98b68e12c316005d928f611cf` | `788968FF912DB6C84B846C2C64A114BCB6B9B6D8F26BF91B05944F46ACECAD52` |
| hpl_hook_routing_custom | 1993 | `f2ffb3a6444da867d7cd81726cb0362ac3cc7ba2e8eef11dcb50f96e6725d09a` | `7E72C154E743E6A57D7AED43BE99751D72B48A85EEF54C308539D68021F68952` |
| hpl_hook_routing_fallback | 1994 | `d701bb43e1aea05ae8bdb3fcbe68b449b6e6d9448420b229a651ed9628a3d309` | `FF2C219C59B2DF6500F8F40E563247F6F78C66E7852C57794A7BCC6805227DCC` |

### Warp Route Contracts

| Contract Name | Code ID | Checksum | Transaction Hash |
|--------------|---------|----------|------------------|
| hpl_warp_cw20 | 1999 | `a97d87804fae105d95b916d1aee72f555dd431ece752a646627cf1ac21aa716d` | `18FD9952226B3B834BB63BDD095D2129D2BE24C9A750455C0289CBAC03B2C1D4` |
| hpl_warp_native | 2000 | `5aa1b379e6524a3c2440b61c08c6012cc831403fae0c825b966ceabecfdb172b` | `5D8E697027851176A4FE0AB5B6C5FF32EE28D609D4F934DA3AC4A0BBB6B24812` |

### Test/Mock Contracts

| Contract Name | Code ID | Checksum | Transaction Hash |
|--------------|---------|----------|------------------|
| hpl_test_mock_hook | 1995 | `15b7b62a78ce535239443228a0dc625408941182d1b09b338b55d778101e7913` | `E797929E1C41151A6B3892E75583B48DB766155CA36F15B4E206A3F212EA9EFA` |
| hpl_test_mock_ism | 1996 | `a5d07479b6d246402438b6e8a5f31adaafa18c2cd769b6dc821f21428ad560ab` | `F20D52763BFDD7B18888CCF667CFED053B445BB2E4F0310F67D6FC48DC426B8B` |
| hpl_test_mock_msg_receiver | 1997 | `35862c951117b77514f959692741d9cabc21ce7c463b9682965fce983140f0c1` | `C40928D341D14A8C9EAC9EC086FC644273AE9392A90DDB50495517B68524F899` |

## Summary

- **Total Contracts Uploaded**: 20
- **Code ID Range**: 1981 - 2000
- **Source**: Downloaded from official Hyperlane repository
- **Artifacts Location**: `/home/lunc/cw-hyperlane/tmp/codes`

## Instantiated Contracts (Testnet Deployment)

Below are the contracts that have been instantiated on Terra Classic Testnet for audit purposes.

### Deployment Information

- **Network**: Terra Classic Testnet (rebel-2)
- **Domain**: 1325
- **Owner/Admin**: terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n (Governance Module)
- **Deployment Date**: November 28, 2025

### Contract Instances

#### 1. Mailbox - Main cross-chain messaging contract

**Code ID**: 1981

**Instantiation Parameters**:
```json
{
  "hrp": "terra",
  "domain": 1325,
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n"
}
```

**Deployed Contract**:
- **Address**: `terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf`
- **Hex Address**: `18111026c945381eb4a6e6852a4affd2b4023e918787379cea28d001314ee44b`

---

#### 2. Validator Announce - Validator registry

**Code ID**: 1982

**Instantiation Parameters**:
```json
{
  "hrp": "terra",
  "mailbox": "terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf"
}
```

**Deployed Contract**:
- **Address**: `terra10szy9ppjpgt8xk3tkywu3dhss8s5scsga85f4cgh452p6mwd092qdzfyup`
- **Hex Address**: `7c044284320a16735a2bb11dc8b6f081e1486208e9e89ae117ad141d6dcd7954`

---

#### 3. ISM Multisig #1 - For BSC Testnet (Domain 97)

**Code ID**: 1984

**Instantiation Parameters**:
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n"
}
```

**Deployed Contract**:
- **Address**: `terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv`
- **Hex Address**: `18d6fb643be899d66edc8305aa1cbfa1115d8256a9679581205ae7b4a895c9b6`

---

#### 4. ISM Multisig #2 - For Solana Testnet (Domain 1399811150)

**Code ID**: 1984

**Instantiation Parameters**:
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n"
}
```

**Deployed Contract**:
- **Address**: `terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a`
- **Hex Address**: `6fbb4504dc8bc2c218740f16f482877d2ef608f16665e5543034712af292a3c`

---

#### 5. ISM Routing - ISM router by domain

**Code ID**: 1986

**Instantiation Parameters**:
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "isms": [
    {
      "domain": 97,
      "address": "terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv"
    },
    {
      "domain": 1399811150,
      "address": "terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a"
    }
  ]
}
```

**Deployed Contract**:
- **Address**: `terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh`
- **Hex Address**: `bd60d3a486bb73e6e0ae290a2be159086e887a80f08494456924f67030398cbf`

---

#### 6. Hook Merkle - Merkle tree for message proofs

**Code ID**: 1990

**Instantiation Parameters**:
```json
{
  "mailbox": "terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf"
}
```

**Deployed Contract**:
- **Address**: `terra1x9ftmmyj0t9n0ql78r2vdfk9stxg5z6vnwnwjym9m7py6lvxz8ls7sa3df`
- **Hex Address**: `3152bdec927acb3783fe38d4c6a6c582cc8a0b4c9ba6e91365df824d7d8611ff`

---

#### 7. IGP - Cross-chain gas payment manager

**Code ID**: 1987

**Instantiation Parameters**:
```json
{
  "hrp": "terra",
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "gas_token": "uluna",
  "beneficiary": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "default_gas_usage": "100000"
}
```

**Deployed Contract**:
- **Address**: `terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9`
- **Hex Address**: `9f9e88b11e3233a01f75a8f8ddd49a4ef59f860174109da43784579c883db6b1`

---

#### 8. IGP Oracle - Gas prices and rates oracle

**Code ID**: 1998

**Instantiation Parameters**:
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n"
}
```

**Deployed Contract**:
- **Address**: `terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg`
- **Hex Address**: `3ac80cf8a4b2fb8d063dfb229a96cfd1813ea81452dc4ea7e315280b74b9ddc7`

---

#### 9. Hook Aggregate #1 - Aggregator (Merkle + IGP)

**Code ID**: 1988

**Instantiation Parameters**:
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "hooks": [
    "terra1x9ftmmyj0t9n0ql78r2vdfk9stxg5z6vnwnwjym9m7py6lvxz8ls7sa3df",
    "terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9"
  ]
}
```

**Deployed Contract**:
- **Address**: `terra14qjm9075m8djus4tl86lc5n2xnsvuazesl52vqyuz6pmaj4k5s5qu5q6jh`
- **Hex Address**: `a825b2bfd4d9db2e42abf9f5fc526a34e0ce745987e8a6009c1683becab6a428`
- **Note**: Set as 'default_hook' in the Mailbox

---

#### 10. Hook Pausable - Hook with pause capability

**Code ID**: 1991

**Instantiation Parameters**:
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "paused": false
}
```

**Deployed Contract**:
- **Address**: `terra1j04kamuwssgckj7592w5v3hlttmlqlu9cqkzvvxsjt8rqyt3stps0xan5l`
- **Hex Address**: `93eb6eef8e84118b4bd42a9d4646ff5af7f07f85c02c2630d092ce30117182c3`

---

#### 11. Hook Fee - Fixed fee charging hook

**Code ID**: 1989

**Instantiation Parameters**:
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "fee": {
    "denom": "uluna",
    "amount": "283215"
  }
}
```

**Deployed Contract**:
- **Address**: `terra13y6vseryqqj09uu9aagk8xks4dr9fr2p0xr3w6gngdzjd362h54sz5fr3j`
- **Hex Address**: `8934c864640024f2f385ef51639ad0ab46548d417987176913434526c74abd2b`
- **Note**: Fee: 0.283215 LUNC per message

---

#### 12. Hook Aggregate #2 - Aggregator (Pausable + Fee)

**Code ID**: 1988

**Instantiation Parameters**:
```json
{
  "owner": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
  "hooks": [
    "terra1j04kamuwssgckj7592w5v3hlttmlqlu9cqkzvvxsjt8rqyt3stps0xan5l",
    "terra13y6vseryqqj09uu9aagk8xks4dr9fr2p0xr3w6gngdzjd362h54sz5fr3j"
  ]
}
```

**Deployed Contract**:
- **Address**: `terra1xdpah0ven023jzd80qw0nkp4ndjxy4d7g5y99dhpfwetyal6q6jqpk42rj`
- **Hex Address**: `3343dbbd999bd51909a7781cf9d8359b646255be450852b6e14bb2b277fa06a4`
- **Note**: Set as 'required_hook' in the Mailbox

---

### Contract Addresses Summary (JSON Format)

```json
{
  "hpl_mailbox": "terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf",
  "hpl_validator_announce": "terra10szy9ppjpgt8xk3tkywu3dhss8s5scsga85f4cgh452p6mwd092qdzfyup",
  "hpl_ism_multisig_bsc": "terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv",
  "hpl_ism_multisig_sol": "terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a",
  "hpl_ism_routing": "terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh",
  "hpl_hook_merkle": "terra1x9ftmmyj0t9n0ql78r2vdfk9stxg5z6vnwnwjym9m7py6lvxz8ls7sa3df",
  "hpl_igp": "terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9",
  "hpl_igp_oracle": "terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg",
  "hpl_hook_aggregate_default": "terra14qjm9075m8djus4tl86lc5n2xnsvuazesl52vqyuz6pmaj4k5s5qu5q6jh",
  "hpl_hook_pausable": "terra1j04kamuwssgckj7592w5v3hlttmlqlu9cqkzvvxsjt8rqyt3stps0xan5l",
  "hpl_hook_fee": "terra13y6vseryqqj09uu9aagk8xks4dr9fr2p0xr3w6gngdzjd362h54sz5fr3j",
  "hpl_hook_aggregate_required": "terra1xdpah0ven023jzd80qw0nkp4ndjxy4d7g5y99dhpfwetyal6q6jqpk42rj"
}
```

### Deployment Statistics

- **Total Contracts Instantiated**: 12
- **Contracts Breakdown**:
  - 1 Mailbox
  - 1 Validator Announce
  - 2 ISM Multisig (BSC Testnet, Solana Testnet)
  - 1 ISM Routing
  - 1 Hook Merkle
  - 1 IGP + 1 IGP Oracle
  - 2 Hook Aggregates
  - 1 Hook Pausable
  - 1 Hook Fee

### Supported Chains (Testnet)

- **BSC Testnet** (Domain 97)
- **Solana Testnet** (Domain 1399811150)

## Explorer Links

You can verify these transactions on Terra Classic Testnet explorers:

- **Ping.pub**: https://testnet.ping.pub/terra-classic/tx/{TX_HASH}
- **Finder (Terra Classic)**: https://finder.terra.money/testnet/tx/{TX_HASH}

Replace `{TX_HASH}` with any transaction hash from the table above.

## Verification

To verify the integrity of uploaded contracts, you can query the code info:

```bash
# Query specific code ID
terrad query wasm code-info [CODE_ID] --node https://rpc.testnet.terra.money --chain-id rebel-2

# Example for mailbox contract
terrad query wasm code-info 1981 --node https://rpc.testnet.terra.money --chain-id rebel-2
```

## Notes

- All contracts were uploaded using the official artifacts from the Hyperlane repository
- Checksums match the official release artifacts
- These code IDs should be used for contract instantiation via governance proposals
- Keep this document as reference for future deployments and upgrades

