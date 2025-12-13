# Enroll Remote Router: Solana Testnet → Terra Classic

This guide shows how to enroll the Terra Classic warp route as a remote router on the Solana Testnet warp route program.

## Overview

After linking Terra Classic → Solana, you need to enroll the Terra Classic router on the Solana side so that Solana knows where to send messages to Terra Classic.

**⚠️ IMPORTANT**: Unlike BSC/EVM chains, Solana does **NOT** use Safe. You interact directly with the Solana program using the `hyperlane-sealevel-client`.

## Prerequisites

- Solana Testnet warp route Program ID: `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`
- Terra Classic warp route: `terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml`
- Terra Classic warp route (hex): `0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b`
- Terra Classic domain: `1325`
- Solana keypair with owner permissions (owner of the Solana warp route)

## Step 1: Convert Terra Classic Address to Hex Format

The Terra Classic bech32 address needs to be converted to a 32-byte hex format (H256) for the Solana program.

**Terra Classic Address:**
```
terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml
```

**Converted Hex (32 bytes):**
```
0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b
```

### How to Convert

#### Method 1: Use cw-hpl CLI (Recommended)

```bash
yarn cw-hpl wallet bech32-to-hex terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml
```

**Expected output:**
```
0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b
```

#### Method 2: Use Node.js

```bash
node -e "
const { fromBech32 } = require('@cosmjs/encoding');
const addr = 'terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml';
const { data } = fromBech32(addr);
const hexed = Buffer.from(data).toString('hex');
const padded = hexed.padStart(64, '0');
console.log('Hex (32 bytes):', '0x' + padded);
"
```

**Expected output:**
```
Hex (32 bytes): 0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b
```

#### Method 3: Use from Context File

If you deployed the warp route using `cw-hyperlane`, the hex address is already in the context file:

```bash
# Read from context
cat context/terraclassic.json | jq -r '.deployments.warp.native[] | select(.id == "wwwwlunc") | .hexed'
```

**Expected output:**
```
0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b
```

## Step 2: Enroll Remote Router on Solana

On Solana, use the `hyperlane-sealevel-client` to enroll the Terra Classic router:

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variables
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
WARP_ROUTE_PROGRAM_ID="5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
TERRA_DOMAIN="1325"
TERRA_WARP_HEX="0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b"

# Enroll remote router
# ⚠️ IMPORTANT: domain and router are POSITIONAL arguments, not flags
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token enroll-remote-router \
  --program-id "$WARP_ROUTE_PROGRAM_ID" \
  "$TERRA_DOMAIN" \
  "$TERRA_WARP_HEX"
```

**⚠️ IMPORTANT**: 
- The `-k` and `-u` flags are **global arguments** and must come **BEFORE** the subcommand (`token enroll-remote-router`)
- The `router` parameter accepts H256 format, which can be:
  - Hex with `0x` prefix: `0x0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02`
  - Hex without `0x` prefix: `0fe22b5522bb88b9836c3ec4888bcfdb40f72d5ec74991a87c7f171e06e63d02`
  - Bech32 address: `terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8` (will be converted automatically)
  - Base58 address: (for Solana addresses)

**Expected Output:**
```
==== Instructions: ====
Instruction 0: Set compute unit limit to 1400000
Instruction 1: No description provided
==== Transaction in base58: ====
XA722NZHBfvS3g781s13SZ1rEZw8HdutpDsbKV6c8KKLMLivQNc75pdvPQibxFkfGZkZNg3dTaikQFsezB7VAZkhxXg9Wir5rJroeTUmVEpV8ktopNZY6DzJqBYE2Vc9m3NVBD9KDCqysVY772teyH9sYUKZhrh1BBV21UV19L3JGGG2HBGs9eYmzkYesir8V4E7Ybe5ohabah3SbrkBmKB9kjjZB2S4YPtf24PSvT1XN6i5brxRpJEib79QV7ifw3oaNJ1qHbVqWLgJ7KrLiWbig7X7g5KvgWXbYtLjmezuvZ5GtsmwXWg72T3AunjDdSg9ARo8UjNpuKBemwZCb82FhVN7KA6YeDhtsy87Aoj6ppLaQrufmLt2zZQKTK9fpkdVzciDDQtJoZ3GvJ5uGYwwKv71iqydeg683nnwxXxxAfx8yUxXoEQ94oge

==== Message in base58: ====
2LRrjv43KXgzLXGnctLbk3SF1xbwBSC29kDz7k3fsHGybmoK4uCarAcCxiQnbL5UtGn5Nt2hSH2SiN5uoLqkskG8D5LeAtXVsRjqHjkwkFeWaPfNHWK9zzp1Ckfav5vDJTcc5jXDQmcAvKKoXw7iYKRnZNDPCt1wbuXRsMWSnYCaTVEV4WPoqtX6wxcq49oEYkvG5416FCexossEikVmZ8jturVPYWC9ak1MWPaHMMnyjij7CWDkSySHWzEgUxwFYg6PvdByef3w2nCvaa8oYcxniBJJh8unDFeg94aDqjBgq4cGMTJHHkGPQ9DqBzcDzN1XDSkh4rrB2hM4KZHd18KZwyzJ9ymsCpYJ
```

**✅ Success!** The transaction has been prepared and sent. The output shows:
- Instructions created (compute unit limit + enroll remote router)
- Transaction in base58 format
- Message in base58 format

**Note**: If you need to verify the transaction on-chain, you can:
1. Check the Solana Explorer using the transaction signature (if displayed)
2. Query the warp route state to confirm the router was enrolled (see Step 3 below)

## Step 3: Verify Enrollment

After execution, verify that the router was enrolled:

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Query the enrolled router for domain 1325
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id "$WARP_ROUTE_PROGRAM_ID" \
  synthetic
```

