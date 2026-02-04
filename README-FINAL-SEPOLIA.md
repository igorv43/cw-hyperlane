# 🚀 Deploy do IGP Terra Classic na SEPOLIA - GUIA FINAL

## ✅ RESULTADO DO DEPLOY BEM-SUCEDIDO (SEPOLIA)

```
Status: ✅ FUNCIONANDO

IGP Deployado:        0xe0f137448c96b5f17759bce44c020db6bdc8e261
Hook Type:            4 (INTERCHAIN_GAS_PAYMASTER) ✅
Warp Route Sepolia:   0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4 ⭐
Terra Classic Domain: 1325
```

**O erro "destination not supported" foi CORRIGIDO com sucesso!** ✅

---

## 🎯 DEPLOY RÁPIDO (1 COMANDO)

```bash
# 1. Definir chave privada da SEPOLIA (não LUNC!)
export PRIVATE_KEY_SEPOLIA='0xSUA_CHAVE_PRIVADA_DA_SEPOLIA'

# 2. Executar script completo
chmod +x deploy-igp-completo-sepolia.sh
./deploy-igp-completo-sepolia.sh
```

**Pronto!** O script faz TUDO automaticamente em 2-3 minutos.

---

## 📚 DOCUMENTAÇÃO

### Documento Principal
📖 **[DOCUMENTACAO-COMPLETA-IGP-SEPOLIA.md](DOCUMENTACAO-COMPLETA-IGP-SEPOLIA.md)**

Este documento contém:
- ✅ Script automático completo
- ✅ Comandos individuais que funcionaram
- ✅ Todos os parâmetros e configurações
- ✅ Troubleshooting completo
- ✅ Como testar

### Outros Documentos Úteis
- 📄 **[SUCESSO-FINAL-SEPOLIA.md](SUCESSO-FINAL-SEPOLIA.md)** - Relatório do deploy bem-sucedido
- 📄 **[INDICE-ARQUIVOS-SEPOLIA.md](INDICE-ARQUIVOS-SEPOLIA.md)** - Índice de todos os arquivos
- 📄 **[DEPLOY-REMIX-CORRETO-SEPOLIA.md](DEPLOY-REMIX-CORRETO-SEPOLIA.md)** - Se preferir Remix IDE

---

## 🔧 ARQUIVOS PRINCIPAIS

### Script Automático
```bash
deploy-igp-completo-sepolia.sh          # ⭐ Script completo (RECOMENDADO)
```

### Contrato
```solidity
TerraClassicIGP-Sepolia.sol             # Contrato usado no deploy
```

### Endereços Deployados
```
IGP_ADDRESS-SEPOLIA.txt                 # Endereço do IGP: 0xe0f137...
ENDERECO-CORRETO-WARP.txt               # Warp Route: 0x224a44...
```

---

## ⚙️ CONFIGURAÇÃO USADA

```javascript
// Warp Route Sepolia (CORRETO)
const WARP_ROUTE = "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4";

// Oracle (já deployado)
const ORACLE = "0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c";

// Terra Classic
const TERRA_CLASSIC_DOMAIN = 1325;
const EXCHANGE_RATE = 142244393;  // Escala 1e10
const GAS_PRICE = 38325000000;    // 38.325 uluna
const GAS_OVERHEAD = 200000;

// Hook Type
const IGP_HOOK_TYPE = 4;  // INTERCHAIN_GAS_PAYMASTER
```

---

## 🔗 TRANSAÇÕES DO DEPLOY BEM-SUCEDIDO

```
Deploy:       https://sepolia.etherscan.io/tx/0x2b71ee751194e529ce59cd2ae7dde14f62e38fcb9674e76f47262e47d308e364
Configuração: https://sepolia.etherscan.io/tx/0xdd317b318fe6f6918f40283dfbe81c4c0b008c22f7581f021b485893af0ce515
Associação:   https://sepolia.etherscan.io/tx/0x456af412df875f425feddad7cc4ec1df0a7ef287ea0dd03d41cecfc63d786d8d
```

---

## 🧪 COMO TESTAR

1. **Acesse:** https://warp.hyperlane.xyz

