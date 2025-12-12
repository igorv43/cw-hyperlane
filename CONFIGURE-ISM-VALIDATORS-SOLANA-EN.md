# Configure ISM Validators on Solana

This guide explains how to configure validators for a Solana ISM (Interchain Security Module) using the `hyperlane-sealevel-client`.

## Prerequisites

- Solana ISM Program deployed
- ISM Program ID: `4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k` (Multisig ISM Message ID)
- Validator addresses in hex format (32 bytes)

## Step 1: Prepare Validator Addresses

Convert Terra Classic validator addresses from Bech32 to hex (32 bytes):

```bash
# Terra Classic validator address (Bech32)
VALIDATOR_BECH32="terra1..."

# Convert to hex (32 bytes, padded)
# Use a tool or script to convert Bech32 to hex
VALIDATOR_HEX="242d8a855a8c932dec51f7999ae7d1e48b10c95e"
```

## Step 2: Set Validators and Threshold

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Variables
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"
DOMAIN="1325"  # Terra Classic domain
VALIDATOR="242d8a855a8c932dec51f7999ae7d1e48b10c95e"  # Terra Classic validator (hex)
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

## Step 3: Verify Configuration

```bash
# Get validators and threshold for a domain
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  ism multisig-message-id get-validators-and-threshold \
  --program-id "$ISM_PROGRAM_ID" \
  --domain "$DOMAIN"
```

## Multiple Validators

To set multiple validators, provide them as a comma-separated list:

```bash
VALIDATORS="validator1,validator2,validator3"
THRESHOLD="2"  # Require 2 out of 3 signatures

cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  ism multisig-message-id set-validators-and-threshold \
  --program-id "$ISM_PROGRAM_ID" \
  --domain "$DOMAIN" \
  --validators "$VALIDATORS" \
  --threshold "$THRESHOLD"
```

## Address Format

- **Solana addresses**: Base58 format (e.g., `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`)
- **EVM addresses**: Hex format, 20 bytes (e.g., `0x242d8a855a8c932dec51f7999ae7d1e48b10c95e`)
- **Cosmos addresses**: Hex format, 32 bytes padded (e.g., `0x242d8a855a8c932dec51f7999ae7d1e48b10c95e000000000000000000000000`)

## Notes

- The ISM Program ID is typically the Multisig ISM Message ID from the core program IDs
- Validators must be configured for each domain that will send messages
- The threshold must be less than or equal to the number of validators
- Changes to validators require the ISM owner's signature

