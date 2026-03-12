# Transfer Remote — Terra Classic → EVM / Sealevel

Guia completo para o script `transfer-remote-terra.sh`, que envia tokens via Hyperlane Warp Route
da **Terra Classic** para redes EVM (Sepolia, BSC Testnet) e Sealevel (Solana Testnet).

---

## Índice

1. [Pré-requisitos](#1--pré-requisitos)
2. [Estrutura de arquivos](#2--estrutura-de-arquivos)
3. [Configurar chave privada](#3--configurar-chave-privada)
4. [Modo interativo](#4--modo-interativo)
5. [Modo não-interativo](#5--modo-não-interativo)
6. [Opções disponíveis (token × rede)](#6--opções-disponíveis-token--rede)
7. [Formatos de endereço do destinatário](#7--formatos-de-endereço-do-destinatário)
8. [Fee IGP (gas de destino)](#8--fee-igp-gas-de-destino)
9. [Saída e relatório](#9--saída-e-relatório)
10. [Como verificar a entrega](#10--como-verificar-a-entrega)
    - [Confirmar o envio na Terra Classic](#1-confirmar-o-envio-na-terra-classic)
    - [Rastrear no Hyperlane Explorer](#2-rastrear-a-mensagem-no-hyperlane-explorer)
    - [Verificar recebimento na rede destino](#3-verificar-recebimento-na-rede-de-destino)
    - [Consultar saldo CW20 via terrad](#4-verificar-saldo-cw20-antes-do-envio-terra-classic)
    - [Consultar saldo LUNC nativo via terrad](#5-consultar-saldo-de-lunc-nativo-de-uma-carteira)
    - [Consultar múltiplos CW20 em loop](#6-consultar-saldo-de-múltiplos-tokens-cw20-todos-de-uma-vez-via-loop)
11. [Referência de contratos](#11--referência-de-contratos)
12. [Troubleshooting](#12--troubleshooting)

---

## 1 — Pré-requisitos

| Dependência | Verificar | Instalar |
|---|---|---|
| `node` (≥ 16) | `node --version` | `nvm install 18` |
| `jq` | `jq --version` | `sudo apt install jq` |
| `curl` | `curl --version` | `sudo apt install curl` |
| `python3` | `python3 --version` | já disponível no Ubuntu |
| `@cosmjs` (node_modules) | automático | `cd ~/cw-hyperlane && yarn install` |

O script localiza automaticamente o `node_modules` percorrendo os diretórios pai até encontrar um `package.json`.

---

## 2 — Estrutura de arquivos

```
script-warp-terraclassic/
├── transfer-remote-terra.sh        ← script principal
├── warp-evm-config.json            ← configuração EVM + tokens Terra Classic
├── warp-sealevel-config.json       ← configuração Solana Testnet
└── log/
    ├── transfer-remote-terra.log   ← log cumulativo de todas as execuções
    └── TRANSFER-REMOTE-<REDE>-<TOKEN>-<timestamp>.txt  ← relatório por envio
```

O script lê os dois arquivos JSON para montar a lista de opções disponíveis. Somente combinações
token × rede marcadas como `"deployed": true` aparecem no menu.

---

## 3 — Configurar chave privada

A chave privada é da **conta remetente na Terra Classic**. Deve ser em formato hexadecimal
(32 bytes = 64 caracteres hex, com ou sem prefixo `0x`).

```bash
export TERRA_PRIVATE_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

Se não estiver definida, o script solicitará interativamente (entrada oculta).

> ⚠️ **Nunca comite sua chave privada em repositórios.**  
> Use variáveis de ambiente ou arquivos `.env` fora do controle de versão.

---

## 4 — Modo interativo

O modo mais simples: o script guia passo a passo.

```bash
cd ~/cw-hyperlane/script-warp-terraclassic

export TERRA_PRIVATE_KEY="sua_chave_hex"
./transfer-remote-terra.sh
```

### Fluxo de execução

**Passo 1 — Menu de seleção**

```
Selecione o token e a rede de destino:

  [1]   LUNC → Ethereum Sepolia Testnet  (domain 11155111)
  [2]   XPTO → Ethereum Sepolia Testnet  (domain 11155111)
  [3]   XPTV → Ethereum Sepolia Testnet  (domain 11155111)
  [4]   LUNC → BSC Testnet  (domain 97)
  [5]   XPV  → BSC Testnet  (domain 97)
  [6]   LUNC → Solana Testnet  (domain 1399811150)
  [7]   JURIS → Solana Testnet  (domain 1399811150)
  [8]   XPTO → Solana Testnet  (domain 1399811150)

  Opção [1-8]:
```

**Passo 2 — Endereço do destinatário**

```
  Formato EVM: 0x... (ex: 0x867f9ce9f0d7218b016351cb6122406e6d247a5e)
  Endereço do destinatário:
```

Para Solana:
```
  Formato Solana: Base58 (ex: EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd)
  Endereço do destinatário:
```

**Passo 3 — Quantidade**

```
  Decimais: 6 — ex: 1 XPTO = 1000000
  Quantidade (em unidades mínimas, ex: 10000000):
```

**Passo 4 — Resumo e confirmação**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Resumo da transferência
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Token          : XPTO  (cw20)
  Destino        : SEPOLIA  (domain 11155111)
  Recipient      : 0x867f9ce9f0d7218b016351cb6122406e6d247a5e
  Recipient b32  : 000000000000000000000000867f9ce9f0d7218b016351cb6122406e6d247a5e
  Amount         : 10000000
  Fee IGP        : 1780832150 uluna
  Warp TC        : terra16ql6l4fuudg0fxarcm4ukxlw0jalg5ljv8kg6h8f7dk9t2e7y6ssq2hqrm
  Collateral CW20: terra1zle6pwm9aztwu228e0spxrydlvmhj2qrq8ap3x2wrjc52kdvu4fs20rkch

  Confirmar e enviar? [s/N]:
```

Digite `s` para confirmar.

---

## 5 — Modo não-interativo

Útil para automação e scripts. Passe todas as variáveis antes da chamada:

```bash
export TERRA_PRIVATE_KEY="sua_chave_hex"

TOKEN_KEY=xpto \
DEST_NETWORK=sepolia \
RECIPIENT="0x867f9ce9f0d7218b016351cb6122406e6d247a5e" \
AMOUNT=10000000 \
AUTO_CONFIRM=s \
./transfer-remote-terra.sh
```

### Variáveis disponíveis

| Variável | Obrigatória | Descrição | Exemplo |
|---|---|---|---|
| `TERRA_PRIVATE_KEY` | ✅ | Chave privada hex do remetente | `xxxxxxxx...` |
| `TOKEN_KEY` | — | Identificador do token | `xpto`, `xptv`, `xpv`, `juris`, `wlunc` |
| `DEST_NETWORK` | — | Rede de destino | `sepolia`, `bsctestnet`, `solanatestnet` |
| `RECIPIENT` | — | Endereço do destinatário | `0x867f...` ou Base58 |
| `AMOUNT` | — | Valor em unidades mínimas | `10000000` |
| `IGP_FEE_ULUNA` | — | Fee manual em uluna (sobrescreve a consulta automática) | `1780832150` |
| `AUTO_CONFIRM` | — | `s` para não pedir confirmação | `s` |

Se `TOKEN_KEY` e `DEST_NETWORK` forem omitidos → modo interativo com menu.  
Se `RECIPIENT` for omitido → solicitado interativamente.  
Se `AMOUNT` for omitido → solicitado interativamente.

---

## 6 — Opções disponíveis (token × rede)

As opções do menu são geradas dinamicamente a partir dos JSONs de configuração.
Somente combinações com `"deployed": true` aparecem.

| # | Token | Rede | Domain | Tipo |
|---|---|---|---|---|
| 1 | LUNC | Ethereum Sepolia Testnet | 11155111 | native |
| 2 | XPTO | Ethereum Sepolia Testnet | 11155111 | CW20 |
| 3 | XPTV | Ethereum Sepolia Testnet | 11155111 | CW20 |
| 4 | LUNC | BSC Testnet | 97 | native |
| 5 | XPV  | BSC Testnet | 97 | CW20 |
| 6 | LUNC | Solana Testnet | 1399811150 | native |
| 7 | JURIS | Solana Testnet | 1399811150 | CW20 |
| 8 | XPTO | Solana Testnet | 1399811150 | CW20 |

### Adicionar um novo token/rede ao menu

Para que um novo warp apareça no menu, basta garantir em `warp-evm-config.json` ou
`warp-sealevel-config.json` que:

```json
// warp-evm-config.json → networks.<rede>.warp_tokens.<token>
{
  "deployed": true,
  "address": "0xEndereçoDoWarpNaRedeEVM"
}
```

```json
// warp-sealevel-config.json → networks.<rede>.warp_tokens.<token>
{
  "deployed": true,
  "program_id": "ProgramIdBase58",
  "program_hex": "0xprogramhex64chars"
}
```

E que o token esteja em `warp-evm-config.json → terra_classic.tokens.<token>.terra_warp` com `warp_address` preenchido.

---

## 7 — Formatos de endereço do destinatário

### EVM (Sepolia, BSC Testnet)

Aceita o formato padrão `0x` de 20 bytes (40 chars hex):

```
0x867f9ce9f0d7218b016351cb6122406e6d247a5e
```

O script converte automaticamente para **bytes32** (64 chars hex com padding de zeros à esquerda):

```
000000000000000000000000867f9ce9f0d7218b016351cb6122406e6d247a5e
```

### Sealevel (Solana Testnet)

Aceita três formatos:

1. **Base58** (formato padrão Solana):
   ```
   EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd
   ```

2. **Hex de 64 chars sem `0x`**:
   ```
   c6525508893d49539a9ae57421ec470517a5c815780b21b93a78e79569c0d01c
   ```

3. **Hex de 64 chars com `0x`**:
   ```
   0xc6525508893d49539a9ae57421ec470517a5c815780b21b93a78e79569c0d01c
   ```

> 💡 Para encontrar o endereço hex de uma wallet Solana Base58, use:
> ```bash
> node -e "
> const bs58 = require('node_modules/bs58');
> console.log(Buffer.from(bs58.decode('SEU_ENDEREÇO_BASE58')).toString('hex'));
> "
> ```

---

## 8 — Fee IGP (gas de destino)

O IGP (Interchain Gas Paymaster) na Terra Classic cobra uma taxa em **uluna** para cobrir o gas
no chain de destino. O script tenta calculá-la automaticamente e usa valores padrão como fallback.

### Cálculo automático

O script consulta o contrato IGP na Terra Classic via LCD:

```
Contrato : terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9
Query    : quote_gas_payment { dest_domain, gas_amount: "300000" }
```

Tenta múltiplos LCD endpoints em sequência.

### Valores padrão (fallback)

Se todos os LCDs falharem, usa valores históricos reais do projeto:

| Rede | Domain | Fee padrão (uluna) | LUNC aproximado |
|---|---|---|---|
| Sepolia | 11155111 | 1.780.832.150 | ~1,78 LUNC |
| BSC Testnet | 97 | 500.000.000 | ~0,50 LUNC |
| Solana Testnet | 1399811150 | 300.000 | ~0,0003 LUNC |

### Sobrescrever manualmente

```bash
IGP_FEE_ULUNA=2000000000 ./transfer-remote-terra.sh
```

> ⚠️ Se o fee for insuficiente, a transação falha com erro de gas. Aumente `IGP_FEE_ULUNA`.

---

## 9 — Saída e relatório

### Sucesso

```
╔═══════════════════════════════════════════════════════════╗
║  ✅  TRANSFERÊNCIA ENVIADA COM SUCESSO!                   ║
╚═══════════════════════════════════════════════════════════╝

  TX Hash :  EA8C0788EDF6194BE96C08844045D16189737A38...
  Explorer:  https://finder.hexxagon.io/rebel-2/tx/EA8C...

  A mensagem será relayada pelo Hyperlane Relayer.
  Tempo estimado de entrega: 1-5 minutos.

  Relatório : log/TRANSFER-REMOTE-SEPOLIA-XPTO-20260312-120000.txt
```

### Arquivos gerados

| Arquivo | Conteúdo |
|---|---|
| `log/transfer-remote-terra.log` | Uma linha por execução: data, token, rede, amount, fee, txhash |
| `log/TRANSFER-REMOTE-<REDE>-<TOKEN>-<timestamp>.txt` | Relatório completo da transferência |

Exemplo do relatório:
```
TRANSFER REMOTE — Terra Classic → SEPOLIA
Data          : Thu Mar 12 12:00:00 UTC 2026
Token         : XPTO  (cw20)
Destino       : SEPOLIA  (domain 11155111)
Recipient     : 0x867f9ce9f0d7218b016351cb6122406e6d247a5e
Recipient b32 : 000000000000000000000000867f9ce9f0d7218b016351cb6122406e6d247a5e
Amount        : 10000000
Fee IGP       : 1780832150 uluna
Warp TC       : terra16ql6l4fuudg0fxarcm4ukxlw0jalg5ljv8kg6h8f7dk9t2e7y6ssq2hqrm
Collateral    : terra1zle6pwm9aztwu228e0spxrydlvmhj2qrq8ap3x2wrjc52kdvu4fs20rkch
TX Hash       : EA8C0788EDF6194BE96C08844045D16189737A38...
Explorer      : https://finder.hexxagon.io/rebel-2/tx/EA8C...
```

---

## 10 — Como verificar a entrega

### 1. Confirmar o envio na Terra Classic

```
https://finder.hexxagon.io/rebel-2/tx/<TX_HASH>
```

Verifique nos eventos do contrato:
- `wasm-HplMessage.dispatched` → mensagem emitida pelo Mailbox
- `wasm-HplIgp.gas_payment` → fee IGP pago
- `message_id` → ID da mensagem (bytes32 hex)

### 2. Rastrear a mensagem no Hyperlane Explorer

```
https://explorer.hyperlane.xyz/message/<MESSAGE_ID>
```

O status deve passar por:
1. **Dispatched** → mensagem enviada
2. **Signed** → validador assinou
3. **Relayed** → relayer entregou no destino

### 3. Verificar recebimento na rede de destino

**EVM (Sepolia / BSC Testnet):**

Acesse o endereço do destinatário no explorador da rede destino e verifique o saldo do token ERC-20 do Warp.

- Sepolia Explorer: `https://sepolia.etherscan.io/address/<RECIPIENT>`
- BSC Testnet: `https://testnet.bscscan.com/address/<RECIPIENT>`

**Solana Testnet:**

```bash
spl-token accounts --owner <RECIPIENT_BASE58> --url https://api.testnet.solana.com
```

Ou no explorer:
```
https://explorer.solana.com/address/<RECIPIENT>?cluster=testnet
```

### 4. Verificar saldo CW20 antes do envio (Terra Classic)

**Via `terrad` (recomendado):**

```bash
terrad query wasm contract-state smart \
  <CW20_ADDRESS> \
  '{"balance":{"address":"<SUA_CARTEIRA>"}}' \
  --node https://rpc.terra-classic.hexxagon.dev:443
```

Exemplo real com XPTO:

```bash
terrad query wasm contract-state smart \
  terra1zle6pwm9aztwu228e0spxrydlvmhj2qrq8ap3x2wrjc52kdvu4fs20rkch \
  '{"balance":{"address":"terra18lr7ujd9nsgyr49930ppaajhadzrezam70j39k"}}' \
  --node https://rpc.terra-classic.hexxagon.dev:443
```

Retorno esperado:

```yaml
data:
  balance: "10000000"
```

**Via `curl` (sem terrad instalado):**

```bash
curl -s "https://lcd.terra-classic.hexxagon.dev/cosmwasm/wasm/v1/contract/<CW20_ADDRESS>/smart/$(
  python3 -c "import json,base64; print(base64.b64encode(json.dumps({'balance':{'address':'<SUA_CARTEIRA>'}}).encode()).decode())"
)" | jq '.data.balance'
```

### 5. Consultar saldo de LUNC nativo de uma carteira

```bash
terrad query bank balances <SUA_CARTEIRA> \
  --node https://rpc.terra-classic.hexxagon.dev:443
```

Exemplo:

```bash
terrad query bank balances terra18lr7ujd9nsgyr49930ppaajhadzrezam70j39k \
  --node https://rpc.terra-classic.hexxagon.dev:443
```

Retorno esperado:

```yaml
balances:
- amount: "5000000000"
  denom: uluna
```

> 💡 `uluna` é a unidade mínima do LUNC. Divida por `1.000.000` para obter o valor em LUNC.  
> Exemplo: `5000000000 uluna` = `5000 LUNC`

### 6. Consultar saldo de múltiplos tokens CW20 (todos de uma vez via loop)

```bash
# Lista de contratos CW20 e nomes (adapte conforme seus tokens)
declare -A CW20_TOKENS=(
  ["XPTO"]="terra1zle6pwm9aztwu228e0spxrydlvmhj2qrq8ap3x2wrjc52kdvu4fs20rkch"
  ["XPTV"]="terra19ujvy60tjeyehjrwlrdpqlp0gxmtt4qv452nwjqc6w6m38pm8xmq22lux3"
  ["XPV"]="terra1f2jw36hc7fzeu7dz2fhk250ezec7e80c2s6uxt3ry5ujjjslf9nqwvpu88"
  ["JURIS"]="terra1w7d0jqehn0ja3hkzsm0psk6z2hjz06lsq0nxnwkzkkq4fqwgq6tqa5te8e"
)
WALLET="terra18lr7ujd9nsgyr49930ppaajhadzrezam70j39k"
NODE="https://rpc.terra-classic.hexxagon.dev:443"

echo "Saldos de $WALLET"
for TOKEN in "${!CW20_TOKENS[@]}"; do
  ADDR="${CW20_TOKENS[$TOKEN]}"
  BAL=$(terrad query wasm contract-state smart "$ADDR" \
    "{\"balance\":{\"address\":\"$WALLET\"}}" \
    --node "$NODE" -o json 2>/dev/null | jq -r '.data.balance // "0"')
  echo "  $TOKEN: $BAL"
done
```

---

## 11 — Referência de contratos

### Terra Classic — Contratos Warp

| Token | Tipo | CW20 Collateral | Warp Contract |
|---|---|---|---|
| LUNC (WLUNC) | native | — | `terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml` |
| JURIS | CW20 | `terra1w7d0jqehn0ja3hkzsm0psk6z2hjz06lsq0nxnwkzkkq4fqwgq6tqa5te8e` | `terra1stu3cl7mhtsc2mf9cputawfd6v6e4a2nkmhhphh47lsrr3j6ktdqlcfe2l` |
| XPTO | CW20 | `terra1zle6pwm9aztwu228e0spxrydlvmhj2qrq8ap3x2wrjc52kdvu4fs20rkch` | `terra16ql6l4fuudg0fxarcm4ukxlw0jalg5ljv8kg6h8f7dk9t2e7y6ssq2hqrm` |
| XPTV | CW20 | `terra19ujvy60tjeyehjrwlrdpqlp0gxmtt4qv452nwjqc6w6m38pm8xmq22lux3` | `terra1n8y4sj9lrqq66pf7je0nm7s6nhln5z4s3accw9g2aassdh8dzqts9y0928` |
| XPV  | CW20 | `terra1f2jw36hc7fzeu7dz2fhk250ezec7e80c2s6uxt3ry5ujjjslf9nqwvpu88` | `terra1dnflusc7slapvals97em3fj4vrfyx90npr3znq6y45qjy7hhd6jqchqsgx` |

### Terra Classic — Contratos Hyperlane

| Contrato | Endereço |
|---|---|
| Mailbox | `terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf` |
| IGP | `terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9` |
| ISM Routing | `terra1h4sd8fyxhde7dc9w9y9zhc2epphgs75q7zzfg3tfynm8qvpe3jlsd7sauh` |

### Sepolia (domain 11155111)

| Token | Warp ERC-20 |
|---|---|
| LUNC | `0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4` |
| XPTO | `0xbF43aA4878f5Ad0fcAC12Cd3A835DD3506981048` |
| XPTV | `0x7d92c2E01933F1C651845152DBd4222d475Bd9f0` |

### BSC Testnet (domain 97)

| Token | Warp ERC-20 |
|---|---|
| LUNC | `0x2144Be4477202ba2d50c9A8be3181241878cf7D8` |
| XPV  | `0x11D6aa52d60611a513ab783842Dc397C86E7fff0` |

### Solana Testnet (domain 1399811150)

| Token | Program ID |
|---|---|
| LUNC | `5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x` |
| JURIS | `G3eEYHv2GrBJ6KTS3XQhRd7QYdwnfWjisQrSVWedQK4y` |
| XPTO | `jNkiNLXQetj9L2tDX6xTgx9QP1tgtNgYXamouNbbwx9` |

---

## 12 — Troubleshooting

### ❌ `Account '...' does not exist on chain`

A conta remetente não existe ou nunca recebeu fundos na Terra Classic.

```
Causa  : wallet nunca usada ou chave privada incorreta
Solução: verifique o endereço em https://finder.hexxagon.io/rebel-2
         certifique-se de que a conta tem saldo de LUNC
```

### ❌ `route not found`

O warp contract na Terra Classic não tem rota configurada para a rede destino.

```
Causa  : enrollRemoteRouter não foi executado ou a rota aponta para endereço antigo
Solução: execute create-warp-evm.sh ou create-warp-sealevel.sh para reconfigurar
         ou use enroll-terra-router.sh para fazer manualmente
```

### ❌ `insufficient funds` / `out of gas`

```
Causa  : saldo de LUNC insuficiente ou IGP fee subestimado
Solução: verifique saldo com:
           curl -s "https://lcd.terra-classic.hexxagon.dev/cosmos/bank/v1beta1/balances/<WALLET>"
         aumente a fee com:
           IGP_FEE_ULUNA=3000000000 ./transfer-remote-terra.sh
```

### ❌ `Nenhuma combinação token/rede deployada encontrada`

```
Causa  : warp-evm-config.json ou warp-sealevel-config.json não tem nenhum token
         com "deployed": true e endereço válido
Solução: verifique os arquivos de configuração e confirme que o warp foi deployado
```

### ❌ Mensagem enviada mas não chega no destino

**Passo a passo de diagnóstico:**

1. Confirme que a TX passou na Terra Classic:
   ```
   https://finder.hexxagon.io/rebel-2/tx/<TX_HASH>
   ```

2. Verifique o relayer/validador no Hyperlane Explorer:
   ```
   https://explorer.hyperlane.xyz/message/<MESSAGE_ID>
   ```
   O `message_id` aparece nos eventos da TX como `wasm-HplMessage.dispatched`.

3. Confirme que o validador está gerando checkpoints:
   - Terra Classic: `https://hyperlane-validator-signatures-igorveras-terraclassic.s3.us-east-1.amazonaws.com/`

4. Verifique se a rota inversa está configurada (destino → Terra Classic):
   - O warp na rede destino precisa ter `enrollRemoteRouter` apontando para o warp da Terra Classic.

### ❌ `Endereço EVM inválido` ou `Endereço Solana inválido`

```
EVM   : use exatamente 40 chars hex com 0x (ex: 0xAbCd...1234)
Solana: use Base58 padrão (ex: EMAYGf...) ou hex de exatamente 64 chars sem 0x
```

### ❌ `node_modules/@cosmjs/cosmwasm-stargate não encontrado`

```bash
cd ~/cw-hyperlane
yarn install
```

---

## Links úteis

| Recurso | URL |
|---|---|
| Explorer Terra Classic | https://finder.hexxagon.io/rebel-2 |
| Hyperlane Explorer (mensagens) | https://explorer.hyperlane.xyz |
| Sepolia Etherscan | https://sepolia.etherscan.io |
| BSC Testnet Explorer | https://testnet.bscscan.com |
| Solana Testnet Explorer | https://explorer.solana.com/?cluster=testnet |
| Mailbox Terra Classic | https://finder.hexxagon.io/rebel-2/address/terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf |
| S3 Validator Terra Classic | https://hyperlane-validator-signatures-igorveras-terraclassic.s3.us-east-1.amazonaws.com/ |
| S3 Validator Sepolia | https://hyperlane-validator-signatures-igorveras-sepolia.s3.us-east-1.amazonaws.com/ |
| S3 Validator BSC Testnet | https://hyperlane-validator-signatures-igorveras-bsctestnet.s3.us-east-1.amazonaws.com/ |
