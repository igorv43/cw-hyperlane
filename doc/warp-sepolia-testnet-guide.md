# 🚀 Guia Completo: Criar Warp Route na Sepolia Testnet

Este documento descreve **passo a passo** como criar e configurar um Warp Route na Ethereum Sepolia Testnet conectado à Terra Classic Testnet (rebel-2), incluindo a configuração completa de **ISM (Interchain Security Module)**, **Hook** e **IGP (Interchain Gas Paymaster)**.

---

## 📋 Índice

1. [Visão Geral da Arquitetura](#visão-geral-da-arquitetura)
2. [Pré-requisitos](#pré-requisitos)
3. [Configuração da Sepolia Testnet](#configuração-da-sepolia-testnet)
4. [Deploy do Warp Route na Sepolia](#deploy-do-warp-route-na-sepolia)
5. [Configuração do ISM (Interchain Security Module)](#configuração-do-ism)
6. [Configuração do Hook](#configuração-do-hook)
7. [Configuração do IGP (Interchain Gas Paymaster)](#configuração-do-igp)
8. [Configuração no Lado Terra Classic](#configuração-no-lado-terra-classic)
9. [Vinculação dos Warp Routes (Enroll Remote Router)](#vinculação-dos-warp-routes)
10. [Verificação e Testes](#verificação-e-testes)
11. [Endereços Deployados (Referência)](#endereços-deployados)
12. [Troubleshooting](#troubleshooting)

---

## 🏗️ Visão Geral da Arquitetura

O Warp Route é uma ponte de tokens cross-chain que funciona sobre o protocolo **Hyperlane**. Para a rota **Terra Classic ↔ Sepolia**, a arquitetura consiste em:

```
┌──────────────────────────────────────────────────────────────────┐
│                    TERRA CLASSIC TESTNET (rebel-2)               │
│                       Domain ID: 1325                            │
│                                                                  │
│  ┌─────────────┐    ┌─────────────┐    ┌──────────────────────┐ │
│  │  Mailbox    │    │ Warp Route  │    │   ISM Routing        │ │
│  │  (hpl_      │◄──►│ hpl_warp_  │    │   (hpl_ism_routing)  │ │
│  │  mailbox)   │    │ native)     │    │   Routes by domain   │ │
│  └──────┬──────┘    └─────────────┘    └──────────────────────┘ │
│         │                                                        │
│  ┌──────▼──────┐    ┌─────────────┐                             │
│  │  Default    │    │ Required    │                             │
│  │  Hook       │    │ Hook        │                             │
│  │ (Merkle+IGP)│    │(Pausable+Fe)│                             │
│  └──────┬──────┘    └─────────────┘                             │
│         │                                                        │
│  ┌──────▼──────┐                                                 │
│  │   IGP       │◄── IGP Oracle (preços Sepolia)                 │
│  └─────────────┘    exchange_rate + gas_price                   │
└──────────────────────────────────────────────────────────────────┘
                           │ Hyperlane
                    Relayers + Validators
                           │
┌──────────────────────────────────────────────────────────────────┐
│                     ETHEREUM SEPOLIA TESTNET                     │
│                       Domain ID: 11155111                        │
│                                                                  │
│  ┌─────────────┐    ┌─────────────┐    ┌──────────────────────┐ │
│  │  Mailbox    │◄──►│ Warp Route  │    │   ISM (Multisig)     │ │
│  │  (oficial   │    │ (Synthetic  │    │  messageIdMultisigIsm│ │
│  │  Hyperlane) │    │ ERC20 LUNC) │    │  validator: Abacus   │ │
│  └─────────────┘    └─────────────┘    └──────────────────────┘ │
│                                                                  │
│            IGP (TerraClassicIGP.sol)                            │
│            hookType = 4 (INTERCHAIN_GAS_PAYMASTER)              │
│            Domain: 1325, Exchange Rate + Gas Price               │
└──────────────────────────────────────────────────────────────────┘
```

### Componentes Principais

| Componente | Chain | Descrição |
|-----------|-------|-----------|
| **Warp Route (Sepolia)** | Ethereum Sepolia | Token ERC20 sintético de LUNC na Sepolia |
| **Warp Route (Terra)** | Terra Classic | Contrato nativo que faz bridge do uluna |
| **ISM (Sepolia)** | Ethereum Sepolia | Valida mensagens da Terra usando validadores |
| **IGP (Sepolia)** | Ethereum Sepolia | Paga gas da execução na Sepolia |
| **IGP Oracle (Terra)** | Terra Classic | Fornece taxa de câmbio LUNC/ETH para Sepolia |
| **Mailbox (Sepolia)** | Ethereum Sepolia | Contrato oficial Hyperlane de mensagens |

---

## 🔧 Pré-requisitos

### Ferramentas Necessárias

```bash
# Node.js v18 ou superior
node --version

# Yarn v4.1.0+
yarn --version

# Hyperlane CLI (para deploy EVM)
npm install -g @hyperlane-xyz/cli
hyperlane --version

# Foundry Cast (opcional, para verificações)
# https://getfoundry.sh/
cast --version
```

### Tokens Necessários

| Chain | Token | Onde Obter |
|-------|-------|-----------|
| **Ethereum Sepolia** | ETH (Sepolia) | https://sepoliafaucet.com/ ou https://www.alchemy.com/faucets/ethereum-sepolia |
| **Terra Classic Testnet** | LUNC (uluna) | Faucet da comunidade ou peers de teste |

### Carteiras Necessárias

- **Carteira Ethereum (MetaMask)** com ETH na Sepolia
- **Carteira Terra Classic** com LUNC no testnet (rebel-2)
- Chaves privadas disponíveis para scripts

### Configuração de Variáveis de Ambiente

```bash
# Chave privada da carteira EVM (Sepolia) - sem o prefixo 0x
export ETH_PRIVATE_KEY="sua_chave_privada_ethereum_aqui"

# Chave privada da carteira Terra Classic
export PRIVATE_KEY="sua_chave_privada_terra_aqui"
```

> ⚠️ **NUNCA** compartilhe ou comite chaves privadas no controle de versão!

---

## 🌐 Configuração da Sepolia Testnet

### Informações da Rede

| Parâmetro | Valor |
|-----------|-------|
| **Nome** | Ethereum Sepolia Testnet |
| **Chain ID** | 11155111 |
| **Domain ID (Hyperlane)** | 11155111 |
| **RPC URL** | https://rpc.sepolia.org ou https://ethereum-sepolia.publicnode.com |
| **Explorer** | https://sepolia.etherscan.io |
| **Faucet** | https://sepoliafaucet.com |

### Contratos Hyperlane Oficiais na Sepolia

O protocolo Hyperlane já possui contratos oficiais deployados na Sepolia. O CLI usa automaticamente esses endereços do [Hyperlane Registry](https://github.com/hyperlane-xyz/hyperlane-registry/tree/main/chains/sepolia).

| Contrato | Endereço |
|---------|---------|
| **Mailbox** | Consultado automaticamente pelo CLI |
| **Merkle Tree Hook** | Consultado automaticamente pelo CLI |
| **ISM Padrão** | Consultado automaticamente pelo CLI |

> 💡 Não é necessário deployar a infraestrutura Hyperlane na Sepolia — ela já existe!

---

## 📦 Deploy do Warp Route na Sepolia

O Warp Route na Sepolia será um **token ERC20 sintético** que representa o LUNC (Terra Classic) na Ethereum Sepolia.

### Passo 1: Criar o Arquivo de Configuração

Crie o arquivo `warp-sepolia.yaml` com as configurações do Warp Route:

```yaml
sepolia:
  isNft: false
  type: synthetic
  name: "Wrapped Terra Classic LUNC"
  symbol: "LUNC"
  decimals: 6
  owner: "0xSEU_ENDERECO_ETHEREUM_AQUI"
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "8804770d6a346210c0fd011258fdf3ab0a5bb0d0"
    threshold: 1
```

> 📁 O projeto já possui este arquivo em `warp-sepolia.yaml` com a configuração oficial.

**Explicação dos Campos:**

| Campo | Descrição |
|-------|-----------|
| `isNft` | `false` para token fungível (ERC20) |
| `type: synthetic` | Token criado na Sepolia representando o LUNC da Terra |
| `name` | Nome completo do token |
| `symbol` | Símbolo do token |
| `decimals: 6` | Mesma precisão do LUNC na Terra Classic |
| `owner` | Endereço que controla o contrato (pode atualizar ISM, Hook, etc.) |
| `validators` | Endereços dos validadores que assinarão mensagens da Terra Classic |
| `threshold: 1` | Mínimo de assinaturas necessárias para validar mensagens |

### Passo 2: Deploy via Hyperlane CLI

```bash
cd /home/lunc/cw-hyperlane

# Deploy do Warp Route na Sepolia
hyperlane warp deploy \
  --config warp-sepolia.yaml \
  --private-key $ETH_PRIVATE_KEY
```

**O que acontece durante o deploy:**
1. O CLI cria um contrato ERC20 sintético na Sepolia
2. Configura o ISM especificado (ou cria um novo `messageIdMultisigIsm`)
3. Conecta o contrato ao Mailbox oficial da Hyperlane na Sepolia

### Passo 3: Salvar o Endereço do Warp Route

Após o deploy, o CLI mostrará o endereço do contrato. Anote-o:

```
✅ Deployed warp route on sepolia:
  Token: 0xABCDEF1234567890...
```

> 📌 **Referência do Projeto**: O endereço deployado é `0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4`

---

## 🔐 Configuração do ISM

O **ISM (Interchain Security Module)** é responsável por **validar a autenticidade das mensagens** recebidas da Terra Classic. Sem uma ISM configurada corretamente, o Warp Route rejeitará transferências.

### Entendendo o ISM na Sepolia

Na Sepolia, o ISM utilizado é do tipo `messageIdMultisigIsm`, que requer que **validadores específicos assinem** as mensagens enviadas da Terra Classic.

### Configuração do ISM no arquivo warp-sepolia.yaml

O ISM é configurado diretamente no arquivo YAML durante o deploy:

```yaml
sepolia:
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "8804770d6a346210c0fd011258fdf3ab0a5bb0d0"  # Abacus Works Validator
    threshold: 1
```

**Parâmetros do ISM:**

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| `type` | `messageIdMultisigIsm` | Tipo: valida por ID de mensagem + assinaturas |
| `validators` | Array de endereços hex | Validadores que assinarão as mensagens |
| `threshold` | `1` | Mínimo de assinaturas (1 de 1 validadores) |

> ⚠️ **Atenção**: O endereço do validador é em formato hexadecimal **sem** o prefixo `0x` no YAML.

### Atualizar o ISM em um Warp Route Existente

Se precisar atualizar o ISM de um Warp Route já deployado, use `hyperlane warp apply`:

**1. Crie o arquivo `warp/warp.json`:**

```json
{
  "tokens": [
    {
      "chainName": "sepolia",
      "standard": "ERC20",
      "addressOrDenom": "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4",
      "name": "Wrapped Terra Classic LUNC",
      "symbol": "LUNC",
      "decimals": 6
    }
  ]
}
```

**2. Atualize `warp-sepolia.yaml` com o novo ISM:**

```yaml
sepolia:
  isNft: false
  type: synthetic
  name: "Wrapped Terra Classic LUNC"
  symbol: "LUNC"
  decimals: 6
  owner: "0x133fD7F7094DBd17b576907d052a5aCBd48dB526"
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "8804770d6a346210c0fd011258fdf3ab0a5bb0d0"
      - "NOVO_VALIDADOR_AQUI"  # Adicionar novo validador
    threshold: 2  # Atualizar threshold
```

**3. Aplique as mudanças:**

```bash
hyperlane warp apply \
  --config warp-sepolia.yaml \
  --warp ./warp/warp.json \
  --private-key $ETH_PRIVATE_KEY
```

### Verificar o ISM Configurado

```bash
# Verificar o ISM atual do Warp Route
cast call 0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4 \
  "interchainSecurityModule()(address)" \
  --rpc-url https://rpc.sepolia.org
```

---

## 🪝 Configuração do Hook

O **Hook** é executado toda vez que uma mensagem é **enviada** através do Warp Route. Para transferências Sepolia → Terra Classic, o Hook correto é o **Interchain Gas Paymaster (IGP)** com `hookType = 4`.

### Por Que o Hook é Crítico?

Sem o Hook IGP configurado corretamente:
- ❌ O front-end retorna o erro `"destination not supported"`
- ❌ O custo de gas não é calculado
- ❌ Transferências de Sepolia → Terra Classic não funcionam

### Opção A: Deploy de um IGP Customizado (Recomendado)

Como a infraestrutura oficial Hyperlane na Sepolia pode não ter configuração para o domain Terra Classic (1325), é necessário **deployar um contrato IGP customizado**.

#### Passo 1: Compilar o Contrato IGP

Use o Remix IDE ou Foundry para compilar e deployar o contrato:

```solidity
// TerraClassicIGPStandalone.sol
// Arquivo disponível em /home/lunc/cw-hyperlane/TerraClassicIGPStandalone.sol
```

#### Passo 2: Deploy via Remix IDE

1. Acesse [https://remix.ethereum.org](https://remix.ethereum.org)
2. Crie novo arquivo `TerraClassicIGPStandalone.sol`
3. Cole o conteúdo do arquivo `TerraClassicIGPStandalone.sol` do projeto
4. Compile com: **Solidity 0.8.22+**, Optimization **ON** (200 runs)
5. Deploy com MetaMask (rede Sepolia) e parâmetros:

```
_GASORACLE:   0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c
_GASOVERHEAD: 200000
_BENEFICIARY: 0x133fD7F7094DBd17b576907d052a5aCBd48dB526
```

#### Passo 3: Configurar o IGP para Terra Classic

Após o deploy, execute a configuração para o domain Terra Classic (1325):

```bash
# Usando cast (Foundry)
cast send $IGP_ADDRESS \
  "setDestinationGasConfig(uint32,address,uint96,uint128)" \
  1325 \
  "0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c" \
  200000 \
  38325000000 \
  --private-key $ETH_PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.org
```

**Parâmetros:**

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| `domain` | `1325` | Domain ID da Terra Classic |
| `gasOracle` | `0x7113Df4d1...` | Endereço do Gas Oracle oficial Hyperlane |
| `gasOverhead` | `200000` | Gas overhead para execução na Terra Classic |
| `exchangeRate` | `142244393` | Taxa de câmbio ETH/LUNC (escala 1e8) |

> 📌 **Referência**: Os valores acima são os usados no deploy bem-sucedido deste projeto.

#### Passo 4: Associar o IGP ao Warp Route

```bash
# Associar o IGP como hook do Warp Route
cast send $WARP_ROUTE_ADDRESS \
  "setHook(address)" \
  $IGP_ADDRESS \
  --private-key $ETH_PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.org
```

### Verificar o Hook Configurado

```bash
# Verificar o hook atual e seu tipo
cast call $WARP_ROUTE_ADDRESS \
  "hook()(address)" \
  --rpc-url https://rpc.sepolia.org

# Verificar o hookType (deve ser 4 para IGP)
cast call $IGP_ADDRESS \
  "hookType()(uint8)" \
  --rpc-url https://rpc.sepolia.org
# Output esperado: 4
```

> ✅ **hookType = 4** significa `INTERCHAIN_GAS_PAYMASTER` — o hook correto!

### Endereços dos Contratos (Referência do Projeto)

| Contrato | Endereço Sepolia | Descrição |
|---------|-----------------|-----------|
| **IGP Customizado** | `0xe0f137448c96b5f17759bce44c020db6bdc8e261` | IGP deployado para Terra Classic |
| **Gas Oracle** | `0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c` | Oracle de preços Hyperlane oficial |
| **Warp Route** | `0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4` | Token wLUNC na Sepolia |

---

## ⛽ Configuração do IGP

O **IGP (Interchain Gas Paymaster)** gerencia os **pagamentos de gas cross-chain**. Ele garante que quem envia tokens da Terra Classic para Sepolia pague o gas necessário para executar a transação na Sepolia.

### Arquitetura do IGP

O IGP tem **dois componentes** principais:

#### 1. IGP na Sepolia (EVM)

Contrato EVM que:
- Cobra o pagamento de gas antecipado
- Define `hookType = 4` (INTERCHAIN_GAS_PAYMASTER)
- Conecta a transferência ao relayer

#### 2. IGP na Terra Classic (CosmWasm)

Contratos CosmWasm que:
- **IGP Core** (`hpl_igp`): Gerencia pagamentos de gas na Terra
- **IGP Oracle** (`hpl_igp_oracle`): Fornece taxas de câmbio e preços de gas

### Configuração do IGP na Sepolia

#### Exchange Rate e Gas Price para Terra Classic

Os valores configurados no IGP da Sepolia para o domain Terra Classic (1325):

```
Exchange Rate: 142244393  (taxa de câmbio ETH/LUNC, escala 1e8)
Gas Price:     38325000000 wei (38.325 Gwei)
```

**Como calcular o Exchange Rate correto:**

```bash
# Fórmula:
# exchange_rate = (origin_gas_token_price_USD / dest_gas_token_price_USD) * TOKEN_EXCHANGE_RATE_SCALE

# Exemplo:
# ETH price:  $3,500 USD
# LUNC price: $0.00006069 USD
# Scale:      1e8 (para Sepolia IGP)

# exchange_rate = (3500 / 0.00006069) * 1e-2
#               ≈ 142,244,393

# Gas Price na Sepolia (em wei):
# 38,325,000,000 wei = 38.325 Gwei (verificar atual em etherscan)
```

#### Transações para Configurar o IGP

```bash
# 1. Deploy do IGP (TerraClassicIGPStandalone.sol)
# Ver seção "Configuração do Hook"

# 2. Configurar taxa de câmbio e gas price
cast send $IGP_ADDRESS \
  "setRemoteGasData(uint32,uint128,uint128)" \
  1325 \
  38325000000 \
  142244393 \
  --private-key $ETH_PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.org

# 3. Verificar configuração
cast call $IGP_ADDRESS \
  "destinationGasConfigs(uint32)(address,uint96,uint128)" \
  1325 \
  --rpc-url https://rpc.sepolia.org
```

### Configuração do IGP Oracle na Terra Classic

O **IGP Oracle** na Terra Classic fornece dados de preço para calcular quanto LUNC cobrar para pagar o gas na Sepolia.

#### Endereços do IGP na Terra Classic

```bash
# IGP Core (Router)
IGP="terra1mcaqgr7kqs9xr3q6w0e9f2ekrj6sehwcep9shtss6u8pdz2rsw5qzrew7r"

# IGP Oracle
IGP_ORACLE="terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds"
```

#### Passo 1: Configurar o IGP Oracle para Sepolia (Domain 11155111)

```bash
# Verificar owner do IGP Oracle
terrad query wasm contract-state smart $IGP_ORACLE \
  '{"ownable":{"get_owner":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq -r '.data.owner'
```

**Atualização direta (se você for o owner):**

```bash
# Valores recomendados para Sepolia
EXCHANGE_RATE="177534"    # Taxa de câmbio LUNC:ETH (escala 1e10 para CosmWasm)
GAS_PRICE="1000000000"   # 1 Gwei = 1,000,000,000 wei

terrad tx wasm execute $IGP_ORACLE \
  "{\"set_remote_gas_data_configs\":{\"configs\":[{\"remote_domain\":11155111,\"token_exchange_rate\":\"${EXCHANGE_RATE}\",\"gas_price\":\"${GAS_PRICE}\"}]}}" \
  --from sua-key-name \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

> 💡 **Nota sobre escala**: No CosmWasm, o `token_exchange_rate` usa escala `10^10`, diferente do EVM que usa `10^8`.

#### Passo 2: Configurar Rota no IGP Router para Sepolia

```bash
# Verificar se a rota já existe
terrad query wasm contract-state smart $IGP \
  '{"router":{"get_route":{"domain":11155111}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443

# Se não existir, configurar a rota
terrad tx wasm execute $IGP \
  "{\"router\":{\"set_routes\":{\"set\":[{\"domain\":11155111,\"route\":\"$IGP_ORACLE\"}]}}}" \
  --from sua-key-name \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

#### Passo 3: Verificar Configuração do IGP Oracle

```bash
# Verificar taxa de câmbio e gas price para Sepolia
terrad query wasm contract-state smart $IGP_ORACLE \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":11155111}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq '.data'
```

**Saída esperada:**
```json
{
  "exchange_rate": "177534",
  "gas_price": "1000000000"
}
```

#### Passo 4: Verificar Rota do IGP Router

```bash
terrad query wasm contract-state smart $IGP \
  '{"router":{"get_route":{"domain":11155111}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

**Saída esperada:**
```json
{
  "data": {
    "route": {
      "domain": 11155111,
      "route": "terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds"
    }
  }
}
```

### Cálculo do Exchange Rate para o IGP

**Fórmula para CosmWasm (escala 1e10):**

```
exchange_rate = (LUNC_units_needed × TOKEN_EXCHANGE_RATE_SCALE) / (gas_amount × gas_price)

Onde:
  TOKEN_EXCHANGE_RATE_SCALE = 10^10 (CosmWasm)
  gas_amount = 200,000 (gas para executar na Sepolia)
  gas_price  = 1,000,000,000 wei (1 Gwei)
```

**Script de cálculo:**

```bash
#!/bin/bash
# Calcular exchange_rate para IGP Oracle (Terra Classic → Sepolia)

GAS_LIMIT=200000             # Gas para executar na Sepolia
GAS_PRICE_GWEI=1             # Gas price em Gwei
ETH_PRICE_USD=3500           # Preço ETH em USD
LUNC_PRICE_USD=0.00006069    # Preço LUNC em USD
MARGEM=1.20                  # 20% de margem para relayers

# Calcular custo em ETH
GAS_PRICE_WEI=$((GAS_PRICE_GWEI * 1000000000))
COST_ETH=$(echo "scale=18; $GAS_LIMIT * $GAS_PRICE_WEI / 1000000000000000000" | bc)

# Converter para USD
COST_USD=$(echo "$COST_ETH * $ETH_PRICE_USD" | bc)

# Converter para LUNC
COST_LUNC=$(echo "$COST_USD / $LUNC_PRICE_USD" | bc)

# Converter para uluna
COST_ULUNA=$(echo "$COST_LUNC * 1000000" | bc | cut -d. -f1)

# Adicionar margem
COST_ULUNA_MARGEM=$(echo "$COST_ULUNA * $MARGEM" | bc | cut -d. -f1)

# Calcular exchange_rate
TOKEN_EXCHANGE_RATE_SCALE=10000000000
EXCHANGE_RATE=$(echo "($COST_ULUNA_MARGEM * $TOKEN_EXCHANGE_RATE_SCALE) / ($GAS_LIMIT * $GAS_PRICE_WEI)" | bc)

echo "=== Cálculo Exchange Rate para Sepolia ==="
echo "Gas Limit: $GAS_LIMIT"
echo "Gas Price: $GAS_PRICE_GWEI Gwei"
echo "Custo em ETH: $COST_ETH"
echo "Custo em USD: $COST_USD"
echo "Custo em LUNC: $COST_LUNC"
echo "Custo em uluna (com margem): $COST_ULUNA_MARGEM"
echo ""
echo "✅ Exchange Rate: $EXCHANGE_RATE"
```

---

## 🌍 Configuração no Lado Terra Classic

### Warp Route na Terra Classic

O Warp Route na Terra Classic usa o contrato `hpl_warp_native` que faz bridge do token nativo `uluna` (LUNC).

#### Endereços Importantes

```bash
# Warp Route Native (uluna) - Terra Classic Testnet
WARP_TERRA="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"

# Mailbox - Terra Classic Testnet
MAILBOX="terra1s4jwfe0tcaztpfsct5wzj02esxyjy7e7lhkcwn5dp04yvly82rwsvzyqmm"
```

#### Verificar Configuração do Warp Route Terra

```bash
# Verificar owner do Warp Route
terrad query wasm contract-state smart $WARP_TERRA \
  '{"ownable":{"get_owner":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443

# Verificar hook configurado
terrad query wasm contract-state smart $WARP_TERRA \
  '{"warp":{"hook":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443

# Verificar ISM configurado
terrad query wasm contract-state smart $WARP_TERRA \
  '{"warp":{"ism":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

### Configurar ISM para Sepolia no Terra Classic

O Mailbox da Terra Classic precisa de uma ISM que valide mensagens **provenientes da Sepolia**.

#### Verificar ISM Routing

```bash
# Verificar o ISM padrão do Mailbox
terrad query wasm contract-state smart $MAILBOX \
  '{"mailbox":{"default_ism":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

#### Adicionar Sepolia ao ISM Routing (Via Governança)

Se a Sepolia ainda não estiver configurada no ISM Routing, crie uma proposta:

```json
{
  "messages": [
    {
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      "sender": "terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n",
      "contract": "terra1na6ljyf4m5x2u7llfvvxxe2nyq0t8628qyk0vnwu4ttpq86tt0cse47t68",
      "msg": {
        "route": {
          "set": {
            "set": [
              {
                "domain": 11155111,
                "route": "ENDEREÇO_ISM_MULTISIG_SEPOLIA"
              }
            ]
          }
        }
      },
      "funds": []
    }
  ],
  "title": "Add Sepolia to ISM Routing",
  "summary": "Configure ISM Routing to validate messages from Sepolia (domain 11155111)"
}
```

---

## 🔗 Vinculação dos Warp Routes

Após deployar o Warp Route em ambas as chains, é necessário **vincular os contratos** para que saibam para onde enviar/receber tokens.

### Passo 1: Vincular Sepolia → Terra Classic

```bash
# Via Hyperlane CLI
hyperlane warp apply \
  --config warp-sepolia.yaml \
  --warp ./warp/warp.json \
  --private-key $ETH_PRIVATE_KEY
```

Ou usando `cast` diretamente (enrollRemoteRouter):

```bash
# Converter endereço Terra Classic para formato bytes32
# terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml
# = 0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b

cast send $WARP_ROUTE_SEPOLIA \
  "enrollRemoteRouter(uint32,bytes32)" \
  1325 \
  "0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b" \
  --private-key $ETH_PRIVATE_KEY \
  --rpc-url https://rpc.sepolia.org
```

### Passo 2: Vincular Terra Classic → Sepolia

```bash
WARP_TERRA="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"

# Converter endereço Sepolia para formato bytes32
# 0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4
# = 0x000000000000000000000000224a4419d7fa69d3bebabce574c7c84b48d829b4

terrad tx wasm execute $WARP_TERRA \
  '{"router":{"set_routes":{"set":[{"domain":11155111,"route":"000000000000000000000000224a4419d7fa69d3bebabce574c7c84b48d829b4"}]}}}' \
  --from sua-key-name \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

### Verificar Vinculação

```bash
# Verificar rota na Sepolia
cast call $WARP_ROUTE_SEPOLIA \
  "routers(uint32)(bytes32)" \
  1325 \
  --rpc-url https://rpc.sepolia.org

# Verificar rota na Terra Classic
terrad query wasm contract-state smart $WARP_TERRA \
  '{"router":{"get_route":{"domain":11155111}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

---

## ✅ Verificação e Testes

### Checklist Pré-Teste

Antes de realizar a primeira transferência, verifique cada item:

- [ ] **Warp Route Sepolia** deployado e endereço salvo
- [ ] **Hook (IGP)** configurado com `hookType = 4`
- [ ] **IGP Sepolia** configurado para domain 1325 (Terra Classic)
- [ ] **ISM Sepolia** configurado com validators corretos
- [ ] **Warp Route Terra Classic** com rota para Sepolia (domain 11155111)
- [ ] **IGP Oracle Terra** configurado para domain 11155111
- [ ] **IGP Router Terra** com rota para o Oracle
- [ ] **Vinculação bidirecional** configurada (enrollRemoteRouter)
- [ ] **Relayer Hyperlane** monitorando as chains

### Script de Verificação Completa

```bash
#!/bin/bash
# Script de verificação completa do Warp Sepolia

WARP_SEPOLIA="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
IGP_SEPOLIA="0xe0f137448c96b5f17759bce44c020db6bdc8e261"
WARP_TERRA="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"
IGP_ORACLE="terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds"
IGP="terra1mcaqgr7kqs9xr3q6w0e9f2ekrj6sehwcep9shtss6u8pdz2rsw5qzrew7r"

echo "=== Verificação do Warp Route Sepolia <-> Terra Classic ==="

echo ""
echo "1. Hook do Warp Route Sepolia:"
cast call $WARP_SEPOLIA "hook()(address)" --rpc-url https://rpc.sepolia.org

echo ""
echo "2. Hook Type (deve ser 4 = IGP):"
HOOK=$(cast call $WARP_SEPOLIA "hook()(address)" --rpc-url https://rpc.sepolia.org)
cast call $HOOK "hookType()(uint8)" --rpc-url https://rpc.sepolia.org

echo ""
echo "3. ISM do Warp Route Sepolia:"
cast call $WARP_SEPOLIA "interchainSecurityModule()(address)" --rpc-url https://rpc.sepolia.org

echo ""
echo "4. Rota na Terra Classic para Sepolia:"
terrad query wasm contract-state smart $WARP_TERRA \
  '{"router":{"get_route":{"domain":11155111}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 2>&1 | grep -A5 '"route"'

echo ""
echo "5. IGP Oracle - Configuração para Sepolia (11155111):"
terrad query wasm contract-state smart $IGP_ORACLE \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":11155111}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json 2>&1 | jq '.data'

echo ""
echo "6. IGP Router - Rota para Sepolia:"
terrad query wasm contract-state smart $IGP \
  '{"router":{"get_route":{"domain":11155111}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 2>&1

echo ""
echo "=== Verificação Concluída ==="
```

### Teste de Transferência: Terra Classic → Sepolia

```bash
WARP_TERRA="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"

# Endereço Sepolia destino (padded para bytes32)
# Exemplo: 0x133fD7F7094DBd17b576907d052a5aCBd48dB526
# Padded:  000000000000000000000000133fD7F7094DBd17b576907d052a5aCBd48dB526

terrad tx wasm execute $WARP_TERRA \
  '{"transfer_remote":{
    "dest_domain": 11155111,
    "recipient": "000000000000000000000000133fd7f7094dbd17b576907d052a5acbd48db526",
    "amount": "1000000"
  }}' \
  --from sua-key-name \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --amount 1283215uluna \
  --yes
```

**Obs:**
- `amount: "1000000"` = 1 LUNC transferido
- `--amount 1283215uluna` = 1 LUNC + 283215 uluna (taxa de hook fee)

### Monitorar Transferência no Hyperlane Explorer

Após a transferência, acompanhe o status em:

🔗 **https://explorer.hyperlane.xyz**

---

## 📍 Endereços Deployados (Referência)

### Ethereum Sepolia Testnet

| Contrato | Endereço | Descrição |
|---------|---------|-----------|
| **Warp Route (LUNC)** | `0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4` | Token ERC20 LUNC sintético |
| **IGP Customizado** | `0xe0f137448c96b5f17759bce44c020db6bdc8e261` | Gas Paymaster para Terra Classic |
| **Gas Oracle** | `0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c` | Oracle de preços Hyperlane |

### Terra Classic Testnet (rebel-2)

| Contrato | Endereço | Descrição |
|---------|---------|-----------|
| **Mailbox** | `terra1s4jwfe0tcaztpfsct5wzj02esxyjy7e7lhkcwn5dp04yvly82rwsvzyqmm` | Mailbox principal |
| **Warp Route (uluna)** | `terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml` | Bridge LUNC nativo |
| **IGP Core** | `terra1mcaqgr7kqs9xr3q6w0e9f2ekrj6sehwcep9shtss6u8pdz2rsw5qzrew7r` | Gas Paymaster |
| **IGP Oracle** | `terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds` | Oracle de preços |
| **ISM Routing** | `terra1na6ljyf4m5x2u7llfvvxxe2nyq0t8628qyk0vnwu4ttpq86tt0cse47t68` | Roteador de ISMs |

### Configurações de Domínio

| Chain | Domain ID | Tipo |
|-------|-----------|------|
| **Terra Classic Testnet** | `1325` | CosmWasm |
| **Ethereum Sepolia** | `11155111` | EVM |

---

## 🛠️ Troubleshooting

### Erro: "destination not supported"

**Causa**: O hook do Warp Route na Sepolia não é do tipo IGP (hookType ≠ 4).

**Diagnóstico:**
```bash
WARP=$(0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4)
HOOK=$(cast call $WARP "hook()(address)" --rpc-url https://rpc.sepolia.org)
cast call $HOOK "hookType()(uint8)" --rpc-url https://rpc.sepolia.org
# Se retornar 2 = AGGREGATION (incorreto)
# Deve retornar 4 = INTERCHAIN_GAS_PAYMASTER
```

**Solução**: Deployar um novo IGP e associá-lo via `setHook()`.

---

### Erro: "gas oracle not found for 11155111"

**Causa**: O IGP Router na Terra Classic não tem rota para Sepolia (domain 11155111).

**Diagnóstico:**
```bash
terrad query wasm contract-state smart terra1mcaqgr7kqs9xr3q6w0e9f2ekrj6sehwcep9shtss6u8pdz2rsw5qzrew7r \
  '{"router":{"get_route":{"domain":11155111}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

**Solução**: Configurar a rota via `set_routes` no IGP Router.

---

### Erro: "insufficient funds" ao Calcular Gas

**Causa**: O `exchange_rate` no IGP Oracle está com valor incorreto (muito alto).

**Diagnóstico:**
```bash
# Verificar o exchange_rate atual
terrad query wasm contract-state smart $IGP_ORACLE \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":11155111}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443

# Se retornar exchange_rate na escala 1e18 em vez de 1e10, está incorreto!
```

**Solução**: Recalcular e atualizar o `exchange_rate` com escala `1e10`.

---

### Erro: "no route found" na Terra Classic

**Causa**: O Warp Route na Terra Classic não tem rota vinculada para Sepolia.

**Solução:**
```bash
# Verificar rotas do Warp Route
terrad query wasm contract-state smart $WARP_TERRA \
  '{"router":{"list_routes":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443

# Se domain 11155111 não aparecer, execute set_routes
```

---

### Erro: Compilação Falhou no Remix

**Solução**: Verificar:
1. Compiler version: `0.8.22` ou superior
2. Optimization: **habilitado** (200 runs)
3. Código colado completo (sem truncar)

---

### MetaMask: "Wrong Network"

**Solução**: Configurar rede Sepolia no MetaMask:
1. Settings → Networks → Add Network
2. Network Name: `Sepolia`
3. RPC URL: `https://rpc.sepolia.org`
4. Chain ID: `11155111`
5. Symbol: `ETH`
6. Explorer: `https://sepolia.etherscan.io`

---

### Obter ETH Sepolia (Faucets)

- https://sepoliafaucet.com/
- https://www.alchemy.com/faucets/ethereum-sepolia
- https://faucets.chain.link/sepolia

---

## 📚 Recursos Adicionais

### Documentação Oficial

- [Hyperlane Docs](https://docs.hyperlane.xyz/)
- [Warp Routes Guide](https://docs.hyperlane.xyz/docs/guides/deploy-warp-route)
- [IGP Configuration](https://docs.hyperlane.xyz/docs/reference/hooks/interchain-gas)
- [ISM Configuration](https://docs.hyperlane.xyz/docs/reference/ISM/specify-your-ISM)

### Ferramentas

- [Hyperlane Explorer](https://explorer.hyperlane.xyz) — Monitorar mensagens cross-chain
- [Remix IDE](https://remix.ethereum.org) — Deploy de contratos Solidity
- [Sepolia Etherscan](https://sepolia.etherscan.io) — Explorar contratos na Sepolia
- [Terra Classic Finder](https://finder.terra-classic.hexxagon.dev/testnet) — Explorar contratos na Terra

### Arquivos do Projeto

| Arquivo | Descrição |
|---------|-----------|
| `warp-sepolia.yaml` | Configuração do Warp Route Sepolia |
| `warp/sepolia/metadata.json` | Metadados do token wLUNC |
| `TerraClassicIGPStandalone.sol` | Contrato IGP customizado |
| `SUCESSO-FINAL-SEPOLIA.md` | Relatório do deploy bem-sucedido |
| `DEPLOY-SUCCESS-REPORT-SEPOLIA.txt` | Transações do deploy |
| `FIX-IGP-SEPOLIA.md` | Guia de correção do IGP |
| `CHECK-IGP-CONFIG.md` | Guia de verificação do IGP |
| `context/terraclassic.json` | Endereços dos contratos Terra Classic |

---

## 🔒 Segurança e Boas Práticas

### Gerenciamento de Chaves

1. **Nunca** commite chaves privadas no Git
2. Use variáveis de ambiente: `export ETH_PRIVATE_KEY="..."`
3. Para produção, use uma carteira multisig (Safe) como `owner`

### Owner do Warp Route

Para maior segurança:
- **Testnet**: Usar endereço próprio temporariamente
- **Mainnet**: Usar Safe Multisig (2/3 ou 3/5 assinaturas)

### Monitoramento

Após o deploy, monitore regularmente:
- [ ] Status do relayer no [Hyperlane Explorer](https://explorer.hyperlane.xyz)
- [ ] Preços do gas na Sepolia para atualizar o IGP Oracle
- [ ] Exchange rate LUNC/ETH para manter taxas corretas

---

**Última atualização:** Março 2026  
**Versão Hyperlane:** v0.0.6-rc8 (CosmWasm) / CLI v4.x (EVM)  
**Terra Classic Testnet Chain ID:** rebel-2  
**Ethereum Sepolia Domain:** 11155111  
**Terra Classic Domain:** 1325  
