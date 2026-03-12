# Guia — `transfer-remote-to-terra.sh`

Envio de tokens **EVM → Terra Classic** e **Sealevel (Solana) → Terra Classic** via Hyperlane Warp Routes.

---

## Índice

1. [Visão geral](#1-visão-geral)
2. [Pré-requisitos](#2-pré-requisitos)
3. [Estrutura de arquivos](#3-estrutura-de-arquivos)
4. [Modo interativo](#4-modo-interativo)
5. [Modo não-interativo](#5-modo-não-interativo)
6. [Variáveis de ambiente](#6-variáveis-de-ambiente)
7. [Fluxo EVM → Terra Classic](#7-fluxo-evm--terra-classic)
8. [Fluxo Sealevel → Terra Classic](#8-fluxo-sealevel--terra-classic)
   - [Importar keypair do Phantom](#importar-keypair-de-uma-carteira-phantom)
9. [Como verificar a entrega](#9-como-verificar-a-entrega)
10. [Consultar saldos](#10-consultar-saldos)
11. [Logs e relatórios](#11-logs-e-relatórios)
12. [Referências de contratos](#12-referências-de-contratos)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. Visão geral

O script `transfer-remote-to-terra.sh` executa uma transferência cross-chain de **qualquer rede de origem** (EVM ou Solana) para a **Terra Classic** usando a infraestrutura Hyperlane Warp.

```
EVM (Sepolia / BSC Testnet)          Terra Classic
   Warp HypERC20 Synthetic   ──────►   Warp CW20 Collateral
   transferRemote()                      (tokens liberados)
```

```
Solana Testnet                        Terra Classic
   Warp SealevelHypSynthetic ──────►   Warp CW20 Collateral
   token transfer-remote                 (tokens liberados)
```

**O que o script faz automaticamente:**
- Lê os contratos deployados dos arquivos `warp-evm-config.json` e `warp-sealevel-config.json`
- Converte o endereço Terra Classic (bech32) para o formato `bytes32` exigido pelo Hyperlane
- Consulta o fee IGP via `quoteGasPayment()` (EVM) ou via configuração (Sealevel)
- Exibe resumo e pede confirmação antes de enviar
- Grava relatório em `log/TRANSFER-TO-TERRA-<REDE>-<TOKEN>-<timestamp>.txt`

---

## 2. Pré-requisitos

### Dependências comuns

| Ferramenta | Como instalar |
|------------|--------------|
| `jq`       | `sudo apt install jq` |
| `curl`     | `sudo apt install curl` |
| `python3`  | `sudo apt install python3` |
| `python3-bech32` | `pip3 install bech32` |

### Para EVM (Sepolia / BSC Testnet)

| Ferramenta | Como instalar |
|------------|--------------|
| `cast` (Foundry) | `curl -L https://foundry.paradigm.xyz \| bash && foundryup` |
| Chave privada EVM com saldo | Ver seção [7](#7-fluxo-evm--terra-classic) |

### Para Sealevel (Solana)

| Ferramenta | Como instalar |
|------------|--------------|
| `hyperlane-sealevel-client` | `cd /home/lunc/hyperlane-monorepo/rust/sealevel && cargo build` |
| Keypair Solana (`.json`) | `solana-keygen new -o ~/minha-carteira.json` |
| Saldo SOL para IGP fee | Obtível via faucet: https://faucet.solana.com |

---

## 3. Estrutura de arquivos

```
script-warp-terraclassic/
├── transfer-remote-to-terra.sh        ← este script
├── warp-evm-config.json               ← contratos EVM deployados
├── warp-sealevel-config.json          ← programas Sealevel deployados
└── log/
    ├── transfer-remote-to-terra.log   ← histórico resumido de todas as transferências
    └── TRANSFER-TO-TERRA-<REDE>-<TOKEN>-<timestamp>.txt  ← relatório individual
```

---

## 4. Modo interativo

Execute sem variáveis de ambiente. O script apresenta um menu numerado com todos os tokens e redes disponíveis:

```bash
cd ~/cw-hyperlane/script-warp-terraclassic
./transfer-remote-to-terra.sh
```

**Exemplo de menu exibido:**

```
🌉  TRANSFER REMOTE — Outra Rede → Terra Classic

Selecione o token e a rede de origem:

  [1]   LUNC ← Ethereum Sepolia Testnet  (domain 11155111)
  [2]   XPTO ← Ethereum Sepolia Testnet  (domain 11155111)
  [3]   XPTV ← Ethereum Sepolia Testnet  (domain 11155111)
  [4]   LUNC ← BSC Testnet               (domain 97)
  [5]   XPV  ← BSC Testnet               (domain 97)
  [6]   LUNC ← Solana Testnet            (domain 1399811150)
  [7]   JURIS ← Solana Testnet           (domain 1399811150)
  [8]   XPTO ← Solana Testnet            (domain 1399811150)

  Opção [1-8]:
```

O script pergunta sequencialmente:
1. **Opção** — número do token/rede
2. **Destinatário** — endereço Terra Classic (`terra1...`)
3. **Quantidade** — em unidades mínimas (ex: `1000000` = 1 XPTO com 6 decimais)
4. **Gas fee** — consultado automaticamente; se falhar, pede manualmente
5. **Chave privada** — EVM (`ETH_PRIVATE_KEY`) ou caminho do keypair Solana
6. **Confirmação** — `[s/N]` antes de enviar

---

## 5. Modo não-interativo

Passe todas as informações via variáveis de ambiente para automação ou scripts de CI.

### EVM → Terra Classic

```bash
cd ~/cw-hyperlane/script-warp-terraclassic

export ETH_PRIVATE_KEY="0xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxab"

TOKEN_KEY=xpto \
SOURCE_NETWORK=sepolia \
RECIPIENT="terra18lr7ujd9nsgyr49930ppaajhadzrezam70j39k" \
AMOUNT=1000000 \
AUTO_CONFIRM=s \
./transfer-remote-to-terra.sh
```

### Sealevel → Terra Classic

```bash
cd ~/cw-hyperlane/script-warp-terraclassic

TOKEN_KEY=xpto \
SOURCE_NETWORK=solanatestnet \
RECIPIENT="terra18lr7ujd9nsgyr49930ppaajhadzrezam70j39k" \
AMOUNT=1000000 \
SOL_KEYPAIR="/home/lunc/keys/solana-keypair-BirXd4QDxfq2vx9LGqgXXSgZrjT81rhoFGUbQRWDEf1j.json" \
AUTO_CONFIRM=s \
./transfer-remote-to-terra.sh
```

> **⚠️ Segurança:** Nunca coloque chaves privadas reais em históricos de shell. Use `export` antes de executar ou passe pela variável no próprio comando e limpe logo em seguida: `unset ETH_PRIVATE_KEY`.

---

## 6. Variáveis de ambiente

| Variável | Obrigatória | Descrição |
|----------|-------------|-----------|
| `TOKEN_KEY` | Não (interativo) | Chave do token no config, ex: `xpto`, `wlunc`, `xpv` |
| `SOURCE_NETWORK` | Não (interativo) | Rede de origem, ex: `sepolia`, `bsctestnet`, `solanatestnet` |
| `RECIPIENT` | Não (interativo) | Endereço Terra Classic destino (`terra1...`) |
| `AMOUNT` | Não (interativo) | Valor em unidades mínimas (sem decimais), ex: `1000000` |
| `ETH_PRIVATE_KEY` | EVM: sim | Chave privada da carteira EVM, com prefixo `0x` |
| `SOL_KEYPAIR` | Sealevel: opcional | Caminho para o arquivo `.json` do keypair Solana |
| `AUTO_CONFIRM` | Não | `s` para confirmar sem interação |

---

## 7. Fluxo EVM → Terra Classic

### O que acontece internamente

```
1. cast call <WARP_EVM> "quoteGasPayment(uint32)" 1325
   → Retorna o fee em wei necessário para pagar o IGP

2. cast send <WARP_EVM> "transferRemote(uint32,bytes32,uint256)"
   <TC_DOMAIN=1325>  <RECIPIENT_B32>  <AMOUNT>
   --value <FEE_WEI>
   --private-key <ETH_PRIVATE_KEY>
   --rpc-url <RPC>
```

### Endereços dos contratos EVM (testnet)

| Rede | Token | Warp Contract | Domain |
|------|-------|--------------|--------|
| Sepolia | LUNC | `0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4` | 11155111 |
| Sepolia | XPTO | `0xbF43aA4878f5Ad0fcAC12Cd3A835DD3506981048` | 11155111 |
| Sepolia | XPTV | `0x7d92c2E01933F1C651845152DBd4222d475Bd9f0` | 11155111 |
| BSC Testnet | LUNC | `0x2144Be4477202ba2d50c9A8be3181241878cf7D8` | 97 |
| BSC Testnet | XPV  | `0x11D6aa52d60611a513ab783842Dc397C86E7fff0` | 97 |

### Converter endereço Terra Classic para bytes32 manualmente

Se precisar calcular o `bytes32` de um endereço manualmente:

```python
import bech32

addr = "terra18lr7ujd9nsgyr49930ppaajhadzrezam70j39k"
hrp, data = bech32.bech32_decode(addr)
raw = bytes(bech32.convertbits(data, 5, 8, False))
print(raw.hex().zfill(64))
# → 0000000000000000000000003fc7ee49a59c1041d4a58bc21ef657eb443c8bbb
```

### Consultar gas fee manualmente

```bash
# Sepolia → Terra Classic (domain 1325)
cast call 0xbF43aA4878f5Ad0fcAC12Cd3A835DD3506981048 \
    "quoteGasPayment(uint32)(uint256)" 1325 \
    --rpc-url https://ethereum-sepolia-rpc.publicnode.com

# BSC Testnet → Terra Classic
cast call 0x11D6aa52d60611a513ab783842Dc397C86E7fff0 \
    "quoteGasPayment(uint32)(uint256)" 1325 \
    --rpc-url https://bsc-testnet-rpc.publicnode.com
```

### Verificar saldo do token EVM (HypERC20 Synthetic)

```bash
# Saldo de XPTO na Sepolia
cast call 0xbF43aA4878f5Ad0fcAC12Cd3A835DD3506981048 \
    "balanceOf(address)(uint256)" \
    "0xSUA_CARTEIRA_EVM" \
    --rpc-url https://ethereum-sepolia-rpc.publicnode.com
```

---

## 8. Fluxo Sealevel → Terra Classic

### O que acontece internamente

```
hyperlane-sealevel-client \
  --url <SOL_RPC> \
  --keypair <KEYPAIR_PATH> \
  token transfer-remote \
  <SENDER_PUBKEY> <AMOUNT> <TC_DOMAIN=1325> <RECIPIENT_B32> synthetic \
  --program-id <PROGRAM_ID>
```

O `RECIPIENT_B32` é o endereço `terra1...` convertido para hex de 64 caracteres (sem `0x`).

### Endereços dos programas Sealevel (testnet)

| Rede | Token | Program ID | Mint Address |
|------|-------|-----------|-------------|
| Solana Testnet | JURIS | `G3eEYHv2GrBJ6KTS3XQhRd7QYdwnfWjisQrSVWedQK4y` | `ExzEij8z7xc71kvjuMHmejRkmM4ACgKjDWuEaXdDubRa` |
| Solana Testnet | XPTO  | `jNkiNLXQetj9L2tDX6xTgx9QP1tgtNgYXamouNbbwx9` | `Db8VbMerYxksYwSSdetpy6Jhp2BrE4hk9Sh9dYJT5dQ2` |

### Verificar saldo SPL antes de enviar

```bash
# Saldo do token XPTO (SPL) no Solana Testnet
# Sintaxe correta: <MINT_ADDRESS> --owner <OWNER> --url <RPC>
spl-token balance Db8VbMerYxksYwSSdetpy6Jhp2BrE4hk9Sh9dYJT5dQ2 \
    --owner BirXd4QDxfq2vx9LGqgXXSgZrjT81rhoFGUbQRWDEf1j \
    --url https://api.testnet.solana.com

# Saldo nativo de SOL (necessário para pagar IGP fee)
solana balance BirXd4QDxfq2vx9LGqgXXSgZrjT81rhoFGUbQRWDEf1j \
    --url https://api.testnet.solana.com
```

> **ℹ️ Nota sobre token accounts:** Se o comando retornar `Could not find token account`, significa que a carteira ainda não recebeu esse token e portanto não pode enviá-lo. É necessário primeiro receber o token via transferência TC → Solana.

### Keypair Solana configurado no script

O campo `keypair` em `warp-sealevel-config.json` define o caminho padrão do keypair:

```json
"solanatestnet": {
  "keypair": "/home/lunc/keys/solana-keypair-BirXd4QDxfq2vx9LGqgXXSgZrjT81rhoFGUbQRWDEf1j.json",
  ...
}
```

Para usar um keypair diferente, passe `SOL_KEYPAIR=/caminho/para/keypair.json` como variável de ambiente.

---

### Importar keypair de uma carteira Phantom

Se você tem tokens SPL em uma carteira criada pelo **Phantom** (ou outra wallet de browser), você pode exportar a chave privada e converter para o formato JSON que o Solana CLI e o `hyperlane-sealevel-client` esperam.

#### Passo 1 — Exportar a chave do Phantom

1. Abra o **Phantom** e selecione a conta desejada
2. Clique nos **3 pontos** (`···`) ao lado do nome da conta → **Account Details**
3. Clique em **Show Private Key**
4. Confirme a senha da carteira
5. Copie a string exibida — é uma chave em formato **base58** (ex: `5K...abc`)

#### Passo 2 — Converter para keypair JSON

Crie o script de conversão:

```bash
cat << 'EOF' > /tmp/convert-phantom-key.py
import sys, json, base58

if len(sys.argv) < 2:
    print("Uso: python3 convert-phantom-key.py <CHAVE_PRIVADA_BASE58>")
    sys.exit(1)

private_key_b58 = sys.argv[1].strip()
try:
    key_bytes = base58.b58decode(private_key_b58)
    if len(key_bytes) == 64:
        keypair_array = list(key_bytes)
    elif len(key_bytes) == 32:
        try:
            from nacl.signing import SigningKey
            sk = SigningKey(key_bytes)
            vk = sk.verify_key
            keypair_array = list(key_bytes) + list(bytes(vk))
        except ImportError:
            keypair_array = list(key_bytes) + [0]*32
            print("AVISO: nacl não disponível, instale com: pip3 install pynacl")
    else:
        print(f"Tamanho inesperado: {len(key_bytes)} bytes"); sys.exit(1)
    print(json.dumps(keypair_array))
except Exception as e:
    print(f"Erro: {e}"); sys.exit(1)
EOF
```

Execute a conversão (substitua `COLE_SUA_CHAVE` pela chave exportada do Phantom):

```bash
# Instalar dependências se necessário
pip3 install base58 pynacl

# Converter e salvar (substitua BirXd4... pelo pubkey da sua carteira)
python3 /tmp/convert-phantom-key.py "COLE_SUA_CHAVE" \
    > /home/lunc/keys/solana-keypair-BirXd4QDxfq2vx9LGqgXXSgZrjT81rhoFGUbQRWDEf1j.json

# Verificar — deve exibir o pubkey correto da sua carteira
solana-keygen pubkey /home/lunc/keys/solana-keypair-BirXd4QDxfq2vx9LGqgXXSgZrjT81rhoFGUbQRWDEf1j.json
```

#### Passo 3 — Atualizar o config

Edite `warp-sealevel-config.json` e aponte o campo `keypair` para o novo arquivo:

```json
"solanatestnet": {
  "keypair": "/home/lunc/keys/solana-keypair-BirXd4QDxfq2vx9LGqgXXSgZrjT81rhoFGUbQRWDEf1j.json",
  ...
}
```

> **⚠️ Segurança:** O arquivo `.json` do keypair contém a chave privada completa. Mantenha-o com permissões restritas (`chmod 600`) e nunca o compartilhe ou comite em repositórios.

```bash
chmod 600 /home/lunc/keys/solana-keypair-BirXd4QDxfq2vx9LGqgXXSgZrjT81rhoFGUbQRWDEf1j.json
```

#### Por que usar uma carteira Phantom e não uma gerada pelo CLI?

Uma carteira criada com `solana-keygen new` começa vazia — ela não tem token accounts criadas para nenhum token SPL. Para enviar XPTO de Solana → TC, a carteira **precisa ter XPTO** previamente recebido (via transferência TC → Solana). Uma carteira Phantom que já recebeu tokens tem as token accounts criadas e o saldo disponível para queimar na transferência cross-chain.

---

## 9. Como verificar a entrega

Após o envio, a mensagem percorre:

```
Origem → Validator (assina) → Relayer (entrega) → Terra Classic Mailbox → Warp CW20 (libera tokens)
```

Tempo estimado: **1 a 5 minutos** dependendo do congestionamento.

### Passo 1 — Verificar a transação na rede de origem

**EVM (Sepolia):**
```
https://sepolia.etherscan.io/tx/<TX_HASH>
```

**Solana Testnet:**
```
https://explorer.solana.com/tx/<TX_SIGNATURE>?cluster=testnet
```

### Passo 2 — Rastrear a mensagem no Hyperlane Explorer

```
https://explorer.hyperlane.xyz/message/<MESSAGE_ID>
```

O `MESSAGE_ID` é emitido como evento na transação de origem. Nas transações EVM, ele aparece no log de eventos do Mailbox.

### Passo 3 — Verificar entrega no Mailbox Terra Classic

```bash
# Verificar se o message_id foi entregue
terrad query wasm contract-state smart \
    terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf \
    '{"mailbox":{"message_delivered":{"id":"<MESSAGE_ID_SEM_0x>"}}}' \
    --node https://rpc.terra-classic.hexxagon.dev
```

> **Nota:** O `MESSAGE_ID` deve ser informado sem o prefixo `0x`.

### Passo 4 — Verificar saldo CW20 no destino

```bash
# Saldo de XPTO no endereço destinatário
terrad query wasm contract-state smart \
    terra1zle6pwm9aztwu228e0spxrydlvmhj2qrq8ap3x2wrjc52kdvu4fs20rkch \
    '{"balance":{"address":"terra18lr7ujd9nsgyr49930ppaajhadzrezam70j39k"}}' \
    --node https://rpc.terra-classic.hexxagon.dev
```

---

## 10. Consultar saldos

### Saldo CW20 no Terra Classic

```bash
terrad query wasm contract-state smart \
    <CONTRATO_CW20> \
    '{"balance":{"address":"<CARTEIRA_TERRA>"}}' \
    --node https://rpc.terra-classic.hexxagon.dev
```

**Exemplo real — XPTO:**
```bash
terrad query wasm contract-state smart \
    terra1zle6pwm9aztwu228e0spxrydlvmhj2qrq8ap3x2wrjc52kdvu4fs20rkch \
    '{"balance":{"address":"terra18lr7ujd9nsgyr49930ppaajhadzrezam70j39k"}}' \
    --node https://rpc.terra-classic.hexxagon.dev
```

A resposta tem o formato:
```json
{"data":{"balance":"1000000"}}
```

### Saldo LUNC nativo

```bash
terrad query bank balances terra18lr7ujd9nsgyr49930ppaajhadzrezam70j39k \
    --node https://rpc.terra-classic.hexxagon.dev
```

### Consultar múltiplos tokens em loop

```bash
#!/usr/bin/env bash
WALLET="terra18lr7ujd9nsgyr49930ppaajhadzrezam70j39k"
NODE="https://rpc.terra-classic.hexxagon.dev"

declare -A TOKENS=(
    ["XPTO"]="terra1zle6pwm9aztwu228e0spxrydlvmhj2qrq8ap3x2wrjc52kdvu4fs20rkch"
    ["XPTV"]="terra1dnflusc7slapvals97em3fj4vrfyx90npr3znq6y45qjy7hhd6jqchqsgx"
    ["XPV"]="terra1d6e9mxaupf2zx2jj5kcayr5epz3q6g2fzm2u83w9fjqvzgz7v34qqdspxx"
    ["JURIS"]="terra1e8zhvt5g5vzy9d8x3dkxr0uxnfhk3lgaqx6l22szecpf4kxt3c4qktzknm"
)

for sym in "${!TOKENS[@]}"; do
    RESULT=$(terrad query wasm contract-state smart "${TOKENS[$sym]}" \
        "{\"balance\":{\"address\":\"${WALLET}\"}}" \
        --node "$NODE" --output json 2>/dev/null | jq -r '.data.balance // "0"')
    echo "$sym: $RESULT"
done
```

### Saldo SPL no Solana Testnet

```bash
# Saldo de XPTO (SPL)
spl-token balance \
    --address Db8VbMerYxksYwSSdetpy6Jhp2BrE4hk9Sh9dYJT5dQ2 \
    --owner <SUA_CARTEIRA_SOLANA> \
    --url https://api.testnet.solana.com

# Saldo de SOL nativo
solana balance <SUA_CARTEIRA_SOLANA> \
    --url https://api.testnet.solana.com
```

---

## 11. Logs e relatórios

Após cada execução bem-sucedida, o script grava:

| Arquivo | Conteúdo |
|---------|----------|
| `log/transfer-remote-to-terra.log` | Uma linha por transferência: data, rede, token, amount, tx hash |
| `log/TRANSFER-TO-TERRA-<REDE>-<TOKEN>-<timestamp>.txt` | Relatório completo com todos os parâmetros |

**Exemplo de relatório:**
```
TRANSFER REMOTE — SEPOLIA → Terra Classic
Data           : Thu Mar 12 15:30:00 UTC 2026
Token          : XPTO / XPTO
Origem         : SEPOLIA  (evm, domain 11155111)
Destino        : Terra Classic  (domain 1325)
Recipient TC   : terra18lr7ujd9nsgyr49930ppaajhadzrezam70j39k
Recipient b32  : 0000000000000000000000003fc7ee49a59c1041d4a58bc21ef657eb443c8bbb
Amount         : 1000000
Warp origem    : 0xbF43aA4878f5Ad0fcAC12Cd3A835DD3506981048
Gas fee (wei)  : 109030327234501
TX Hash        : 0xabc123...
```

**Visualizar histórico:**
```bash
cat ~/cw-hyperlane/script-warp-terraclassic/log/transfer-remote-to-terra.log
```

**Listar todos os relatórios:**
```bash
ls ~/cw-hyperlane/script-warp-terraclassic/log/TRANSFER-TO-TERRA-*.txt
```

---

## 12. Referências de contratos

### Terra Classic (rebel-2)

| Contrato | Endereço |
|----------|---------|
| Mailbox | `terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf` |
| ISM Routing | `terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh` |
| IGP | `terra1e7fkst7mzsucl0jka2yf5vw9h07s9uvf2yy53z4r4mshqnkktl8q78h0zd` |
| Warp LUNC (native) | `terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml` |
| Warp XPTO (CW20) | `terra16ql6l4fuudg0fxarcm4ukxlw0jalg5ljv8kg6h8f7dk9t2e7y6ssq2hqrm` |
| Warp XPTV (CW20) | `terra1vd8lgn2l38dzl2xhd4fph5cdtflm3e0exls9aeyl30d9e52sfpaq9zzp4c` |
| CW20 XPTO | `terra1zle6pwm9aztwu228e0spxrydlvmhj2qrq8ap3x2wrjc52kdvu4fs20rkch` |
| CW20 XPTV | `terra1dnflusc7slapvals97em3fj4vrfyx90npr3znq6y45qjy7hhd6jqchqsgx` |

### Links úteis

| Recurso | URL |
|---------|-----|
| Terra Classic Explorer | https://finder.hexxagon.io/rebel-2 |
| Sepolia Etherscan | https://sepolia.etherscan.io |
| BSC Testnet Explorer | https://testnet.bscscan.com |
| Solana Testnet Explorer | https://explorer.solana.com/?cluster=testnet |
| Hyperlane Explorer | https://explorer.hyperlane.xyz |
| S3 Validator TC | https://hyperlane-validator-signatures-igorveras-terraclassic.s3.us-east-1.amazonaws.com/ |
| S3 Validator Sepolia | https://hyperlane-validator-signatures-igorveras-sepolia.s3.us-east-1.amazonaws.com/ |
| S3 Validator BSC | https://hyperlane-validator-signatures-igorveras-bsctestnet.s3.us-east-1.amazonaws.com/ |

---

## 13. Troubleshooting

### ❌ `quoteGasPayment falhou`

O script tenta automaticamente todos os RPCs configurados em `rpc_urls`. Se todos falharem, pede o valor manualmente.

**Valores históricos (referência):**

| Rede origem | Gas fee aproximado |
|-------------|-------------------|
| Sepolia → TC | `109030327234501` wei (~0.00011 ETH) |
| BSC Testnet → TC | `1` wei (valor simbólico) |

Para consultar manualmente:
```bash
cast call <WARP_CONTRACT> "quoteGasPayment(uint32)(uint256)" 1325 \
    --rpc-url <RPC_URL>
```

---

### ❌ `ERR: endereço deve começar com terra1`

O recipient informado não é um endereço Terra Classic válido. Verifique que começa com `terra1` e tem o tamanho correto (44 caracteres).

---

### ❌ `insufficient funds` (EVM)

A carteira não tem saldo suficiente de ETH/BNB para pagar o gas fee + taxa da transação.

```bash
# Verificar saldo ETH da carteira
cast balance <SUA_CARTEIRA_EVM> --rpc-url https://ethereum-sepolia-rpc.publicnode.com

# Faucets testnet
# Sepolia: https://sepoliafaucet.com
# BSC Testnet: https://testnet.bnbchain.org/faucet-smart
```

---

### ❌ `SEM SALDO SPL — TRANSFERÊNCIA CANCELADA` (Sealevel)

O script detectou que a carteira não tem tokens SPL do token desejado. Isso ocorre quando:

1. **A carteira nunca recebeu esse token** — a token account não existe ainda
2. **O saldo é zero** — todos os tokens foram queimados em transferências anteriores

**Diagnóstico:**
```bash
# Sintaxe correta do spl-token balance (mint + owner + url)
spl-token balance Db8VbMerYxksYwSSdetpy6Jhp2BrE4hk9Sh9dYJT5dQ2 \
    --owner BirXd4QDxfq2vx9LGqgXXSgZrjT81rhoFGUbQRWDEf1j \
    --url https://api.testnet.solana.com
```

**Solução:** Primeiro envie tokens do Terra Classic para o Solana:
```bash
# Passo 1: TC → Solana (mint tokens na carteira Solana)
TOKEN_KEY=xpto DEST_NETWORK=solanatestnet \
  RECIPIENT="BirXd4QDxfq2vx9LGqgXXSgZrjT81rhoFGUbQRWDEf1j" \
  AMOUNT=2000000 AUTO_CONFIRM=s \
  ./transfer-remote-terra.sh

# Passo 2: após chegar (~2-5 min), enviar Solana → TC
TOKEN_KEY=xpto SOURCE_NETWORK=solanatestnet \
  RECIPIENT="terra18lr7ujd9nsgyr49930ppaajhadzrezam70j39k" \
  AMOUNT=1000000 AUTO_CONFIRM=s \
  ./transfer-remote-to-terra.sh
```

---

### ❌ `InvalidAccountData` / `BurnChecked` falha (Sealevel)

Erro mais detalhado que indica o mesmo problema: token account inexistente ou sem saldo.

```
Transaction simulation failed: Error processing Instruction 1: invalid account data for instruction
Program log: Instruction: BurnChecked
Program log: Error: InvalidAccountData
```

**Causa:** A carteira não tem token account criada para o mint em questão.  
**Solução:** Igual ao caso acima — primeiro receber tokens via TC → Solana.

---

### ❌ Usar carteira criada via `solana-keygen` vs Phantom

Carteiras criadas com `solana-keygen new` começam completamente vazias — sem nenhuma token account SPL. Para enviar tokens Solana → TC, a carteira **precisa ter tokens** previamente recebidos.

Se você tem uma carteira Phantom com saldo, importe-a conforme descrito na [seção 8 — Importar keypair do Phantom](#importar-keypair-de-uma-carteira-phantom).

---

### ❌ Mensagem enviada mas tokens não chegaram no Terra Classic

1. **Confirmar a transação na origem** — verificar no Explorer se a tx foi confirmada
2. **Verificar se o validator fez checkpoint** — acessar o S3 do validator e conferir se há novos arquivos
3. **Aguardar o relayer** — pode levar até 5 minutos
4. **Verificar entrega no Mailbox:**
   ```bash
   terrad query wasm contract-state smart \
       terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf \
       '{"mailbox":{"message_delivered":{"id":"<MESSAGE_ID_SEM_0x>"}}}' \
       --node https://rpc.terra-classic.hexxagon.dev
   ```
5. **Verificar saldo CW20** — seção [10](#10-consultar-saldos)

---

### ❌ `hyperlane-sealevel-client não encontrado`

O binário Rust precisa ser compilado:

```bash
cd /home/lunc/hyperlane-monorepo/rust/sealevel
cargo build
# Binário gerado em: target/debug/hyperlane-sealevel-client
```

---

### ❌ Combinação TOKEN_KEY + SOURCE_NETWORK não encontrada

Os valores de `TOKEN_KEY` e `SOURCE_NETWORK` devem corresponder exatamente às chaves dos arquivos de configuração.

**Valores válidos para EVM (`warp-evm-config.json`):**

| `SOURCE_NETWORK` | `TOKEN_KEY` disponíveis |
|------------------|------------------------|
| `sepolia` | `wlunc`, `xpto`, `xptv` |
| `bsctestnet` | `wlunc`, `xpv` |

**Valores válidos para Sealevel (`warp-sealevel-config.json`):**

| `SOURCE_NETWORK` | `TOKEN_KEY` disponíveis |
|------------------|------------------------|
| `solanatestnet` | `wlunc`, `juris`, `xpto` |
