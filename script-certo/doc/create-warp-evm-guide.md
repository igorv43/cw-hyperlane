# Guia Completo: `create-warp-evm.sh`

> Script interativo para criar e configurar Warp Routes Hyperlane em redes EVM conectadas à Terra Classic.  
> Totalmente portável — basta copiar a pasta `script-certo/` para qualquer projeto `cw-hyperlane`.

---

## 📋 Índice

1. [O que o script faz](#1-o-que-o-script-faz)
2. [Pré-requisitos](#2-pré-requisitos)
3. [Estrutura de arquivos](#3-estrutura-de-arquivos)
4. [Configurando o `warp-evm-config.json`](#4-configurando-o-warp-evm-configjson)
   - [Seção `terra_classic.tokens`](#41-seção-terra_classictokens)
   - [Seção `networks`](#42-seção-networks)
   - [Adicionando um novo token](#43-adicionando-um-novo-token)
   - [Habilitando uma nova rede](#44-habilitando-uma-nova-rede)
5. [Configurando o `config.yaml`](#5-configurando-o-configyaml)
6. [Executando o script](#6-executando-o-script)
   - [Execução completa (do zero)](#61-execução-completa-do-zero)
   - [Deploy automático da Terra Classic](#62-deploy-automático-da-terra-classic)
   - [Retomando após falha](#63-retomando-após-falha)
   - [Pulando etapas já executadas](#64-pulando-etapas-já-executadas)
7. [O que o script configura — Etapas detalhadas](#7-o-que-o-script-configura--etapas-detalhadas)
8. [Deploy manual do IGP via Remix](#8-deploy-manual-do-igp-via-remix)
9. [Deploy do Warp na Terra Classic (manual)](#9-deploy-do-warp-na-terra-classic-manual)
10. [Atualizando o JSON após o deploy](#10-atualizando-o-json-após-o-deploy)
11. [Scripts auxiliares](#11-scripts-auxiliares)
12. [Usando em outro projeto (portabilidade)](#12-usando-em-outro-projeto-portabilidade)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. O que o script faz

O `create-warp-evm.sh` automatiza o deploy e a configuração completa de um Warp Route Hyperlane no lado EVM, conectado à Terra Classic.

Para cada par **token + rede EVM** escolhido, o script executa de forma automatizada:

| Componente | O que é | Por que é necessário |
|---|---|---|
| **Terra Classic Warp** | Contrato `hpl_warp_cw20` ou `hpl_warp_native` | Ponto de entrada/saída na Terra Classic |
| **Mailbox** | Hub central Hyperlane da rede EVM | Recebe e envia mensagens cross-chain |
| **ISM** | Interchain Security Module (`messageIdMultisigIsm`) | Valida que as mensagens vieram da Terra Classic |
| **IGP** | Contrato de gas customizado (`TerraClassicIGPStandalone`) | Calcula e cobra gas para execução na Terra Classic |
| **AggregationHook** | `[MerkleTreeHook + IGP]` como hook do Warp | Garante que msgs entram na merkle tree (para o validator) **e** pagam o IGP |
| **enrollRemoteRouter** | Vínculo bidirecional Warp EVM ↔ Warp Terra | Autoriza a rota cross-chain |

---

## 2. Pré-requisitos

### Ferramentas obrigatórias

| Ferramenta | Versão mínima | Instalação |
|---|---|---|
| `bash` | 4+ | nativo no Linux/macOS |
| `jq` | 1.6+ | `sudo apt install jq` |
| `node` / `npm` | 18+ | [nodejs.org](https://nodejs.org/) |
| `yarn` | 1+ | `npm install -g yarn` |
| `python3` | 3.6+ | `sudo apt install python3` |
| `hyperlane CLI` | **26+** | `npm install -g @hyperlane-xyz/cli` |

> ⚠️ **A versão mínima do Hyperlane CLI é v26.** Versões anteriores falham com `invalid_enum_value` ao processar o protocolo `tron`. O script detecta isso e atualiza automaticamente.

### Ferramentas recomendadas (deploy automático do IGP)

| Ferramenta | Instalação |
|---|---|
| `forge` (Foundry 1.x) | `curl -L https://foundry.paradigm.xyz \| bash && foundryup` |
| `cast` (Foundry 1.x) | Instalado junto com `forge` |

> **Sem o Foundry**, o script pausa na Etapa 3 e exibe instruções para deploy manual via **Remix IDE** (veja [Seção 8](#8-deploy-manual-do-igp-via-remix)).

### Saldo mínimo

| Rede | Saldo recomendado | Faucet |
|---|---|---|
| Sepolia | 0.1 ETH | [sepoliafaucet.com](https://sepoliafaucet.com) |
| BSC Testnet | 0.1 BNB | [testnet.binance.org/faucet-smart](https://testnet.binance.org/faucet-smart) |

---

## 3. Estrutura de arquivos

A pasta `script-certo/` é autocontida. Copie-a inteira para qualquer projeto `cw-hyperlane`:

```
script-certo/
│
├── create-warp-evm.sh                     ← script principal de deploy (executável)
├── enroll-terra-router.sh                 ← vincula rota EVM no Warp Terra Classic
├── transfer-cw20-terra.sh                 ← transfere tokens CW20 na Terra Classic
├── warp-evm-config.json                   ← configuração de redes e tokens (EDITE AQUI)
├── TerraClassicIGPStandalone-Sepolia.sol  ← contrato IGP (compilado/deployado automaticamente)
├── config.yaml                            ← configuração Terra Classic para o cw-hpl CLI
│
├── context/
│   └── terraclassic.json                  ← deployments existentes na Terra Classic
│
├── example/warp/
│   ├── terraclassic-cw20-xpto.json        ← exemplo CW20 collateral
│   ├── terraclassic-cw20-juris.json       ← exemplo CW20 collateral
│   ├── terraclassic-native-ustc.json      ← exemplo native collateral
│   └── terraclassic-native.json           ← exemplo native collateral (genérico)
│
└── doc/
    ├── create-warp-evm-guide.md           ← este documento
    └── enroll-terra-router-guide.md       ← guia do enroll-terra-router.sh
```

**Arquivos gerados automaticamente na execução:**

| Arquivo | Conteúdo |
|---|---|
| `create-warp-evm.log` | Log completo da execução |
| `warp-<rede>-<token>.yaml` | YAML gerado para o CLI Hyperlane |
| `WARP-<REDE>-<TOKEN>.txt` | Relatório com todos os endereços |
| `.warp-evm-state.json` | Estado salvo (permite retomar após falha) |

---

## 4. Configurando o `warp-evm-config.json`

Este é o **arquivo central de configuração**. Todo o comportamento do script vem daqui.

### 4.1 Seção `terra_classic.tokens`

Define cada token com suas configurações para a Terra Classic.

```json
"terra_classic": {
  "chain_id": "rebel-2",
  "domain": 1325,
  "rpc": "https://rpc.terra-classic.hexxagon.dev",
  "lcd": "https://lcd.terra-classic.hexxagon.dev",

  "tokens": {
    "meutoken": {
      "id": "meutoken",
      "name": "Meu Token",
      "symbol": "MTK",
      "decimals": 6,
      "description": "Descrição",
      "image": "https://url-da-imagem.png",

      "terra_warp": {
        "type":               "cw20",       ← "cw20" ou "native"
        "mode":               "collateral", ← "collateral" ou "locked"
        "owner":              "terra1...",  ← endereço admin na Terra Classic
        "denom":              "",           ← preencher se type = "native" (ex: "uluna")
        "collateral_address": "terra1...", ← preencher se type = "cw20"
        "warp_address":       "",          ← preenchido APÓS deploy Terra Classic
        "warp_hexed":         "",          ← preenchido APÓS deploy Terra Classic
        "deployed":           false        ← muda para true após o deploy
      }
    }
  }
}
```

#### Tokens pré-configurados

| ID | Tipo | Warp Terra Classic | Status |
|---|---|---|---|
| `wlunc` | `native/collateral` (uluna) | `terra1zlm0h...` | ✅ Deployado |
| `ustc` | `native/collateral` (uusd) | `terra1rnpvp...` | ✅ Deployado |
| `juris` | `cw20/collateral` | `terra1stu3c...` | ✅ Deployado |
| `xpto` | `cw20/collateral` | `terra16ql6l...` | ✅ Deployado |

---

### 4.2 Seção `networks`

Define cada rede EVM com todos os endereços Hyperlane e configurações do IGP.

```json
"networks": {
  "sepolia": {
    "enabled": true,                        ← true = aparece no menu
    "display_name": "Ethereum Sepolia Testnet",
    "chain_id": 11155111,
    "domain":   11155111,
    "is_testnet": true,
    "native_token": { "symbol": "ETH", "decimals": 18 },
    "rpc_urls": [
      "https://ethereum-sepolia-rpc.publicnode.com",
      "https://rpc.sepolia.org"             ← URL alternativa (fallback automático)
    ],
    "explorer": "https://sepolia.etherscan.io",

    "mailbox": {
      "address": "0xfFAEF09B3cd11D9b20d1a19bECca54EEC2884766"
    },

    "ism": {
      "type":             "messageIdMultisigIsm",
      "factory":          "0xFEb9585b2f948c1eD74034205a7439261a9d27DD",
      "deployed_address": "",               ← opcional: ISM já deployado
      "validators":       [ "0x8804770d6a346210c0fd011258fdf3ab0a5bb0d0" ],
      "threshold":        1
    },

    "hook": {
      "merkle_tree":      "0x4917a9746A7B6E0A57159cCb7F5a6744247f2d0d",
      "agg_hook_factory": "0x160C28C92cA453570aD7C031972b58d5Dd128F72"
    },

    "igp": {
      "gas_oracle":      "0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c",
      "overhead_default": 200000,
      "terra_classic_config": {
        "exchange_rate":   142244393,       ← veja cálculo abaixo
        "gas_price_wei":   38325000000
      }
    },

    "warp_tokens": {
      "xpto": {
        "deployed":          true,
        "address":           "0xbF43aA4878f5Ad0fcAC12Cd3A835DD3506981048",
        "igp_custom":        "0xf285D5769db5AE6E79Bb3179d03082f6bc47055f",
        "hook_aggregation":  "0x1a13d7A50b76d4527a611e507B3f73058eCa5eAC",
        "owner":             "0x133fD7F7094DBd17b576907d052a5aCBd48dB526"
      }
    }
  }
}
```

#### Cálculo do `exchange_rate`

Configura o IGP para cobrar o valor correto em ETH/BNB para pagar o gas na Terra Classic.

```
exchange_rate = (PRECO_ETH_USD / PRECO_LUNC_USD) × 0,01

Exemplo:
  ETH  = $3.500 USD
  LUNC = $0,00006069 USD
  exchange_rate = (3500 / 0,00006069) × 0,01 ≈ 142.244.393
```

> **Atualize este valor periodicamente** para refletir os preços reais do mercado.

---

### 4.3 Adicionando um novo token

**Passo 1** — Adicione o token na seção `terra_classic.tokens`:

```json
"novotoken": {
  "id":          "novotoken",
  "name":        "Novo Token",
  "symbol":      "NTK",
  "decimals":    6,
  "description": "Descrição do token",
  "image":       "",
  "terra_warp": {
    "type":               "cw20",
    "mode":               "collateral",
    "owner":              "terra12awgqg...",
    "denom":              "",
    "collateral_address": "terra1ENDERECO_DO_CW20...",
    "warp_address":       "",
    "warp_hexed":         "",
    "deployed":           false
  }
}
```

> Para token **native**, preencha `"denom": "uluna"` (ou outro denom) e deixe `collateral_address` vazio.

**Passo 2** — Adicione o token em `warp_tokens` de **cada rede**:

```json
"warp_tokens": {
  "novotoken": {
    "deployed":         false,
    "address":          "",
    "igp_custom":       "",
    "hook_aggregation": "",
    "owner":            ""
  }
}
```

**Passo 3** — Execute o script, selecione o novo token e a rede desejada.  
Se tiver `TERRA_PRIVATE_KEY` definida, o deploy da Terra Classic é **automático**.

---

### 4.4 Habilitando uma nova rede

Para habilitar uma rede desabilitada, edite o campo `enabled`:

```json
"bsctestnet": {
  "enabled": true,   ← mude de false para true
  ...
}
```

> ⚠️ **Para redes mainnet**, confirme todos os endereços de contratos Hyperlane e o `exchange_rate` antes de executar.

---

## 5. Configurando o `config.yaml`

O `config.yaml` contém as configurações da **conta na Terra Classic** usada pelo `cw-hpl` CLI para fazer deploys.

```yaml
networks:
  - id: 'terraclassic'
    chainId: 'rebel-2'
    hrp: 'terra'
    signer: SUA_CHAVE_PRIVADA_TERRA_HEX   ← chave privada sem prefixo 0x
    endpoint:
       rpc: 'https://rpc.terra-classic.hexxagon.dev'   ← use hexxagon (sincronizado)
       rest: 'https://lcd.terra-classic.hexxagon.dev'
       grpc: 'https://grpc.terra-classic.hexxagon.dev'
    gas:
      price: '28.325'
      denom: 'uluna'
    domain: 1325
```

> ⚠️ **Use sempre o RPC do `hexxagon`**. O `rpc.luncblaze.com` pode estar dias atrasado e causar falhas silenciosas de deploy (timeout + `account sequence mismatch`). Veja [Troubleshooting](#-timeouterror2--account-sequence-mismatch).

---

## 6. Executando o script

### 6.1 Execução completa (do zero)

```bash
# 1. Entrar na pasta script-certo (ou na raiz do projeto)
cd ~/cw-hyperlane/script-certo

# 2. Dar permissão de execução (apenas na primeira vez)
chmod +x create-warp-evm.sh

# 3. Definir a chave privada EVM (owner do Warp)
export ETH_PRIVATE_KEY="0xSUA_CHAVE_EVM"

# 4. (Opcional) Definir a chave privada Terra Classic para deploy automático
export TERRA_PRIVATE_KEY="SUA_CHAVE_TERRA_HEX"

# 5. Executar
./create-warp-evm.sh
```

O script apresenta dois menus interativos:

```
PASSO 1 — SELECIONAR TOKEN (Terra Classic)
   [1]  wlunc  — Wrapped Terra Classic LUNC  (native/collateral)  ✅ warp terra deployado
   [2]  ustc   — Wrapped TerraClassic USD    (native/collateral)  ✅ warp terra deployado
   [3]  juris  — Juris Token                 (cw20/collateral)    ✅ warp terra deployado
   [4]  xpto   — XPTO Token                  (cw20/collateral)    ✅ warp terra deployado

  Escolha o token [1-4]: 4

PASSO 2 — SELECIONAR REDE EVM
   [1]  bsctestnet — BSC Testnet             [testnet] [novo deploy]
   [2]  sepolia    — Ethereum Sepolia Testnet [testnet] [warp já deployado]

  Escolha a rede [1-2]: 2

▶ Prosseguir com deploy de XPTO na rede Ethereum Sepolia Testnet? [s/N]: s
```

---

### 6.2 Deploy automático da Terra Classic

Quando um token ainda não tem Warp na Terra Classic (`deployed: false`), o script oferece **duas opções**:

#### Opção A — Automático (recomendado)

Defina `TERRA_PRIVATE_KEY` e o script faz tudo sozinho:

```bash
export ETH_PRIVATE_KEY="0xSUA_CHAVE_EVM"
export TERRA_PRIVATE_KEY="SUA_CHAVE_TERRA_HEX"  ← chave sem prefixo 0x
./create-warp-evm.sh
```

O script irá automaticamente:
1. Gerar o arquivo de configuração `example/warp/terraclassic-<tipo>-<token>.json`
2. Copiar o `config.yaml` para a raiz do projeto (necessário para o `yarn cw-hpl`)
3. Executar `yarn cw-hpl warp create ... -n terraclassic`
4. Extrair o endereço `terra1...` do output
5. Converter para hex `0x...` (via Python3 — `bech32_to_hex`)
6. Atualizar o `warp-evm-config.json` automaticamente
7. Continuar para o `enrollRemoteRouter` no lado EVM

#### Opção B — Manual

Sem `TERRA_PRIVATE_KEY`, o script exibe as instruções e aguarda:

```bash
cd ~/cw-hyperlane
export PRIVATE_KEY="SUA_CHAVE_TERRA_HEX"
yarn cw-hpl warp create \
  ./example/warp/terraclassic-cw20-novotoken.json \
  -n terraclassic
```

Após o deploy, **preencha o `warp-evm-config.json`** com o endereço retornado (veja [Seção 10](#10-atualizando-o-json-após-o-deploy)) e reexecute o script.

---

### 6.3 Retomando após falha

O script salva o estado em `.warp-evm-state.json`. Para retomar:

```bash
./create-warp-evm.sh
# O script detecta o estado anterior e informa os endereços salvos
```

Para **recomeçar do zero** (apagar estado):

```bash
rm -f .warp-evm-state.json
./create-warp-evm.sh
```

---

### 6.4 Pulando etapas já executadas

Use variáveis de ambiente para informar contratos já deployados:

```bash
# Warp Route EVM já deployado → pula Etapa 2
export WARP_ADDRESS="0xENDERECO_WARP"

# IGP já deployado → pula Etapa 3
export IGP_ADDRESS="0xENDERECO_IGP"

# Pular o enrollRemoteRouter
export SKIP_ENROLL="1"

export ETH_PRIVATE_KEY="0xSUA_CHAVE"
./create-warp-evm.sh
```

---

## 7. O que o script configura — Etapas detalhadas

### Etapa 1 — Gerar Warp YAML

Gera o arquivo `warp-<rede>-<token>.yaml` para o Hyperlane CLI:

```yaml
# Exemplo: warp-sepolia-xpto.yaml
sepolia:
  isNft: false
  type: synthetic
  name: "XPTO Token"
  symbol: "XPTO"
  decimals: 6
  owner: "0xSEU_ENDERECO"
  mailbox: "0xfFAEF09B3cd11D9b20d1a19bECca54EEC2884766"
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "0x8804770d6a346210c0fd011258fdf3ab0a5bb0d0"
    threshold: 1
```

---

### Etapa 2 — Deploy Warp Route

Executa o deploy do token sintético na rede EVM via Hyperlane CLI:

```bash
hyperlane warp deploy \
  --config warp-sepolia-xpto.yaml \
  --key $ETH_PRIVATE_KEY \
  --yes
```

Cria o contrato ERC20 sintético (`wXPTO`) e registra no Mailbox da rede.

---

### Etapa 3 — Deploy IGP customizado

Deploya o `TerraClassicIGPStandalone` com `hookType = 4`.

O script usa `cast send --create` com o bytecode compilado pelo Foundry (compatível com **Foundry v1.5+**, que entrou em modo dry-run por padrão no `forge create`):

```bash
# Compilação
forge build

# Deploy via cast send --create (Foundry v1.5+)
cast send \
  --rpc-url $RPC \
  --private-key $ETH_PRIVATE_KEY \
  --legacy \
  --create $BYTECODE_COM_ARGS_CONSTRUCTOR
```

| Parâmetro | Valor |
|---|---|
| `_GASORACLE` | Oracle oficial Hyperlane da rede |
| `_GASOVERHEAD` | `200000` |
| `_BENEFICIARY` | Endereço da sua carteira (owner) |

---

### Etapa 4 — Configurar Gas Oracle

Chama `setRemoteGasData` no **GAS ORACLE** (não no IGP) para configurar a taxa de câmbio e gas price:

```bash
cast send $GAS_ORACLE \
  "setRemoteGasData(uint32,uint128,uint128)" \
  1325 142244393 38325000000 \
  --rpc-url $RPC --private-key $ETH_PRIVATE_KEY --legacy
```

| Parâmetro | Significado |
|---|---|
| `1325` | Domain ID da Terra Classic |
| `142244393` | Exchange rate ETH/LUNC (escala 1e8) |
| `38325000000` | Gas price na rede em wei |

> ⚠️ `setRemoteGasData` é função do **Gas Oracle** (`igp.gas_oracle` no JSON), **não** do contrato IGP.

---

### Etapa 5 — Configurar Hook (AggregationHook = MerkleTree + IGP)

O Warp precisa usar um **`AggregationHook`** que combina:

- **`MerkleTreeHook`** — insere a mensagem na árvore merkle do Mailbox, permitindo que o validator a assine
- **`IGP customizado`** — cobra o gas no momento do envio

> ⚠️ **Por que não usar o IGP diretamente como hook?**
> O `requiredHook` do Mailbox Sepolia é o `ProtocolFee` (não o MerkleTreeHook). O MerkleTreeHook faz parte
> do `defaultHook`. Ao setar um hook customizado no Warp sem incluir o MerkleTree, as mensagens **nunca
> entram na merkle tree** — o validator não as vê e não as assina, impedindo a entrega na Terra Classic.

O script deploya o `AggregationHook` via factory e o seta no Warp:

```bash
# 1. Deploy do AggregationHook (endereço deterministico via factory)
cast call $AGG_HOOK_FACTORY \
  "deploy(address[])(address)" \
  "[$MERKLE_TREE_HOOK,$IGP_ADDRESS]" \
  --rpc-url $RPC

# 2. Deploy on-chain
cast send $AGG_HOOK_FACTORY \
  "deploy(address[])" \
  "[$MERKLE_TREE_HOOK,$IGP_ADDRESS]" \
  --rpc-url $RPC --private-key $ETH_PRIVATE_KEY --legacy

# 3. Setar no Warp Route
cast send $WARP_ADDRESS "setHook(address)" $AGG_HOOK_ADDRESS \
  --rpc-url $RPC --private-key $ETH_PRIVATE_KEY --legacy
```

| Parâmetro | Endereço (Sepolia) |
|---|---|
| `MERKLE_TREE_HOOK` | `0x4917a9746A7B6E0A57159cCb7F5a6744247f2d0d` |
| `AGG_HOOK_FACTORY` | `0x160C28C92cA453570aD7C031972b58d5Dd128F72` |

O endereço do `AggregationHook` deployado é salvo em `hook_aggregation` no `warp-evm-config.json`.

---

### Etapa 6 — Configurar ISM

Se um `deployed_address` estiver definido no JSON, o script aplica ao Warp Route:

```bash
cast send $WARP_ADDRESS \
  "setInterchainSecurityModule(address)" $ISM_ADDRESS \
  --rpc-url $RPC --private-key $ETH_PRIVATE_KEY --legacy
```

Caso contrário, o Warp herda o ISM padrão do Mailbox (comportamento normal).

---

### Etapa 7 — enrollRemoteRouter (EVM → Terra Classic)

Registra o Warp Terra Classic no contrato EVM, autorizando mensagens vindas do domínio 1325:

```bash
cast send $WARP_ADDRESS \
  "enrollRemoteRouter(uint32,bytes32)" \
  1325 0xd03fafd53ce350f49ba3c6ebcb1bee7cbbf453f261ec8d5ce9f36c55ab3e26a1 \
  --rpc-url $RPC --private-key $ETH_PRIVATE_KEY --legacy
```

O `bytes32` é o endereço `terra1...` do Warp na Terra Classic convertido de bech32 para hex de 32 bytes.

> ⚠️ **Atenção ao formato bytes32:** endereços CosmWasm têm 32 bytes (64 hex chars) — não devem ser
> tratados como endereços EVM (20 bytes). A função `to_bytes32` do script foi corrigida para distinguir
> automaticamente os dois tipos: usa padding esquerdo com zeros apenas para endereços EVM (40 chars),
> e mantém o hash CosmWasm inalterado quando já tem 64 chars.

> Esta etapa é **pulada** se `deployed: false` no JSON e `TERRA_PRIVATE_KEY` não foi definida.

---

### Etapa 7B — set_route (Terra Classic → EVM)

Registra o Warp EVM no contrato Warp da Terra Classic, criando o **vínculo bidirecional** completo:

```javascript
// CosmWasm execute (executado via Node.js + @cosmjs)
{
  "router": {
    "set_route": {
      "set": {
        "domain": 11155111,
        "route": "000000000000000000000000bf43aa4878f5ad0fcac12cd3a835dd3506981048"
      }
    }
  }
}
```

> ⚠️ **Sem esta etapa, o `transfer_remote` da Terra Classic falha com `route not found`.**
> A rota EVM deve ser registrada no lado Terra Classic antes de qualquer transferência.

Esta etapa requer `TERRA_PRIVATE_KEY` e é executada automaticamente no `create-warp-evm.sh`.
Para executar manualmente depois, use o script auxiliar `enroll-terra-router.sh`
(ver [Scripts auxiliares](#11-scripts-auxiliares)).

---

### Etapa 8 — Verificação final

O script verifica on-chain via `cast call`:

| Verificação | Função | Esperado |
|---|---|---|
| Mailbox existe | `eth_getCode` | bytecode != `0x` |
| Warp Route existe | `eth_getCode` | bytecode != `0x` |
| Hook = AggregationHook | `hook()(address)` | endereço do AggregationHook `[MerkleTree+IGP]` |
| hookType = 4 | `hookType()(uint8)` | `4` |
| ISM configurado | `interchainSecurityModule()(address)` | endereço != zero |
| Router Terra (EVM→Terra) | `routers(uint32)(bytes32)` | bytes32 do Warp Terra |
| Router EVM (Terra→EVM) | `router.list_routes` (CosmWasm) | domain EVM → bytes32 do Warp EVM |

> Se a verificação do Router Terra mostrar `0x000...`, execute `enroll-terra-router.sh` manualmente.

---

## 8. Deploy manual do IGP via Remix

Quando o Foundry não está instalado, o script para na Etapa 3 com instruções. Siga:

**1.** Abra [remix.ethereum.org](https://remix.ethereum.org)

**2.** Crie `TerraClassicIGP.sol` e cole o conteúdo de `TerraClassicIGPStandalone-Sepolia.sol`

**3.** Compile:
- Versão: `0.8.13` ou superior
- Optimization: `ON` — 200 runs

**4.** Na aba **Deploy & Run**:
- Environment: `Injected Provider - MetaMask`
- Rede: a rede desejada
- Contrato: `TerraClassicIGPStandalone`

**5.** Parâmetros do constructor (exemplo Sepolia):

| Campo | Valor |
|---|---|
| `_GASORACLE` | `0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c` |
| `_GASOVERHEAD` | `200000` |
| `_BENEFICIARY` | Seu endereço (owner) |

**6.** Clique em **Deploy** e confirme na MetaMask.

**7.** Copie o endereço e retome o script:

```bash
export IGP_ADDRESS="0xENDERECO_DO_REMIX"
export WARP_ADDRESS="0xENDERECO_WARP_ANTERIOR"  # se já deployado
export ETH_PRIVATE_KEY="0xSUA_CHAVE"
./create-warp-evm.sh
```

---

## 9. Deploy do Warp na Terra Classic (manual)

Para fazer o deploy manualmente (sem `TERRA_PRIVATE_KEY`):

### Token CW20

```bash
# 1. Criar o arquivo de configuração (já existe em example/warp/)
cat example/warp/terraclassic-cw20-novotoken.json

# 2. Definir chave privada
export PRIVATE_KEY="SUA_CHAVE_TERRA_HEX"  ← sem prefixo 0x

# 3. Deploy (rodar da raiz do projeto)
cd ~/cw-hyperlane
yarn cw-hpl warp create \
  ./example/warp/terraclassic-cw20-novotoken.json \
  -n terraclassic
```

### Token Native

```bash
cat example/warp/terraclassic-native-novotoken.json
export PRIVATE_KEY="SUA_CHAVE_TERRA_HEX"
yarn cw-hpl warp create \
  ./example/warp/terraclassic-native-novotoken.json \
  -n terraclassic
```

**Saída esperada:**
```
[DEBUG] [contract] deploying hpl_warp_cw20
[INFO]  [contract] deployed hpl_warp_cw20 at terra1ENDERECODEPLOY...
```

Após o deploy, o endereço é automaticamente salvo em `context/terraclassic.json`.

---

## 10. Atualizando o JSON após o deploy

### Após deploy do Warp na Terra Classic

Abra `warp-evm-config.json` e preencha a seção do token:

```json
"novotoken": {
  "terra_warp": {
    "warp_address": "terra1ENDERECORETORNADO...",
    "warp_hexed":   "0xHEXCONVERTIDO...",
    "deployed":     true
  }
}
```

**Convertendo bech32 → hex manualmente:**

```bash
python3 - "terra1ENDERECO..." <<'EOF'
import sys
addr = sys.argv[1]
CHARSET = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l'
sep = addr.rfind('1')
data_str = addr[sep+1:-6]
vals = [CHARSET.index(c) for c in data_str]
result, acc, bits = [], 0, 0
for v in vals:
    acc = (acc << 5) | v
    bits += 5
    while bits >= 8:
        bits -= 8
        result.append((acc >> bits) & 0xFF)
print('0x' + ''.join(f'{b:02x}' for b in result))
EOF
```

### Após deploy do Warp e IGP na rede EVM

```json
"warp_tokens": {
  "novotoken": {
    "deployed":         true,
    "address":          "0xENDERECO_WARP_EVM",
    "igp_custom":       "0xENDERECO_IGP_EVM",
    "hook_aggregation": "0xENDERECO_AGG_HOOK",
    "owner":            "0xSEU_ENDERECO"
  }
}
```

---

## 11. Scripts auxiliares

A pasta `script-certo/` contém scripts de suporte para operações pontuais — úteis tanto para correções manuais quanto para uso após o deploy inicial.

---

### `enroll-terra-router.sh` — Vincular rota EVM no Warp Terra Classic

Chama `router.set_route` no contrato Warp da **Terra Classic** para registrar um Warp EVM como roteador autorizado.

**Quando usar:**
- O deploy foi feito sem `TERRA_PRIVATE_KEY` (Etapa 7B pulada)
- O `transfer_remote` falha com `route not found`
- Precisa re-registrar a rota após troca do contrato EVM

```bash
cd ~/cw-hyperlane/script-certo
export TERRA_PRIVATE_KEY="sua_chave_terra_hex"
./enroll-terra-router.sh
```

O script apresenta menus interativos para selecionar token e rede, mostra o resumo da operação e pede confirmação antes de enviar.

> 📄 Documentação completa: [`doc/enroll-terra-router-guide.md`](./enroll-terra-router-guide.md)

---

### `transfer-cw20-terra.sh` — Transferir tokens CW20 na Terra Classic

Realiza uma transferência simples de tokens CW20 entre contas na Terra Classic.

**Configurações padrão** (sobrescrevíveis via env vars):

| Variável | Padrão |
|---|---|
| `CW20_CONTRACT_ADDRESS` | `terra1zle6pwm9...` (XPTO) |
| `SENDER_ADDRESS` | `terra12awgqgwm2...` |
| `RECIPIENT_ADDRESS` | `terra18lr7ujd9n...` |
| `AMOUNT` | `100000000000` |

```bash
cd ~/cw-hyperlane/script-certo
export TERRA_PRIVATE_KEY="sua_chave_terra_hex"

# Transferência padrão (100 XPTO)
./transfer-cw20-terra.sh

# Ou com valores customizados
export AMOUNT="50000000000"
export RECIPIENT_ADDRESS="terra1OUTRO..."
./transfer-cw20-terra.sh
```

O script exibe saldos antes e depois, salva relatório em `TRANSFER-CW20-<timestamp>.txt`.

---

## 12. Usando em outro projeto (portabilidade)

A pasta `script-certo/` foi projetada para ser **100% portável**. O script detecta automaticamente a raiz do projeto (onde está o `package.json`) subindo os diretórios.

### Copiar para um novo projeto

```bash
# Copiar a pasta inteira
cp -r script-certo/ /caminho/do/novo-projeto/script-certo/

# Entrar na pasta
cd /caminho/do/novo-projeto/script-certo/

# Executar
export ETH_PRIVATE_KEY="0xSUA_CHAVE"
export TERRA_PRIVATE_KEY="SUA_CHAVE_TERRA"
./create-warp-evm.sh
```

### O que o script resolve automaticamente

| Situação | O que acontece |
|---|---|
| `package.json` está no diretório pai | `PROJECT_ROOT` é definido como o pai |
| `config.yaml` está em `script-certo/` mas o `yarn cw-hpl` precisa na raiz | O script copia automaticamente antes de executar |
| `context/terraclassic.json` é escrito pelo `cw-hpl` na raiz | O script lê do `PROJECT_ROOT/context/` |

### Requisito único

O projeto de destino deve ser um `cw-hyperlane` com o `yarn build` já executado (ou seja, `dist/index.js` deve existir). Verifique:

```bash
ls /caminho/do/novo-projeto/dist/index.js   # deve existir
```

Se não existir:
```bash
cd /caminho/do/novo-projeto
yarn install && yarn build
```

---

## 13. Troubleshooting

### ❌ `ZodError: "received": "tron", "code": "invalid_enum_value"`

**Causa:** Hyperlane CLI abaixo da versão 26 não reconhece o protocolo `tron`.  
**Solução:** O script atualiza automaticamente. Para forçar manualmente:

```bash
npm install -g @hyperlane-xyz/cli@latest
hyperlane --version   # deve mostrar 26.x ou superior
```

---

### ❌ `"String must contain at least 1 character"` ao executar `hyperlane warp deploy`

**Causa:** `ETH_PRIVATE_KEY` não está definida ou está vazia.  
**Solução:**

```bash
export ETH_PRIVATE_KEY="0xSUA_CHAVE_COMPLETA_COM_0x"
./create-warp-evm.sh
```

---

### ❌ `"Warning: Dry run enabled, not broadcasting transaction"` (Forge v1.5+)

**Causa:** O Foundry v1.5 passou a usar dry-run por padrão no `forge create`.  
**Solução:** O script já usa `cast send --create` com bytecode compilado. Se ocorrer com versões antigas do script, atualize o script ou use Remix (Seção 8).

---

### ❌ `TimeoutError2` + `account sequence mismatch, expected N, got N-1`

**Causa:** O RPC da Terra Classic está dias atrasado. A TX foi enviada para um nó desatualizado e o CLI expirou esperando confirmação.

**Diagnóstico:**
```bash
# Comparar blocos dos RPCs
curl -s "https://rpc.luncblaze.com/status" | jq '.result.sync_info.latest_block_height'
curl -s "https://rpc.terra-classic.hexxagon.dev/status" | jq '.result.sync_info.latest_block_height'
```

**Solução:** Use sempre o `hexxagon` no `config.yaml`:

```yaml
endpoint:
   rpc:  'https://rpc.terra-classic.hexxagon.dev'
   rest: 'https://lcd.terra-classic.hexxagon.dev'
   grpc: 'https://grpc.terra-classic.hexxagon.dev'
```

---

### ❌ `"Failed to estimate gas: execution reverted"` ao chamar `setRemoteGasData`

**Causa:** `setRemoteGasData` está sendo chamado no contrato IGP em vez do **Gas Oracle**.  
**Solução:** Use o endereço do `igp.gas_oracle` do JSON, **não** o `igp_custom`:

```bash
cast send $GAS_ORACLE \
  "setRemoteGasData(uint32,uint128,uint128)" \
  1325 142244393 38325000000 \
  --rpc-url $RPC --private-key $ETH_PRIVATE_KEY --legacy
```

---

### ❌ Mensagem enviada (Sepolia → Terra Classic) mas não chega — validator não assina

**Causa:** O hook do Warp EVM não inclui o `MerkleTreeHook`. Sem ele, a mensagem **não entra na
merkle tree** do Mailbox e o validator nunca a vê para assinar o checkpoint.

Isso ocorre quando o Warp usa o `IGP customizado` diretamente como hook, sem o `AggregationHook`.

**Diagnóstico:**
```bash
RPC="https://ethereum-sepolia-rpc.publicnode.com"
WARP="0xbF43aA4878f5Ad0fcAC12Cd3A835DD3506981048"
MERKLE="0x4917a9746A7B6E0A57159cCb7F5a6744247f2d0d"

# 1. Verificar o hook atual do Warp
cast call $WARP "hook()(address)" --rpc-url $RPC

# 2. Verificar o tamanho da merkle tree — deve crescer a cada dispatch
cast call $MERKLE "count()(uint32)" --rpc-url $RPC

# 3. Verificar o último checkpoint assinado pelo validator no S3
curl -s "https://BUCKET.s3.REGION.amazonaws.com/checkpoint_latest_index.json"
# Se o índice for menor que o nonce da mensagem → validator não assinou ainda
```

**Solução:** Atualizar o hook para um `AggregationHook = [MerkleTreeHook + IGP]`:

```bash
AGG_FACTORY="0x160C28C92cA453570aD7C031972b58d5Dd128F72"
MERKLE="0x4917a9746A7B6E0A57159cCb7F5a6744247f2d0d"
IGP_CUSTOM="0xSEU_IGP_CUSTOM"

# Deploy do AggregationHook
cast send $AGG_FACTORY \
  "deploy(address[])" "[$MERKLE,$IGP_CUSTOM]" \
  --rpc-url $RPC --private-key $ETH_PRIVATE_KEY --legacy

# Obter o endereço
AGG_HOOK=$(cast call $AGG_FACTORY \
  "deploy(address[])(address)" "[$MERKLE,$IGP_CUSTOM]" \
  --rpc-url $RPC)

# Setar no Warp
cast send $WARP "setHook(address)" $AGG_HOOK \
  --rpc-url $RPC --private-key $ETH_PRIVATE_KEY --legacy
```

> O `create-warp-evm.sh` já implementa essa lógica automaticamente na Etapa 5.
> Para Warps já deployados, basta reexecutar o script com `WARP_ADDRESS` e `IGP_ADDRESS` definidos.

---

### ❌ `"destination not supported"` ao transferir

**Causa:** O hook do Warp não inclui um IGP com `hookType=4` (INTERCHAIN_GAS_PAYMASTER), ou o
`AggregationHook` está incorreto.

**Diagnóstico e solução:**

```bash
# Verificar hook atual (deve ser o AggregationHook)
cast call $WARP_ADDRESS "hook()(address)" --rpc-url $RPC

# Verificar hookType do IGP customizado (deve ser 4)
cast call $IGP_CUSTOM "hookType()(uint8)" --rpc-url $RPC

# Verificar count da merkle tree (deve crescer a cada dispatch)
cast call $MERKLE_TREE "count()(uint32)" --rpc-url $RPC

# Se o hook não for o AggregationHook correto, reconfigure (ver seção anterior)
```

---

### ❌ `"insufficient funds"` no enrollRemoteRouter

**Causa:** A carteira sendo usada não tem saldo **ou** não é o owner do Warp.  
**Diagnóstico:**

```bash
# Verificar owner do contrato
cast call $WARP_ADDRESS "owner()(address)" --rpc-url $RPC

# Verificar saldo
cast balance SEU_ENDERECO --rpc-url $RPC | xargs cast to-unit ether
```

O `enrollRemoteRouter` deve ser chamado pelo **owner** do Warp Route. Use `ETH_PRIVATE_KEY` da carteira owner.

---

### ❌ `"jq: command not found"`

```bash
sudo apt-get install -y jq        # Ubuntu/Debian
brew install jq                   # macOS
```

---

### ❌ `"RPC indisponível"`

O script tenta o RPC alternativo automaticamente. Para forçar um RPC específico, edite `rpc_urls` no `warp-evm-config.json`:

```json
"rpc_urls": [
  "https://seu-rpc-preferido.com",
  "https://rpc-alternativo.com"
]
```

---

### ⚠️ `exchange_rate` desatualizado (transferência muito cara ou muito barata)

Recalcule e atualize o `warp-evm-config.json`:

```
exchange_rate = (PRECO_ETH_USD / PRECO_LUNC_USD) × 0,01

Exemplo com ETH = $2.000 e LUNC = $0,00005:
  (2000 / 0,00005) × 0,01 = 80.000.000
```

Atualize em `igp.terra_classic_config.exchange_rate` e reexecute a Etapa 4 (Gas Oracle).

---

### ❌ `"route not found"` ao chamar `transfer_remote` na Terra Classic

**Causa:** O contrato Warp da Terra Classic não tem a rota para o domínio EVM de destino.
A Etapa 7B (`set_route`) foi pulada ou falhou durante o deploy.

**Diagnóstico:**
```bash
# Verificar rotas registradas no Warp Terra Classic
node -e "
const p=require('path'), nm=p.join('/home/lunc/cw-hyperlane','node_modules');
const {CosmWasmClient}=require(p.join(nm,'@cosmjs/cosmwasm-stargate'));
(async()=>{
  const c=await CosmWasmClient.connect('https://rpc.terra-classic.hexxagon.dev');
  const r=await c.queryContractSmart('SEU_WARP_TERRA', {router:{list_routes:{}}});
  console.log(JSON.stringify(r, null, 2));
})();"
```

**Solução:** Execute o script de correção:
```bash
export TERRA_PRIVATE_KEY="sua_chave_terra_hex"
./enroll-terra-router.sh
```

---

### ❌ Message ID não aparece nos eventos do Mailbox de destino

**Causa:** A mensagem foi despachada na origem mas o **relayer** ainda não a entregou na cadeia de destino.  
O processo de entrega Hyperlane tem 3 etapas independentes:

```
1. Origem:   Mailbox.dispatch() → gera message_id
2. Validador: assina o checkpoint e salva no S3/GCS
3. Relayer:  lê as assinaturas e chama Mailbox.process() no destino
```

**Diagnóstico completo:**
```bash
RPC="https://ethereum-sepolia-rpc.publicnode.com"
MAILBOX="0xfFAEF09B3cd11D9b20d1a19bECca54EEC2884766"
MSG_ID="0xSEU_MESSAGE_ID"

# 1. Mensagem foi entregue?
cast call $MAILBOX "delivered(bytes32)(bool)" $MSG_ID --rpc-url $RPC

# 2. Router EVM está configurado? (deve ser != 0x000...)
cast call $SEU_WARP_EVM "routers(uint32)(bytes32)" 1325 --rpc-url $RPC

# 3. Verificar no Hyperlane Explorer:
# https://explorer.hyperlane.xyz/message/$MSG_ID
```

**Causas comuns e soluções:**

| Causa | Diagnóstico | Solução |
|---|---|---|
| `enrollRemoteRouter(1325)` faltando no Warp EVM | `routers(1325)` retorna `0x000...` | `cast send $WARP "enrollRemoteRouter(uint32,bytes32)" 1325 0xHEX_TERRA --private-key $ETH_KEY --legacy` |
| Validador não assinando | Último checkpoint S3 é antigo | Reiniciar o validador Hyperlane |
| Relayer não rodando | Nenhuma tentativa de `process()` | Iniciar o relayer com `hyperlane relayer --chains sepolia` |
| Bytes32 errado no `enrollRemoteRouter` | `routers(1325)` ≠ hex do Warp Terra | Re-executar `enrollRemoteRouter` com o hex correto de 32 bytes |

> 💡 **Verificar o validador:** O validador deve ter um `checkpoint_latest_index.json` recente no seu storage (S3/GCS).
> Se o índice parou de avançar, o validador não está rodando.

---

### ❌ `enrollRemoteRouter` falha ou registra bytes32 errado (endereço EVM no lugar do Terra)

**Causa:** A função `to_bytes32` no script estava com um bug: adicionava 24 zeros de padding
(`000000000000000000000000`) antes do hash, correto para endereços EVM (20 bytes / 40 hex chars)
mas **errado** para hashes CosmWasm (32 bytes / 64 hex chars).

**Exemplo do problema:**
```
# Terra Classic Warp hex (correto = 64 chars):
d03fafd53ce350f49ba3c6ebcb1bee7cbbf453f261ec8d5ce9f36c55ab3e26a1

# Resultado errado (88 chars, cast rejeita):
000000000000000000000000d03fafd53ce350f49ba3c6ebcb1bee7cbbf453f261ec8d5ce9f36c55ab3e26a1
```

**Verificação:**
```bash
cast call $WARP_EVM "routers(uint32)(bytes32)" 1325 --rpc-url $RPC
# Se retornar 0x000...000 ou um valor com 24 zeros extras no início: re-executar
```

**Solução manual:**
```bash
# Pegar o hex correto do warp-evm-config.json:
HEX=$(jq -r '.terra_classic.tokens.xpto.terra_warp.warp_hexed' warp-evm-config.json)
HEX="${HEX#0x}"  # remover 0x

# Verificar tamanho (deve ser 64):
echo ${#HEX}

# Executar com o hex correto:
cast send $WARP_EVM \
  "enrollRemoteRouter(uint32,bytes32)" \
  1325 "0x${HEX}" \
  --rpc-url $RPC --private-key $ETH_PRIVATE_KEY --legacy
```

> O script `create-warp-evm.sh` está corrigido desde a versão atual (usa `printf '%064s' ... | tr ' ' '0'`).

---

## 🔗 Links úteis

| Recurso | URL |
|---|---|
| Hyperlane Docs | [docs.hyperlane.xyz](https://docs.hyperlane.xyz/) |
| Hyperlane Explorer | [explorer.hyperlane.xyz](https://explorer.hyperlane.xyz) |
| Foundry (forge/cast) | [book.getfoundry.sh](https://book.getfoundry.sh/) |
| Remix IDE | [remix.ethereum.org](https://remix.ethereum.org) |
| Sepolia Etherscan | [sepolia.etherscan.io](https://sepolia.etherscan.io) |
| BSC Testnet Explorer | [testnet.bscscan.com](https://testnet.bscscan.com) |
| Terra Classic Finder | [finder.terra-classic.hexxagon.dev/testnet](https://finder.terra-classic.hexxagon.dev/testnet) |
| Faucet Sepolia | [sepoliafaucet.com](https://sepoliafaucet.com) |
| Faucet BSC Testnet | [testnet.binance.org/faucet-smart](https://testnet.binance.org/faucet-smart) |
