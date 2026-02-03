# 🎯 Deploy do IGP Terra Classic - Guia Correto

## ✅ CORREÇÃO IMPORTANTE

O IGP é deployado na **SEPOLIA** (chain de origem), não na Terra Classic!

```
❌ ERRADO: PRIVATE_KEY_LUNC
✅ CORRETO: PRIVATE_KEY_SEPOLIA
```

---

## 💡 Por quê Sepolia?

```
SEPOLIA (Origem)          →→→          TERRA CLASSIC (Destino)
                                       
• Deploy do IGP ✅                     • Recebe mensagens
• Warp Route ✅                        • Executa ações  
• Calcula custos ✅
• Cobra taxas ✅
```

O IGP é deployado na chain de **origem** para:
- Calcular os custos de envio para o destino
- Cobrar as taxas em ETH da Sepolia
- Pagar os relayers que entregarão a mensagem

---

## 🚀 DEPLOY RÁPIDO (2 comandos)

```bash
# 1. Defina sua chave privada da SEPOLIA
export PRIVATE_KEY_SEPOLIA='0xSUA_CHAVE_PRIVADA_DA_SEPOLIA'

# 2. Execute o deploy automático
./deploy-e-associar-igp.sh
```

**Pronto!** O script faz tudo:
- ✅ Compila o contrato
- ✅ Deploy na Sepolia
- ✅ Configura para Terra Classic
- ✅ Associa ao Warp Route
- ✅ Verifica se funcionou

---

## 🖥️ Deploy Manual no Remix (Passo a Passo)

### 1. Copiar o contrato

```bash
cat TerraClassicIGPOfficial.sol
```

Copie **TUDO** (Ctrl+A, Ctrl+C)

### 2. Deploy no Remix

1. **Abra:** https://remix.ethereum.org

2. **Crie arquivo:** `TerraClassicIGP.sol`

3. **Cole** o código

4. **Compile:**
   - Compiler: `0.8.13+`
   - Optimization: habilitado
   - Clique em "Compile"

5. **Deploy:**
   - Environment: `Injected Provider - MetaMask`
   - Network: **Sepolia** (importante!)
   - Constructor:
     ```
     _beneficiary: 0x133fD7F7094DBd17b576907d052a5aCBd48dB526
     ```
   - Clique em "Deploy"
   - **Confirme a transação no MetaMask**

6. **COPIE** o endereço do contrato deployado

### 3. Configurar o IGP

```bash
# Defina as variáveis
export IGP_ADDRESS='0xENDERECO_QUE_VOCE_COPIOU'
export PRIVATE_KEY_SEPOLIA='0xSUA_CHAVE_PRIVADA_DA_SEPOLIA'

# Configurar gas data para Terra Classic
cast send $IGP_ADDRESS \
  "setRemoteGasData(uint32,uint128,uint128)" \
  1325 142244393 38325000000 \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $PRIVATE_KEY_SEPOLIA \
  --legacy

# Configurar gas overhead
cast send $IGP_ADDRESS \
  "setGasOverhead(uint32,uint96)" \
  1325 200000 \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $PRIVATE_KEY_SEPOLIA \
  --legacy
```

### 4. Associar ao Warp Route

```bash
# Associar o IGP ao Warp Route
cast send 0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4 \
  "setHook(address)" \
  $IGP_ADDRESS \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $PRIVATE_KEY_SEPOLIA \
  --legacy
```

### 5. Verificar

```bash
# Verificar se o hook foi associado
cast call 0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4 \
  "hook()(address)" \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com

# Verificar hookType (deve ser 4)
cast call $IGP_ADDRESS \
  "hookType()(uint8)" \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com

# Verificar configuração para Terra Classic
cast call $IGP_ADDRESS \
  "getExchangeRateAndGasPrice(uint32)(uint128,uint128)" \
  1325 \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com
```

