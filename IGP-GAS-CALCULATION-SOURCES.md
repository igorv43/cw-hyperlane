# Fontes e Cálculo da Taxa de Gas do IGP

Este documento explica as fontes usadas para calcular a taxa de gas e como verificar se os valores estão corretos.

## Fórmula do IGP

A fórmula usada pelo IGP para calcular o custo é:

```
cost_uluna = (gas_amount × gas_price × token_exchange_rate) / 10^18
```

Onde:
- `gas_amount`: Quantidade de gas necessária na chain de destino (BSC)
- `gas_price`: Preço do gas na chain de destino em wei
- `token_exchange_rate`: Taxa de câmbio entre uluna e o token da chain de destino (BNB)
- `10^18`: Fator de escala para o exchange_rate

## Fontes dos Valores

### 1. Gas Amount (100,000)

**Fonte:** Configuração do IGP (`default_gas_usage`)

```bash
# Verificar o default_gas do IGP
IGP="terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9"

terrad query wasm contract-state smart ${IGP} \
  '{"igp":{"default_gas":{}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

**Valor atual:** 100,000 gas units

**Nota:** Este é o valor padrão configurado. O gas real usado pode variar dependendo da complexidade da mensagem.

### 2. Gas Price (50,000,000 wei = 0.05 Gwei)

**Fonte:** BSC Testnet gas price atual

**Verificação:**
1. **BSCScan Testnet:** https://testnet.bscscan.com/
   - Verificar "Gas Tracker" para o preço atual
   - BSC reduziu o gas price para 0.05 Gwei em outubro de 2025

2. **Via Web3/ethers.js:**
```javascript
const provider = new ethers.providers.JsonRpcProvider('https://data-seed-prebsc-1-s1.binance.org:8545');
const gasPrice = await provider.getGasPrice();
console.log('Gas Price:', gasPrice.toString(), 'wei');
console.log('Gas Price:', gasPrice.div(1e9).toString(), 'Gwei');
```

3. **Conversão:**
   - 0.05 Gwei = 0.05 × 10^9 = 50,000,000 wei ✅

**Valor usado:** 50,000,000 wei (0.05 Gwei)

### 3. Token Exchange Rate

**Fonte:** Cálculo baseado em preços de mercado

**Fórmula:**
```
exchange_rate = (cost_uluna × 10^18) / (gas_amount × gas_price)
```

**Cálculo passo a passo:**

1. **Custo em BNB:**
   ```
   gas_cost_bnb = (gas_amount × gas_price) / 10^18
   gas_cost_bnb = (100000 × 50000000) / 10^18
   gas_cost_bnb = 0.000005 BNB
   ```

2. **Custo em USD:**
   ```
   gas_cost_usd = gas_cost_bnb × bnb_price_usd
   gas_cost_usd = 0.000005 × 897.88
   gas_cost_usd = $0.004489
   ```

3. **Custo em LUNC:**
   ```
   gas_cost_lunc = gas_cost_usd / lunc_price_usd
   gas_cost_lunc = 0.004489 / 0.00006069
   gas_cost_lunc = 73.97 LUNC
   ```

4. **Custo em uluna:**
   ```
   gas_cost_uluna = gas_cost_lunc × 10^6
   gas_cost_uluna = 73.97 × 10^6
   gas_cost_uluna = 73,972,647 uluna
   ```

5. **Exchange Rate:**
   ```
   exchange_rate = (gas_cost_uluna × 10^18) / (gas_amount × gas_price)
   exchange_rate = (73,972,647 × 10^18) / (100000 × 50000000)
   exchange_rate = 14,794,529,576,536
   ```

## Verificação dos Valores Reais

### 1. Verificar Gas Price Real no BSC Testnet

```bash
# Usando curl para consultar BSC Testnet RPC
curl -X POST https://data-seed-prebsc-1-s1.binance.org:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":1}' | jq -r '.result' | xargs printf "%d\n" | awk '{print $1/1e9 " Gwei"}'
```

### 2. Verificar Preços de Mercado

**BNB Price:**
- CoinGecko: https://www.coingecko.com/pt-br/moedas/bnb
- CoinMarketCap: https://coinmarketcap.com/pt-br/currencies/bnb/

**LUNC Price:**
- CoinGecko: https://www.coingecko.com/pt-br/moedas/terra-luna
- CoinMarketCap: https://coinmarketcap.com/pt-br/currencies/terra-luna-classic/

### 3. Verificar Cálculo do IGP

```bash
IGP="terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9"

# Verificar quote_gas_payment
terrad query wasm contract-state smart ${IGP} \
  '{"igp":{"quote_gas_payment":{"dest_domain":97,"gas_amount":"100000"}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

