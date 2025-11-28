# Hyperlane Governance Operations Guide - Terra Classic Testnet

This document provides detailed instructions for managing Hyperlane contracts through governance proposals on Terra Classic Testnet. It covers how to update validators, modify gas fees, exchange rates, and other operational configurations.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Governance Module Address](#governance-module-address)
- [Contract Addresses](#contract-addresses)
- [1. Managing Validators](#1-managing-validators)
- [2. Managing Gas Oracle Configuration](#2-managing-gas-oracle-configuration)
- [3. Managing IGP Routes](#3-managing-igp-routes)
- [4. Managing Mailbox Configuration](#4-managing-mailbox-configuration)
- [5. Managing Hook Fees](#5-managing-hook-fees)
- [6. Managing Pausable Hooks](#6-managing-pausable-hooks)
- [How to Submit Proposals](#how-to-submit-proposals)

---

## Prerequisites

- Terra Classic CLI (`terrad`) installed
- Access to governance account or ability to submit proposals
- Minimum deposit: 10,000,000 uluna (10 LUNC)
- Understanding of JSON message formatting

## Governance Module Address

The governance module address that must be used as `sender` in all governance proposals:

```
terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n
```

## Contract Addresses

Current testnet contract deployments:

| Contract | Address |
|----------|---------|
| Mailbox | `terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf` |
| ISM Multisig BSC | `terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv` |
| ISM Multisig Solana | `terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a` |
| ISM Routing | `terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh` |
| IGP | `terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9` |
| IGP Oracle | `terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg` |
| Hook Merkle | `terra1x9ftmmyj0t9n0ql78r2vdfk9stxg5z6vnwnwjym9m7py6lvxz8ls7sa3df` |
| Hook Aggregate Default | `terra14qjm9075m8djus4tl86lc5n2xnsvuazesl52vqyuz6pmaj4k5s5qu5q6jh` |
| Hook Pausable | `terra1j04kamuwssgckj7592w5v3hlttmlqlu9cqkzvvxsjt8rqyt3stps0xan5l` |
| Hook Fee | `terra13y6vseryqqj09uu9aagk8xks4dr9fr2p0xr3w6gngdzjd362h54sz5fr3j` |
| Hook Aggregate Required | `terra1xdpah0ven023jzd80qw0nkp4ndjxy4d7g5y99dhpfwetyal6q6jqpk42rj` |

---

## 1. Managing Validators

### 1.1. Update BSC Testnet Validators (Domain 97)

**Purpose**: Add, remove, or modify validators for BSC Testnet messages.

**Current Configuration**:
- Domain: 97 (BSC Testnet)
- Threshold: 2 of 3 validators
- Validators: 3 addresses

**Message Structure**:

```json
{
  "set_validators": {
    "domain": 97,
    "threshold": 2,
    "validators": [
      "242d8a855a8c932dec51f7999ae7d1e48b10c95e",
      "f620f5e3d25a3ae848fec74bccae5de3edcd8796",
      "1f030345963c54ff8229720dd3a711c15c554aeb"
    ]
  }
}
```

**Example: Adding a New Validator (4 validators, threshold 3)**

```json
{
  "set_validators": {
    "domain": 97,
    "threshold": 3,
    "validators": [
      "242d8a855a8c932dec51f7999ae7d1e48b10c95e",
      "f620f5e3d25a3ae848fec74bccae5de3edcd8796",
      "1f030345963c54ff8229720dd3a711c15c554aeb",
      "a1b2c3d4e5f6789012345678901234567890abcd"
    ]
  }
}
```

**Example: Removing a Validator (2 validators, threshold 2)**

```json
{
  "set_validators": {
    "domain": 97,
    "threshold": 2,
    "validators": [
      "242d8a855a8c932dec51f7999ae7d1e48b10c95e",
      "f620f5e3d25a3ae848fec74bccae5de3edcd8796"
    ]
  }
}
```

**Governance Proposal JSON**:

```json
{
  "messages": [
    {
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      "sender": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
      "contract": "terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv",
      "msg": {
        "set_validators": {
          "domain": 97,
          "threshold": 3,
          "validators": [
            "242d8a855a8c932dec51f7999ae7d1e48b10c95e",
            "f620f5e3d25a3ae848fec74bccae5de3edcd8796",
            "1f030345963c54ff8229720dd3a711c15c554aeb",
            "a1b2c3d4e5f6789012345678901234567890abcd"
          ]
        }
      },
      "funds": []
    }
  ],
  "metadata": "Update BSC Testnet validators to 4 validators with threshold 3",
  "deposit": "10000000uluna",
  "title": "Update Hyperlane BSC Testnet Validators",
  "summary": "Add new validator to BSC Testnet ISM Multisig, increasing threshold from 2/3 to 3/4",
  "expedited": false
}
```

### 1.2. Update Solana Testnet Validators (Domain 1399811150)

**Current Configuration**:
- Domain: 1399811150 (Solana Testnet)
- Threshold: 1 of 1 validator
- Validators: 1 address

**Example: Adding Multiple Validators (3 validators, threshold 2)**

```json
{
  "set_validators": {
    "domain": 1399811150,
    "threshold": 2,
    "validators": [
      "d4ce8fa138d4e083fc0e480cca0dbfa4f5f30bd5",
      "e5df9ga249e5f194gd0e591ddb0ebea5g6g41ce6",
      "f6e08hb35af6g205he1f602eed1fcfb6h7h52df7"
    ]
  }
}
```

**Governance Proposal JSON**:

```json
{
  "messages": [
    {
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      "sender": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
      "contract": "terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a",
      "msg": {
        "set_validators": {
          "domain": 1399811150,
          "threshold": 2,
          "validators": [
            "d4ce8fa138d4e083fc0e480cca0dbfa4f5f30bd5",
            "e5df9ga249e5f194gd0e591ddb0ebea5g6g41ce6",
            "f6e08hb35af6g205he1f602eed1fcfb6h7h52df7"
          ]
        }
      },
      "funds": []
    }
  ],
  "metadata": "Update Solana Testnet validators to 3 validators with threshold 2",
  "deposit": "10000000uluna",
  "title": "Update Hyperlane Solana Testnet Validators",
  "summary": "Increase Solana Testnet validators from 1/1 to 2/3 for improved security",
  "expedited": false
}
```

---

## 2. Managing Gas Oracle Configuration

### 2.1. Update Exchange Rates and Gas Prices

**Purpose**: Modify token exchange rates and gas prices for destination chains.

**Current Configuration**:
- **BSC Testnet (97)**:
  - Exchange Rate: `1805936462255558` (LUNC:BNB)
  - Gas Price: `50000000` (0.05 Gwei)
- **Solana Testnet (1399811150)**:
  - Exchange Rate: `57675000000000000` (LUNC:SOL)
  - Gas Price: `1`

**Message Structure**:

```json
{
  "set_remote_gas_data_configs": {
    "configs": [
      {
        "remote_domain": 97,
        "token_exchange_rate": "1805936462255558",
        "gas_price": "50000000"
      },
      {
        "remote_domain": 1399811150,
        "token_exchange_rate": "57675000000000000",
        "gas_price": "1"
      }
    ]
  }
}
```

### 2.2. Example: Increase BSC Gas Price to 0.1 Gwei

**When to Use**: When gas prices on BSC Testnet increase and you need to ensure relayers are properly compensated.

```json
{
  "set_remote_gas_data_configs": {
    "configs": [
      {
        "remote_domain": 97,
        "token_exchange_rate": "1805936462255558",
        "gas_price": "100000000"
      }
    ]
  }
}
```

**Governance Proposal JSON**:

```json
{
  "messages": [
    {
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      "sender": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
      "contract": "terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg",
      "msg": {
        "set_remote_gas_data_configs": {
          "configs": [
            {
              "remote_domain": 97,
              "token_exchange_rate": "1805936462255558",
              "gas_price": "100000000"
            }
          ]
        }
      },
      "funds": []
    }
  ],
  "metadata": "Increase BSC Testnet gas price to 0.1 Gwei",
  "deposit": "10000000uluna",
  "title": "Update BSC Testnet Gas Price in IGP Oracle",
  "summary": "Increase BSC Testnet gas price from 0.05 to 0.1 Gwei to account for increased network costs",
  "expedited": false
}
```

### 2.3. Example: Update Token Exchange Rate

**When to Use**: When LUNC price changes significantly relative to destination chain tokens.

**Calculate Exchange Rate**:
```
exchange_rate = (1 LUNC value in USD) / (1 destination_token value in USD) * 10^18
```

Example calculation:
- 1 LUNC = $0.00005 USD
- 1 BNB = $300 USD
- exchange_rate = (0.00005 / 300) * 10^18 = 166666666666666

```json
{
  "set_remote_gas_data_configs": {
    "configs": [
      {
        "remote_domain": 97,
        "token_exchange_rate": "166666666666666",
        "gas_price": "50000000"
      }
    ]
  }
}
```

### 2.4. Example: Update Multiple Chains Simultaneously

```json
{
  "set_remote_gas_data_configs": {
    "configs": [
      {
        "remote_domain": 97,
        "token_exchange_rate": "2000000000000000",
        "gas_price": "75000000"
      },
      {
        "remote_domain": 1399811150,
        "token_exchange_rate": "60000000000000000",
        "gas_price": "2"
      }
    ]
  }
}
```

---

## 3. Managing IGP Routes

### 3.1. Update IGP Oracle Routes

**Purpose**: Point IGP to new Oracle contract or add routes for new chains.

**Current Configuration**:
- Domain 97 (BSC Testnet) → IGP Oracle
- Domain 1399811150 (Solana Testnet) → IGP Oracle

**Message Structure**:

```json
{
  "router": {
    "set_routes": {
      "set": [
        {
          "domain": 97,
          "route": "terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"
        },
        {
          "domain": 1399811150,
          "route": "terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"
        }
      ]
    }
  }
}
```

### 3.2. Example: Add New Chain Route

**When to Use**: When adding support for a new chain.

```json
{
  "router": {
    "set_routes": {
      "set": [
        {
          "domain": 42161,
          "route": "terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"
        }
      ]
    }
  }
}
```

**Governance Proposal JSON**:

```json
{
  "messages": [
    {
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      "sender": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
      "contract": "terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9",
      "msg": {
        "router": {
          "set_routes": {
            "set": [
              {
                "domain": 42161,
                "route": "terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"
              }
            ]
          }
        }
      },
      "funds": []
    }
  ],
  "metadata": "Add IGP route for Arbitrum (domain 42161)",
  "deposit": "10000000uluna",
  "title": "Add Arbitrum Support to Hyperlane IGP",
  "summary": "Configure IGP route for Arbitrum chain to enable cross-chain gas payments",
  "expedited": false
}
```

---

## 4. Managing Mailbox Configuration

### 4.1. Update Default ISM

**Purpose**: Change the security module used to validate incoming messages.

**Current Configuration**:
- Default ISM: ISM Routing (`terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh`)

**Message Structure**:

```json
{
  "set_default_ism": {
    "ism": "terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh"
  }
}
```

**Governance Proposal JSON**:

```json
{
  "messages": [
    {
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      "sender": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
      "contract": "terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf",
      "msg": {
        "set_default_ism": {
          "ism": "terra1NEW_ISM_ADDRESS_HERE"
        }
      },
      "funds": []
    }
  ],
  "metadata": "Update Mailbox default ISM to new routing contract",
  "deposit": "10000000uluna",
  "title": "Update Hyperlane Mailbox Default ISM",
  "summary": "Change default ISM to newly deployed routing contract with updated configuration",
  "expedited": false
}
```

### 4.2. Update Default Hook

**Purpose**: Change the hook executed when sending messages.

**Current Configuration**:
- Default Hook: Hook Aggregate #1 (`terra14qjm9075m8djus4tl86lc5n2xnsvuazesl52vqyuz6pmaj4k5s5qu5q6jh`)
  - Contains: Merkle + IGP

**Message Structure**:

```json
{
  "set_default_hook": {
    "hook": "terra14qjm9075m8djus4tl86lc5n2xnsvuazesl52vqyuz6pmaj4k5s5qu5q6jh"
  }
}
```

### 4.3. Update Required Hook

**Purpose**: Change the mandatory hook that cannot be bypassed.

**Current Configuration**:
- Required Hook: Hook Aggregate #2 (`terra1xdpah0ven023jzd80qw0nkp4ndjxy4d7g5y99dhpfwetyal6q6jqpk42rj`)
  - Contains: Pausable + Fee

**Message Structure**:

```json
{
  "set_required_hook": {
    "hook": "terra1xdpah0ven023jzd80qw0nkp4ndjxy4d7g5y99dhpfwetyal6q6jqpk42rj"
  }
}
```

---

## 5. Managing Hook Fees

### 5.1. Update Message Fee Amount

**Purpose**: Modify the fixed fee charged per cross-chain message.

**Current Configuration**:
- Fee: 283,215 uluna (0.283215 LUNC per message)
- Denom: uluna

**Message Structure**:

```json
{
  "set_fee": {
    "fee": {
      "denom": "uluna",
      "amount": "283215"
    }
  }
}
```

### 5.2. Example: Increase Fee to 1 LUNC

**When to Use**: To increase revenue or reduce spam.

```json
{
  "set_fee": {
    "fee": {
      "denom": "uluna",
      "amount": "1000000"
    }
  }
}
```

**Governance Proposal JSON**:

```json
{
  "messages": [
    {
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      "sender": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
      "contract": "terra13y6vseryqqj09uu9aagk8xks4dr9fr2p0xr3w6gngdzjd362h54sz5fr3j",
      "msg": {
        "set_fee": {
          "fee": {
            "denom": "uluna",
            "amount": "1000000"
          }
        }
      },
      "funds": []
    }
  ],
  "metadata": "Increase Hyperlane message fee to 1 LUNC",
  "deposit": "10000000uluna",
  "title": "Update Hyperlane Message Fee",
  "summary": "Increase per-message fee from 0.283215 LUNC to 1 LUNC to reduce spam and increase protocol revenue",
  "expedited": false
}
```

### 5.3. Example: Decrease Fee to 0.1 LUNC

**When to Use**: To encourage adoption or reduce user costs.

```json
{
  "set_fee": {
    "fee": {
      "denom": "uluna",
      "amount": "100000"
    }
  }
}
```

### 5.4. Update Fee Beneficiary

**Purpose**: Change the address that receives accumulated fees.

**Message Structure**:

```json
{
  "set_beneficiary": {
    "beneficiary": "terra1NEW_BENEFICIARY_ADDRESS_HERE"
  }
}
```

---

## 6. Managing Pausable Hooks

### 6.1. Pause Message Sending

**Purpose**: Emergency stop of all outgoing messages.

**When to Use**: 
- Security incident detected
- Critical bug discovered
- Chain maintenance
- Emergency situations

**Message Structure**:

```json
{
  "pause": {}
}
```

**Governance Proposal JSON**:

```json
{
  "messages": [
    {
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      "sender": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
      "contract": "terra1j04kamuwssgckj7592w5v3hlttmlqlu9cqkzvvxsjt8rqyt3stps0xan5l",
      "msg": {
        "pause": {}
      },
      "funds": []
    }
  ],
  "metadata": "Emergency pause of Hyperlane message sending",
  "deposit": "10000000uluna",
  "title": "Emergency Pause Hyperlane Messages",
  "summary": "Temporarily pause all outgoing Hyperlane messages due to security concerns",
  "expedited": true
}
```

### 6.2. Unpause Message Sending

**Purpose**: Resume normal operations after pause.

**Message Structure**:

```json
{
  "unpause": {}
}
```

**Governance Proposal JSON**:

```json
{
  "messages": [
    {
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      "sender": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
      "contract": "terra1j04kamuwssgckj7592w5v3hlttmlqlu9cqkzvvxsjt8rqyt3stps0xan5l",
      "msg": {
        "unpause": {}
      },
      "funds": []
    }
  ],
  "metadata": "Resume Hyperlane message sending after maintenance",
  "deposit": "10000000uluna",
  "title": "Unpause Hyperlane Messages",
  "summary": "Resume normal operations after security audit completion",
  "expedited": false
}
```

---

## How to Submit Proposals

### Method 1: Using proposal.json file

1. **Create proposal JSON file** (e.g., `my-proposal.json`) with the structure shown in examples above

2. **Submit via CLI**:

```bash
terrad tx gov submit-proposal my-proposal.json \
  --from <your-wallet-name> \
  --chain-id rebel-2 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 28.5uluna \
  --node https://rpc.luncblaze.com:443 \
  -y
```

### Method 2: Using the script

1. **Modify** `submit-proposal-testnet.ts` with your desired changes

2. **Run the script**:

```bash
PRIVATE_KEY="your-private-key" npx tsx script/submit-proposal-testnet.ts
```

3. **Submit generated proposal**:

```bash
terrad tx gov submit-proposal proposal_testnet.json \
  --from <your-wallet-name> \
  --chain-id rebel-2 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 28.5uluna \
  --node https://rpc.luncblaze.com:443 \
  -y
```

### Voting on Proposals

After submission, validators and delegators must vote:

```bash
# Vote YES
terrad tx gov vote <PROPOSAL_ID> yes \
  --from <your-wallet-name> \
  --chain-id rebel-2 \
  --gas auto \
  --gas-prices 28.5uluna \
  --node https://rpc.luncblaze.com:443 \
  -y

# Vote NO
terrad tx gov vote <PROPOSAL_ID> no \
  --from <your-wallet-name> \
  --chain-id rebel-2 \
  --gas auto \
  --gas-prices 28.5uluna \
  --node https://rpc.luncblaze.com:443 \
  -y
```

### Check Proposal Status

```bash
terrad query gov proposal <PROPOSAL_ID> \
  --node https://rpc.luncblaze.com:443 \
  --chain-id rebel-2
```

---

## Best Practices

1. **Test First**: Always test changes on testnet before proposing for mainnet
2. **Clear Documentation**: Provide detailed explanation in proposal summary
3. **Community Discussion**: Discuss significant changes with community before proposing
4. **Emergency Procedures**: Use `expedited: true` only for critical security issues
5. **Validator Coordination**: Coordinate with validators before submitting validator changes
6. **Rate Monitoring**: Regularly monitor exchange rates and gas prices for accuracy
7. **Fee Analysis**: Analyze transaction volume and costs before changing fees

---

## Common Operations Summary

| Operation | Contract | Frequency | Urgency |
|-----------|----------|-----------|---------|
| Update Validators | ISM Multisig | Monthly | Medium |
| Update Exchange Rates | IGP Oracle | Weekly | High |
| Update Gas Prices | IGP Oracle | Weekly | High |
| Adjust Fees | Hook Fee | Quarterly | Low |
| Emergency Pause | Hook Pausable | As needed | Critical |
| Update Routes | IGP | Rarely | Low |
| Update ISM/Hooks | Mailbox | Rarely | Medium |

---

## Support and Resources

- **Official Documentation**: https://docs.hyperlane.xyz/
- **Testnet Artifacts**: See `TESTNET-ARTIFACTS.md`
- **Deployment Guide**: See `DEPLOYMENT-TERRACLASSIC.md`
- **Contract Repository**: https://github.com/many-things/cw-hyperlane

---

## Notes

- All validator addresses must be 40-character hexadecimal strings (20 bytes)
- Exchange rates and gas prices should be monitored and updated regularly
- The governance module address must always be used as sender in proposals
- Minimum proposal deposit: 10,000,000 uluna (10 LUNC)
- Voting period: Varies by chain governance parameters
- For mainnet operations, use appropriate mainnet contract addresses

