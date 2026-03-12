# Guia Completo: `create-warp-sealevel.sh`

> Script interativo para criar e configurar Warp Routes Hyperlane em **Solana (Sealevel)** conectados à Terra Classic.  
> Totalmente portável — basta copiar a pasta `script-warp-terraclassic/` para qualquer projeto `cw-hyperlane`.

---

## 📋 Índice

1. [O que o script faz](#1-o-que-o-script-faz)
2. [Diferenças Sealevel vs EVM](#2-diferenças-sealevel-vs-evm)
3. [Pré-requisitos](#3-pré-requisitos)
4. [Estrutura de arquivos](#4-estrutura-de-arquivos)
5. [Configurando o `warp-sealevel-config.json`](#5-configurando-o-warp-sealevel-configjson)
   - [Seção `networks`](#51-seção-networks)
   - [Seção `warp_tokens`](#52-seção-warp_tokens)
   - [Adicionando um novo token](#53-adicionando-um-novo-token)
   - [Habilitando Solana Mainnet](#54-habilitando-solana-mainnet)
6. [Configurando o `warp-evm-config.json` (tokens Terra Classic)](#6-configurando-o-warp-evm-configjson-tokens-terra-classic)
7. [Metadata dos tokens (Solana)](#7-metadata-dos-tokens-solana)
8. [Executando o script](#8-executando-o-script)
   - [Execução completa (do zero)](#81-execução-completa-do-zero)
   - [Pulando etapas já executadas](#82-pulando-etapas-já-executadas)
   - [Retomando após falha](#83-retomando-após-falha)
9. [O que o script configura — Passos detalhados](#9-o-que-o-script-configura--passos-detalhados)
10. [Atualizando o JSON após o deploy](#10-atualizando-o-json-após-o-deploy)
11. [Deploy e configuração manual (sem o script)](#11-deploy-e-configuração-manual-sem-o-script)
12. [Como verificar o estado após o deploy](#12-como-verificar-o-estado-após-o-deploy)
13. [Como encontrar endereços Hyperlane no Solana](#13-como-encontrar-endereços-hyperlane-no-solana)
14. [Como verificar o recebimento de tokens após transferência](#14-como-verificar-o-recebimento-de-tokens-após-transferência)
15. [Troubleshooting](#15-troubleshooting)
16. [Referência de endereços deployados](#16-referência-de-endereços-deployados)
17. [Links úteis](#17-links-úteis)

---

## 1. O que o script faz

O `create-warp-sealevel.sh` automatiza o deploy e a configuração completa de um Warp Route Hyperlane no **Solana (Sealevel)**, conectado à Terra Classic.

Para cada par **token + rede Solana** escolhido, o script executa automaticamente:

| Passo | Componente | O que é | Por que é necessário |
|-------|-----------|---------|---------------------|
| 1 | **Warp Route (Program)** | Programa Solana SPL implantado via `warp-route deploy` | Ponto de entrada/saída no Solana |
| 2 | **ISM** | MultisigISM (`multisig-ism-message-id`) | Valida que as mensagens vieram da Terra Classic |
| 3 | **IGP** | Interchain Gas Paymaster (Overhead IGP) | Estima e cobra gas para execução na Terra Classic |
| 4 | **Destination Gas** | `set-destination-gas-amount` | Configura o custo de gas para o domínio Terra Classic |
| 5 | **enrollRemoteRouter** | Enrola o Warp Terra Classic no Solana | Autoriza o Solana a aceitar mensagens da Terra Classic |
| 6 | **set_route (Terra)** | Chama `router.set_route` no Warp Terra Classic | Autoriza a Terra Classic a enviar para o Solana |

---

## 2. Diferenças Sealevel vs EVM

| Aspecto | EVM (Sepolia, BSC...) | Sealevel (Solana) |
|---------|----------------------|-------------------|
| Deploy do Warp | `hyperlane warp deploy` (CLI TS) | `warp-route deploy` (cliente Rust) |
| Endereço do router | Endereço hex 20 bytes (EVM address) | Program ID base58 (32 bytes) |
| Hook | AggregationHook = MerkleTree + IGP | Sem AggregationHook — IGP é configurado diretamente |
| ISM | `messageIdMultisigIsm` (EVM contract) | `multisig-ism-message-id` (Solana program) |
| IGP | `TerraClassicIGPStandalone.sol` | Overhead IGP nativo do Hyperlane Solana |
| Token SPL | — | Mint Address criado automaticamente pelo deploy |
| Ferramentas | Foundry (cast/forge), hyperlane CLI | Rust (cargo), solana-cli |
| Metadata imagem | Não exigida | URL deve existir e ser acessível (ou campo vazio `""`) |

> **Importante:** No Sealevel, o **AggregationHook não é necessário**. O validator do Solana usa o `MerkleTree` internamente — o IGP é configurado como programa separado, não como hook do Warp.

---

## 3. Pré-requisitos

### Ferramentas obrigatórias

| Ferramenta | Versão mínima | Instalação |
|-----------|--------------|-----------|
| `bash` | 4+ | nativo no Linux/macOS |
| `jq` | 1.6+ | `apt install jq` |
| `python3` | 3.8+ | nativo no Linux |
| `node` + `npm` | Node 18+ | `nvm install 18` |
| `cargo` (Rust) | 1.70+ | `curl https://sh.rustup.rs -sSf \| sh` |
| `solana` CLI | 1.18+ | [https://docs.solana.com/cli/install-solana-cli-tools](https://docs.solana.com/cli/install-solana-cli-tools) |

### Pacotes Node.js necessários

O script usa `@cosmjs/cosmwasm-stargate` para executar transações na Terra Classic.  
Instale na raiz do projeto `cw-hyperlane`:

```bash
cd ~/cw-hyperlane
npm install @cosmjs/cosmwasm-stargate @cosmjs/proto-signing
```

### Binário Rust do cliente Sealevel

O deploy do Warp no Solana usa o cliente Rust do Hyperlane Monorepo:

```bash
cd /home/lunc/hyperlane-monorepo/rust/sealevel
cargo build --release -p hyperlane-sealevel-client
# Binário: target/release/hyperlane-sealevel-client
```

### Keypair Solana

Precisa de um arquivo JSON de keypair Solana com saldo suficiente (mínimo ~1 SOL para deploy):

```bash
solana-keygen new --outfile /home/lunc/keys/solana-keypair-MEU_PUBKEY.json
solana airdrop 2 --url https://api.testnet.solana.com MEU_PUBKEY
```

### Chave privada Terra Classic

Exportar antes de executar o script:

```bash
export TERRA_PRIVATE_KEY="sua_chave_privada_terra_em_hex"
```

---

## 4. Estrutura de arquivos

```
script-warp-terraclassic/
├── create-warp-sealevel.sh       # Script principal
├── warp-sealevel-config.json     # Config redes Solana + tokens warp
├── warp-evm-config.json          # Config tokens Terra Classic (compartilhado com EVM)
├── .warp-sealevel-state.json     # Estado do último deploy (gerado automaticamente)
├── log/
│   ├── create-warp-sealevel.log      # Log de execução
│   └── WARP-SOLANATESTNET-XPTO.txt   # Relatório final gerado após deploy (exemplo)
└── doc/
    └── create-warp-sealevel-guide.md  # Este documento

warp/solana/
├── metadata-xpto.json            # Metadata SPL para XPTO
├── metadata-xptv.json            # Metadata SPL para XPTV
├── metadata-xpv.json             # Metadata SPL para XPV
├── metadata-ustc.json            # Metadata SPL para USTC
└── metadata.json                 # Metadata SPL para wLUNC
```

---

## 5. Configurando o `warp-sealevel-config.json`

Este arquivo centraliza toda a configuração das redes Solana e os tokens Warp deploados.

### 5.1 Seção `networks`

```json
{
  "networks": {
    "solanatestnet": {
      "enabled": true,
      "display_name": "Solana Testnet",
      "environment": "testnet",
      "domain": 1399811150,
      "rpc": "https://api.testnet.solana.com",
      "explorer": "https://explorer.solana.com/?cluster=testnet",
      "keypair": "/caminho/para/solana-keypair.json",
      "monorepo_dir": "/home/lunc/hyperlane-monorepo/rust/sealevel",
      "ism": {
        "program_id": "5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh",
        "threshold": 1
      },
      "igp": {
        "program_id": "5p7Hii6CJL4xGBYYTGEQmH9LnUSZteFJUu9AVLDExZX2",
        "account": "E9i32KsKGQZMYTguZ81VHUueNvpTGh7nb9J5bRif4xT1",
        "destination_gas_terra": 3000000
      },
      "warp_tokens": { ... }
    }
  }
}
```

| Campo | Descrição |
|-------|-----------|
| `enabled` | `true` para habilitar a rede no menu. Use `false` para ocultar |
| `domain` | Domínio Hyperlane da rede. Solana Testnet = `1399811150`, Mainnet = `1399811149` |
| `keypair` | Caminho absoluto para o arquivo `.json` da keypair Solana |
| `monorepo_dir` | Caminho para `hyperlane-monorepo/rust/sealevel` (onde fica o binário) |
| `ism.program_id` | Program ID do MultisigISM que valida msgs da Terra Classic |
| `ism.threshold` | Número mínimo de validadores para aceitar a mensagem |
| `igp.program_id` | Program ID do IGP Overhead |
| `igp.account` | Conta pública do IGP (usada como `interchainGasPaymaster` no token-config) |
| `igp.destination_gas_terra` | Unidades de gas usadas na Terra Classic (padrão: `3000000`) |

### 5.2 Seção `warp_tokens`

```json
"warp_tokens": {
  "xpto": {
    "deployed": true,
    "type": "synthetic",
    "program_id": "FNzjjdex7mx5CpcA5NmWtUcL4wZ1J2xctT4qbQ1RrSrq",
    "program_hex": "0xd5a618e0c5bcb84675444410b4981e512af1bf3e04ac9dbdbe3618e0496c11b6",
    "mint_address": "FmSCs8FcQPwXdw5Y4uvAPLfGAXqg8iQpwuiqUxosiu4M",
    "metadata_uri": "https://raw.githubusercontent.com/igorv43/cw-hyperlane/refs/heads/main/warp/solana/metadata-xpto.json",
    "decimals": 6,
    "owner": "EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd"
  }
}
```

| Campo | Descrição |
|-------|-----------|
| `deployed` | `true` após o deploy bem-sucedido. O script pula o deploy se for `true` e `program_id` estiver preenchido |
| `type` | `"synthetic"` para tokens CW20/native que viram SPL no Solana |
| `program_id` | Program ID base58 do Warp Route no Solana (preenchido após deploy) |
| `program_hex` | Mesmo Program ID em hex bytes32 com `0x` (preenchido automaticamente) |
| `mint_address` | Endereço base58 do token SPL criado (preenchido após deploy) |
| `metadata_uri` | URL da metadata JSON do token (ver seção 7). Pode ser `""` para omitir |
| `decimals` | Decimais do token (deve coincidir com o token na Terra Classic) |
| `owner` | Pubkey do dono/deployer da Solana |

### 5.3 Adicionando um novo token

1. Adicione a entrada em `warp-evm-config.json` → `.terra_classic.tokens.MEU_TOKEN` (ver [seção 6](#6-configurando-o-warp-evm-configjson-tokens-terra-classic))

2. Adicione em `warp-sealevel-config.json` → `.networks.solanatestnet.warp_tokens`:

```json
"meu_token": {
  "_comment": "MEU_TOKEN CW20 → token sintético no Solana",
  "deployed": false,
  "type": "synthetic",
  "program_id": "",
  "program_hex": "",
  "mint_address": "",
  "metadata_uri": "https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/warp/solana/metadata-meu_token.json",
  "decimals": 6,
  "owner": "SEU_PUBKEY_SOLANA"
}
```

3. Crie o arquivo de metadata `warp/solana/metadata-meu_token.json` (ver [seção 7](#7-metadata-dos-tokens-solana))

4. Execute o script normalmente.

### 5.4 Habilitando Solana Mainnet

1. Preencha todos os campos da seção `"solana"` em `warp-sealevel-config.json` com os endereços reais da mainnet
2. Mude `"enabled": false` para `"enabled": true`
3. Configure o `keypair` com um caminho para uma keypair Solana Mainnet com saldo
4. O script vai mostrar a rede no menu automaticamente

---

## 6. Configurando o `warp-evm-config.json` (tokens Terra Classic)

O script usa o `warp-evm-config.json` para obter os dados dos tokens na Terra Classic (endereço do Warp TC, domínio, tipo de token etc.). Este é o mesmo arquivo compartilhado com o script EVM.

Estrutura relevante para Sealevel:

```json
{
  "terra_classic": {
    "domain": 1325,
    "chain_id": "rebel-2",
    "rpc": "https://rpc.terra-classic.hexxagon.dev",
    "lcd": "https://terra-classic-lcd.publicnode.com",
    "tokens": {
      "xpto": {
        "name": "XPTO Token",
        "symbol": "XPTO",
        "decimals": 6,
        "image": "https://...",
        "terra_warp": {
          "type": "cw20",
          "mode": "collateral",
          "deployed": true,
          "warp_address": "terra16ql6l4fuudg0fxarcm4ukxlw0jalg5ljv8kg6h8f7dk9t2e7y6ssq2hqrm",
          "warp_hexed":   "0xd03fafd53ce350f49ba3c6ebcb1bee7cbbf453f261ec8d5ce9f36c55ab3e26a1",
          "collateral_address": "terra1zle6pwm9aztwu228e0spxrydlvmhj2qrq8ap3x2wrjc52kdvu4fs20rkch",
          "owner": "terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze"
        }
      }
    }
  }
}
```

> O Warp Terra Classic (`warp_address`) precisa estar deployado antes de executar o script Sealevel, pois o script precisa registrar a rota Solana ↔ Terra em ambos os lados.

---

## 7. Metadata dos tokens (Solana)

O cliente Rust valida a metadata ao fazer o deploy do token SPL. O arquivo deve estar disponível via HTTP(S).

### Formato do arquivo (`warp/solana/metadata-xpto.json`)

```json
{
  "name": "XPTO Token",
  "symbol": "XPTO",
  "description": "XPTO Token via Hyperlane Warp Route",
  "image": "",
  "attributes": []
}
```

| Campo | Obrigatório | Descrição |
|-------|-------------|-----------|
| `name` | ✅ Sim | Nome completo do token |
| `symbol` | ✅ Sim | Símbolo (ticker) |
| `description` | ✅ Sim | Descrição breve |
| `image` | ❌ Opcional | URL de imagem (PNG/SVG). Pode ser `""` para omitir |
| `attributes` | ❌ Opcional | Array de atributos adicionais |

> **Nota:** Se `image` for `""` (string vazia), o cliente Rust aceita sem validação (comportamento corrigido no patch local). Se quiser logo, use uma URL pública direta (ex: raw.githubusercontent.com).

### O script auto-detecta a acessibilidade da URI

- Se `metadata_uri` retornar **HTTP 200** → o campo `uri` é incluído no `token-config.json` → token SPL terá metadata on-chain
- Se `metadata_uri` retornar **HTTP 404** ou estiver **vazio** → o campo `uri` é **omitido** → token SPL é criado sem metadata on-chain (você pode atualizar depois)

Para hospedar a metadata no GitHub, faça o commit do arquivo e use a URL raw:

```
https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/refs/heads/main/warp/solana/metadata-TOKEN.json
```

---

## 8. Executando o script

### 8.1 Execução completa (do zero)

```bash
cd ~/cw-hyperlane/script-warp-terraclassic

# Exportar chaves
export TERRA_PRIVATE_KEY="sua_chave_privada_terra_hex"
# (não precisa de ETH_PRIVATE_KEY — o script é só Solana + Terra Classic)

chmod +x create-warp-sealevel.sh
./create-warp-sealevel.sh
```

O script vai:
1. Verificar ferramentas e configurações
2. Exibir menu para selecionar o **token** (da Terra Classic)
3. Exibir menu para selecionar a **rede Solana**
4. Executar os 6 passos automaticamente
5. Gravar um relatório `log/WARP-SOLANATESTNET-TOKEN.txt`

### 8.2 Pulando etapas já executadas

Use variáveis de ambiente para pular etapas específicas:

| Variável | Efeito |
|----------|--------|
| `export WARP_PROGRAM_ID="Base58ID"` | Pula deploy do Warp Solana (usa o programa existente) |
| `export SKIP_ISM="1"` | Pula configuração do ISM |
| `export SKIP_IGP="1"` | Pula configuração do IGP |
| `export SKIP_GAS="1"` | Pula `set-destination-gas-amount` |
| `export SKIP_ENROLL="1"` | Pula `enroll-remote-router` (Solana → Terra Classic) |
| `export SKIP_TC_ROUTE="1"` | Pula `set_route` na Terra Classic (Terra → Solana) |

Exemplo: token já deployado, só reconfigurar a rota Terra Classic:

```bash
export TERRA_PRIVATE_KEY="..."
export WARP_PROGRAM_ID="FNzjjdex7mx5CpcA5NmWtUcL4wZ1J2xctT4qbQ1RrSrq"
export SKIP_ISM="1"
export SKIP_IGP="1"
export SKIP_GAS="1"
export SKIP_ENROLL="1"
./create-warp-sealevel.sh
```

### 8.3 Retomando após falha

O script salva o estado em `.warp-sealevel-state.json`. Se houver falha, o estado é restaurado automaticamente na próxima execução **para o mesmo token + rede**.

Para descartar o estado e começar do zero:

```bash
rm -f ~/cw-hyperlane/script-warp-terraclassic/.warp-sealevel-state.json
```

---

## 9. O que o script configura — Passos detalhados

### Passo 1 — Deploy do Warp Route no Solana

O script gera um `token-config.json` e chama:

```bash
hyperlane-sealevel-client \
  -k /caminho/keypair.json \
  -u https://api.testnet.solana.com \
  warp-route deploy \
  --warp-route-name TOKEN \
  --environment testnet \
  --environments-dir .../environments \
  --token-config-file .../token-config.json \
  --built-so-dir .../target/deploy \
  --registry ~/.hyperlane/registry \
  --ata-payer-funding-amount 5000000
```

**Resultado:** Program ID + Mint Address do token SPL.

O `token-config.json` gerado tem o formato:

```json
{
  "solanatestnet": {
    "type": "synthetic",
    "name": "XPTO Token",
    "symbol": "XPTO",
    "decimals": 6,
    "totalSupply": "0",
    "interchainGasPaymaster": "E9i32KsKGQZMYTguZ81VHUueNvpTGh7nb9J5bRif4xT1",
    "uri": "https://raw.githubusercontent.com/..."
  }
}
```

### Passo 2 — Configurar ISM

Define qual programa ISM o Warp Route deve usar para validar mensagens recebidas. O script usa o comando `token set-interchain-security-module` do cliente Rust:

```bash
hyperlane-sealevel-client \
  -k /caminho/keypair.json \
  -u https://api.testnet.solana.com \
  token set-interchain-security-module \
  --program-id WARP_PROGRAM_ID \
  --ism ISM_PROGRAM_ID
```

> **Diferença importante:** Este comando associa o ISM *ao Warp token*, não cadastra validadores no ISM. O ISM Solana (`5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh`) já deve ter os validadores da Terra Classic pré-cadastrados via `multisig-ism-message-id enroll-validators` (feito uma única vez, separadamente, ao configurar a infraestrutura Hyperlane).

### Passo 3 — Configurar IGP

Associa o programa IGP e a conta IGP ao Warp Route, para que o cálculo de gas seja feito corretamente no lado Solana:

```bash
hyperlane-sealevel-client \
  -k /caminho/keypair.json \
  -u https://api.testnet.solana.com \
  token igp \
  --program-id WARP_PROGRAM_ID \
  set IGP_PROGRAM_ID igp IGP_ACCOUNT
```

### Passo 4 — Destination Gas

Define a quantidade de gas (em unidades da Terra Classic) que o Warp Solana vai estimar para as mensagens que vão para a Terra Classic:

```bash
hyperlane-sealevel-client \
  -k /caminho/keypair.json \
  -u https://api.testnet.solana.com \
  token set-destination-gas \
  --program-id WARP_PROGRAM_ID \
  TERRA_DOMAIN DEST_GAS_AMOUNT
# ex: TERRA_DOMAIN = 1325, DEST_GAS_AMOUNT = 3000000
```

### Passo 5 — Enroll Remote Router (Solana → Terra Classic)

Registra o Warp Terra Classic como rota autorizada no Warp Solana:

```bash
hyperlane-sealevel-client \
  -k /caminho/keypair.json \
  -u https://api.testnet.solana.com \
  token enroll-remote-router \
  --program-id WARP_PROGRAM_ID \
  TERRA_DOMAIN 0xTERRA_WARP_HEX_32BYTES
# ex: 1325 0xd03fafd53ce350f49ba3c6ebcb1bee7cbbf453f261ec8d5ce9f36c55ab3e26a1
```

### Passo 6 — Set Route (Terra Classic → Solana)

Registra o Warp Solana como rota autorizada no Warp Terra Classic (via Node.js + CosmJS):

```js
// Mensagem executada no contrato terra_warp_address
// ⚠️ IMPORTANTE: o campo "route" deve ser o hex de 32 bytes SEM o prefixo "0x"
{
  "router": {
    "set_route": {
      "set": {
        "domain": 1399811150,
        "route": "0adafdae59c217a1b7409f65ca81505f9991c257be80af8902ebed96d8801ba6"
      }
    }
  }
}
```

> **Nota:** O contrato CosmWasm da Terra Classic **rejeita** o prefixo `0x` na rota — use apenas os 64 caracteres hex sem prefixo.

> **Verificação inteligente:** O script verifica não apenas se a rota existe, mas também se ela aponta para o Program ID correto. Se estiver apontando para um Program ID antigo (de um deploy anterior fracassado), a rota é **atualizada automaticamente**.

---

## 10. Atualizando o JSON após o deploy

Após o deploy bem-sucedido, **atualize o `warp-sealevel-config.json`** para registrar os endereços:

```json
"xpto": {
  "deployed": true,
  "type": "synthetic",
  "program_id": "jNkiNLXQetj9L2tDX6xTgx9QP1tgtNgYXamouNbbwx9",
  "program_hex": "0x0adafdae59c217a1b7409f65ca81505f9991c257be80af8902ebed96d8801ba6",
  "mint_address": "Db8VbMerYxksYwSSdetpy6Jhp2BrE4hk9Sh9dYJT5dQ2",
  "metadata_uri": "https://raw.githubusercontent.com/igorv43/cw-hyperlane/refs/heads/main/warp/solana/metadata-xpto.json",
  "decimals": 6,
  "owner": "EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd"
}
```

> O script grava um relatório `log/WARP-SOLANATESTNET-TOKEN.txt` com todos os endereços. Use-o como referência.

---

## 11. Deploy e configuração manual (sem o script)

### 11.1 Gerar token-config.json manualmente

```json
{
  "solanatestnet": {
    "type": "synthetic",
    "name": "NOME_TOKEN",
    "symbol": "SYM",
    "decimals": 6,
    "totalSupply": "0",
    "interchainGasPaymaster": "CONTA_IGP_BASE58",
    "uri": "https://URL_DA_METADATA.json"
  }
}
```

Salve em: `environments/testnet/warp-routes/TOKEN/token-config.json`

### 11.2 Deploy do Warp Solana

```bash
cd /home/lunc/hyperlane-monorepo/rust/sealevel

./target/release/hyperlane-sealevel-client \
  -k /caminho/keypair.json \
  -u https://api.testnet.solana.com \
  warp-route deploy \
  --warp-route-name TOKEN \
  --environment testnet \
  --environments-dir ./environments \
  --token-config-file ./environments/testnet/warp-routes/TOKEN/token-config.json \
  --built-so-dir ./target/deploy \
  --registry ~/.hyperlane/registry \
  --ata-payer-funding-amount 5000000
```

Após o deploy, o Program ID e Mint Address ficam salvos em:
```
environments/testnet/warp-routes/TOKEN/program-ids.json
```

### 11.3 Configurar ISM manualmente

```bash
./target/release/hyperlane-sealevel-client \
  -k /caminho/keypair.json \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id enroll-validators \
  --program-id 5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh \
  --domains 1325 \
  --validators 0xENDERECO_VALIDATOR_TERRA \
  --threshold 1
```

> Para encontrar o endereço do validador da Terra Classic:  
> Consulte `ValidatorAnnounce` na Terra Classic ou veja o `agent-config.json`.

### 11.4 Configurar Destination Gas manualmente

```bash
./target/release/hyperlane-sealevel-client \
  -k /caminho/keypair.json \
  -u https://api.testnet.solana.com \
  igp set-destination-gas-amount \
  --program-id 5p7Hii6CJL4xGBYYTGEQmH9LnUSZteFJUu9AVLDExZX2 \
  --destination-domain 1325 \
  --gas-amount 3000000
```

### 11.5 Enroll Remote Router (Solana → Terra Classic) manualmente

```bash
./target/release/hyperlane-sealevel-client \
  -k /caminho/keypair.json \
  -u https://api.testnet.solana.com \
  warp-route enroll-remote-router \
  --program-id PROGRAM_ID_DO_WARP_SOLANA \
  --destination-domain 1325 \
  --router 0xTERRA_WARP_HEX_32BYTES
```

> O hex do Warp Terra Classic pode ser obtido em `warp-evm-config.json` → `terra_classic.tokens.TOKEN.terra_warp.warp_hexed`  
> Ou convertendo manualmente:
> ```bash
> python3 -c "
> import bech32
> _, data = bech32.decode('terra', 'terra16ql...')
> print('0x' + bytes(bech32.convertbits(data, 5, 8, False)).hex().zfill(64))
> "
> ```

### 11.6 Set Route (Terra Classic → Solana) manualmente

> ⚠️ **Importante:** O campo `route` deve ser o hex de 32 bytes do Program ID Solana **sem o prefixo `0x`**. O contrato CosmWasm rejeita o formato `0x...` com erro `invalid hex`.

Para converter o Program ID base58 para hex sem `0x`:

```bash
python3 -c "
import base58
program_id = 'jNkiNLXQetj9L2tDX6xTgx9QP1tgtNgYXamouNbbwx9'
print(base58.b58decode(program_id).hex())
# saída: 0adafdae59c217a1b7409f65ca81505f9991c257be80af8902ebed96d8801ba6
"
```

Usando Node.js diretamente (não precisa de chave no keyring — método recomendado):

```bash
export TERRA_PRIVATE_KEY="sua_chave_privada_hex"

node - <<'EOF'
const { SigningCosmWasmClient } = require("@cosmjs/cosmwasm-stargate");
const { DirectSecp256k1Wallet } = require("@cosmjs/proto-signing");
const { GasPrice } = require("@cosmjs/stargate");

async function main() {
  const privkeyHex = process.env.TERRA_PRIVATE_KEY;
  const privkeyBytes = Buffer.from(privkeyHex, "hex");
  const wallet = await DirectSecp256k1Wallet.fromKey(privkeyBytes, "terra");
  const [account] = await wallet.getAccounts();
  const client = await SigningCosmWasmClient.connectWithSigner(
    "https://rpc.terra-classic.hexxagon.dev",
    wallet,
    { gasPrice: GasPrice.fromString("0.015uluna") }
  );

  // ⚠️ route = hex de 32 bytes SEM "0x"
  const programHex = "0adafdae59c217a1b7409f65ca81505f9991c257be80af8902ebed96d8801ba6";

  const result = await client.execute(
    account.address,
    "TERRA_WARP_ADDRESS",                           // ex: terra16ql6l4fu...
    { router: { set_route: { set: { domain: 1399811150, route: programHex } } } },
    "auto",
    "set_route TC → Solana"
  );
  console.log("TX:", result.transactionHash);
}
main().catch(e => { console.error(e); process.exit(1); });
EOF
```

Verificar se a rota foi gravada corretamente:

```bash
terrad query wasm contract-state smart TERRA_WARP_ADDRESS \
  '{"router":{"get_route":{"domain":1399811150}}}' \
  --node https://rpc.terra-classic.hexxagon.dev
# Saída esperada: route: "0adafdae..." (sem 0x, ou com 0x dependendo da versão do contrato)
```

> Para verificar usando a lista completa de rotas:
> ```bash
> terrad query wasm contract-state smart TERRA_WARP_ADDRESS \
>   '{"router":{"list_routes":{}}}' \
>   --node https://rpc.terra-classic.hexxagon.dev
> ```

---

## 12. Como verificar o estado após o deploy

### Verificar o Warp Solana (token query)

```bash
cd /home/lunc/hyperlane-monorepo/rust/sealevel

./target/release/hyperlane-sealevel-client \
  -k /caminho/keypair.json \
  -u https://api.testnet.solana.com \
  token query \
  --program-id PROGRAM_ID_BASE58 \
  synthetic
```

**Saída esperada:** Nome, símbolo, decimais, mint address, ISM program.

### Verificar o ISM Solana

```bash
./target/release/hyperlane-sealevel-client \
  -k /caminho/keypair.json \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id 5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh \
  --domains 1325
```

**Saída esperada:** Threshold = 1, validador registrado = endereço do validator Terra Classic.

### Verificar rota na Terra Classic

```bash
terrad query wasm contract-state smart TERRA_WARP_ADDRESS \
  '{"router":{"get_route":{"domain":1399811150}}}' \
  --node https://rpc.terra-classic.hexxagon.dev
```

**Saída esperada:** `route: "0adafdae59c217a1b7409f65ca81505f9991c257be80af8902ebed96d8801ba6"` (hex de 32 bytes do Program ID Solana).

> ⚠️ **Atenção:** Verifique que o hex retornado corresponde ao **Program ID real no Solana** (não a um deploy anterior fracassado). Para confirmar:
> ```bash
> solana account PROGRAM_ID_BASE58 --url https://api.testnet.solana.com
> # Deve retornar dados da conta. "AccountNotFound" = deploy não aconteceu.
> ```
> Se a rota estiver apontando para um Program ID antigo, corrija usando o método manual da seção 11.6.

### Verificar a rota no Warp Solana (Remote Router)

No Explorer do Solana, acesse o Program ID do Warp e verifique as contas associadas.  
Ou use a query Rust:

```bash
./target/release/hyperlane-sealevel-client \
  -k /caminho/keypair.json \
  -u https://api.testnet.solana.com \
  warp-route query \
  --program-id PROGRAM_ID_BASE58
```

---

## 13. Como encontrar endereços Hyperlane no Solana

### Usando o Hyperlane Registry

O Hyperlane Registry está em `~/.hyperlane/registry/` após instalar o CLI:

```bash
npm install -g @hyperlane-xyz/cli@latest
```

Para listar endereços do Solana Testnet:

```bash
hyperlane registry list
# ou consultando diretamente:
cat ~/.hyperlane/registry/chains/solanatestnet/addresses.yaml
```

### Endereços oficiais Solana Testnet (Hyperlane)

| Contrato | Program ID |
|---------|-----------|
| Mailbox | `692KZJaoe2KRcD6uhCTDTeHbkoxHSFDMm5TKAwA7v2fE` |
| IGP (Overhead) | `5p7Hii6CJL4xGBYYTGEQmH9LnUSZteFJUu9AVLDExZX2` |
| IGP Account | `E9i32KsKGQZMYTguZ81VHUueNvpTGh7nb9J5bRif4xT1` |
| MultisigISM | `5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh` |
| ValidatorAnnounce | `DH43ae1LwemXAboWwSh8zc9pG8j72gKUEXNi57w8SPSN` |

### Domínios Hyperlane

| Rede | Domain ID |
|------|-----------|
| Terra Classic (rebel-2) | `1325` |
| Solana Testnet | `1399811150` |
| Solana Mainnet | `1399811149` |
| Sepolia | `11155111` |
| BSC Testnet | `97` |

> Fonte oficial: [https://docs.hyperlane.xyz/docs/reference/domains](https://docs.hyperlane.xyz/docs/reference/domains)

---

## 14. Como verificar o recebimento de tokens após transferência

> ⚠️ **Atenção:** Tokens que chegam via Warp Route são **tokens CW20** (Terra Classic) ou **tokens SPL** (Solana). Eles **não aparecem como saldo nativo** (LUNA / SOL) na carteira — você precisa consultar o contrato específico.

---

### 14.1 Verificar saldo CW20 na Terra Classic (destino: Solana → Terra Classic)

Quando você envia tokens do Solana para a Terra Classic, os tokens chegam como CW20 no Warp Collateral (endereço do colateral que foi travado antes).

**Verificar via terminal:**

```bash
# Substitua:
# - CW20_CONTRACT = endereço do contrato CW20 (terra1zle6...)
# - RECIPIENT      = endereço do destinatário na Terra Classic

terrad query wasm contract-state smart \
  CW20_CONTRACT \
  '{"balance":{"address":"RECIPIENT"}}' \
  --node https://rpc.terra-classic.hexxagon.dev:443
```

**Exemplo real (XPTO):**

```bash
terrad query wasm contract-state smart \
  terra1zle6pwm9aztwu228e0spxrydlvmhj2qrq8ap3x2wrjc52kdvu4fs20rkch \
  '{"balance":{"address":"terra18lr7ujd9nsgyr49930ppaajhadzrezam70j39k"}}' \
  --node https://rpc.terra-classic.hexxagon.dev:443
# Saída: data: { balance: "99515999100" }
#        = 99.515,999 XPTO (dividir por 10^6 para decimais=6)
```

**Verificar via Explorer:**

Acesse `https://finder.hexxagon.io/rebel-2/address/RECIPIENT` e procure a aba **"CW20 Tokens"** ou **"Token Balances"**.

---

### 14.2 Verificar saldo SPL na Solana (destino: Terra Classic → Solana)

Quando você envia tokens da Terra Classic para a Solana, os tokens chegam como SPL na conta associada (ATA — Associated Token Account) do destinatário.

**Verificar via terminal:**

```bash
# Listar todos os tokens SPL de uma conta Solana
spl-token accounts --owner DESTINATARIO_PUBKEY --url https://api.testnet.solana.com

# Ou verificar saldo de um Mint específico
spl-token balance --owner DESTINATARIO_PUBKEY MINT_ADDRESS --url https://api.testnet.solana.com
```

**Exemplo real (XPTO):**

```bash
spl-token balance \
  --owner EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd \
  Db8VbMerYxksYwSSdetpy6Jhp2BrE4hk9Sh9dYJT5dQ2 \
  --url https://api.testnet.solana.com
```

**Verificar via Explorer:**

Acesse `https://explorer.solana.com/address/DESTINATARIO?cluster=testnet` e procure a aba **"Tokens"**.

---

### 14.3 Verificar se a mensagem foi entregue no Terra Classic Mailbox

Para confirmar que a mensagem foi processada (independente da carteira):

```bash
MAILBOX="terra1s4jwfe0tcaztpfsct5wzj02esxyjy7e7lhkcwn5dp04yvly82rwsvzyqmm"
MESSAGE_ID="SEU_MESSAGE_ID_SEM_0x"  # ex: 830a1e166747001c54097299...

terrad query wasm contract-state smart "$MAILBOX" \
  "{\"mailbox\":{\"message_delivered\":{\"id\":\"${MESSAGE_ID}\"}}}" \
  --node https://rpc.terra-classic.hexxagon.dev:443
# Saída: data: { delivered: true }  ← mensagem entregue com sucesso
# Saída: data: { delivered: false } ← ainda pendente (relayer não processou)
```

---

### 14.4 Rastrear uma mensagem passo a passo

Dado o **message ID** de uma transferência Solana → Terra Classic, verifique em ordem:

| Passo | Verificação | URL / Comando |
|-------|-------------|--------------|
| 1 | TX na Solana | `https://explorer.solana.com/tx/TX_HASH?cluster=testnet` |
| 2 | Checkpoints do validator TC | `https://hyperlane-validator-signatures-igorveras-terraclassic.s3.us-east-1.amazonaws.com/` |
| 3 | Entrega no TC Mailbox | `terrad query wasm ... message_delivered {id: "..."}` |
| 4 | Saldo CW20 no destinatário | `terrad query wasm ... balance {address: "..."}` |

> **Dica:** Se `delivered: true` mas o saldo não aparece na carteira — o token chegou! A carteira pode não exibir tokens CW20. Use o comando `terrad query wasm` para confirmar.

---

## 15. Troubleshooting

### ❌ `RelativeUrlWithoutBase` ao validar metadata

**Causa:** O campo `image` na metadata JSON está como `""` (string vazia) e o cliente Rust tentou fazer `GET("")`.

**Solução:** O repositório contém um patch em `warp_route.rs` que torna o campo `image` opcional. Para reaplicar se o monorepo for atualizado:

```rust
// warp_route.rs, função validate()
// Substituir o bloco de validação de imagem por:
if let Some(image_url) = &self.image {
    if !image_url.is_empty() {
        let image = reqwest::blocking::get(image_url).unwrap();
        assert!(image.status().is_success(), ...);
    }
}
```

Depois recompilar:

```bash
cd /home/lunc/hyperlane-monorepo/rust/sealevel
cargo build --release -p hyperlane-sealevel-client
```

### ❌ `Failed to parse metadata JSON: reqwest::Error { kind: Decode ... integer 404 }`

**Causa:** O `metadata_uri` configurado retorna HTTP 404 (arquivo não existe no GitHub ainda).

**Solução:** O script detecta o código HTTP e omite o campo `uri` do `token-config.json` automaticamente. O deploy prossegue sem metadata on-chain. Para adicionar a metadata depois, faça commit do arquivo JSON no GitHub e reexecute apenas o passo de metadata.

### ❌ `error: Found argument '--use-rpc' which wasn't expected`

**Causa:** A Solana CLI instalada é **anterior à v1.16** e não reconhece o flag `--use-rpc` que o cliente Rust do Hyperlane adiciona por padrão. O deploy falha em todas as tentativas, mas o script pode ter gerado um `log/WARP-*.txt` com Program IDs locais **que nunca chegaram à testnet** (os endereços são dos keypairs gerados localmente, não de contas reais on-chain).

**Como verificar se o deploy realmente aconteceu:**

```bash
solana account PROGRAM_ID --url https://api.testnet.solana.com
# Se retornar "AccountNotFound" → deploy não aconteceu
```

**Solução — Patch no código Rust (não requer atualização da CLI):**

```bash
# 1. Editar o arquivo
nano /home/lunc/hyperlane-monorepo/rust/sealevel/client/src/cmd_utils.rs
# Localizar e remover a linha:   "--use-rpc",

# 2. Recompilar
cd /home/lunc/hyperlane-monorepo/rust/sealevel
cargo build --release -p hyperlane-sealevel-client

# 3. Limpar keypairs do deploy fracassado
rm -f environments/testnet/warp-routes/TOKEN/keys/*.json

# 4. Resetar o state e o config
rm -f ~/cw-hyperlane/script-warp-terraclassic/.warp-sealevel-state.json
# Em warp-sealevel-config.json: setar deployed:false, program_id:"", mint_address:""

# 5. Reexecutar o script
./create-warp-sealevel.sh
```

> **Alternativa:** Atualizar a Solana CLI para v1.16+:
> ```bash
> sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
> ```

---

### ❌ `warp-route deploy falhou (exit 101)`

**Causa:** Pode ser:
1. Saldo insuficiente na keypair Solana
2. Arquivo `token-config.json` inválido
3. `.so` (bytecode do programa) não compilado

**Diagnóstico:**

```bash
# Verificar saldo
solana balance PUBKEY --url https://api.testnet.solana.com

# Verificar se o .so existe
ls /home/lunc/hyperlane-monorepo/rust/sealevel/target/deploy/*.so

# Ver log completo
cat ~/cw-hyperlane/script-warp-terraclassic/log/create-warp-sealevel.log
```

**Solução para .so ausente:**

```bash
cd /home/lunc/hyperlane-monorepo/rust/sealevel
cargo build-bpf   # ou: cargo build-sbf
```

### ❌ `account sequence mismatch` na Terra Classic

**Causa:** O RPC da Terra Classic está desatualizado.

**Solução:** Usar o RPC sincronizado:

```bash
# No warp-evm-config.json:
"rpc": "https://rpc.terra-classic.hexxagon.dev"
```

### ❌ Mensagem enviada (Solana → Terra Classic) mas não chega

**Diagnóstico:**
1. Verificar se o relayer tem Solana configurado em `relayChains`
2. Verificar se o ISM da Terra Classic tem o validator Solana registrado
3. Verificar se o validator Solana está fazendo checkpoints no S3

```bash
# Verificar validator announcement (substitua pela URL do seu S3)
curl https://hyperlane-validator-signatures-SEU_BUCKET.s3.us-east-1.amazonaws.com/announcement.json
```

### ❌ Mensagem enviada (Terra Classic → Solana) mas não chega

**Diagnóstico — cheklist em ordem:**

**1. Verificar se a rota no Terra Classic aponta para o Program ID CORRETO**

Este é o erro mais comum após um deploy com falha silenciosa. O `set_route` pode ter registrado o Program ID de um deploy anterior (que não existe on-chain):

```bash
# Obter a rota atual na Terra Classic
terrad query wasm contract-state smart terra16ql6l4fuudg0fxarcm4ukxlw0jalg5ljv8kg6h8f7dk9t2e7y6ssq2hqrm \
  '{"router":{"list_routes":{}}}' \
  --node https://rpc.terra-classic.hexxagon.dev

# Confirmar se o Program ID existe no Solana
solana account PROGRAM_ID_BASE58 --url https://api.testnet.solana.com
```

Se `AccountNotFound` → a rota aponta para um programa inválido. Corrija conforme seção 11.6.

**2. Verificar se o ISM Solana tem o validator da Terra Classic registrado**

```bash
cd /home/lunc/hyperlane-monorepo/rust/sealevel
./target/release/hyperlane-sealevel-client \
  -k /caminho/keypair.json \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id 5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh \
  --domains 1325
```

Saída esperada: `threshold: 1`, validator = endereço do validator Terra Classic.

**3. Verificar se o validator da Terra Classic está fazendo checkpoints**

```bash
# Substitua pela URL do S3 do seu validator Terra Classic
curl https://hyperlane-validator-signatures-NOME.s3.us-east-1.amazonaws.com/announcement.json
# Deve retornar um JSON com "validator", "mailbox_address", "storage_location"
```

**4. Verificar se o relayer está monitorando a Terra Classic**

Confirme que `relayChains` no config do relayer inclui `terraclassic` ou o domain `1325`.

### ❌ Rota na Terra Classic aponta para Program ID antigo/inválido

**Sintoma:** Mensagens saem da Terra Classic sem erro, mas nunca chegam ao Solana. A rota existe no contrato mas aponta para um programa que não existe on-chain.

**Causa:** Um deploy anterior foi iniciado mas falhou silenciosamente (ex: erro `--use-rpc`), gerando um Program ID local que nunca foi publicado. O `set_route` registrou este ID inválido.

**Como identificar:**

```bash
# Listar todas as rotas configuradas no Warp Terra Classic
terrad query wasm contract-state smart TERRA_WARP_ADDRESS \
  '{"router":{"list_routes":{}}}' \
  --node https://rpc.terra-classic.hexxagon.dev

# Para cada route encontrado, verificar no Solana
solana account PROGRAM_ID_BASE58 --url https://api.testnet.solana.com
# "AccountNotFound" = Program ID inválido
```

**Como corrigir — executar `set_route` com o Program ID correto:**

```bash
export TERRA_PRIVATE_KEY="sua_chave_privada_hex"

node - <<'EOF'
const { SigningCosmWasmClient } = require("@cosmjs/cosmwasm-stargate");
const { DirectSecp256k1Wallet } = require("@cosmjs/proto-signing");
const { GasPrice } = require("@cosmjs/stargate");

async function main() {
  const wallet = await DirectSecp256k1Wallet.fromKey(
    Buffer.from(process.env.TERRA_PRIVATE_KEY, "hex"), "terra"
  );
  const [account] = await wallet.getAccounts();
  const client = await SigningCosmWasmClient.connectWithSigner(
    "https://rpc.terra-classic.hexxagon.dev",
    wallet,
    { gasPrice: GasPrice.fromString("0.015uluna") }
  );

  // Program ID Solana em hex de 32 bytes, SEM "0x"
  const programHex = "0adafdae59c217a1b7409f65ca81505f9991c257be80af8902ebed96d8801ba6";
  const warpAddr   = "terra16ql6l4fuudg0fxarcm4ukxlw0jalg5ljv8kg6h8f7dk9t2e7y6ssq2hqrm";
  const domain     = 1399811150;

  const result = await client.execute(
    account.address, warpAddr,
    { router: { set_route: { set: { domain, route: programHex } } } },
    "auto", "corrigir set_route TC → Solana"
  );
  console.log("TX:", result.transactionHash);
}
main().catch(e => { console.error(e); process.exit(1); });
EOF
```

> **O script `create-warp-sealevel.sh` previne este problema** verificando automaticamente se a rota existente aponta para o Program ID correto antes de pular a etapa.

---

### ❌ `invalid hex` ao executar `set_route` na Terra Classic

**Causa:** O campo `route` foi passado com o prefixo `0x`. O contrato CosmWasm da Terra Classic aceita apenas hex puro (64 caracteres sem prefixo).

**Solução:** Remova o `0x` do valor do campo `route`:

```
❌  "route": "0x0adafdae59c217a1b7409f65ca81505f9991c257be80af8902ebed96d8801ba6"
✅  "route": "0adafdae59c217a1b7409f65ca81505f9991c257be80af8902ebed96d8801ba6"
```

---

### ❌ `gasPriceAmount.multiply is not a function` no Node.js

**Causa:** Uso incorreto do `GasPrice` ao construir o cliente CosmJS.

**Solução:** Use `GasPrice.fromString(...)` em vez de passar um objeto literal:

```js
// ❌ Errado:
{ gasPrice: { amount: "28.325", denom: "uluna" } }

// ✅ Correto:
const { GasPrice } = require("@cosmjs/stargate");
{ gasPrice: GasPrice.fromString("0.015uluna") }
```

---

### ❌ `TERRA_PRIVATE_KEY não definida`

**Solução:**

```bash
export TERRA_PRIVATE_KEY="sua_chave_privada_hex_sem_0x"
./create-warp-sealevel.sh
```

---

## 16. Referência de endereços deployados

### XPTO — Solana Testnet ↔ Terra Classic

> ✅ **Status: Funcionando em produção** — transferências bidirecionais confirmadas (Solana → Terra Classic e Terra Classic → Solana).

| Campo | Valor |
|-------|-------|
| **Program ID (Solana)** | `jNkiNLXQetj9L2tDX6xTgx9QP1tgtNgYXamouNbbwx9` |
| **Program Hex (32b)** | `0x0adafdae59c217a1b7409f65ca81505f9991c257be80af8902ebed96d8801ba6` |
| **Route (sem 0x, para set_route)** | `0adafdae59c217a1b7409f65ca81505f9991c257be80af8902ebed96d8801ba6` |
| **Mint Address (SPL)** | `Db8VbMerYxksYwSSdetpy6Jhp2BrE4hk9Sh9dYJT5dQ2` |
| **Mailbox Solana (usado pelo Warp)** | `75HBBLae3ddeneJVrZeyrDfv6vb7SMC3aCpBucSXS5aR` |
| **ISM Program** | `5FgXjCJ8hw1hDbYhvwMB7PFN6oBhVcHuLo3ABoYynMZh` |
| **IGP Program** | `5p7Hii6CJL4xGBYYTGEQmH9LnUSZteFJUu9AVLDExZX2` |
| **IGP Account** | `E9i32KsKGQZMYTguZ81VHUueNvpTGh7nb9J5bRif4xT1` |
| **Warp Terra Classic (bech32)** | `terra16ql6l4fuudg0fxarcm4ukxlw0jalg5ljv8kg6h8f7dk9t2e7y6ssq2hqrm` |
| **Warp Terra Hex** | `0xd03fafd53ce350f49ba3c6ebcb1bee7cbbf453f261ec8d5ce9f36c55ab3e26a1` |
| **CW20 Collateral (Terra)** | `terra1zle6pwm9aztwu228e0spxrydlvmhj2qrq8ap3x2wrjc52kdvu4fs20rkch` |
| **Mailbox Terra Classic** | `terra1s4jwfe0tcaztpfsct5wzj02esxyjy7e7lhkcwn5dp04yvly82rwsvzyqmm` |
| **ISM Routing Terra Classic** | `terra1na6ljyf4m5x2u7llfvvxxe2nyq0t8628qyk0vnwu4ttpq86tt0cse47t68` |
| **Multisig ISM Terra Classic** | `terra18gh7nl0tk047ykrvy0a8z2lhv0rvl65wu95texyawrj879qenysq02p98f` |
| **Metadata URI** | `https://raw.githubusercontent.com/igorv43/cw-hyperlane/refs/heads/main/warp/solana/metadata-xpto.json` |
| **Domain Solana Testnet** | `1399811150` |
| **Domain Terra Classic** | `1325` |
| **Deployer (keypair)** | `EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd` |

**Verificar on-chain:**

```bash
# Warp Solana — confirmar que o programa existe
solana account jNkiNLXQetj9L2tDX6xTgx9QP1tgtNgYXamouNbbwx9 --url https://api.testnet.solana.com

# Mint SPL — confirmar que o token existe
solana account Db8VbMerYxksYwSSdetpy6Jhp2BrE4hk9Sh9dYJT5dQ2 --url https://api.testnet.solana.com

# Rota Terra Classic → Solana
terrad query wasm contract-state smart terra16ql6l4fuudg0fxarcm4ukxlw0jalg5ljv8kg6h8f7dk9t2e7y6ssq2hqrm \
  '{"router":{"get_route":{"domain":1399811150}}}' \
  --node https://rpc.terra-classic.hexxagon.dev
```

---

## 17. Links úteis

| Recurso | URL |
|---------|-----|
| Explorer Solana Testnet | https://explorer.solana.com/?cluster=testnet |
| Explorer Terra Classic | https://finder.hexxagon.io/rebel-2 |
| Hyperlane Docs | https://docs.hyperlane.xyz |
| Hyperlane Domínios | https://docs.hyperlane.xyz/docs/reference/domains |
| Solana CLI | https://docs.solana.com/cli/install-solana-cli-tools |
| Faucet Solana Testnet | https://faucet.solana.com |
| Faucet Terra Classic | https://faucet.terra.dev |
| **Validators — S3 (checkpoints)** | |
| S3 Validator Terra Classic | https://hyperlane-validator-signatures-igorveras-terraclassic.s3.us-east-1.amazonaws.com/announcement.json |
| S3 Validator Sepolia | https://hyperlane-validator-signatures-igorveras-sepolia.s3.us-east-1.amazonaws.com/announcement.json |
| S3 Validator BSC Testnet | https://hyperlane-validator-signatures-igorveras-bsctestnet.s3.us-east-1.amazonaws.com/announcement.json |
| **Contratos on-chain (XPTO)** | |
| Mailbox Terra Classic | `terra1s4jwfe0tcaztpfsct5wzj02esxyjy7e7lhkcwn5dp04yvly82rwsvzyqmm` |
| Warp XPTO Terra Classic | `terra16ql6l4fuudg0fxarcm4ukxlw0jalg5ljv8kg6h8f7dk9t2e7y6ssq2hqrm` |
| CW20 XPTO (colateral) | `terra1zle6pwm9aztwu228e0spxrydlvmhj2qrq8ap3x2wrjc52kdvu4fs20rkch` |
| Program XPTO Solana | `jNkiNLXQetj9L2tDX6xTgx9QP1tgtNgYXamouNbbwx9` |
| Mint XPTO SPL | `Db8VbMerYxksYwSSdetpy6Jhp2BrE4hk9Sh9dYJT5dQ2` |
| **Repositórios** | |
| Hyperlane Registry GitHub | https://github.com/hyperlane-xyz/hyperlane-registry |
| Hyperlane Monorepo | https://github.com/hyperlane-xyz/hyperlane-monorepo |
| cw-hyperlane (metadata Solana) | https://github.com/igorv43/cw-hyperlane/tree/main/warp/solana |