**Expected output:**
```
data:
  gas_needed: "73972647"  # ~74 LUNC
```

### 4. Verificar Configuração do Oracle

```bash
IGP_ORACLE="terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"

terrad query wasm contract-state smart ${IGP_ORACLE} \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":97}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443
```

**Expected output:**
```json
{
  "token_exchange_rate": "14794529576536",
  "gas_price": "50000000"
}
```

## Possíveis Problemas

### 1. Gas Price Incorreto

Se o gas price real no BSC Testnet for diferente de 0.05 Gwei:

```bash
# Exemplo: Se o gas price real for 0.1 Gwei (100,000,000 wei)
# Recalcular exchange_rate:
NEW_GAS_PRICE=100000000  # 0.1 Gwei
NEW_EXCHANGE_RATE=$((73972647 * 10**18 / (100000 * NEW_GAS_PRICE)))
echo "Novo exchange_rate: $NEW_EXCHANGE_RATE"
```

### 2. Gas Amount Incorreto

Se o gas real usado for diferente de 100,000:

```bash
# Exemplo: Se o gas real for 150,000
NEW_GAS_AMOUNT=150000
NEW_EXCHANGE_RATE=$((73972647 * 10**18 / (NEW_GAS_AMOUNT * 50000000)))
echo "Novo exchange_rate: $NEW_EXCHANGE_RATE"
```

### 3. Preços de Mercado Desatualizados

Se os preços do BNB ou LUNC mudaram:

```bash
# Atualizar preços
BNB_PRICE_USD=897.88  # Preço atual do BNB
LUNC_PRICE_USD=0.00006069  # Preço atual do LUNC

# Recalcular
GAS_COST_BNB=0.000005
GAS_COST_USD=$(echo "$GAS_COST_BNB * $BNB_PRICE_USD" | bc)
GAS_COST_LUNC=$(echo "$GAS_COST_USD / $LUNC_PRICE_USD" | bc)
GAS_COST_ULUNA=$(echo "$GAS_COST_LUNC * 1000000" | bc)
NEW_EXCHANGE_RATE=$(echo "$GAS_COST_ULUNA * 10^18 / (100000 * 50000000)" | bc)
echo "Novo exchange_rate: $NEW_EXCHANGE_RATE"
```

## Script de Verificação Completa

```bash
#!/bin/bash

echo "=== Verificando Valores Reais ==="
echo ""

# 1. Verificar gas price no BSC Testnet
echo "1. Gas Price no BSC Testnet:"
GAS_PRICE_WEI=$(curl -s -X POST https://data-seed-prebsc-1-s1.binance.org:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":1}' | jq -r '.result' | xargs printf "%d\n")
GAS_PRICE_GWEI=$(echo "scale=2; $GAS_PRICE_WEI / 1000000000" | bc)
echo "   Gas Price: $GAS_PRICE_WEI wei ($GAS_PRICE_GWEI Gwei)"
echo ""

# 2. Verificar configuração do IGP Oracle
echo "2. Configuração do IGP Oracle:"
IGP_ORACLE="terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"
terrad query wasm contract-state smart ${IGP_ORACLE} \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":97}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 --output json | jq -r '.data'
echo ""

# 3. Verificar quote do IGP
echo "3. Quote Gas Payment do IGP:"
IGP="terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9"
terrad query wasm contract-state smart ${IGP} \
  '{"igp":{"quote_gas_payment":{"dest_domain":97,"gas_amount":"100000"}}}' \
  --chain-id rebel-2 \
  --node https://rpc.luncblaze.com:443 --output json | jq -r '.data.gas_needed'
echo ""

# 4. Calcular custo esperado
echo "4. Cálculo Esperado:"
GAS_AMOUNT=100000
GAS_PRICE=50000000
EXCHANGE_RATE=14794529576536
COST_ULUNA=$((GAS_AMOUNT * GAS_PRICE * EXCHANGE_RATE / 10**18))
echo "   Custo esperado: $COST_ULUNA uluna ($(echo "scale=6; $COST_ULUNA / 1000000" | bc) LUNC)"
```

## Conclusão

Os valores atuais estão baseados em:
- ✅ Gas Price: 0.05 Gwei (confirmado pela redução da BSC em outubro de 2025)
- ✅ Gas Amount: 100,000 (configuração padrão do IGP)
- ✅ Exchange Rate: Calculado baseado em preços de mercado atuais (BNB @ $897.88, LUNC @ $0.00006069)

**Se você achar que está errado, verifique:**
1. O gas price real no BSC Testnet (pode variar)
2. O gas amount real necessário (pode ser diferente de 100,000)
3. Os preços de mercado atuais (BNB e LUNC)