2. **Conecte sua carteira:**
   - MetaMask
   - Rede: Sepolia

3. **Configure:**
   - DE: Sepolia
   - PARA: Terra Classic
   - Valor: qualquer quantidade

4. **Verifique:**
   - ✅ Custo estimado aparece
   - ✅ SEM erro "destination not supported"
   - ✅ Pode prosseguir com o envio

---

## 📊 COMANDOS INDIVIDUAIS (ALTERNATIVA)

Se o script automático não funcionar, veja os comandos individuais em:
**[DOCUMENTACAO-COMPLETA-IGP-SEPOLIA.md](DOCUMENTACAO-COMPLETA-IGP-SEPOLIA.md#-opção-2-comandos-individuais-que-funcionaram)**

Todos os comandos foram testados e funcionaram! ✅

---

## ❓ TROUBLESHOOTING

### Problema: Script não funciona
**Solução:** Use os comandos individuais na documentação completa.

### Problema: "PRIVATE_KEY_SEPOLIA não definida"
**Solução:**
```bash
export PRIVATE_KEY_SEPOLIA='0xSUA_CHAVE_PRIVADA'
```

### Problema: "Insufficient funds"
**Solução:** Obtenha Sepolia ETH em:
- https://sepoliafaucet.com
- https://faucet.quicknode.com/ethereum/sepolia

### Problema: Erro no teste do site
**Aguarde:** Pode levar alguns minutos para propagação na blockchain.

---

## 💰 CUSTOS

```
Deploy + Configuração + Associação:  ~$7-11 USD (Sepolia ETH)
Por transferência:                   ~$0.50 USD
```

---

## ⚠️ IMPORTANTE

### Chave Privada Correta
```
❌ ERRADO: PRIVATE_KEY_LUNC
✅ CORRETO: PRIVATE_KEY_SEPOLIA
```

O IGP é deployado na **SEPOLIA** (origem), não na Terra Classic!

### Warp Route Correto
```
✅ CORRETO: 0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4
```

Use este endereço - foi verificado e está funcionando.

---

## 📁 ESTRUTURA DE ARQUIVOS

```
deploy-igp-completo-sepolia.sh           ⭐ Script automático
DOCUMENTACAO-COMPLETA-IGP-SEPOLIA.md     ⭐ Documentação completa
README-FINAL-SEPOLIA.md                  ⭐ Este arquivo
SUCESSO-FINAL-SEPOLIA.md                    Relatório de sucesso
INDICE-ARQUIVOS-SEPOLIA.md                  Índice de todos os arquivos
TerraClassicIGP-Sepolia.sol                 Código do contrato
IGP_ADDRESS-SEPOLIA.txt                     Endereço do IGP deployado
```

---

## ✅ CHECKLIST

Após o deploy, verifique:

- [x] IGP deployado: `0xe0f137448c96b5f17759bce44c020db6bdc8e261`
- [x] Hook Type: 4 ✅
- [x] Associado ao Warp: `0x224a...` ✅
- [x] Configurado para domain 1325 ✅
- [x] Exchange Rate: 142244393 ✅
- [x] Gas Price: 38325000000 ✅
- [x] Teste no site: FUNCIONANDO ✅

---

## 🎉 SUCESSO!

O deploy foi executado com sucesso e está **FUNCIONANDO**!

Você pode agora fazer transferências de tokens de **Sepolia** para **Terra Classic** via Hyperlane Warp Routes sem nenhum erro.

---

## 📞 SUPORTE

Se precisar de ajuda:
1. Leia: **[DOCUMENTACAO-COMPLETA-IGP-SEPOLIA.md](DOCUMENTACAO-COMPLETA-IGP-SEPOLIA.md)**
2. Verifique: **[SUCESSO-FINAL-SEPOLIA.md](SUCESSO-FINAL-SEPOLIA.md)**
3. Consulte: **[INDICE-ARQUIVOS-SEPOLIA.md](INDICE-ARQUIVOS-SEPOLIA.md)**

---

**Última atualização:** 2026-02-03  
**Versão:** 1.0 Final  
**Status:** ✅ Testado e Funcionando  
**Deploy executado por:** IA Assistant com sucesso
