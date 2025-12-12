# Fix: `--use-rpc` Error in Solana Deploy

## Problem

When executing `warp-route deploy` on Solana, the command fails with:

```
error: Found argument '--use-rpc' which wasn't expected, or isn't valid in this context
```

This occurs because Solana CLI 1.14.20 doesn't support the `--use-rpc` flag that the `hyperlane-sealevel-client` code is trying to use.

## Solution: Use `program-ids.json`

Since you've already deployed the program with Program ID `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`, use `program-ids.json` to reference the existing Program ID instead of trying to deploy again.

### 1. Create `program-ids.json`

Create the file `~/hyperlane-monorepo/rust/sealevel/environments/testnet/warp-routes/lunc-solana/program-ids.json`:

```json
{
  "solanatestnet": {
    "hex": "0x3e39de1edbc0495cee651b3e046f63d01ff9436932bb520e8c0cb4ba5c5c7f1d",
    "base58": "5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
  }
}
```

### 2. Update `token-config.json`

**⚠️ IMPORTANT**: Do NOT include `foreignDeployment` in the initial `token-config.json`. The format should be:

```json
{
  "solanatestnet": {
    "type": "synthetic",
    "name": "Luna Classic",
    "symbol": "wwwwLUNC",
    "decimals": 6,
    "totalSupply": "0"
  }
}
```

### 3. Execute Deploy

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

cargo run -- \
  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \
  -u https://api.testnet.solana.com \
  warp-route deploy \
  --warp-route-name lunc-solana \
  --environment testnet \
  --environments-dir ../environments \
  --token-config-file ../environments/testnet/warp-routes/lunc-solana/token-config.json \
  --built-so-dir ../target/deploy \
  --registry ~/.hyperlane/registry \
  --ata-payer-funding-amount 5000000
```

### 4. Expected Result

The command will:
1. ✅ Recognize the existing Program ID from `program-ids.json`
2. ✅ Skip program deployment (avoiding the `--use-rpc` error)
3. ✅ Initialize the synthetic token using the existing Program ID
4. ✅ Create the Mint Account and configure metadata

## Note

The `program-ids.json` file tells the `hyperlane-sealevel-client` that the program has already been deployed (manually or elsewhere) and should use that Program ID instead of attempting a new deployment.

## Alternative: Manual Program Deployment

If you need to deploy the program manually first:

```bash
cd ~/hyperlane-monorepo/rust/sealevel
cargo build-sbf --manifest-path programs/hyperlane-sealevel-token/Cargo.toml

solana program deploy target/deploy/hyperlane_sealevel_token.so \
  --url testnet \
  --keypair /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json
```

Then create the `program-ids.json` file with the returned Program ID.

