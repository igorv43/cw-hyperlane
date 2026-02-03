# 🎯 Deploy do IGP Terra Classic - Guia Rápido

## 📋 Contexto

Você está vendo este erro ao tentar enviar tokens de Sepolia para Terra Classic:

```
❌ Error: destination not supported
```

**Causa:** O hook configurado no Warp Route tem `hookType = 2` (AGGREGATION) mas deveria ser `4` (INTERCHAIN_GAS_PAYMASTER).

**Solução:** Deploy de um novo IGP correto e associação ao Warp Route.

---

## ⚡ SOLUÇÃO RÁPIDA (2 minutos)

```bash
# 1. Defina sua chave privada
export PRIVATE_KEY_LUNC='0xSUA_CHAVE_PRIVADA'

# 2. Execute o deploy e configuração automáticos
./deploy-e-associar-igp.sh
```

**Pronto!** O script faz tudo automaticamente:
- ✅ Compila o contrato IGP
- ✅ Faz deploy na Sepolia
- ✅ Configura para Terra Classic (domain 1325)
- ✅ Associa ao Warp Route
- ✅ Verifica se está funcionando

---

## 🖥️ ALTERNATIVA: Deploy Manual no Remix

Se preferir uma interface visual:

### 1. Ver o guia completo
```bash
cat SOLUCAO-FINAL.md
```

### 2. Copiar o contrato
```bash
cat TerraClassicIGPStandalone.sol
```

### 3. Deploy no Remix

1. Abra: https://remix.ethereum.org
2. Crie arquivo `TerraClassicIGP.sol` e cole o código
3. Compile (Solidity 0.8.13+)
4. Deploy com parâmetros:
   ```
   _gasOracle:   0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c
   _gasOverhead: 200000
   _beneficiary: 0x133fD7F7094DBd17b576907d052a5aCBd48dB526
   ```
5. Copie o endereço do contrato deployado

### 4. Configurar e associar
```bash
export IGP_ADDRESS='0xENDERECO_DO_REMIX'
export PRIVATE_KEY_LUNC='0xSUA_CHAVE_PRIVADA'
./configurar-e-associar-igp.sh
```

---

## 🧪 Testar

Após o deploy:

1. Acesse: https://warp.hyperlane.xyz
2. Conecte sua carteira
3. Selecione: **Sepolia → Terra Classic**
4. Tente enviar tokens

**Resultado esperado:**
```
✅ Erro "destination not supported" CORRIGIDO
✅ Você verá o custo estimado da transferência
✅ Poderá prosseguir com o envio
```

---

## 📚 Documentação Completa

- **SOLUCAO-FINAL.md** - Guia completo passo a passo
- **TerraClassicIGPStandalone.sol** - Código do contrato
- **deploy-e-associar-igp.sh** - Script automático completo
- **configurar-e-associar-igp.sh** - Script de configuração pós-deploy

---

## 💡 Informações Técnicas

### Endereços Importantes
```
Warp Route:       0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4
Oracle:           0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c
Beneficiary:      0x133fD7F7094DBd17b576907d052a5aCBd48dB526
```

### Configuração Terra Classic
```
Domain:           1325
Exchange Rate:    142244393 (escala 1e10)
Gas Price:        38325000000 WEI
Gas Overhead:     200000
```

### Características do IGP
```
Hook Type:        4 (INTERCHAIN_GAS_PAYMASTER)
Solidity:         ^0.8.13
Interface:        IPostDispatchHook (Hyperlane oficial)
```

---

## ❓ Problemas Comuns

### "PRIVATE_KEY_LUNC não definida"
```bash
export PRIVATE_KEY_LUNC='0xSUA_CHAVE_PRIVADA'
```

### "Insufficient funds"
- Obtenha ETH na Sepolia: https://sepoliafaucet.com

### "Hook Type incorreto"
- Certifique-se de usar o contrato `TerraClassicIGPStandalone.sol`
- Verifique se o deploy foi bem-sucedido

---

## 🎉 Sucesso!

Após seguir os passos, você verá:

```
╔═══════════════════════════════════════════════════════════════════════╗
║                  ✅ CONFIGURAÇÃO CONCLUÍDA! ✅                        ║
╚═══════════════════════════════════════════════════════════════════════╝

📋 RESUMO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✅ IGP: 0x... (seu endereço)
  ✅ Warp Route: 0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4
  ✅ Hook Type: 4 (correto)
  ✅ Terra Classic configurado (domain 1325)

✅ Transferências Sepolia → Terra Classic FUNCIONANDO!
```

---

**Última Atualização:** 2026-02-03  
**Status:** ✅ Pronto para deploy