**Resultado esperado:**
```
Hook configurado: 0x... (seu IGP)
Hook Type: 4 ✅
Exchange Rate: 142244393 ✅
Gas Price: 38325000000 ✅
```

---

## 🧪 Testar a Correção

1. Acesse: **https://warp.hyperlane.xyz**
2. Conecte sua carteira (MetaMask na Sepolia)
3. Selecione:
   - **De:** Sepolia
   - **Para:** Terra Classic
4. Digite um valor e clique para enviar

**Resultado esperado:**
```
✅ Custo estimado mostrado (~$0.50 USD)
✅ SEM erro "destination not supported"
✅ Você pode prosseguir com o envio
```

---

## 📊 Informações Técnicas

### Endereços Importantes

```
Warp Route Sepolia:  0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4
Beneficiary:         0x133fD7F7094DBd17b576907d052a5aCBd48dB526
```

### Configuração Terra Classic

```
Domain:              1325
Exchange Rate:       142244393  (escala 1e10)
Gas Price:           38325000000 WEI (38.325 uluna)
Gas Overhead:        200000
Hook Type:           4 (INTERCHAIN_GAS_PAYMASTER)
```

### Novo Contrato

**TerraClassicIGPOfficial.sol**
- Baseado no `InterchainGasPaymaster.sol` oficial do Hyperlane
- `hookType()` retorna `4` ✅
- `TOKEN_EXCHANGE_RATE_SCALE = 1e10` ✅
- Parsing de mensagens e metadata idêntico ao oficial ✅
- Suporte a refund de overpayment ✅

---

## 💰 Custos

```
Deploy do IGP:        ~$5-7 USD (Sepolia ETH)
Configuração (2 TXs): ~$2-4 USD (Sepolia ETH)  
Associação ao Warp:   ~$1-2 USD (Sepolia ETH)
──────────────────────────────────────────────
Total:                ~$8-13 USD

Por transferência:    ~$0.50 USD
```

**Onde obter Sepolia ETH:**
- https://sepoliafaucet.com
- https://faucet.quicknode.com/ethereum/sepolia

---

## ❓ Troubleshooting

### "PRIVATE_KEY_SEPOLIA não definida"
```bash
export PRIVATE_KEY_SEPOLIA='0xSUA_CHAVE_PRIVADA'
```

### "Insufficient funds"
- Você precisa de ETH na **Sepolia** (não LUNC!)
- Use um faucet (links acima)

### "Not owner"
- Verifique se está usando a chave privada correta
- Você deve ser o owner do Warp Route

### "destination not configured"
- Execute os comandos `setRemoteGasData` e `setGasOverhead`
- Aguarde a confirmação das transações

---

## 📚 Arquivos Disponíveis

- **TerraClassicIGPOfficial.sol** ⭐ - Contrato oficial para deploy
- **deploy-e-associar-igp.sh** - Script automático completo
- **configurar-e-associar-igp.sh** - Script de configuração
- **SOLUCAO-FINAL.md** - Documentação completa

---

## 🎉 Sucesso Esperado

Após seguir os passos:

```
╔═══════════════════════════════════════════════════════════════════════╗
║                  ✅ CONFIGURAÇÃO CONCLUÍDA! ✅                        ║
╚═══════════════════════════════════════════════════════════════════════╝

📋 RESUMO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✅ IGP deployado na SEPOLIA
  ✅ Configurado para Terra Classic (domain 1325)
  ✅ Associado ao Warp Route
  ✅ Hook Type: 4 (correto)
  ✅ Erro "destination not supported" CORRIGIDO
  
✅ Transferências Sepolia → Terra Classic FUNCIONANDO!
```

---

**Data:** 2026-02-03  
**Versão:** 2.0 (Corrigida)  
**Status:** ✅ Pronto para produção

**Importante:** Sempre use `PRIVATE_KEY_SEPOLIA` pois o deploy é na Sepolia!
