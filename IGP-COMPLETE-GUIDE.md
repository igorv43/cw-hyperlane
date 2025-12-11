# Guia Completo: Interchain Gas Paymaster (IGP)

Este documento fornece uma explicação completa sobre o Interchain Gas Paymaster (IGP) do Hyperlane, incluindo fórmulas de cálculo, comandos de consulta e atualização, e troubleshooting.

## Índice

1. [Introdução ao IGP](#introdução-ao-igp)
2. [Fórmulas Oficiais do Hyperlane](#fórmulas-oficiais-do-hyperlane)
3. [Cálculo do Exchange Rate](#cálculo-do-exchange-rate)
4. [Comandos de Consulta](#comandos-de-consulta)
5. [Comandos de Atualização](#comandos-de-atualização)
6. [Verificação e Validação](#verificação-e-validação)
7. [Troubleshooting](#troubleshooting)
8. [Exemplos Práticos](#exemplos-práticos)

---

## Introdução ao IGP

O **Interchain Gas Paymaster (IGP)** é um contrato que permite que usuários paguem as taxas de gas da chain de destino usando tokens nativos da chain de origem. Isso facilita transferências cross-chain sem necessidade de ter tokens nativos na chain de destino.

### Componentes do IGP

1. **IGP Core**: Contrato principal que gerencia pagamentos de gas
2. **IGP Oracle**: Contrato que fornece taxas de câmbio e preços de gas para chains remotas
3. **Default Gas Usage**: Valor padrão de gas usado quando não especificado

### Endereços no Terra Classic Testnet

```bash
# IGP Core
IGP="terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9"

# IGP Oracle
IGP_ORACLE="terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"
```

---

## Fórmulas Oficiais do Hyperlane

Baseado na [documentação oficial do Hyperlane](https://docs.hyperlane.xyz/docs/protocol/core/interchain-gas-payment#interchaingaspaymasters), o cálculo do pagamento de gas interchain segue estas fórmulas:

### 1. Custo da Transação no Destino

```
destinationTxCost = destinationGasPrice × gasLimit
```

Onde:
- `destinationGasPrice`: Preço do gas na chain de destino (em wei)
- `gasLimit`: Quantidade de gas necessária para processar a mensagem

### 2. Taxa de Câmbio

```
exchangeRate = originGasTokenPrice / destinationGasTokenPrice
```

Onde:
- `originGasTokenPrice`: Preço do token de gas na chain de origem (USD)
- `destinationGasTokenPrice`: Preço do token de gas na chain de destino (USD)

### 3. Taxa na Chain de Origem

```
originFee = exchangeRate × destinationTxCost
```

### 4. Fórmula no Código Cosmos

No código Cosmos do Hyperlane, a fórmula implementada é:

```
gas_needed = (gas_amount × gas_price × exchange_rate) / TOKEN_EXCHANGE_RATE_SCALE
```

Onde:
- `TOKEN_EXCHANGE_RATE_SCALE = 10^10` (não 10^18!)
- `gas_amount`: Quantidade de gas necessária (gasLimit)
- `gas_price`: Preço do gas na chain de destino (em wei)
- `exchange_rate`: Taxa de câmbio escalada (escala 10^10)

---

## Cálculo do Exchange Rate

### Passo a Passo

#### 1. Determinar o Custo do Gas no Destino

```bash
# Exemplo: BSC Testnet
gas_limit = 200,000  # Gas necessário para transferência warp route
gas_price_wei = 100,000,000  # 0.1 Gwei
destination_tx_cost_wei = 200,000 × 100,000,000 = 20,000,000,000,000 wei
destination_tx_cost_bnb = 20,000,000,000,000 / 10^18 = 0.00002 BNB
```

#### 2. Converter para USD

```bash
# Preços de mercado (exemplo)
BNB_PRICE_USD = 897.88
LUNC_PRICE_USD = 0.00006069

destination_tx_cost_usd = 0.00002 × 897.88 = $0.017958
```

#### 3. Converter para Token da Origem

```bash
origin_fee_lunc = 0.017958 / 0.00006069 = 295.89 LUNC
origin_fee_uluna = 295.89 × 1,000,000 = 295,890,591 uluna
```

#### 4. Adicionar Margem para Relayers

```bash
# Recomendado: 20% de margem
margem = 1.20
origin_fee_uluna_com_margem = 295,890,591 × 1.20 = 355,068,709 uluna
```

#### 5. Calcular Exchange Rate para o Oracle

```bash
# Fórmula: exchange_rate = (gas_needed × 10^10) / (gas_amount × gas_price)
TOKEN_EXCHANGE_RATE_SCALE = 10^10
exchange_rate = (355,068,709 × 10^10) / (200,000 × 100,000,000)
exchange_rate = 177,534
```

### Script de Cálculo Automático

```bash
#!/bin/bash
# Calcular exchange_rate para IGP Oracle

# Parâmetros
GAS_LIMIT="${1:-200000}"  # Default: 200k gas
GAS_PRICE_GWEI="${2:-0.1}"  # Default: 0.1 Gwei
MARGEM="${3:-1.20}"  # Default: 20% margem

# Preços de mercado (atualizar conforme necessário)
BNB_PRICE_USD=897.88
LUNC_PRICE_USD=0.00006069

# Converter gas_price para wei
GAS_PRICE_WEI=$(echo "$GAS_PRICE_GWEI * 1000000000" | bc)

# Calcular custo em BNB
GAS_COST_BNB=$(echo "scale=18; $GAS_LIMIT * $GAS_PRICE_WEI / 1000000000000000000" | bc)

# Calcular custo em USD
GAS_COST_USD=$(echo "$GAS_COST_BNB * $BNB_PRICE_USD" | bc)

# Calcular custo em LUNC
GAS_COST_LUNC=$(echo "$GAS_COST_USD / $LUNC_PRICE_USD" | bc)

# Converter para uluna
GAS_COST_ULUNA=$(echo "$GAS_COST_LUNC * 1000000" | bc | cut -d. -f1)

# Adicionar margem
GAS_COST_ULUNA_MARGEM=$(echo "$GAS_COST_ULUNA * $MARGEM" | bc | cut -d. -f1)

# Calcular exchange_rate
TOKEN_EXCHANGE_RATE_SCALE=10000000000
EXCHANGE_RATE=$(echo "($GAS_COST_ULUNA_MARGEM * $TOKEN_EXCHANGE_RATE_SCALE) / ($GAS_LIMIT * $GAS_PRICE_WEI)" | bc | cut -d. -f1)

echo "=== Resultado do Cálculo ==="
echo "Gas Limit: $GAS_LIMIT"
echo "Gas Price: $GAS_PRICE_GWEI Gwei ($GAS_PRICE_WEI wei)"
echo "Custo em BNB: $GAS_COST_BNB"
echo "Custo em USD: \$$GAS_COST_USD"
echo "Custo em LUNC: $GAS_COST_LUNC"
echo "Custo em uluna: $GAS_COST_ULUNA"
echo "Custo com margem ($(echo "($MARGEM - 1) * 100" | bc)%): $GAS_COST_ULUNA_MARGEM uluna"
echo ""
echo "✅ Exchange Rate para configurar: $EXCHANGE_RATE"
echo "✅ Gas Price para configurar: $GAS_PRICE_WEI"
```

---

## Comandos de Consulta

### 1. Verificar Owner do IGP Oracle

```bash
IGP_ORACLE="terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"

terrad query wasm contract-state smart ${IGP_ORACLE} \
  '{"ownable":{"get_owner":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq -r '.data.owner'
```

### 2. Verificar Configuração do IGP Oracle

```bash
# Verificar exchange_rate e gas_price para um domain específico
terrad query wasm contract-state smart ${IGP_ORACLE} \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":97}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq '.data'
```

**Saída esperada:**
```json
{
  "gas_price": "100000000",
  "exchange_rate": "177534"
}
```

### 3. Verificar Default Gas do IGP

```bash
IGP="terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9"

terrad query wasm contract-state smart ${IGP} \
  '{"igp":{"default_gas":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq -r '.data.gas'
```

### 4. Verificar Gas para Domain Específico

```bash
# Verificar se há gas customizado para um domain
terrad query wasm contract-state smart ${IGP} \
  '{"igp":{"gas_for_domain":{"domains":[97]}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq '.data'
```

### 5. Calcular Quote de Gas Payment

```bash
# Calcular quanto gas é necessário para uma transferência
# Parâmetros: dest_domain, gas_amount
terrad query wasm contract-state smart ${IGP} \
  '{"igp":{"quote_gas_payment":{"dest_domain":97,"gas_amount":"200000"}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq -r '.data.gas_needed' | \
  awk '{printf "Gas needed: %s uluna (%.2f LUNC)\n", $1, $1/1000000}'
```

### 6. Verificar Rota do IGP para Domain

```bash
# Verificar qual Oracle está configurado para um domain
terrad query wasm contract-state smart ${IGP} \
  '{"router":{"get_route":{"domain":97}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq -r '.data.route'
```

### 7. Listar Todas as Rotas do IGP

```bash
terrad query wasm contract-state smart ${IGP} \
  '{"router":{"list_routes":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq '.data.routes'
```

### 8. Verificar Beneficiário do IGP

```bash
terrad query wasm contract-state smart ${IGP} \
  '{"igp":{"beneficiary":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq -r '.data.beneficiary'
```

---

## Comandos de Atualização

### 1. Atualizar IGP Oracle (Exchange Rate e Gas Price)

**Pré-requisito:** Você deve ser o owner do contrato IGP Oracle.

```bash
IGP_ORACLE="terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"
KEY_NAME="hypelane-val-testnet"  # Ajuste para sua key name

# Valores recomendados (gas_limit 200k, 20% margem, 0.1 Gwei)
EXCHANGE_RATE="177534"
GAS_PRICE="100000000"

terrad tx wasm execute ${IGP_ORACLE} \
  "{\"set_remote_gas_data_configs\":{\"configs\":[{\"remote_domain\":97,\"token_exchange_rate\":\"${EXCHANGE_RATE}\",\"gas_price\":\"${GAS_PRICE}\"}]}}" \
  --from ${KEY_NAME} \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

### 2. Atualizar Default Gas do IGP

```bash
IGP="terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9"
NEW_DEFAULT_GAS="200000"  # Recomendado: 200k para warp routes

terrad tx wasm execute ${IGP} \
  "{\"set_default_gas\":{\"gas\":\"${NEW_DEFAULT_GAS}\"}}" \
  --from ${KEY_NAME} \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

### 3. Configurar Gas Customizado para Domain Específico

```bash
# Configurar gas customizado para domain 97 (BSC Testnet)
CUSTOM_GAS="200000"

terrad tx wasm execute ${IGP} \
  "{\"set_gas_for_domain\":{\"config\":{\"domain\":97,\"gas\":\"${CUSTOM_GAS}\"}}}" \
  --from ${KEY_NAME} \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

### 4. Remover Gas Customizado para Domain

```bash
# Remover configuração customizada (usará default_gas)
terrad tx wasm execute ${IGP} \
  "{\"unset_gas_for_domain\":{\"domains\":[97]}}" \
  --from ${KEY_NAME} \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

### 5. Atualizar Beneficiário do IGP

```bash
NEW_BENEFICIARY="terra1..."  # Endereço do novo beneficiário

terrad tx wasm execute ${IGP} \
  "{\"set_beneficiary\":{\"beneficiary\":\"${NEW_BENEFICIARY}\"}}" \
  --from ${KEY_NAME} \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

---

## Verificação e Validação

### Script de Verificação Completa

```bash
#!/bin/bash
# Script para verificar toda a configuração do IGP

IGP="terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9"
IGP_ORACLE="terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"
DOMAIN=97  # BSC Testnet

echo "=== Verificação Completa do IGP ===\n"

# 1. Default Gas
echo "1. Default Gas do IGP:"
DEFAULT_GAS=$(terrad query wasm contract-state smart ${IGP} \
  '{"igp":{"default_gas":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq -r '.data.gas')
echo "   $DEFAULT_GAS gas\n"

# 2. Gas para Domain
echo "2. Gas para Domain $DOMAIN:"
GAS_FOR_DOMAIN=$(terrad query wasm contract-state smart ${IGP} \
  "{\"igp\":{\"gas_for_domain\":{\"domains\":[$DOMAIN]}}}" \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq -r '.data.gas[0].gas // "Não configurado (usa default)"')
echo "   $GAS_FOR_DOMAIN gas\n"

# 3. Rota do IGP
echo "3. Rota do IGP para Domain $DOMAIN:"
ROUTE=$(terrad query wasm contract-state smart ${IGP} \
  "{\"router\":{\"get_route\":{\"domain\":$DOMAIN}}}" \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq -r '.data.route')
echo "   $ROUTE\n"

# 4. Configuração do Oracle
echo "4. Configuração do IGP Oracle para Domain $DOMAIN:"
ORACLE_CONFIG=$(terrad query wasm contract-state smart ${IGP_ORACLE} \
  "{\"oracle\":{\"get_exchange_rate_and_gas_price\":{\"dest_domain\":$DOMAIN}}}" \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq '.data')
echo "$ORACLE_CONFIG\n"

# 5. Quote de Gas Payment
GAS_AMOUNT=${GAS_FOR_DOMAIN:-$DEFAULT_GAS}
echo "5. Quote de Gas Payment (gas_amount: $GAS_AMOUNT):"
QUOTE=$(terrad query wasm contract-state smart ${IGP} \
  "{\"igp\":{\"quote_gas_payment\":{\"dest_domain\":$DOMAIN,\"gas_amount\":\"$GAS_AMOUNT\"}}}" \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq -r '.data.gas_needed')
QUOTE_LUNC=$(echo "scale=2; $QUOTE / 1000000" | bc)
echo "   $QUOTE uluna ($QUOTE_LUNC LUNC)\n"

# 6. Beneficiário
echo "6. Beneficiário do IGP:"
BENEFICIARY=$(terrad query wasm contract-state smart ${IGP} \
  '{"igp":{"beneficiary":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq -r '.data.beneficiary')
echo "   $BENEFICIARY\n"

echo "=== Verificação Completa ===\n"
```

### Validar Cálculo Manual

```bash
#!/bin/bash
# Validar se o exchange_rate está correto

# Valores do Oracle
EXCHANGE_RATE="177534"
GAS_PRICE="100000000"
GAS_AMOUNT="200000"

# Calcular gas_needed esperado
TOKEN_EXCHANGE_RATE_SCALE=10000000000
GAS_NEEDED=$(echo "($GAS_AMOUNT * $GAS_PRICE * $EXCHANGE_RATE) / $TOKEN_EXCHANGE_RATE_SCALE" | bc)

# Converter para LUNC
GAS_NEEDED_LUNC=$(echo "scale=2; $GAS_NEEDED / 1000000" | bc)

echo "=== Validação do Cálculo ==="
echo "Exchange Rate: $EXCHANGE_RATE"
echo "Gas Price: $GAS_PRICE wei ($(echo "scale=2; $GAS_PRICE / 1000000000" | bc) Gwei)"
echo "Gas Amount: $GAS_AMOUNT"
echo ""
echo "Gas Needed (calculado): $GAS_NEEDED uluna ($GAS_NEEDED_LUNC LUNC)"
echo ""
echo "Verificar com quote_gas_payment:"
IGP="terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9"
QUOTE=$(terrad query wasm contract-state smart ${IGP} \
  "{\"igp\":{\"quote_gas_payment\":{\"dest_domain\":97,\"gas_amount\":\"$GAS_AMOUNT\"}}}" \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq -r '.data.gas_needed')
QUOTE_LUNC=$(echo "scale=2; $QUOTE / 1000000" | bc)
echo "Gas Needed (do contrato): $QUOTE uluna ($QUOTE_LUNC LUNC)"
echo ""
if [ "$GAS_NEEDED" = "$QUOTE" ]; then
  echo "✅ Cálculo está correto!"
else
  echo "❌ Diferença encontrada: $((GAS_NEEDED - QUOTE)) uluna"
fi
```

---

## Troubleshooting

### Problema 1: "insufficient funds" - Gas Needed Muito Alto

**Sintoma:** O IGP está pedindo bilhões de LUNC para uma transferência.

**Causa:** O `exchange_rate` está configurado com escala errada (10^18 em vez de 10^10).

**Solução:**
1. Verificar o `exchange_rate` atual:
```bash
terrad query wasm contract-state smart ${IGP_ORACLE} \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":97}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

2. Recalcular o `exchange_rate` correto (ver seção [Cálculo do Exchange Rate](#cálculo-do-exchange-rate))

3. Atualizar o IGP Oracle com o valor correto

### Problema 2: Gas Payment Não Cobre o Custo Real

**Sintoma:** Transferências falham porque o gas payment é insuficiente.

**Causa:** 
- `gas_limit` muito baixo (ex: 100k em vez de 200k)
- `gas_price` desatualizado
- `exchange_rate` não inclui margem suficiente

**Solução:**
1. Verificar o gas real usado em uma transferência warp route
2. Aumentar o `default_gas_usage` ou `gas_for_domain` para 200k-300k
3. Atualizar `gas_price` com valor atual da chain de destino
4. Adicionar margem de 20-30% no cálculo do `exchange_rate`

### Problema 3: Exchange Rate Desatualizado

**Sintoma:** O custo calculado não reflete os preços atuais de mercado.

**Causa:** Preços de LUNC ou BNB mudaram significativamente.

**Solução:**
1. Obter preços atuais:
   - LUNC: https://www.coingecko.com/pt-br/moedas/terra-luna
   - BNB: https://www.coingecko.com/pt-br/moedas/bnb
2. Recalcular `exchange_rate` com novos preços
3. Atualizar IGP Oracle

### Problema 4: Gas Price Desatualizado

**Sintoma:** O `gas_price` não reflete o preço real na chain de destino.

**Causa:** O gas price na chain de destino mudou.

**Solução:**
1. Verificar gas price atual na chain de destino:
```bash
# BSC Testnet
curl -X POST https://bsc-testnet.publicnode.com \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":1}' | \
  jq -r '.result' | python3 -c "import sys; value = int(sys.stdin.read(), 16); print(f'{value} wei ({value/1e9:.2f} Gwei)')"
```

2. Atualizar `gas_price` no IGP Oracle

### Problema 5: "unauthorized" ao Tentar Atualizar

**Sintoma:** Erro ao executar `set_remote_gas_data_configs`.

**Causa:** Você não é o owner do contrato IGP Oracle.

**Solução:**
1. Verificar o owner:
```bash
terrad query wasm contract-state smart ${IGP_ORACLE} \
  '{"ownable":{"get_owner":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

2. Se o owner for o módulo de governança, usar proposta de governança
3. Se você for o owner, verificar se está usando a key correta

---

## Exemplos Práticos

### Exemplo 1: Configurar IGP para BSC Testnet (Primeira Vez)

```bash
# 1. Verificar gas price atual no BSC Testnet
GAS_PRICE_GWEI=$(curl -s -X POST https://bsc-testnet.publicnode.com \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":1}' | \
  jq -r '.result' | python3 -c "import sys; print(int(sys.stdin.read(), 16) / 1e9)")

echo "Gas Price atual no BSC Testnet: $GAS_PRICE_GWEI Gwei"

# 2. Calcular exchange_rate (assumindo gas_limit 200k, 20% margem)
# ... usar script de cálculo ...

# 3. Atualizar IGP Oracle
EXCHANGE_RATE="177534"
GAS_PRICE_WEI="100000000"

terrad tx wasm execute terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg \
  "{\"set_remote_gas_data_configs\":{\"configs\":[{\"remote_domain\":97,\"token_exchange_rate\":\"${EXCHANGE_RATE}\",\"gas_price\":\"${GAS_PRICE_WEI}\"}]}}" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes

# 4. Atualizar default_gas_usage
terrad tx wasm execute terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9 \
  '{"set_default_gas":{"gas":"200000"}}' \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes

# 5. Verificar configuração
terrad query wasm contract-state smart terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":97}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

### Exemplo 2: Atualizar Exchange Rate Após Mudança de Preços

```bash
# 1. Obter preços atuais (exemplo)
LUNC_PRICE_USD=0.00006069
BNB_PRICE_USD=897.88

# 2. Recalcular exchange_rate
# ... usar script de cálculo ...

# 3. Atualizar IGP Oracle
NEW_EXCHANGE_RATE="177534"

terrad tx wasm execute terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg \
  "{\"set_remote_gas_data_configs\":{\"configs\":[{\"remote_domain\":97,\"token_exchange_rate\":\"${NEW_EXCHANGE_RATE}\",\"gas_price\":\"100000000\"}]}}" \
  --from hypelane-val-testnet \
  --keyring-backend file \
  --chain-id "rebel-2" \
  --node "https://rpc.luncblaze.com:443" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes
```

### Exemplo 3: Verificar Quote Antes de Transferência

```bash
# Calcular quanto gas será necessário antes de fazer uma transferência
GAS_AMOUNT="200000"  # Gas estimado para a transferência

QUOTE=$(terrad query wasm contract-state smart terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9 \
  "{\"igp\":{\"quote_gas_payment\":{\"dest_domain\":97,\"gas_amount\":\"${GAS_AMOUNT}\"}}}" \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 \
  --output json | jq -r '.data.gas_needed')

QUOTE_LUNC=$(echo "scale=2; $QUOTE / 1000000" | bc)

echo "Gas necessário para transferência: $QUOTE uluna ($QUOTE_LUNC LUNC)"
echo "Certifique-se de ter saldo suficiente!"
```

---

## Referências

- [Documentação Oficial do Hyperlane - Interchain Gas Payments](https://docs.hyperlane.xyz/docs/protocol/core/interchain-gas-payment#interchaingaspaymasters)
- [Documentação de Hooks - Interchain Gas](https://docs.hyperlane.xyz/docs/reference/hooks/interchain-gas)
- [Hyperlane Explorer](https://explorer.hyperlane.xyz/)

---

## Valores Recomendados para BSC Testnet

Com base em testes e cálculos, os valores recomendados são:

- **Exchange Rate**: `177534` (gas_limit 200k, 20% margem, 0.1 Gwei)
- **Gas Price**: `100000000` (0.1 Gwei)
- **Default Gas Usage**: `200000` (200k gas)
- **Custo Esperado**: `~355 LUNC` por transferência warp route

**Nota:** Estes valores devem ser atualizados periodicamente conforme:
- Preços de mercado mudam (LUNC/BNB)
- Gas price na BSC Testnet muda
- Gas real usado em transferências muda

---

**Última atualização:** Dezembro 2025

