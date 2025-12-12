# Initialize Solana Synthetic Token Manually

## Problem

When you use `foreignDeployment` in `token-config.json`, the `hyperlane-sealevel-client` code **does not initialize** the synthetic token, assuming everything was already done elsewhere.

But in your case, you only deployed the program (`5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x`), but still need to **initialize the synthetic token**.

## Solution: Use `program-ids.json` Instead

To initialize the token, you should use `program-ids.json` to reference the existing Program ID, rather than `foreignDeployment` in `token-config.json`.

### Step 1: Create `program-ids.json`

Create the file manually:

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

### Step 2: Update `token-config.json`

**⚠️ IMPORTANT**: Remove `foreignDeployment` from `token-config.json`:

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

### Step 3: Execute Deploy

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

### Step 4: Expected Result

Now the command should:
1. ✅ Read `program-ids.json` and use the existing Program ID
2. ✅ **Initialize the synthetic token** (create the token PDA)
3. ✅ Create the Mint Account and configure Mint Authority
4. ✅ Show messages like "Initializing Warp Route program..."

### Step 5: Verify Initialization

After execution, you should see messages like:
- "Initializing Warp Route program: domain_id: ..."
- "Warp route token initialized successfully"
- Information about the Mint Account

## Note

The `program-ids.json` file makes the code use the existing Program ID instead of trying to deploy again. But without `foreignDeployment`, the code still processes the chain and initializes the token.

## Difference Between `program-ids.json` and `foreignDeployment`

- **`program-ids.json`**: Tells the code to use an existing Program ID, but still processes the chain and initializes the token.
- **`foreignDeployment`**: Tells the code that everything (including token initialization) was done elsewhere, so it skips all processing for that chain.

For your use case, use `program-ids.json` to reference the existing Program ID while still allowing the code to initialize the token.

