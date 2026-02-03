# Cálculo do Exchange Rate e Gas Price para IGP

Este documento explica como calcular corretamente o **Token Exchange Rate** e **Gas Price** para configuração do InterchainGasPaymaster (IGP) entre Terra Classic e Sepolia.

## 📊 Valores Atuais (03/02/2026)

### Preços de Mercado
- **LUNC**: $0.00003674
- **ETH**: $2,292.94

### Configuração Desejada
- **Gas Price Terra Classic**: 38.325 uluna

## 🧮 Fórmulas

### 1. Token Exchange Rate (para EVM chains como Sepolia)

A fórmula oficial do Hyperlane para EVM chains é:

```
exchange_rate = (LUNC_price_USD / ETH_price_USD) × 10^18
```

**Por que 10^18?**
- ETH usa 18 decimais (1 ETH = 10^18 wei)
- O exchange rate precisa converter entre as unidades base das duas chains

### 2. Cálculo Passo a Passo

```bash
# Preços atuais
LUNC_USD = 0.00003674
ETH_USD = 2292.94

# Razão de preço
price_ratio = LUNC_USD / ETH_USD
price_ratio = 0.00003674 / 2292.94
price_ratio = 0.00000001602066...

# Aplicar escala de 10^18
exchange_rate = price_ratio × 10^18
exchange_rate = 0.00000001602066 × 1000000000000000000
exchange_rate = 16,020,660,000,000
```

### 3. Gas Price

O gas price representa o custo em uluna (microLuna) na Terra Classic:

```bash
# Valor desejado: 38.325 uluna
# Conversão para unidade base (nano-uluna)
gas_price = 38.325 × 10^9
gas_price = 38,325,000,000
```

## 💡 Entendendo a Fórmula de Custo do IGP

Quando um usuário faz uma transferência de Sepolia para Terra Classic, o IGP calcula:

```
custo_em_wei = (gas_usado × gas_price × exchange_rate) / 10^18
```

**Exemplo prático:**
```bash
# Parâmetros
gas_usado = 200,000 (típico para transferência)
gas_price = 38,325,000,000 (38.325 uluna)
exchange_rate = 16,020,660,000,000

# Cálculo
custo_em_wei = (200000 × 38325000000 × 16020660000000) / 10^18
custo_em_wei = 122,798,262,000,000,000,000,000,000 / 10^18
custo_em_wei = 122,798,262 wei
custo_em_eth = 0.000122798262 ETH

# Valor em USD
custo_em_usd = 0.000122798262 × 2292.94
custo_em_usd ≈ $0.28 USD
```

## 🔄 Comparação: Cosmos para Cosmos vs EVM para Cosmos

### Para Cosmos → Cosmos (ex: Terra → Solana)
```
TOKEN_EXCHANGE_RATE_SCALE = 10^10
exchange_rate = (gas_needed × 10^10) / (gas_amount × gas_price)
```

### Para EVM → Cosmos (ex: Sepolia → Terra)
```
TOKEN_EXCHANGE_RATE_SCALE = 10^18  (ETH decimals)
exchange_rate = (source_token_price / dest_token_price) × 10^18
```

## 📝 Valores Configurados

### config-testnet.yaml (Cosmos-side)
```yaml
hooks:
  default:
    type: igp
    configs:
      11155111:  # Sepolia domain
        exchange_rate: 16020660000000
        gas_price: 38325000000  # 38.325 uluna
```

### Sepolia IGP (EVM-side)
```typescript
// StorageGasOracle configuration
{
  remoteDomain: 1325,  // Terra Classic
  tokenExchangeRate: "16020660000000",
  gasPrice: "38325000000"  // 38.325 uluna
}
```

## 🔧 Atualização de Valores

Para atualizar quando os preços mudarem:

### 1. Obter Preços Atuais
```bash
# CoinGecko API (exemplo)
curl "https://api.coingecko.com/api/v3/simple/price?ids=terra-luna,ethereum&vs_currencies=usd"
```

### 2. Recalcular Exchange Rate
```bash
# Use a fórmula:
LUNC_USD=0.00003674  # Atualizar com preço atual
ETH_USD=2292.94      # Atualizar com preço atual

# Calcular com bc (bash calculator)
echo "scale=0; ($LUNC_USD / $ETH_USD) * 1000000000000000000 / 1" | bc
```

### 3. Atualizar Configurações
- Para Terra Classic → Sepolia: atualizar `config-testnet.yaml`
- Para Sepolia → Terra Classic: re-executar script de deploy ou atualizar via governance

## ⚠️ Notas Importantes

1. **Exchange Rate Inverso**: 
   - De Sepolia→Terra: use `(LUNC/ETH) × 10^18`
   - De Terra→Sepolia: use `(ETH/LUNC) × 10^10`

2. **Gas Price Units**:
   - Terra Classic: uluna (1 uluna = 10^-6 LUNC)
   - Sepolia: wei (1 wei = 10^-18 ETH)

3. **Atualização Periódica**:
   - Monitore os preços das moedas
   - Atualize exchange rates quando houver mudanças significativas (>10%)
   - Use governance proposals para atualizar em produção

4. **Overhead de Gas**:
   - `GAS_OVERHEAD = 200,000` é um buffer para cobrir custos extras
   - Ajuste baseado em dados reais de consumo de gas

## 🔍 Verificação

Após deploy/atualização, verifique:

```bash
# Verificar configuração no Gas Oracle (Sepolia)
cast call "STORAGE_GAS_ORACLE_ADDRESS" \
  "getExchangeRateAndGasPrice(uint32)(uint128,uint128)" \
  1325 \
  --rpc-url https://1rpc.io/sepolia

# Verificar configuração no IGP Oracle (Terra Classic)
terrad query wasm contract-state smart \
  terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":11155111}}}' \
  --node https://rpc.luncblaze.com:443
```

## 📚 Referências

- [Hyperlane IGP Documentation](https://docs.hyperlane.xyz/docs/reference/hooks/interchain-gas-paymaster)
- [StorageGasOracle Contract](https://github.com/hyperlane-xyz/hyperlane-monorepo/blob/main/solidity/contracts/hooks/igp/StorageGasOracle.sol)
- [CoinGecko API](https://www.coingecko.com/en/api)
