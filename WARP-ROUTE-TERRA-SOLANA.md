# Guia Completo: Warp Route Terra Classic ↔ Solana

Este guia fornece instruções passo a passo para criar um Warp Route entre Terra Classic Testnet (Native LUNC) e Solana Testnet (Synthetic LUNC), permitindo transferências cross-chain bidirecionais.

## Índice

1. [Visão Geral](#visão-geral)
2. [Pré-requisitos](#pré-requisitos)
3. [Arquitetura do Warp Route](#arquitetura-do-warp-route)
4. [Passo 1: Deploy no Terra Classic](#passo-1-deploy-no-terra-classic)
5. [Passo 2: Deploy na Solana](#passo-2-deploy-na-solana)
6. [Passo 3: Configurar ISM no Terra Classic (Opcional)](#passo-3-configurar-ism-no-terra-classic-opcional)
7. [Passo 4: Link Bidirecional](#passo-4-link-bidirecional)
8. [Passo 5: Testar Transferências](#passo-5-testar-transferências)
9. [Troubleshooting](#troubleshooting)
10. [Referências](#referências)

---

## Visão Geral

### Tipo de Warp Route

- **Terra Classic**: Native LUNC (Colateral)
- **Solana**: Synthetic LUNC (Token sintético criado na Solana)

### Fluxo de Transferência

1. **Terra Classic → Solana**:
   - Usuário envia LUNC nativo no Terra Classic
   - LUNC é bloqueado no contrato warp route
   - Token sintético LUNC é mintado na Solana

2. **Solana → Terra Classic**:
   - Usuário queima token sintético LUNC na Solana
   - LUNC nativo é desbloqueado e enviado no Terra Classic

### Ferramentas Necessárias

- **Terra Classic**: `cw-hyperlane` CLI (TypeScript/Node.js)
- **Solana**: `hyperlane-sealevel-client` (Rust)

---

## Pré-requisitos

### 1. Instalação de Ferramentas

#### Terra Classic CLI (cw-hyperlane)

```bash
# Já deve estar instalado no projeto
cd /home/lunc/cw-hyperlane
yarn install
```

#### Solana CLI e Hyperlane Sealevel Client

```bash
# Instalar Solana CLI
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"

# Adicionar ao PATH
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# Verificar instalação
solana --version
solana config set --url https://api.testnet.solana.com

# Clonar hyperlane-monorepo para usar o sealevel client
git clone https://github.com/hyperlane-xyz/hyperlane-monorepo
cd hyperlane-monorepo
```

### 2. Configuração de Chaves

#### Terra Classic

```bash
# Verificar se a chave está configurada
terrad keys list --keyring-backend file

# Se necessário, adicionar chave
terrad keys add hypelane-val-testnet --keyring-backend file
```

#### Solana

```bash
# Gerar nova chave para Solana (se necessário)
solana-keygen new --outfile ~/solana-warp-deployer-key.json

# Verificar saldo
solana balance --url https://api.testnet.solana.com

# Obter SOL de teste (se necessário)
solana airdrop 1 $(solana address --keypair ~/solana-warp-deployer-key.json) --url https://api.testnet.solana.com
```

### 3. Verificar Contratos Hyperlane

Certifique-se de que os contratos Hyperlane estão deployados:

- **Terra Classic**: Ver `TESTNET-ARTIFACTS.md`
- **Solana**: Verificar no [Hyperlane Registry](https://github.com/hyperlane-xyz/hyperlane-registry/tree/main/chains/solanatestnet)

### 4. Informações das Chains

| Chain | Domain ID | RPC Endpoint | Explorer |
|-------|-----------|--------------|----------|
| Terra Classic Testnet | `1325` | `https://rpc.luncblaze.com:443` | https://finder.terra-classic.hexxagon.dev/testnet |
| Solana Testnet | `1399811150` | `https://api.testnet.solana.com` | https://explorer.solana.com/?cluster=testnet |

---

## Arquitetura do Warp Route

### Componentes

1. **Terra Classic Side**:
   - Warp Route Contract (Native Collateral)
   - Endereço: Será gerado após deploy
   - Tipo: `native` + `collateral`
   - ISM: Pode ser configurado no warp route ou usar o padrão do Mailbox

2. **Solana Side**:
   - Warp Route Program (Synthetic)
   - Program ID: Será gerado após deploy
   - Tipo: `synthetic` (Token-2022)
   - ISM: Usa o ISM configurado no Mailbox da Solana (não configurável no warp route)

### Diferenças de ISM entre Chains

| Aspecto | Terra Classic | BSC (EVM) | Solana (SVM) |
|---------|--------------|-----------|--------------|
| **Configuração ISM** | Opcional via `--ism` flag | No arquivo YAML (`interchainSecurityModule`) | Não configurável no warp route |
| **ISM Padrão** | Usa ISM do Mailbox se não especificado | Pode ter ISM próprio no YAML | Sempre usa ISM do Mailbox |
| **Arquitetura** | ISM pode ser por warp route | ISM pode ser por warp route | ISM é gerenciado pelo Mailbox |
| **Formato Config** | JSON (cw-hyperlane) | YAML (Hyperlane CLI) | JSON (sealevel client) |

### Fluxo de Dados

```
Terra Classic                    Solana
     │                              │
     │ 1. transfer_remote           │
     ├─────────────────────────────>│
     │                              │ 2. Mint synthetic token
     │                              │
     │ 3. Message via Hyperlane     │
     │<─────────────────────────────┤
     │                              │
     │ 4. Unlock native LUNC        │
     │                              │
```

---

## Passo 1: Deploy no Terra Classic

### 1.1. Criar Arquivo de Configuração

Crie o arquivo de configuração para o warp route nativo:

```bash
cat > example/warp/uluna-solana.json << EOF
{
  "type": "native",
  "mode": "collateral",
  "id": "uluna",
  "owner": "<signer>",
  "config": {
    "collateral": {
      "denom": "uluna"
    }
  }
}
EOF
```

### 1.2. Deploy do Warp Route

```bash
# Deploy do warp route no Terra Classic
yarn cw-hpl warp create ./example/warp/uluna-solana.json -n terraclassic
```

**Saída esperada:**
```
[INFO] Deploying native warp route...
[INFO] Warp route deployed at: terra1...
[INFO] Address: terra1...
[INFO] Hex Address: 0x...
```

**Salve o endereço do contrato:**
```bash
TERRA_WARP_ADDRESS="terra1..."  # Substitua pelo endereço real
TERRA_WARP_HEX="0x..."          # Substitua pelo hex address real
```

### 1.3. Verificar Deploy

```bash
# Verificar o contrato no explorer
echo "https://finder.terra-classic.hexxagon.dev/testnet/address/${TERRA_WARP_ADDRESS}"

# Verificar no contexto
cat context/terraclassic.json | jq '.deployments.warp.native[] | select(.id == "uluna")'
```

---

## Passo 2: Deploy na Solana

### 2.1. Preparar Ambiente Rust

```bash
# Instalar Rust (se necessário)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Verificar instalação
rustc --version
cargo --version
```

### 2.2. Build dos Programas Sealevel

```bash
cd hyperlane-monorepo

# Build dos programas warp route
cd rust/sealevel

# IMPORTANTE: cargo build-sbf não aceita --release diretamente
# Use -- --release para passar para o cargo subjacente
# Ou simplesmente use cargo build-sbf (build de debug, mais rápido)

# Opção 1: Build otimizado (release)
cargo build-sbf -- --release

# Opção 2: Build de debug (mais rápido, recomendado para testes)
cargo build-sbf

# Os programas compilados estarão em:
# target/deploy/hyperlane_sealevel_token.so
# target/deploy/hyperlane_sealevel_token_collateral.so
# target/deploy/hyperlane_sealevel_token_native.so
```

**Nota:** O `cargo build-sbf` é um wrapper do Solana que compila programas Sealevel. Para passar flags ao cargo subjacente (como `--release`), use `--` antes das flags. Para testes, o build de debug (`cargo build-sbf` sem flags) é mais rápido e suficiente.

### 2.3. Preparar Configuração do Token

Crie o arquivo de configuração do token:

```bash
# Criar diretório para a configuração
mkdir -p environments/testnet/warp-routes/lunc-solana

# Criar arquivo de configuração do token
cat > environments/testnet/warp-routes/lunc-solana/token-config.json << EOF
{
  "name": "Luna Classic",
  "symbol": "LUNC",
  "decimals": 6,
  "total_supply": "0",
  "type": "synthetic"
}
EOF
```

**⚠️ Importante: Configuração de ISM na Solana**

Diferente das chains EVM (BSC, Ethereum), o `token-config.json` do sealevel client **não possui campo para ISM**. Na Solana:

1. **ISM Padrão**: O warp route na Solana usa o ISM configurado no **Mailbox da Solana** por padrão
2. **ISM do Mailbox**: O Mailbox da Solana já tem um ISM padrão configurado (geralmente um Multisig ISM)
3. **ISM Customizado**: Se necessário configurar um ISM específico para o warp route, isso deve ser feito **após o deploy** usando comandos do sealevel client

**Comparação:**

| Chain | Formato | ISM no Config |
|-------|---------|---------------|
| **BSC/EVM** | YAML | ✅ `interchainSecurityModule` no arquivo YAML |
| **Solana** | JSON | ❌ Não há campo ISM no `token-config.json` |
| **Terra Classic** | JSON | ✅ Opcional via `--ism` flag no deploy |

**Nota:** O ISM na Solana é gerenciado pelo Mailbox, não pelo warp route individual. Isso é uma diferença arquitetural entre EVM e SVM (Solana Virtual Machine).

**Estrutura de Diretórios:**
```
hyperlane-monorepo/
└── rust/
    └── sealevel/
        ├── programs/          # Código fonte dos programas
        ├── client/            # Cliente CLI para deploy
        ├── environments/      # Configurações por ambiente
        │   └── testnet/
        │       └── warp-routes/
        │           └── lunc-solana/
        │               └── token-config.json
        └── target/
            └── deploy/        # Programas compilados (.so)
```

### 2.4. Compilar Programas Solana (Se Necessário)

**⚠️ IMPORTANTE**: Diferente do Cosmos onde você pode baixar `.wasm` pré-compilados, na Solana você precisa compilar os programas localmente.

**Problema**: A compilação pode falhar com erro de stack overflow. Veja [FIX-SOLANA-STACK-OVERFLOW.md](./FIX-SOLANA-STACK-OVERFLOW.md) para soluções.

**Alternativa**: Se os programas já foram deployados na Solana, você pode usar os Program IDs existentes sem precisar compilar.

#### Compilar Programas

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Limpar build anterior
cargo clean

# Compilar programa de token sintético
cargo build-sbf --manifest-path programs/hyperlane-sealevel-token/Cargo.toml

# Verificar se compilou
ls -lh target/deploy/hyperlane_sealevel_token.so

# Calcular hash para auditoria
cd target/deploy
sha256sum hyperlane_sealevel_token.so
```

**📖 Guia Completo**: Veja [SOLANA-PRECOMPILED-BINARIES.md](./SOLANA-PRECOMPILED-BINARIES.md) para informações sobre binários pré-compilados e verificação de hash.

### 2.5. Deploy do Warp Route na Solana

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Deploy do warp route
# NOTA: Os programas devem estar compilados em target/deploy/
cargo run -- \
  -k ~/solana-warp-deployer-key.json \
  warp-route deploy \
  --warp-route-name lunc-solana \
  --environment testnet \
  --environments-dir ../../environments \
  --built-so-dir ../../target/deploy \
  --token-config-file ../../environments/testnet/warp-routes/lunc-solana/token-config.json \
  --registry ~/.hyperlane/registry \
  --ata-payer-funding-amount 10000000 \
  --url https://api.testnet.solana.com
```

**Saída esperada:**
```
[INFO] Deploying warp route program...
[INFO] Program ID: ...
[INFO] Mint Account: ...
[INFO] Mint Authority: ...
```

**Salve as informações:**
```bash
SOLANA_PROGRAM_ID="..."  # Program ID do warp route
SOLANA_MINT_ACCOUNT="..." # Mint account do token sintético
SOLANA_MINT_AUTHORITY="..." # Mint authority
```

### 2.5. Configurar ISM no Warp Route da Solana (Opcional)

**⚠️ Importante:** Na Solana, você **pode configurar um ISM específico** no warp route após o deploy, mesmo sem credenciais do Mailbox.

**Por padrão**, o warp route usa o ISM configurado no Mailbox da Solana. Se você quiser usar um ISM específico:

```bash
cd ~/hyperlane-monorepo/rust/sealevel/client

# Program ID do warp route (obtido no deploy)
WARP_ROUTE_PROGRAM_ID="SEU_PROGRAM_ID_AQUI"

# Opção 1: Usar ISM padrão do Mailbox (não precisa fazer nada)
# O warp route já usa o ISM padrão automaticamente

# Opção 2: Configurar ISM específico (se necessário)
ISM_PROGRAM_ID="4GHxwWyKB9exhKG4fdyU2hfLgfFzhHp2WcsSKc2uNR1k"  # Exemplo

cargo run -- \
  -k ~/solana-warp-deployer-key.json \
  token set-interchain-security-module \
  --program-id ${WARP_ROUTE_PROGRAM_ID} \
  --ism ${ISM_PROGRAM_ID} \
  --url https://api.testnet.solana.com

# Opção 3: Remover ISM customizado (voltar ao padrão)
cargo run -- \
  -k ~/solana-warp-deployer-key.json \
  token set-interchain-security-module \
  --program-id ${WARP_ROUTE_PROGRAM_ID} \
  --ism None \
  --url https://api.testnet.solana.com
```

**📖 Guia Completo:** Veja [CONFIGURAR-ISM-SOLANA-WARP.md](./CONFIGURAR-ISM-SOLANA-WARP.md) para instruções detalhadas.

**Diferença Arquitetural:**
- **EVM (BSC)**: ISM configurado no YAML durante o deploy
- **Solana**: ISM pode ser configurado após o deploy via `sealevel client` (owner do warp route)
- **Terra Classic**: ISM pode ser configurado no deploy via `--ism` flag ou após via `terrad tx wasm execute`

### 2.6. Verificar Deploy na Solana

```bash
# Verificar o programa
solana program show ${SOLANA_PROGRAM_ID} --url https://api.testnet.solana.com

# Verificar o token mint
spl-token supply ${SOLANA_MINT_ACCOUNT} --url https://api.testnet.solana.com
```

---

## Passo 3: Configurar ISM e Validadores

### 3.1. Verificar ISM Atual

Antes de fazer o link, você pode configurar um ISM específico para o warp route no Terra Classic:

```bash
# Verificar ISM atual do warp route
terrad query wasm contract-state smart ${TERRA_WARP_ADDRESS} \
  '{"connection":{"ism":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

### 3.2. Configurar ISM (Se Necessário)

Se você quiser usar um ISM específico (diferente do padrão do Mailbox):

```bash
# ISM Multisig para Solana (domain 1399811150)
ISM_SOLANA="terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a"

# Configurar ISM no warp route
terrad tx wasm execute ${TERRA_WARP_ADDRESS} \
  "{\"connection\":{\"set_ism\":{\"ism\":\"${ISM_SOLANA}\"}}}" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

**Nota:** Se você não configurar um ISM específico, o warp route usará o ISM padrão configurado no Mailbox do Terra Classic.

### 3.3. Configurar Validadores do ISM para Solana

**⚠️ Importante:** O ISM Multisig precisa ter validadores configurados para validar mensagens vindas da Solana. Você **não precisa de credenciais do Mailbox** para configurar validadores.

O ISM Multisig tem um `owner` que pode configurar validadores:
- **Se você é o owner**: Pode configurar diretamente via `terrad tx wasm execute`
- **Se o owner é governance**: Precisa fazer via proposta de governança

**📖 Guia Completo:** Veja [CONFIGURAR-VALIDADORES-ISM.md](./CONFIGURAR-VALIDADORES-ISM.md) para instruções detalhadas.

**Resumo Rápido:**

```bash
# 1. Verificar owner do ISM
ISM_SOLANA="terra1d7a52pxu309jcgv8grck7jpgwlfw7cy0zen9u42rqdr39tef9g7qc8gp4a"
terrad query wasm contract-state smart ${ISM_SOLANA} \
  '{"ownable":{"owner":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443

# 2. Se owner é governance, criar proposta:
# Veja CONFIGURAR-VALIDADORES-ISM.md para detalhes completos

# 3. Se você é o owner, executar diretamente:
terrad tx wasm execute ${ISM_SOLANA} \
  '{"set_validators":{"domain":1399811150,"threshold":2,"validators":["242d8a855a8c932dec51f7999ae7d1e48b10c95e","f620f5e3d25a3ae848fec74bccae5de3edcd8796","1f030345963c54ff8229720dd3a711c15c554aeb"]}}' \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

---

## Passo 4: Link Bidirecional

### 4.1. Converter Endereços para Formato Hex (32 bytes)

#### Converter Endereço Terra Classic (Bech32) para Hex

O warp route na Solana precisa do endereço do Terra Classic em formato hex (32 bytes):

```bash
# Método 1: Usar o hex address gerado no deploy (recomendado)
# O deploy já gera o hex address automaticamente
TERRA_WARP_ADDRESS="terra1..."  # Endereço bech32
TERRA_WARP_HEX="0x..."          # Hex address (já gerado no deploy)

# Método 2: Converter manualmente usando cw-hpl CLI
yarn cw-hpl wallet convert-cosmos-to-eth ${TERRA_WARP_ADDRESS}

# Método 3: Usar função do projeto
cd /home/lunc/cw-hyperlane
node -e "
const { fromBech32 } = require('@cosmjs/encoding');
const addr = '${TERRA_WARP_ADDRESS}';
const { data } = fromBech32(addr);
const hexed = Buffer.from(data).toString('hex');
const padded = hexed.padStart(64, '0');
console.log('0x' + padded);
"
```

#### Converter Endereço Solana (Base58) para Hex

Para transferências do Terra Classic para Solana, o endereço Solana precisa ser convertido:

```bash
# Método 1: Usar Python (recomendado)
python3 << EOF
import base58
import binascii

solana_address = "YOUR_SOLANA_ADDRESS"  # Base58
decoded = base58.b58decode(solana_address)
hex_address = binascii.hexlify(decoded).decode('utf-8')
# Pad para 64 caracteres (32 bytes)
hex_padded = hex_address.zfill(64)
print(f"0x{hex_padded}")
EOF

# Método 2: Usar solana CLI (se disponível)
# O solana CLI não tem conversão direta, use Python

# Salvar o resultado
SOLANA_RECIPIENT_HEX="0x..."  # 64 caracteres hex após 0x
```

**Importante:**
- Terra Classic → Solana: Recipient deve ser hex (32 bytes, 64 caracteres, sem 0x no JSON)
- Solana → Terra Classic: Recipient deve ser hex (32 bytes, 64 caracteres, sem 0x no JSON)

### 4.2. Link Terra Classic → Solana

No Terra Classic, registrar o warp route da Solana:

```bash
# Converter Solana Program ID para formato hex (32 bytes)
# O Program ID da Solana precisa ser convertido para hex
# Exemplo: Se o Program ID é base58, converter para hex

# Usar o comando link do cw-hyperlane
yarn cw-hpl warp link \
  --asset-type native \
  --asset-id uluna \
  --target-domain 1399811150 \
  --warp-address ${SOLANA_PROGRAM_ID_HEX} \
  -n terraclassic
```

**Nota:** O `SOLANA_PROGRAM_ID_HEX` deve ser o Program ID da Solana convertido para hex (32 bytes, 64 caracteres hex, sem 0x).

### 4.3. Link Solana → Terra Classic

Na Solana, registrar o warp route do Terra Classic:

```bash
cd hyperlane-monorepo/rust/sealevel/client

# Enroll remote router (Terra Classic) no warp route da Solana
cargo run -- \
  -k ~/solana-warp-deployer-key.json \
  -u https://api.testnet.solana.com \
  token enroll-remote-router \
  --program-id ${SOLANA_PROGRAM_ID} \
  --remote-domain 1325 \
  --remote-router ${TERRA_WARP_HEX}
```

**Parâmetros:**
- `--program-id`: Program ID do warp route na Solana
- `--remote-domain`: Domain ID do Terra Classic (1325)
- `--remote-router`: Endereço hex do warp route no Terra Classic (32 bytes)

### 4.4. Verificar Links

#### Verificar no Terra Classic

```bash
# Verificar rota configurada
terrad query wasm contract-state smart ${TERRA_WARP_ADDRESS} \
  '{"router":{"get_route":{"domain":1399811150}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq -r '.data.route'
```

#### Verificar na Solana

```bash
# Query do programa para verificar remote router
cargo run -- \
  -k ~/solana-warp-deployer-key.json \
  -u https://api.testnet.solana.com \
  token query \
  --program-id ${SOLANA_PROGRAM_ID} \
  synthetic
```

---

## Passo 5: Testar Transferências

### 5.1. Transferência: Terra Classic → Solana

#### Usando terrad CLI

```bash
# 1. Calcular IGP gas payment primeiro
IGP="terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9"
GAS_AMOUNT="200000"  # Gas estimado para Solana

IGP_GAS=$(terrad query wasm contract-state smart ${IGP} \
  '{"igp":{"quote_gas_payment":{"dest_domain":1399811150,"gas_amount":"'${GAS_AMOUNT}'"}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq -r '.data.gas_needed')

echo "IGP Gas needed: ${IGP_GAS} uluna ($(echo "scale=2; ${IGP_GAS}/1000000" | bc) LUNC)"

# 2. Converter endereço Solana para formato hex (32 bytes)
SOLANA_RECIPIENT="YOUR_SOLANA_ADDRESS"  # Seu endereço Solana (base58)

# Converter usando Python
SOLANA_RECIPIENT_HEX=$(python3 << EOF
import base58
import binascii
solana_address = "${SOLANA_RECIPIENT}"
decoded = base58.b58decode(solana_address)
hex_address = binascii.hexlify(decoded).decode('utf-8')
hex_padded = hex_address.zfill(64)
print(hex_padded)  # Sem 0x, apenas 64 caracteres hex
EOF
)

echo "Solana recipient hex: ${SOLANA_RECIPIENT_HEX}"

# 3. Calcular valores
TRANSFER_AMOUNT="10000000"  # 10 LUNC em uluna
HOOK_FEE="283215"  # Hook fee fixo
TOTAL_AMOUNT=$((TRANSFER_AMOUNT + HOOK_FEE + IGP_GAS))

# 4. Executar transferência
terrad tx wasm execute ${TERRA_WARP_ADDRESS} \
  "{\"transfer_remote\":{\"dest_domain\":1399811150,\"recipient\":\"${SOLANA_RECIPIENT_HEX}\",\"amount\":\"${TRANSFER_AMOUNT}\"}}" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 28.5uluna \
  --amount ${TOTAL_AMOUNT}uluna \
  --yes
```

#### Usando cw-hpl CLI

```bash
yarn cw-hpl warp transfer \
  --asset-type native \
  --asset-id uluna \
  --target-domain 1399811150 \
  --recipient ${SOLANA_RECIPIENT_HEX} \
  --amount 10000000 \
  -n terraclassic
```

### 5.2. Verificar Recebimento na Solana

```bash
# Verificar saldo do token sintético
spl-token balance ${SOLANA_MINT_ACCOUNT} \
  --owner ~/solana-warp-deployer-key.json \
  --url https://api.testnet.solana.com

# Ou verificar no explorer
echo "https://explorer.solana.com/address/${SOLANA_MINT_ACCOUNT}?cluster=testnet"
```

### 5.3. Transferência: Solana → Terra Classic

```bash
cd hyperlane-monorepo/rust/sealevel/client

# Converter endereço Terra Classic para hex (32 bytes)
TERRA_RECIPIENT="terra1..."  # Seu endereço Terra Classic
TERRA_RECIPIENT_HEX="0x..."  # Convertido para hex (32 bytes)

# Executar transferência
cargo run -- \
  -k ~/solana-warp-deployer-key.json \
  -u https://api.testnet.solana.com \
  token transfer-remote \
  ~/solana-warp-deployer-key.json \
  10000000 \
  1325 \
  ${TERRA_RECIPIENT_HEX} \
  synthetic \
  --program-id ${SOLANA_PROGRAM_ID}
```

**Parâmetros:**
- `10000000`: Quantidade em unidades menores (6 decimais = 10 LUNC)
- `1325`: Domain ID do Terra Classic
- `TERRA_RECIPIENT_HEX`: Endereço Terra Classic em hex (32 bytes)
- `synthetic`: Tipo de token na origem (Solana)
- `--program-id`: Program ID do warp route

### 5.4. Verificar Recebimento no Terra Classic

```bash
# Verificar saldo
terrad query bank balances ${TERRA_RECIPIENT} \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443

# Verificar no explorer
echo "https://finder.terra-classic.hexxagon.dev/testnet/address/${TERRA_RECIPIENT}"
```

---

## Troubleshooting

### Problema 1: Erro ao Converter Endereço Solana para Hex

**Sintoma:** Erro ao tentar linkar ou transferir.

**Solução:**
```bash
# Instalar dependências Python (se necessário)
pip3 install base58

# Converter endereço Solana (base58) para hex
python3 << EOF
import base58
import binascii

solana_address = "YOUR_SOLANA_ADDRESS"
decoded = base58.b58decode(solana_address)
hex_address = binascii.hexlify(decoded).decode('utf-8')
# Pad para 64 caracteres (32 bytes)
hex_padded = hex_address.zfill(64)
print(hex_padded)  # Para usar em transfer_remote (sem 0x)
# print(f"0x{hex_padded}")  # Para usar em outros contextos
EOF
```

**Nota:** Para `transfer_remote` no Terra Classic, use apenas os 64 caracteres hex (sem `0x`).

### Problema 2: IGP Gas Payment Insuficiente

**Sintoma:** Erro "insufficient hook payment" ou "insufficient funds".

**Solução:**
1. Verificar configuração do IGP Oracle para domain 1399811150:
```bash
IGP_ORACLE="terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"
terrad query wasm contract-state smart ${IGP_ORACLE} \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":1399811150}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

2. Recalcular IGP gas payment (ver `IGP-COMPLETE-GUIDE.md`)

3. Aumentar `--amount` para incluir IGP gas payment

### Problema 3: Erro "Route Not Found" na Solana

**Sintoma:** Transferência da Solana falha com "route not found".

**Solução:**
1. Verificar se o remote router foi enrollado:
```bash
cargo run -- \
  -k ~/solana-warp-deployer-key.json \
  -u https://api.testnet.solana.com \
  token query \
  --program-id ${SOLANA_PROGRAM_ID} \
  synthetic
```

2. Re-enroll o remote router se necessário (ver Passo 3.3)

### Problema 4: Token Não Aparece na Solana

**Sintoma:** Transferência parece ter sucesso, mas token não aparece.

**Solução:**
1. Verificar se a ATA (Associated Token Account) foi criada:
```bash
# Criar ATA se necessário
spl-token create-account ${SOLANA_MINT_ACCOUNT} \
  --owner ~/solana-warp-deployer-key.json \
  --url https://api.testnet.solana.com
```

2. Verificar se o relayer processou a mensagem:
   - Verificar no [Hyperlane Explorer](https://explorer.hyperlane.xyz/)
   - Aguardar alguns minutos para processamento

### Problema 5: Erro ao Build dos Programas Sealevel

**Sintoma:** Erro ao compilar programas Rust.

**Solução:**
```bash
# Atualizar Rust
rustup update

# Limpar e rebuild
cd hyperlane-monorepo/rust/sealevel
cargo clean

# Build correto (sem --release diretamente)
cargo build-sbf -- --release

# Ou build de debug (mais rápido)
cargo build-sbf

# Verificar dependências
cargo check

# Se houver problemas com versão do Solana CLI
solana-install update
```

**Erro comum:** `cargo build-sbf --release` (incorreto)
**Correto:** `cargo build-sbf -- --release` ou `cargo build-sbf`

---

## Referências

### Documentação Oficial

- [Hyperlane Solana Warp Route Guide](https://docs.hyperlane.xyz/docs/guides/warp-routes/svm/svm-warp-route-guide)
- [Extending Warp Routes](https://docs.hyperlane.xyz/docs/guides/warp-routes/evm/extending-warp-routes)
- [Hyperlane Registry - Solana Testnet](https://github.com/hyperlane-xyz/hyperlane-registry/tree/main/chains/solanatestnet)

### Repositórios

- [Hyperlane Monorepo](https://github.com/hyperlane-xyz/hyperlane-monorepo)
- [cw-hyperlane](https://github.com/many-things/cw-hyperlane)

### Exploradores

- [Hyperlane Explorer](https://explorer.hyperlane.xyz/)
- [Terra Classic Finder](https://finder.terra-classic.hexxagon.dev/testnet)
- [Solana Explorer](https://explorer.solana.com/?cluster=testnet)

### Ferramentas

- [Solana CLI Documentation](https://docs.solana.com/cli)
- [SPL Token CLI](https://spl.solana.com/token)

---

## Resumo dos Comandos Principais

### Terra Classic

```bash
# Deploy
yarn cw-hpl warp create ./example/warp/uluna-solana.json -n terraclassic

# Link
yarn cw-hpl warp link \
  --asset-type native \
  --asset-id uluna \
  --target-domain 1399811150 \
  --warp-address ${SOLANA_PROGRAM_ID_HEX} \
  -n terraclassic

# Transfer
yarn cw-hpl warp transfer \
  --asset-type native \
  --asset-id uluna \
  --target-domain 1399811150 \
  --recipient ${SOLANA_RECIPIENT_HEX} \
  --amount 10000000 \
  -n terraclassic
```

### Solana

```bash
# Deploy
cargo run -- -k ~/solana-warp-deployer-key.json warp-route deploy \
  --warp-route-name lunc-solana \
  --environment testnet \
  --token-config-file token-config.json

# Enroll Remote Router
cargo run -- -k ~/solana-warp-deployer-key.json \
  -u https://api.testnet.solana.com \
  token enroll-remote-router \
  --program-id ${SOLANA_PROGRAM_ID} \
  --remote-domain 1325 \
  --remote-router ${TERRA_WARP_HEX}

# Transfer
cargo run -- -k ~/solana-warp-deployer-key.json \
  -u https://api.testnet.solana.com \
  token transfer-remote \
  ~/solana-warp-deployer-key.json \
  10000000 \
  1325 \
  ${TERRA_RECIPIENT_HEX} \
  synthetic \
  --program-id ${SOLANA_PROGRAM_ID}
```

---

**Última atualização:** Dezembro 2025

