# Valores IGP Atualizados para Sepolia

## 📅 Data: 03/02/2026

## 💰 Preços de Mercado
- **LUNC**: $0.00003674
- **ETH**: $2,292.94
- **Gas Price Desejado**: 38.325 uluna

## 🧮 Cálculos

### Exchange Rate (Terra → Sepolia)
```
Fórmula: (LUNC_USD / ETH_USD) × 10^18

Cálculo:
  0.00003674 / 2292.94 = 1.602309... × 10^-8
  1.602309 × 10^-8 × 10^18 = 16,023,096,984
```

**Resultado: `16023096984`**

### Gas Price
```
38.325 uluna × 10^9 = 38,325,000,000 (nano-uluna)
```

**Resultado: `38325000000`**

## 📝 Configurações para Scripts

### Para Bash Script:
```bash
export TERRA_EXCHANGE_RATE="16023096984"
export TERRA_GAS_PRICE="38325000000"
export GAS_OVERHEAD="200000"
export WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
```

### Para TypeScript:
```typescript
const TERRA_EXCHANGE_RATE = "16023096984";
const TERRA_GAS_PRICE = "38325000000";
const GAS_OVERHEAD = "200000";
```

### Para config-testnet.yaml:
```yaml
hooks:
  default:
    type: igp
    configs:
      11155111:  # Sepolia domain
        exchange_rate: 16023096984
        gas_price: 38325000000
```

## 🚀 Como Executar

### Opção 1: Script TypeScript (Recomendado)
```bash
export SEPOLIA_PRIVATE_KEY="0xsua_private_key"
export WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
export TERRA_EXCHANGE_RATE="16023096984"
export TERRA_GAS_PRICE="38325000000"

npx tsx script/criar-igp-e-associar-warp-sepolia.ts
```

### Opção 2: Verificar Cálculo Primeiro
```bash
# Use o script Python para validar os cálculos
python3 script/calcular-exchange-rate.py \
  --lunc 0.00003674 \
  --eth 2292.94 \
  --chain sepolia \
  --gas-price-uluna 38.325
```

## ⚠️ Notas Importantes

1. **Valor Anterior**: O config-testnet.yaml atual tem `exchange_rate: 1805936462255558` para BSC
2. **Novo Valor**: Com preços atualizados, deveria ser aproximadamente `16023096984`
3. **Grande Diferença**: O novo valor é ~112x menor que o anterior

### Por que a diferença?

O valor anterior pode ter sido calculado com:
- Preços desatualizados de mercado
- Fórmula diferente ou escala diferente
- Margem de segurança muito alta

### Recomendação

Antes de deployar, verifique:

1. ✅ Se você é o owner do Warp Route
2. ✅ Se tem ETH suficiente para gas
3. ✅ Teste primeiro com valores pequenos
4. ✅ Monitore os custos reais após deploy

## 💡 Custo Estimado por Transferência

Com os novos valores, uma transferência que consome 200,000 gas custaria:

```
Custo = (200000 × 38325000000 × 16023096984) / 10^18
Custo ≈ 122,817,038 wei
Custo ≈ 0.000000122817 ETH
Custo ≈ $0.0003 USD
```

**Isso é praticamente zero!** ⚠️

### Ajuste Sugerido

Se quiser cobrar um custo razoável (ex: $0.50 por transferência), você precisa ajustar:

```bash
# Para ~$0.50 por transferência de 200k gas:
# Custo desejado em ETH = 0.50 / 2292.94 = 0.000218 ETH = 218,000,000,000,000 wei

# Resolver para exchange_rate:
# 200000 × 38325000000 × exchange_rate = 218000000000000 × 10^18
# exchange_rate = (218000000000000 × 10^18) / (200000 × 38325000000)
# exchange_rate ≈ 28,444,000,000,000,000 (2.8 × 10^16)
```

Valores ajustados para ~$0.50 por transferência:
```bash
export TERRA_EXCHANGE_RATE="28444000000000000"  # ~$0.50/tx
export TERRA_GAS_PRICE="38325000000"
```

## 🎯 Próximos Passos

1. **Decida o custo desejado** por transferência (em USD)
2. **Ajuste o exchange_rate** conforme necessário
3. **Execute o script** de criação do IGP
4. **Teste** com uma transferência pequena
5. **Monitore** e ajuste conforme necessário

## 📞 Suporte

Use o script Python para recalcular valores sempre que os preços mudarem:

```bash
python3 script/calcular-exchange-rate.py --help
```
