# 🎯 Próximos Passos - Criar IGP para Sepolia

## ✅ Status Atual

- ✅ Chave privada configurada
- ✅ Endereço derivado: `0x8804770d6a346210c0Fd011258FDf3Ab0a5bb0d0`
- ✅ Warp Route identificado: `0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4`
- ✅ Scripts preparados e atualizados
- ❌ **PENDENTE**: Obter ETH de Sepolia

## 🚨 AÇÃO NECESSÁRIA

### Passo 1: Obter ETH de Sepolia

Seu endereço atual está **sem saldo**. Você precisa de ETH testnet para pagar o gas das transações.

**Seu Endereço:**
```
0x8804770d6a346210c0Fd011258FDf3Ab0a5bb0d0
```

**Faucets Recomendados:**

1. **Alchemy** (Mais Rápido)
   - URL: https://www.alchemy.com/faucets/ethereum-sepolia
   - Quantidade: ~0.5 ETH
   - Tempo: ~2 minutos

2. **QuickNode**
   - URL: https://faucet.quicknode.com/ethereum/sepolia
   - Quantidade: ~0.1 ETH
   - Tempo: ~5 minutos

3. **Sepolia PoW Faucet** (Sem cadastro)
   - URL: https://sepolia-faucet.pk910.de/
   - Quantidade: Variável (mineração)
   - Tempo: ~10-30 minutos

### Passo 2: Verificar Saldo

Após solicitar ETH no faucet, verifique o saldo:

```bash
cast balance 0x8804770d6a346210c0Fd011258FDf3Ab0a5bb0d0 \
  --rpc-url https://1rpc.io/sepolia
```

Ou convertido para ETH:

```bash
cast balance 0x8804770d6a346210c0Fd011258FDf3Ab0a5bb0d0 \
  --rpc-url https://1rpc.io/sepolia \
  --ether
```

### Passo 3: Executar o Script

Assim que tiver saldo (recomendado: pelo menos 0.1 ETH), execute:

```bash
cd /home/lunc/cw-hyperlane
./executar-igp-sepolia.sh
```

## 📋 Configurações que Serão Usadas

### Valores Calculados (03/02/2026)
- **LUNC Price**: $0.00003674
- **ETH Price**: $2,292.94
- **Target Cost**: ~$0.50 por transferência

### Parâmetros do IGP
```
Terra Domain: 1325
Sepolia Domain: 11155111

Terra Exchange Rate: 28,444,000,000,000,000
Terra Gas Price: 38,325,000,000 (38.325 uluna)
Gas Overhead: 200,000
```

### Contratos
```
Warp Route (Sepolia): 0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4
Owner/Deployer: 0x8804770d6a346210c0Fd011258FDf3Ab0a5bb0d0
```

## 🔄 O Que o Script Vai Fazer

1. ✅ Verificar saldo da conta
2. ✅ Verificar ownership do Warp Route
3. 🚀 Deploy StorageGasOracle contract
4. ⚙️ Configurar gas data para Terra Classic (domain 1325)
5. 🚀 Deploy InterchainGasPaymaster contract
6. ⚙️ Inicializar IGP com owner e beneficiary
7. ⚙️ Configurar destination gas configs
8. 🔗 Associar IGP ao Warp Route (via setHook)
9. 💾 Salvar endereços deployados em arquivo JSON

## 💰 Estimativa de Gas

- **StorageGasOracle deploy**: ~500k gas (~0.005 ETH)
- **IGP deploy**: ~1M gas (~0.01 ETH)
- **Configurações**: ~200k gas (~0.002 ETH)
- **Associação ao Warp**: ~100k gas (~0.001 ETH)

**Total estimado**: ~0.02 ETH

Com margem de segurança: **recomendado ter pelo menos 0.1 ETH**

## ⚠️ Verificações Importantes

### Antes de Executar

- [ ] Tenho pelo menos 0.1 ETH em Sepolia
- [ ] Confirmei que sou owner do Warp Route (ou tenho permissão)
- [ ] Revisei os valores de exchange_rate e gas_price
- [ ] Entendo que isso é testnet (não há risco real)

### Após Executar

- [ ] Verifique os endereços deployados no output
- [ ] Salve os endereços em local seguro
- [ ] Teste com uma transferência pequena
- [ ] Monitore os custos reais

## 🆘 Troubleshooting

### "Saldo insuficiente"
→ Obtenha mais ETH dos faucets

### "Você não é o owner do Warp Route"
→ Verifique se está usando a conta correta
→ Entre em contato com o owner do Warp Route

### "Bytecode não encontrado"
→ Os bytecodes estão hardcoded no script TypeScript
→ Se falhar, será necessário compilar os contratos Hyperlane

### "RPC falhou"
→ O script tentará múltiplos RPCs automaticamente
→ Você pode especificar um RPC customizado via variável de ambiente

## 📞 Comandos Úteis

### Ver saldo atual
```bash
cast balance 0x8804770d6a346210c0Fd011258FDf3Ab0a5bb0d0 \
  --rpc-url https://1rpc.io/sepolia --ether
```

### Verificar owner do Warp Route
```bash
cast call 0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4 \
  "owner()(address)" \
  --rpc-url https://1rpc.io/sepolia
```

### Verificar hook atual do Warp Route
```bash
cast call 0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4 \
  "hook()(address)" \
  --rpc-url https://1rpc.io/sepolia
```

### Recalcular valores
```bash
python3 script/calcular-exchange-rate.py \
  --lunc 0.00003674 \
  --eth 2292.94 \
  --chain sepolia \
  --gas-price-uluna 38.325
```

## 🎉 Após Sucesso

Os endereços dos contratos deployados serão salvos em:
```
deployments/sepolia-igp.json
```

Conteúdo esperado:
```json
{
  "storageGasOracle": "0x...",
  "interchainGasPaymaster": "0x...",
  "warpRoute": "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4",
  "owner": "0x8804770d6a346210c0Fd011258FDf3Ab0a5bb0d0",
  "beneficiary": "0x8804770d6a346210c0Fd011258FDf3Ab0a5bb0d0",
  "configuration": {
    "terraDomain": 1325,
    "terraGasPrice": "38325000000",
    "terraExchangeRate": "28444000000000000",
    "gasOverhead": "200000"
  },
  "deployedAt": "2026-02-03T...",
  "network": "sepolia"
}
```

---

**Próximo passo**: Obtenha ETH de Sepolia usando um dos faucets acima! 💰
