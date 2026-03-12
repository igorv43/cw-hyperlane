# Guia — Submissão de Proposta de Governança Hyperlane (Terra Classic Testnet)

> **Script**: `submit-proposal-testnet.ts`  
> **Localização**: `/home/lunc/cw-hyperlane/script-warp-terraclassic/submit-proposal-testnet.ts`  
> **Rede**: Terra Classic Testnet (`rebel-2`)

---

## Índice

1. [Visão Geral](#1--visão-geral)
2. [Pré-requisitos](#2--pré-requisitos)
3. [Estrutura de Arquivos](#3--estrutura-de-arquivos)
4. [Modos de Execução](#4--modos-de-execução)
5. [Como Executar](#5--como-executar)
6. [O que o Script Configura](#6--o-que-o-script-configura)
   - [MSG 1 — ISM Multisig BSC Testnet](#msg-1--ism-multisig-bsc-testnet-domínio-97)
   - [MSG 2 — ISM Multisig Sepolia](#msg-2--ism-multisig-sepolia-domínio-11155111)
   - [MSG 3 — ISM Multisig Solana](#msg-3--ism-multisig-solana-domínio-1399811150)
   - [MSG 4 — IGP Oracle (Exchange Rate e Gas Price)](#msg-4--igp-oracle-exchange-rate-e-gas-price)
   - [MSG 5 — IGP Rotas para Oracle](#msg-5--igp-rotas-para-oracle)
   - [MSG 6 — ISM Routing para Sepolia](#msg-6--ism-routing-para-sepolia)
   - [MSG 7 — Mailbox: Default ISM](#msg-7--mailbox-default-ism)
   - [MSG 8 — Mailbox: Default Hook](#msg-8--mailbox-default-hook)
   - [MSG 9 — Mailbox: Required Hook](#msg-9--mailbox-required-hook)
7. [Contratos Configurados](#7--contratos-configurados)
8. [Como Alterar ISM (Validators)](#8--como-alterar-ism-validators)
9. [Como Alterar IGP (Taxa de Câmbio e Gas Price)](#9--como-alterar-igp-taxa-de-câmbio-e-gas-price)
10. [Como Alterar Hooks](#10--como-alterar-hooks)
11. [Como Adicionar uma Nova Rede](#11--como-adicionar-uma-nova-rede)
12. [Submeter Proposta via CLI](#12--submeter-proposta-via-cli)
13. [Votar na Proposta](#13--votar-na-proposta)
14. [Verificar Execução](#14--verificar-execução)
15. [Arquivos Gerados](#15--arquivos-gerados)
16. [Troubleshooting](#16--troubleshooting)
17. [Links Úteis](#17--links-úteis)

---

## 1 — Visão Geral

O script `submit-proposal-testnet.ts` serve para **configurar os contratos Hyperlane no Terra Classic Testnet** de forma segura, via proposta de governança, ou diretamente para testes rápidos.

### O que ele faz

O script empacota 9 mensagens de execução de contrato em uma **proposta de governança** (ou executa diretamente), configurando:

| Componente | O que configura |
|---|---|
| **ISM Multisig** | Quais validadores assinam mensagens de cada rede remota |
| **ISM Routing** | Qual ISM Multisig usar para cada domínio de origem |
| **IGP Oracle** | Taxa de câmbio LUNC ↔ token remoto + gas price |
| **IGP** | Rotas para consultar Oracle ao calcular taxa de gás |
| **Mailbox** | ISM padrão, hook padrão e hook obrigatório |

### Diagrama de fluxo (mensagem recebida)

```
Mensagem chega (ex: Sepolia → TC)
       ↓
  Mailbox consulta ISM Routing
       ↓
  ISM Routing direciona para ISM_MULTISIG_SEP
       ↓
  ISM Multisig valida assinaturas do validador Sepolia
       ↓
  Mensagem entregue ao contrato destinatário (Warp)
```

### Diagrama de fluxo (mensagem enviada)

```
transfer_remote() chamado no Warp (TC → destino)
       ↓
  Mailbox executa Required Hook (Pausable + Fee)
       ↓
  Mailbox executa Default Hook (Merkle + IGP)
       ↓
  IGP calcula taxa → consulta Oracle → cobra LUNC do remetente
  Merkle registra a mensagem na árvore para o validador assinar
       ↓
  Mensagem emitida como evento
       ↓
  Validador assina o checkpoint → Relayer entrega no destino
```

---

## 2 — Pré-requisitos

### Software

```bash
# Node.js 18+
node --version

# npx + tsx
npm install -g tsx

# Dependências do projeto (instalar na pasta do script)
cd ~/cw-hyperlane/script-warp-terraclassic
npm install @cosmjs/cosmwasm-stargate @cosmjs/proto-signing @cosmjs/stargate
```

### Carteira

Você precisa de uma carteira Terra Classic com:
- Saldo de LUNC para pagar taxas de transação
- Em modo `proposal`: pelo menos **10 LUNC** para depósito inicial da proposta

### Chave privada

A chave privada deve ser configurada via variável de ambiente:

```bash
export TERRA_PRIVATE_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
# ou
export PRIVATE_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

> ⚠️ **NUNCA** coloque a chave privada diretamente no script ou em arquivos de configuração versionados!

---

## 3 — Estrutura de Arquivos

```
script-warp-terraclassic/
├── submit-proposal-testnet.ts     ← Script principal
├── exec_msgs_testnet.json         ← Gerado: mensagens individuais
├── proposal_testnet.json          ← Gerado: proposta formatada para terrad
└── doc/
    └── submit-proposal-guide.md  ← Este documento
```

---

## 4 — Modos de Execução

O script possui dois modos controlados pela variável de ambiente `MODE`:

### Modo `proposal` (padrão — recomendado para produção)

Gera os arquivos JSON com a proposta formatada e exibe o comando `terrad` para submetê-la. **Não executa nenhum contrato diretamente**.

```bash
# MODE=proposal é o padrão, não precisa definir
export TERRA_PRIVATE_KEY="xxxxxxxx..."
npx tsx submit-proposal-testnet.ts
```

### Modo `direct` (para testes rápidos)

Executa as mensagens diretamente na blockchain, sem passar por governança. Use apenas em testnet/desenvolvimento.

```bash
export MODE=direct
export TERRA_PRIVATE_KEY="xxxxxxxx..."
npx tsx submit-proposal-testnet.ts
```

> ⚠️ O modo `direct` só funciona se a carteira for a **owner/admin** dos contratos. Em produção, os contratos são gerenciados pelo módulo de governança (`terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n`).

---

## 5 — Como Executar

### Passo 1 — Instalar dependências

```bash
cd ~/cw-hyperlane/script-warp-terraclassic
npm install @cosmjs/cosmwasm-stargate @cosmjs/proto-signing @cosmjs/stargate
```

### Passo 2 — Configurar a chave privada

```bash
export TERRA_PRIVATE_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

### Passo 3 — Executar o script

```bash
npx tsx submit-proposal-testnet.ts
```

### Saída esperada (modo `proposal`)

```
================================================================================
PREPARING HYPERLANE GOVERNANCE PROPOSAL - TESTNET MULTI-CHAIN
================================================================================

📋 PROPOSAL INFORMATION:
────────────────────────────────────────────────────────────────────────────────
Title: Hyperlane Contracts Configuration - Testnet Multi-Chain

🌐 SUPPORTED CHAINS (TESTNET):
  • Sepolia Testnet (Domain 11155111) - 1/1 validator
  • BSC Testnet (Domain 97) - 2/3 validators
  • Solana Testnet (Domain 1399811150) - 1/1 validator

📝 EXECUTION MESSAGES (9 messages):
...

💾 SAVING FILES...
  ✓ exec_msgs_testnet.json
  ✓ proposal_testnet.json

🚀 COMMAND TO SUBMIT VIA CLI:
terrad tx gov submit-proposal proposal_testnet.json \
  --from hyperlane-testnet \
  --chain-id rebel-2 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 28.5uluna \
  --node https://rpc.luncblaze.com:443 \
  -y
```

---

## 6 — O que o Script Configura

### Fluxo geral das 9 mensagens

```
MSG 1  → ISM_MULTISIG_BSC   → set_validators (BSC, domínio 97)
MSG 2  → ISM_MULTISIG_SEP   → set_validators (Sepolia, domínio 11155111)
MSG 3  → ISM_MULTISIG_SOL   → set_validators (Solana, domínio 1399811150)
MSG 4  → IGP_ORACLE          → set_remote_gas_data_configs (3 redes)
MSG 5  → IGP                 → set_routes (3 redes → Oracle)
MSG 6  → ISM_ROUTING         → set (Sepolia → ISM_MULTISIG_SEP)
MSG 7  → MAILBOX             → set_default_ism (ISM Routing)
MSG 8  → MAILBOX             → set_default_hook (Merkle + IGP)
MSG 9  → MAILBOX             → set_required_hook (Pausable + Fee)
```

---

### MSG 1 — ISM Multisig BSC Testnet (Domínio 97)

**Contrato**: `terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv`

**O que faz**: Registra os 3 validadores que assinam mensagens vindas da BSC Testnet. O threshold de **2/3** significa que pelo menos 2 dos 3 precisam assinar.

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

**Como encontrar os validadores BSC**: Consulte o S3 do validador:
```
https://hyperlane-validator-signatures-igorveras-bsctestnet.s3.us-east-1.amazonaws.com/announcement.json
```

---

### MSG 2 — ISM Multisig Sepolia (Domínio 11155111)

**Contrato**: `terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa`

**O que faz**: Registra 1 validador para mensagens vindas do Sepolia. Threshold **1/1**.

```json
{
  "set_validators": {
    "domain": 11155111,
    "threshold": 1,
    "validators": [
      "133fd7f7094dbd17b576907d052a5acbd48db526"
    ]
  }
}
```

**Como encontrar o validador Sepolia**:
```
https://hyperlane-validator-signatures-igorveras-sepolia.s3.us-east-1.amazonaws.com/announcement.json
```

O campo `validator` no JSON de anúncio é o endereço do validador (sem `0x`).

---

### MSG 3 — ISM Multisig Solana (Domínio 1399811150)

**Contrato**: `terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a`

**O que faz**: Registra 1 validador para mensagens vindas do Solana Testnet. Threshold **1/1**.

```json
{
  "set_validators": {
    "domain": 1399811150,
    "threshold": 1,
    "validators": [
      "d4ce8fa138d4e083fc0e480cca0dbfa4f5f30bd5"
    ]
  }
}
```

**Como encontrar o validador Solana**:
```
https://hyperlane-validator-signatures-igorveras-terraclassic.s3.us-east-1.amazonaws.com/
```
> O validador do Solana que assina para TC está no anúncio do lado Terra Classic.

---

### MSG 4 — IGP Oracle (Exchange Rate e Gas Price)

**Contrato**: `terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg`

**O que faz**: Configura o preço do gás e a taxa de câmbio entre LUNC e o token nativo de cada rede de destino. O IGP usa esses dados para calcular quanto cobrar do remetente.

```json
{
  "set_remote_gas_data_configs": {
    "configs": [
      {
        "remote_domain": 11155111,
        "token_exchange_rate": "10000000000000000",
        "gas_price": "10000000000"
      },
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

**Fórmula de cálculo do custo**:
```
Custo em LUNC = (gas_usado_no_destino × gas_price × token_exchange_rate) / 1e10
```

**Como encontrar valores atualizados**:

| Rede | Consultar gas price |
|---|---|
| Sepolia | https://sepolia.etherscan.io/gastracker |
| BSC Testnet | https://testnet.bscscan.com/gastracker |
| Solana Testnet | https://explorer.solana.com/?cluster=testnet |

Para taxa de câmbio LUNC/ETH:
```bash
# Via CoinGecko (exemplo)
curl "https://api.coingecko.com/api/v3/simple/price?ids=terra-luna,ethereum&vs_currencies=usd"
```

> O `token_exchange_rate` é calculado como: `(preço_LUNC / preço_destino_token) × 1e18`  
> Exemplo: LUNC = 0.000088 USD, ETH = 1800 USD → rate = (0.000088/1800) × 1e18 ≈ 4.9e10

---

### MSG 5 — IGP Rotas para Oracle

**Contrato**: `terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9`

**O que faz**: Configura o IGP para consultar o IGP Oracle ao calcular taxas de gás para cada domínio remoto.

```json
{
  "router": {
    "set_routes": {
      "set": [
        { "domain": 11155111, "route": "terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg" },
        { "domain": 97,       "route": "terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg" },
        { "domain": 1399811150, "route": "terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg" }
      ]
    }
  }
}
```

---

### MSG 6 — ISM Routing para Sepolia

**Contrato**: `terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh`

**O que faz**: Registra no ISM Routing que mensagens vindas do domínio `11155111` (Sepolia) devem ser validadas pelo `ISM_MULTISIG_SEP`.

```json
{
  "set": {
    "ism": {
      "domain": 11155111,
      "address": "terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa"
    }
  }
}
```

> **Nota**: BSC e Solana já estão configurados no ISM Routing pelos scripts anteriores. Este passo adiciona Sepolia.

---

### MSG 7 — Mailbox: Default ISM

**Contrato**: `terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf`

**O que faz**: Define o ISM Routing como o módulo de segurança padrão do Mailbox. Toda mensagem recebida será validada pelo ISM Routing, que direciona para o ISM Multisig correto de acordo com o domínio de origem.

```json
{
  "set_default_ism": {
    "ism": "terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh"
  }
}
```

---

### MSG 8 — Mailbox: Default Hook

**Contrato**: `terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf`

**O que faz**: Define o **Hook Aggregate #1** como hook padrão para envio de mensagens. Este hook combina:
- **Merkle Hook**: Adiciona a mensagem à árvore de Merkle para que o validador possa assinar o checkpoint
- **IGP Hook**: Processa o pagamento de gás para execução no destino

```json
{
  "set_default_hook": {
    "hook": "terra14qjm9075m8djus4tl86lc5n2xnsvuazesl52vqyuz6pmaj4k5s5qu5q6jh"
  }
}
```

> ⚠️ **Importante**: O Merkle Hook é essencial! Se o hook padrão não incluir o Merkle Hook, o validador não conseguirá assinar os checkpoints e as mensagens nunca serão entregues.

---

### MSG 9 — Mailbox: Required Hook

**Contrato**: `terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf`

**O que faz**: Define o **Hook Aggregate #2** como hook obrigatório (sempre executado, não pode ser bypassado). Este hook combina:
- **Hook Pausable**: Permite pausar o envio de mensagens em emergências
- **Hook Fee**: Cobra uma taxa fixa de ~0.283215 LUNC por mensagem (anti-spam)

```json
{
  "set_required_hook": {
    "hook": "terra1xdpah0ven023jzd80qw0nkp4ndjxy4d7g5y99dhpfwetyal6q6jqpk42rj"
  }
}
```

---

## 7 — Contratos Configurados

### Tabela de endereços (Testnet `rebel-2`)

| Contrato | Endereço | Função |
|---|---|---|
| **Mailbox** | `terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf` | Hub central de mensagens |
| **ISM Routing** | `terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh` | Direciona para ISM correto por domínio |
| **ISM Multisig BSC** | `terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv` | Valida msgs da BSC Testnet (2/3) |
| **ISM Multisig Sepolia** | `terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa` | Valida msgs do Sepolia (1/1) |
| **ISM Multisig Solana** | `terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a` | Valida msgs do Solana (1/1) |
| **IGP** | `terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9` | Processa pagamento de gás |
| **IGP Oracle** | `terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg` | Fornece preços de gás por rede |
| **Hook Aggregate 1** | `terra14qjm9075m8djus4tl86lc5n2xnsvuazesl52vqyuz6pmaj4k5s5qu5q6jh` | Default hook (Merkle + IGP) |
| **Hook Aggregate 2** | `terra1xdpah0ven023jzd80qw0nkp4ndjxy4d7g5y99dhpfwetyal6q6jqpk42rj` | Required hook (Pausable + Fee) |
| **Governance Module** | `terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n` | Owner dos contratos em produção |

---

## 8 — Como Alterar ISM (Validators)

### Cenário: Adicionar novo validador ao BSC (mudar de 2/3 para 3/4)

**No script** (`submit-proposal-testnet.ts`), localize a MSG 1 e altere:

```typescript
// Antes (2/3)
set_validators: {
  domain: 97,
  threshold: 2,
  validators: [
    '242d8a855a8c932dec51f7999ae7d1e48b10c95e',
    'f620f5e3d25a3ae848fec74bccae5de3edcd8796',
    '1f030345963c54ff8229720dd3a711c15c554aeb',
  ],
},

// Depois (3/4)
set_validators: {
  domain: 97,
  threshold: 3,
  validators: [
    '242d8a855a8c932dec51f7999ae7d1e48b10c95e',
    'f620f5e3d25a3ae848fec74bccae5de3edcd8796',
    '1f030345963c54ff8229720dd3a711c15c554aeb',
    'NOVO_VALIDATOR_SEM_0X_PREFIX',              // ← novo
  ],
},
```

### Cenário: Verificar validators atuais no contrato

```bash
# Consultar validators configurados para BSC (domínio 97)
terrad query wasm contract-state smart \
  terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv \
  '{"get_validators":{"domain":97}}' \
  --node https://rpc.terra-classic.hexxagon.dev

# Consultar validators configurados para Sepolia (domínio 11155111)
terrad query wasm contract-state smart \
  terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa \
  '{"get_validators":{"domain":11155111}}' \
  --node https://rpc.terra-classic.hexxagon.dev
```

### Cenário: Adicionar suporte a nova rede (ex: Avalanche Fuji, domínio 43113)

1. **Descobrir o endereço do validador** — Consulte o S3 do validador Avalanche:
   ```
   https://hyperlane-validator-signatures-<nome>-avalanchefuji.s3.us-east-1.amazonaws.com/announcement.json
   ```

2. **Criar novo contrato ISM Multisig** para o domínio (via governance ou script de deploy)

3. **Adicionar nova constante no script**:
   ```typescript
   const ISM_MULTISIG_AVAX = 'terra1...novo_contrato...';
   ```

4. **Adicionar nova MSG de set_validators**:
   ```typescript
   {
     contractAddress: ISM_MULTISIG_AVAX,
     description: 'Configure multisig validators for Avalanche Fuji (domain 43113)',
     msg: {
       set_validators: {
         domain: 43113,
         threshold: 1,
         validators: ['ENDERECO_VALIDADOR_SEM_0X'],
       },
     },
   },
   ```

5. **Adicionar MSG de ISM Routing** para mapear o novo domínio ao ISM_MULTISIG_AVAX

---

## 9 — Como Alterar IGP (Taxa de Câmbio e Gas Price)

### Conceitos

| Campo | Unidade | Descrição |
|---|---|---|
| `token_exchange_rate` | `1e18` base | Razão entre o preço do LUNC e o token nativo do destino |
| `gas_price` | wei / lamports | Gas price na rede destino |

### Fórmula para calcular `token_exchange_rate`

```
token_exchange_rate = (preço_LUNC_USD / preço_token_destino_USD) × 1e18
```

**Exemplos**:
- LUNC = $0.000088, ETH = $1800 → rate = (0.000088/1800) × 1e18 ≈ `49000000000000`
- LUNC = $0.000088, BNB = $250 → rate = (0.000088/250) × 1e18 ≈ `352000000000000`
- LUNC = $0.000088, SOL = $130 → rate = (0.000088/130) × 1e18 ≈ `677000000000000`

### Como alterar no script

Localize MSG 4 em `submit-proposal-testnet.ts` e edite os valores:

```typescript
{
  contractAddress: IGP_ORACLE,
  msg: {
    set_remote_gas_data_configs: {
      configs: [
        {
          remote_domain: 11155111,
          token_exchange_rate: '49000000000000',  // ← atualizar
          gas_price: '15000000000',               // ← 15 Gwei
        },
        // ...
      ],
    },
  },
},
```

### Alterar manualmente via `terrad` (sem proposta)

Se você for o admin/owner do contrato:

```bash
terrad tx wasm execute terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg \
  '{
    "set_remote_gas_data_configs": {
      "configs": [
        {
          "remote_domain": 11155111,
          "token_exchange_rate": "49000000000000",
          "gas_price": "15000000000"
        }
      ]
    }
  }' \
  --from <sua-carteira> \
  --chain-id rebel-2 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 28.5uluna \
  --node https://rpc.luncblaze.com:443 \
  -y
```

### Verificar configuração atual do Oracle

```bash
# Consultar gas data para Sepolia (11155111)
terrad query wasm contract-state smart \
  terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg \
  '{"get_remote_gas_data":{"domain":11155111}}' \
  --node https://rpc.terra-classic.hexxagon.dev

# Consultar gas data para BSC (97)
terrad query wasm contract-state smart \
  terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg \
  '{"get_remote_gas_data":{"domain":97}}' \
  --node https://rpc.terra-classic.hexxagon.dev
```

---

## 10 — Como Alterar Hooks

### O que é um Hook?

Um Hook é executado toda vez que uma mensagem é **enviada** pelo Mailbox. Existem dois tipos:
- **Default Hook**: Executado para todas as mensagens (contém Merkle + IGP)
- **Required Hook**: Sempre executado antes do default (contém Pausable + Fee)

### Cenário: Verificar hooks atuais

```bash
# Verificar ISM padrão
terrad query wasm contract-state smart \
  terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf \
  '{"default_ism":{}}' \
  --node https://rpc.terra-classic.hexxagon.dev

# Verificar hook padrão
terrad query wasm contract-state smart \
  terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf \
  '{"default_hook":{}}' \
  --node https://rpc.terra-classic.hexxagon.dev

# Verificar hook obrigatório
terrad query wasm contract-state smart \
  terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf \
  '{"required_hook":{}}' \
  --node https://rpc.terra-classic.hexxagon.dev
```

### Cenário: Trocar o Default Hook

No script, localize MSG 8 e altere o endereço do hook:

```typescript
{
  contractAddress: MAILBOX,
  msg: {
    set_default_hook: {
      hook: 'terra1...novo_hook_address...',  // ← novo endereço
    },
  },
},
```

> ⚠️ **Atenção**: O novo hook deve **sempre incluir o Merkle Hook** (`terra1x9ftmmyj0t9n0ql78r2vdfk9stxg5z6vnwnwjym9m7py6lvxz8ls7sa3df`). Sem ele, o validador não consegue assinar checkpoints e as mensagens não são entregues.

### Alterar hook manualmente via `terrad`

```bash
terrad tx wasm execute terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf \
  '{"set_default_hook":{"hook":"terra1...novo_hook..."}}' \
  --from <sua-carteira> \
  --chain-id rebel-2 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 28.5uluna \
  --node https://rpc.luncblaze.com:443 \
  -y
```

### Endereços dos hooks individuais (referência)

| Hook | Endereço | Função |
|---|---|---|
| **Merkle Hook** | `terra1x9ftmmyj0t9n0ql78r2vdfk9stxg5z6vnwnwjym9m7py6lvxz8ls7sa3df` | Registra msgs no Merkle tree |
| **Hook Pausable** | `terra1j04kamuwssgckj7592w5v3hlttmlqlu9cqkzvvxsjt8rqyt3stps0xan5l` | Pausa envio em emergências |
| **Hook Fee** | `terra13y6vseryqqj09uu9aagk8xks4dr9fr2p0xr3w6gngdzjd362h54sz5fr3j` | Cobra taxa fixa por mensagem |
| **Hook Agg #1** | `terra14qjm9075m8djus4tl86lc5n2xnsvuazesl52vqyuz6pmaj4k5s5qu5q6jh` | Merkle + IGP (default) |
| **Hook Agg #2** | `terra1xdpah0ven023jzd80qw0nkp4ndjxy4d7g5y99dhpfwetyal6q6jqpk42rj` | Pausable + Fee (required) |

---

## 11 — Como Adicionar uma Nova Rede

Para adicionar suporte a uma nova rede EVM (ex: Polygon Mumbai, domínio `80001`):

### Passo 1 — Obter o endereço do validador

```bash
curl https://hyperlane-validator-signatures-<nome>-mumbai.s3.us-east-1.amazonaws.com/announcement.json
# O campo "validator" contém o endereço (sem 0x)
```

### Passo 2 — Criar ISM Multisig para a nova rede

```bash
# Via Hyperlane CLI (em EVM) ou cw-hpl CLI (em TC)
# Ou verificar se já existe um contrato reutilizável
```

### Passo 3 — Atualizar o script

```typescript
// 1. Adicionar constante
const ISM_MULTISIG_MUMBAI = 'terra1...novo_contrato...';

// 2. Adicionar MSG para set_validators
{
  contractAddress: ISM_MULTISIG_MUMBAI,
  description: 'Configure multisig for Mumbai (domain 80001)',
  msg: {
    set_validators: {
      domain: 80001,
      threshold: 1,
      validators: ['ENDERECO_VALIDATOR_SEM_0X'],
    },
  },
},

// 3. Adicionar ao IGP Oracle (MSG 4)
{
  remote_domain: 80001,
  token_exchange_rate: '...',  // LUNC/MATIC exchange rate × 1e18
  gas_price: '...',
},

// 4. Adicionar às rotas IGP (MSG 5)
{ domain: 80001, route: IGP_ORACLE },

// 5. Adicionar ao ISM Routing (nova MSG)
{
  contractAddress: ISM_ROUTING,
  msg: {
    set: {
      ism: {
        domain: 80001,
        address: ISM_MULTISIG_MUMBAI,
      },
    },
  },
},
```

---

## 12 — Submeter Proposta via CLI

Após executar o script no modo `proposal`, dois arquivos são gerados. Use-os para submeter a proposta:

```bash
# 1. Revisar o arquivo da proposta
cat proposal_testnet.json

# 2. Submeter a proposta
terrad tx gov submit-proposal proposal_testnet.json \
  --from hyperlane-testnet \
  --chain-id rebel-2 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 28.5uluna \
  --node https://rpc.luncblaze.com:443 \
  -y

# 3. Anotar o PROPOSAL_ID exibido na saída
# Procure por: proposal_id: "XX"
```

> 💡 Para submeter você precisa de pelo menos **10 LUNC** na carteira para o depósito inicial.

---

## 13 — Votar na Proposta

```bash
# Listar propostas ativas
terrad query gov proposals \
  --status voting_period \
  --node https://rpc.luncblaze.com:443

# Votar YES na proposta (substitua <ID> pelo número)
terrad tx gov vote <ID> yes \
  --from hyperlane-testnet \
  --chain-id rebel-2 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 28.5uluna \
  --node https://rpc.luncblaze.com:443 \
  -y

# Verificar resultado da votação
terrad query gov proposal <ID> \
  --node https://rpc.luncblaze.com:443
```

---

## 14 — Verificar Execução

Após aprovação da proposta, verifique se os contratos foram configurados corretamente:

### Verificar ISM padrão no Mailbox

```bash
terrad query wasm contract-state smart \
  terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf \
  '{"default_ism":{}}' \
  --node https://rpc.terra-classic.hexxagon.dev
# Deve retornar o endereço do ISM Routing
```

### Verificar validators do BSC

```bash
terrad query wasm contract-state smart \
  terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv \
  '{"get_validators":{"domain":97}}' \
  --node https://rpc.terra-classic.hexxagon.dev
```

### Verificar oracle para Sepolia

```bash
terrad query wasm contract-state smart \
  terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg \
  '{"get_remote_gas_data":{"domain":11155111}}' \
  --node https://rpc.terra-classic.hexxagon.dev
```

### Verificar hook padrão do Mailbox

```bash
terrad query wasm contract-state smart \
  terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf \
  '{"default_hook":{}}' \
  --node https://rpc.terra-classic.hexxagon.dev
# Deve retornar o endereço do Hook Aggregate #1
```

---

## 15 — Arquivos Gerados

| Arquivo | Descrição |
|---|---|
| `exec_msgs_testnet.json` | Array com todas as mensagens de execução individuais |
| `proposal_testnet.json` | Proposta completa no formato esperado pelo `terrad` |

### Exemplo de `proposal_testnet.json`

```json
{
  "messages": [
    {
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      "sender": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
      "contract": "terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv",
      "msg": { "set_validators": { "domain": 97, "threshold": 2, "validators": ["..."] } },
      "funds": []
    }
  ],
  "metadata": "Initial configuration of Hyperlane contracts for testnet multi-chain support",
  "deposit": "10000000uluna",
  "title": "Hyperlane Contracts Configuration - Testnet Multi-Chain",
  "summary": "...",
  "expedited": false
}
```

---

## 16 — Troubleshooting

### ❌ `ERROR: Set the PRIVATE_KEY environment variable.`

**Causa**: A chave privada não foi configurada.

**Solução**:
```bash
export TERRA_PRIVATE_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
# ou
export PRIVATE_KEY="xxxxxxxx..."
```

---

### ❌ `Error: Account 'terra1...' does not exist on chain`

**Causa**: A carteira associada à chave privada não tem saldo ou não foi ativada na rede.

**Solução**: Envie LUNC para a carteira:
```bash
terrad query bank balances terra1... --node https://rpc.terra-classic.hexxagon.dev
```

---

### ❌ `out of gas in location: wasm contract`

**Causa**: Gas insuficiente para executar todas as 9 mensagens em sequência.

**Solução** (modo direct): O script usa `'auto'` para estimar gas automaticamente. Certifique-se de ter saldo suficiente.

**Solução** (via terrad CLI): Aumente o `--gas-adjustment`:
```bash
terrad tx gov submit-proposal proposal_testnet.json \
  --gas auto \
  --gas-adjustment 2.0 \
  ...
```

---

### ❌ `failed to execute message: unauthorized`

**Causa**: A carteira não tem permissão para executar os contratos diretamente (modo `direct`).

**Solução**: Em produção, use o modo `proposal` para submeter via governança. Os contratos aceitam somente mensagens com `sender = terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n` (módulo de governança).

---

### ❌ `Cannot find module '@cosmjs/cosmwasm-stargate'`

**Causa**: Dependências não instaladas.

**Solução**:
```bash
cd ~/cw-hyperlane/script-warp-terraclassic
npm install @cosmjs/cosmwasm-stargate @cosmjs/proto-signing @cosmjs/stargate
```

---

### ❌ Proposta aprovada mas contratos não foram configurados

**Causa**: Pode ser um erro no formato das mensagens no `proposal_testnet.json`, ou o contrato rejeitou a execução.

**Diagnóstico**: Consulte o TX hash da execução da proposta no explorer:
```
https://finder.hexxagon.io/rebel-2/
```

---

## 17 — Links Úteis

### Explorers

| Rede | Explorer |
|---|---|
| Terra Classic Testnet | https://finder.hexxagon.io/rebel-2/ |
| Sepolia | https://sepolia.etherscan.io |
| BSC Testnet | https://testnet.bscscan.com |
| Solana Testnet | https://explorer.solana.com/?cluster=testnet |

### Contratos on-chain (Testnet)

| Contrato | Explorer Link |
|---|---|
| Mailbox | https://finder.hexxagon.io/rebel-2/address/terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf |
| ISM Routing | https://finder.hexxagon.io/rebel-2/address/terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh |
| ISM Multisig BSC | https://finder.hexxagon.io/rebel-2/address/terra1rrt0kepmazvavmkusvz6589l5yg4mqjk49netqfqttnmf2y4exmqxhp0hv |
| ISM Multisig Sepolia | https://finder.hexxagon.io/rebel-2/address/terra1mzkakdts4958dyks72saw9wgas2eqmmxpuqc8gut2jvt9xuj8qzqc03vxa |
| ISM Multisig Solana | https://finder.hexxagon.io/rebel-2/address/terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a |
| IGP | https://finder.hexxagon.io/rebel-2/address/terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9 |
| IGP Oracle | https://finder.hexxagon.io/rebel-2/address/terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg |

### S3 dos Validadores

| Validador | URL |
|---|---|
| Terra Classic | https://hyperlane-validator-signatures-igorveras-terraclassic.s3.us-east-1.amazonaws.com/ |
| Sepolia | https://hyperlane-validator-signatures-igorveras-sepolia.s3.us-east-1.amazonaws.com/ |
| BSC Testnet | https://hyperlane-validator-signatures-igorveras-bsctestnet.s3.us-east-1.amazonaws.com/ |

### Documentação Hyperlane

- https://docs.hyperlane.xyz/docs/reference/messaging/messaging-interface
- https://docs.hyperlane.xyz/docs/reference/ISM/multisig-ISM
- https://docs.hyperlane.xyz/docs/reference/hooks/interchain-gas

### RPC Nodes Terra Classic

| Endpoint | Provider |
|---|---|
| `https://rpc.terra-classic.hexxagon.dev` | Hexxagon |
| `https://rpc.luncblaze.com:443` | LuncBlaze |
| `https://terra-classic-rpc.publicnode.com` | PublicNode |
