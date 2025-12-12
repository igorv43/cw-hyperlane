# Configure ISM for Solana Warp Route

## Overview

Unlike EVM (BSC) and Cosmos (Terra Classic) chains, Solana warp routes **do not** have an ISM field in the `token-config.json` during deployment. The warp route uses the ISM configured in the Solana Mailbox by default.

However, you can configure a custom ISM for the warp route **after deployment** using the `sealevel client`'s `token set-interchain-security-module` command.

## Prerequisites

- Warp route deployed on Solana
- Program ID: `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`
- ISM Program ID (typically the Multisig ISM Message ID): `4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k`

## Step 1: Set Custom ISM

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variables
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
PROGRAM_ID="5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"

# Set custom ISM
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token set-interchain-security-module \
  --program-id "$PROGRAM_ID" \
  --ism "$ISM_PROGRAM_ID"
```

## Step 2: Verify ISM Configuration

```bash
# Query the current ISM
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token get-interchain-security-module \
  --program-id "$PROGRAM_ID"
```

## Step 3: Configure Validators in ISM

After setting the ISM, configure validators for specific domains:

```bash
# Variables
DOMAIN="1325"  # Terra Classic domain
VALIDATOR="242d8a855a8c932dec51f7999ae7d1e48b10c95e"  # Terra Classic validator
THRESHOLD="1"

# Configure validators
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  ism multisig-message-id set-validators-and-threshold \
  --program-id "$ISM_PROGRAM_ID" \
  --domain "$DOMAIN" \
  --validators "$VALIDATOR" \
  --threshold "$THRESHOLD"
```

## Default Behavior

If you don't set a custom ISM, the warp route will use the **default ISM configured in the Solana Mailbox**. This is typically the ISM Routing that routes to different ISM Multisig contracts based on the source domain.

## Notes

- The ISM must be deployed before you can set it on the warp route
- The ISM Program ID is usually the same as the Multisig ISM Message ID from the core program IDs
- Validators must be configured for each domain that will send messages to this warp route

