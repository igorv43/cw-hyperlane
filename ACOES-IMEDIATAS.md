# 🎯 Ações Imediatas - Correção do Erro IGP

## ✅ Status Atual

- ❌ **Erro confirmado**: "destination not supported"
- 🔍 **Causa identificada**: IGP com hookType = 2 (deveria ser 4)
- ✅ **Solução pronta**: TerraClassicIGPStandalone.sol
- ⏳ **Aguardando**: Deploy manual no Remix IDE

---

## 🚀 O Que Fazer Agora (3 Passos Simples)

### Passo 1: Ver o Código do Contrato

```bash
cat /home/lunc/cw-hyperlane/TerraClassicIGPStandalone.sol
```

**Copie TODO o código que aparece** (Ctrl+C)

---

### Passo 2: Deploy no Remix IDE

#### 2.1. Abra o Remix
- **Link**: https://remix.ethereum.org

#### 2.2. Crie o Arquivo
1. Clique em **"File explorer"** (ícone de pasta à esquerda)
2. Clique com botão direito em `contracts`
3. Selecione **"New File"**
4. Nome: `TerraClassicIGPStandalone.sol`

#### 2.3. Cole o Código
- Cole o código que você copiou no Passo 1
- Salve (Ctrl+S)

#### 2.4. Compile
1. Clique no ícone **"Solidity Compiler"** (3º ícone da esquerda)
2. Configuração:
   - **Compiler**: `0.8.22` ou superior
   - **Optimization**: ✅ Enabled (200 runs)
3. Clique em **"Compile TerraClassicIGPStandalone.sol"**
4. Aguarde o ✅ verde

#### 2.5. Deploy
1. Clique no ícone **"Deploy & Run Transactions"** (4º ícone)
2. Configure:
   - **Environment**: `Injected Provider - MetaMask`
   - **Account**: Sua conta MetaMask (deve ter ETH Sepolia)
   - **Contract**: `TerraClassicIGPStandalone`

3. **Preencha os parâmetros** (copie e cole EXATAMENTE):

```
_GASORACLE
0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c

_GASOVERHEAD
200000

_BENEFICIARY
0x133fD7F7094DBd17b576907d052a5aCBd48dB526
```

4. Clique em **"Deploy"**
5. Confirme no MetaMask
6. Aguarde confirmação (~30 segundos)
7. **COPIE O ENDEREÇO DO CONTRATO DEPLOYADO**

---

### Passo 3: Associar ao Warp Route

No terminal Linux:

```bash
cd /home/lunc/cw-hyperlane

# Cole o endereço do IGP que você deployou
export IGP_ADDRESS="<COLE_AQUI>"

# Execute o script de associação
./deploy-igp-final.sh
```

**O script irá**:
- ✅ Verificar hookType = 4
- ✅ Associar ao Warp Route
- ✅ Testar funcionamento
- ✅ Confirmar correção

---

## 🧪 Verificar Correção

Após executar os passos acima:

```bash
./testar-warp-sepolia.sh
```

**Resultado esperado**: ✅ SUCESSO! Sem erros!

---

## 🎉 Teste Final

1. Acesse o front-end de transferência Hyperlane
2. Selecione: **Sepolia → Terra Classic**
3. Digite o valor
4. **O erro NÃO deve mais aparecer**
5. O custo será calculado (~$0.50 USD)

---

## 💰 Custos

- **Deploy do IGP**: ~$3-5 USD (Sepolia ETH)
- **Associação (setHook)**: ~$1-2 USD (Sepolia ETH)
- **Total**: ~$5-7 USD

---

## ⏱️ Tempo Estimado

- **Leitura e preparação**: 2 minutos
- **Deploy no Remix**: 3 minutos
- **Associação**: 2 minutos
- **Testes**: 1 minuto
- **Total**: ~8-10 minutos

---

## 🆘 Precisa de Ajuda?

### Não tenho ETH Sepolia
- Faucet 1: https://sepoliafaucet.com/
- Faucet 2: https://www.alchemy.com/faucets/ethereum-sepolia

### Erro no MetaMask: "Wrong network"
- Mude para Sepolia no MetaMask (topo do app)

### Compilação falhou no Remix
- Verifique: Compiler version 0.8.22 ou superior
- Verifique: Optimization habilitada
- Verifique: Código colado completo

### Deploy não confirmou
- Aguarde 1-2 minutos
- Verifique no Etherscan: https://sepolia.etherscan.io

---

## 📚 Documentação Completa

Se quiser entender melhor:

```bash
# Guia visual completo
cat DEPLOY-AGORA.md

# Visão executiva
cat RESUMO-EXECUTIVO-SOLUCAO.md

# Análise técnica
cat SOLUCAO-FINAL-IGP.md

# Índice de tudo
cat INDICE-COMPLETO.md
```

---

## ✅ Checklist Rápido

- [ ] Código copiado
- [ ] Remix IDE aberto
- [ ] Arquivo criado no Remix
- [ ] Código colado
- [ ] Compilado com sucesso
- [ ] MetaMask conectado (Sepolia)
- [ ] Parâmetros preenchidos
- [ ] Deploy confirmado
- [ ] Endereço copiado
- [ ] Script executado
- [ ] Teste passou
- [ ] Front-end funcionando

---

## 🎯 Resultado Final

**Antes**:
- ❌ Erro: "destination not supported"
- ❌ Transferências não funcionam

**Depois**:
- ✅ Sem erros
- ✅ Transferências Sepolia → Terra Classic funcionando
- ✅ Custo calculado corretamente (~$0.50 USD)

---

**Pronto para começar?**

```bash
# Passo 1
cat TerraClassicIGPStandalone.sol

# Passo 2
# (Deploy no Remix - manual)

# Passo 3
export IGP_ADDRESS="<seu_endereço>"
./deploy-igp-final.sh
```

---

**Data**: 2026-02-03  
**Status**: ⏳ Aguardando deploy manual  
**Tempo**: 8-10 minutos  
**Custo**: ~$5-7 USD