Look for `remote_routers` in the output. It should show:

```
remote_routers: {
    1325: 0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b,
},
```

**✅ Success Example Output:**

```
AccountData {
    data: HyperlaneToken {
        bump: 250,
        mailbox: 75HBBLae3ddeneJVrZeyrDfv6vb7SMC3aCpBucSXS5aR,
        mailbox_process_authority: s9Jd399kbL2prRtWCJku7Q4AaQQaxNhUhUi9LvG8Ue9,
        dispatch_authority_bump: 254,
        decimals: 6,
        remote_decimals: 6,
        owner: Some(
            EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd,
        ),
        interchain_security_module: Some(
            8eFJPnNRz9byTu7NYc9NdsCMHQWfD37PZnhN8fZcahJS,
        ),
        interchain_gas_paymaster: None,
        destination_gas: {},
        remote_routers: {
            1325: 0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b,
        },
        plugin_data: SyntheticPlugin {
            mint: DA3ymZtWfJa7dxKkXgar3j5tYnKDRw9JXWh2N5SGbQtA,
            mint_bump: 255,
            ata_payer_bump: 255,
        },
    },
}
```

**✅ Confirmed!** The Terra Classic router (domain 1325) is successfully enrolled. The hex address `0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b` matches your Terra Classic warp route.

## Complete Command Reference

### Full Command (One-liner)

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client && \
cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  token enroll-remote-router \
  --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x \
  1325 \
  0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b
```

**⚠️ IMPORTANT**: `domain` and `router` are **positional arguments**, not flags. The correct syntax is:
- `--program-id` (optional flag, uses default if omitted)
- `DOMAIN` (positional argument)
- `ROUTER` (positional argument)

### Using Bech32 Address Directly

The `hyperlane-sealevel-client` can automatically convert bech32 addresses to H256:

```bash
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token enroll-remote-router \
  --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x \
  1325 \
  terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml
```

**Note**: `domain` and `router` are positional arguments, not flags.

**Note**: The client uses `hex_or_base58_or_bech32_to_h256` internally, so it can handle bech32 addresses directly.

## Function Signature

The `enrollRemoteRouter` function in the Solana program:

```rust
pub fn enroll_remote_routers(
    ctx: Context<EnrollRemoteRouters>,
    router_configs: Vec<RemoteRouterConfig>,
) -> Result<()>
```

Where `RemoteRouterConfig` is:
```rust
pub struct RemoteRouterConfig {
    pub domain: u32,
    pub router: H256,  // 32-byte hash
}
```

**Parameters:**
- `domain`: Terra Classic domain ID (1325)
- `router`: Terra Classic warp route address as H256 (32-byte hex format)

## Comparison: BSC vs Solana

| Aspect | BSC (EVM) | Solana (SVM) |
|--------|-----------|--------------|
| **Method** | Safe CLI + `cast calldata` | `hyperlane-sealevel-client` directly |
| **Address Format** | 32-byte hex (0x...) | H256 (accepts hex, base58, or bech32) |
| **Command** | `cast calldata` + `safe tx create` | `token enroll-remote-router` |
| **Owner Check** | Safe must be owner | Keypair signer must be owner |
| **Transaction** | Multi-step (create → sign → execute) | Single command |

## Important Notes

1. **Domain ID**: Terra Classic domain is `1325` (not to be confused with other networks)
2. **Address Format**: The Terra Classic address can be provided as:
- Hex with `0x` prefix: `0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b`
- Hex without `0x` prefix: `17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b`
- Bech32: `terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml` (auto-converted)
3. **Ownership**: The keypair signer must be the owner of the Solana warp route program
4. **Bidirectional**: After enrolling on Solana, make sure Terra Classic → Solana is also linked (see `LINK-ULUNA-WARP-BSC.md` for Terra Classic side)

## Troubleshooting

### Error: "Owner not signer"

**Problem**: The keypair signer is not the owner of the warp route program.

**Solution**: Verify the owner:
```bash
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x \
  synthetic
```

Look for `owner` in the output. If it's not your keypair address, you need to use the owner's keypair or transfer ownership.

### Error: "Invalid router format"

**Problem**: The router address format is incorrect.

**Solution**: 
- Use hex format: `0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b`
- Or use bech32: `terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml`
- The client will automatically convert bech32 to H256

### Error: "Account has insufficient funds"

**Problem**: Your Solana account doesn't have enough SOL for the transaction.

**Solution**: Request airdrop:
```bash
solana airdrop 1 EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd --url https://api.testnet.solana.com
```

## Next Steps

After successfully enrolling the remote router:

1. **Verify both directions are linked:**
   - Terra Classic → Solana: Check route on Terra Classic
   - Solana → Terra Classic: Verify router enrollment on Solana

2. **Test cross-chain transfer:**
   - Transfer from Terra Classic to Solana
   - Transfer from Solana to Terra Classic

## References

- [ENROLL-REMOTE-ROUTER-BSC.md](./ENROLL-REMOTE-ROUTER-BSC.md) - BSC example (uses Safe)
- [WARP-ROUTE-TERRA-SOLANA-EN.md](./WARP-ROUTE-TERRA-SOLANA-EN.md) - Complete Terra Classic ↔ Solana guide
- [Hyperlane Sealevel Client](https://github.com/hyperlane-xyz/hyperlane-monorepo/tree/main/rust/sealevel/client)

