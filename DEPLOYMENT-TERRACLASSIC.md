# Deploying Hyperlane with Terra Classic

> This guide will help you setup Hyperlane on Terra Classic (LUNC).

## Prerequisites

- [Cast](https://book.getfoundry.sh/cast/)
- Terra Classic account with sufficient balance
- Node.js and Yarn installed

### Setting Up Your Wallet

It is recommended to use the same account for all networks.

#### Generating Private Key from Existing Wallet

If you already have a Terra Classic wallet with a mnemonic phrase, you can export the private key in hexadecimal format to use in the configuration:

```bash
# Step 1: Recover your wallet using the mnemonic
terrad keys add hyperlane-validator --recover --keyring-backend file

# You will be prompted to enter your mnemonic phrase
> Enter your bip39 mnemonic
# Example: coffee table mountain river sunset ocean forest digital cloud brave wisdom happy journey frozen treasure robot galaxy planet crystal silver moon star universe magic

# Enter and confirm a keyring passphrase
Enter keyring passphrase (attempt 1/3):
Re-enter keyring passphrase:

# Output will show your address information:
- address: terra1abc123def456ghi789jkl012mno345pqr678st
  name: hyperlane-validator
  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Ax1Y2Z3..."}'
  type: local
```

```bash
# Step 2: Export the private key in unarmored hexadecimal format
terrad keys export hyperlane-validator --unarmored-hex --unsafe --keyring-backend file

WARNING: The private key will be exported as an unarmored hexadecimal string. USE AT YOUR OWN RISK. Continue? [y/N]: y

# Enter your keyring passphrase
Enter keyring passphrase (attempt 1/3):

# Output will be your private key in hexadecimal format (64 characters)
# Example: 1a2b3c4d5e6f7890abcdef1234567890abcdef1234567890abcdef1234567890
```

**⚠️ SECURITY WARNING:**
- Never share your mnemonic phrase or private key with anyone
- Never commit private keys to version control (Git)
- Store your keys securely (use password managers or hardware wallets)
- The private key shown above is for **EXAMPLE ONLY** - use your real key in config files

#### Getting Addresses from Existing Keys

You can easily get the bech32 address by running the commands below (first setup `config.yaml`):

- Get address from private key:  
  ```bash
  yarn cw-hpl wallet address -n terraclassic --private-key [private-key]
  ```

- Get address from mnemonic phrase:  
  ```bash
  yarn cw-hpl wallet address -n terraclassic --mnemonic [mnemonic]
  ```

- Get Ethereum address from private key:  
  ```bash
  cast wallet address --private-key [private-key]
  ```

- Or create a new wallet:  
  ```bash
  yarn cw-hpl wallet new -n terraclassic
  ```

## 1. Create `config.yaml` with your network config

> Don't forget to setup deploy settings below

**📁 Configuration Templates Available:**

This repository includes ready-to-use configuration templates:
- `config-testnet.yaml` - Configuration for Terra Classic Testnet
- `config-mainnet.yaml` - Configuration for Terra Classic Mainnet

You can copy one of these files as a starting point:

```bash
# For Testnet
cp config-testnet.yaml config.yaml

# Or for Mainnet
cp config-mainnet.yaml config.yaml
```

Then edit the `config.yaml` file with your specific settings (private key, addresses, etc.).

### Example `config.yaml` file for Terra Classic:

```yaml
networks:
  - id: 'terraclassic'
    chainId: 'rebel-2'
    hrp: 'terra'
    signer: <your-private-key-or-mnemonic>
    endpoint:
       rpc: 'https://rpc.luncblaze.com'
       rest: 'https://lcd.luncblaze.com'
       grpc: 'https://grpc.terra-classic.hexxagon.dev'
    gas:
      price: '28.325'
      denom: 'uluna'
    domain: 1325   # terra-classic -> ascii / decimal -> sum

deploy:
  ism:
    type: "routing"
    owner: <your-terra-address>
    isms:
      97:
          type: multisig
          owner: <your-terra-address>
          validators:
            97:
              addrs:
                - '<validator-address-1>'
                - '<validator-address-2>'
                - '<validator-address-3>'
              threshold: 2
      
      1399811150:
          type: multisig
          owner: <your-terra-address>
          validators:
            1399811150:
              addrs:
                - '<validator-address>'
              threshold: 1

  hooks:
    default:
      type: aggregate
      owner: <your-terra-address>
      hooks:
        - type: merkle

        - type: igp
          owner: <your-terra-address>
          configs:
            97:
              exchange_rate: 1805936462255558    
              gas_price: 50_000_000   # 0.05 Gwei                          
            
            1399811150:
              exchange_rate: 57675000000000000     
              gas_price: 1   

          default_gas_usage: 100000

    required:
      type: aggregate
      owner: <your-terra-address>
      hooks:
        - type: pausable
          owner: <your-terra-address>
          paused: false

        - type: fee
          owner: <your-terra-address>
          fee:
            denom: uluna
            amount: 283215
```

## 2. Upload Contract Codes

You must use the original contract codes from [Github](https://github.com/many-things/cw-hyperlane/releases).

```bash
yarn install

# Check all versions of contract codes from Github
yarn cw-hpl upload remote-list -n terraclassic

# This command will create one file:
# - context with artifacts (default path: {project-root}/context/terraclassic.json)
yarn cw-hpl upload remote v0.0.6-rc8 -n terraclassic
```

## 3. Instantiate Contracts

Contract instantiation on Terra Classic is performed through a separate governance process and custom scripts.

### 📚 Additional Documentation

For detailed information about the deployment process and advanced configurations, check out:

**[Complete Hyperlane Deployment Guide](https://github.com/igorv43/hyperlane-docs/blob/main/HYPERLANE_DEPLOYMENT_EN.md)**

This guide contains:
- Detailed explanations of each Hyperlane component
- ISM (Interchain Security Modules) configurations
- Hooks configurations (Merkle, IGP, Pausable, Fee)
- Best practices and troubleshooting
- Practical configuration examples

## 4. Setup Validator / Relayer

To run the validator and relayer services that are essential for Hyperlane operation, you will need to configure and run these components.

### 📚 Configuration Guide

Access the complete repository with detailed instructions:

**[Hyperlane Validator & Relayer - Complete Guide](https://github.com/igorv43/hyperlane-validator/tree/main)**

This repository contains:

- **Validator Configuration**: Complete setup to run a Hyperlane validator node, including:
  - Configuration files for Terra Classic
  - Startup and monitoring scripts
  - Infrastructure requirements
  
- **Relayer Configuration**: Instructions to run the relayer that transmits messages between chains:
  - Multiple network configuration
  - Gas and fee management
  - Monitoring and logs

- **Docker Compose**: Containerized setup for easy deployment
  - Ready-to-use docker-compose files
  - Optimized network configurations
  - Maintenance scripts

### Quick Summary

1. Clone the validator repository
2. Configure your private keys in the configuration files
3. Adjust network parameters as needed
4. Run with Docker Compose or directly
5. Monitor logs to ensure correct operation

Replace all occurrences of `{terra_private_key}` in the configuration files with your private key.

## 5. Warp Route

```bash
# Deploy warp route on another network (e.g., Sepolia)
yarn cw-hpl-exp warp deploy --pk 'YOUR_PRIVATE_KEY'

# The output will be something like:
{ "hypErc20Terra": "0x..." }

# Deploy warp route on Terra Classic
yarn cw-hpl warp create ./example/warp/uluna.json -n terraclassic

# Register Terra Classic warp route to the other network
yarn cw-hpl-exp warp link $hypErc20Terra 1325 $TERRACLASSIC_WARP_ROUTE_ADDRESS --pk 'YOUR_PRIVATE_KEY'

# Also register the other network's warp route to Terra Classic
yarn cw-hpl warp link \
  --asset-type native \
  --asset-id uluna \
  --target-domain 11155111 \
  --warp-address $hypErc20Terra \
  -n terraclassic

# Test transfer
yarn cw-hpl warp transfer \
  --asset-type native \
  --asset-id uluna \
  --target-domain 11155111 \
  -n terraclassic
```

## 6. Done! 🎉

Congratulations! You have successfully configured Hyperlane on Terra Classic.

This setup is suitable for production environments. Make sure to:

- Keep your private keys secure
- Regularly monitor validators and relayers
- Keep contracts updated
- Backup important configurations

For additional support, check out:
- [Official Hyperlane Documentation](https://docs.hyperlane.xyz/)
- [Project Repository](https://github.com/many-things/cw-hyperlane)
