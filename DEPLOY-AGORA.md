# 🚀 FAÇA O DEPLOY AGORA - Guia Rápido Visual

## ✅ ERRO CONFIRMADO

O teste detectou o erro:
```
❌ ERRO: 'destination not supported'
Hook Type: Errado (não é 4)
```

## 🎯 SOLUÇÃO EM 5 MINUTOS

### Passo 1: Abra o Remix IDE

🔗 **Clique aqui**: https://remix.ethereum.org

### Passo 2: Crie o arquivo

1. Clique em **"File explorer"** (ícone de pasta)
2. Clique com botão direito na pasta `contracts`
3. Selecione **"New File"**
4. Nome do arquivo: `TerraClassicIGPStandalone.sol`

### Passo 3: Cole o código

```bash
# No terminal Linux, execute:
cat /home/lunc/cw-hyperlane/TerraClassicIGPStandalone.sol
```

**Copie TODA a saída** e cole no Remix no arquivo `TerraClassicIGPStandalone.sol`

### Passo 4: Compile

1. Clique no ícone **"Solidity Compiler"** (terceiro ícone da esquerda)
2. Configurações:
   - **Compiler**: `0.8.22` ou superior
   - **EVM Version**: `default`
   - **Optimization**: ✅ Enabled (200 runs)
3. Clique em **"Compile TerraClassicIGPStandalone.sol"**
4. Aguarde compilação (deve aparecer ✅ verde)

### Passo 5: Deploy

1. Clique no ícone **"Deploy & Run Transactions"** (quarto ícone da esquerda)
2. Configurações:
   - **Environment**: `Injected Provider - MetaMask`
   - **Account**: Sua conta MetaMask (deve ter ETH Sepolia)
   - **Contract**: `TerraClassicIGPStandalone - TerraClassicIGPStandalone.sol`

3. **Preencha os parâmetros do constructor** (cole exatamente como está):

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

### Passo 6: Copie o endereço

1. Após deploy, expanda o contrato no painel "Deployed Contracts"
2. **Copie o endereço** (exemplo: `0x1234...5678`)
3. Cole aqui no terminal:

```bash
cd /home/lunc/cw-hyperlane

export IGP_ADDRESS="<COLE_O_ENDEREÇO_AQUI>"

# Exemplo:
# export IGP_ADDRESS="0x1234567890abcdef1234567890abcdef12345678"
```

### Passo 7: Execute o script de associação

```bash
# Associar ao Warp Route
./deploy-igp-final.sh
```

Quando perguntado, **cole o endereço do IGP** que você copiou.

### Passo 8: Teste novamente

```bash
# Verificar se o erro foi corrigido
./testar-warp-sepolia.sh
```

**Resultado esperado**: ✅ SUCESSO! Sem erros!

## 📋 Checklist de Verificação

Marque conforme completa:

- [ ] Remix IDE aberto
- [ ] Arquivo `TerraClassicIGPStandalone.sol` criado
- [ ] Código colado no Remix
- [ ] Contrato compilado (✅ verde)
- [ ] MetaMask conectado no Sepolia
- [ ] Parâmetros preenchidos corretamente
- [ ] Deploy feito com sucesso
- [ ] Endereço do contrato copiado
- [ ] `deploy-igp-final.sh` executado
- [ ] Associação concluída
- [ ] Teste passou (✅ SUCESSO)

## 🎯 Resultado Final

Após seguir estes passos:

1. ✅ Erro `destination not supported` será CORRIGIDO
2. ✅ Transferências Sepolia → Terra Classic funcionarão
3. ✅ Custo: ~$0.50 USD por transferência

## 🆘 Problemas?

### Erro no MetaMask: "Insufficient funds"

**Solução**: Você precisa de ETH Sepolia. Pegue no faucet:
- https://sepoliafaucet.com/
- https://www.alchemy.com/faucets/ethereum-sepolia

### Erro: "Wrong network"

**Solução**: Mude para Sepolia no MetaMask:
1. Clique na rede atual (topo do MetaMask)
2. Selecione "Sepolia test network"

### Erro: "Compilation failed"

**Solução**: Verifique:
1. Compiler version: 0.8.22 ou superior
2. Código colado completo (sem cortar)
3. Optimization habilitada

### Deploy não aparece

**Solução**: Aguarde 1-2 minutos. Verifique no Etherscan:
```
https://sepolia.etherscan.io/address/<SEU_ENDEREÇO_METAMASK>
```

## 📞 Próximo Passo Após Deploy

Execute no terminal:

```bash
cd /home/lunc/cw-hyperlane

# Cole o endereço do IGP que você deployou
export IGP_ADDRESS="<ENDEREÇO_AQUI>"

# Execute o script de associação
./deploy-igp-final.sh
```

O script irá:
1. ✅ Verificar hookType = 4
2. ✅ Associar ao Warp Route
3. ✅ Testar funcionamento
4. ✅ Confirmar correção do erro

---

## 🎉 Depois de Tudo Pronto

Teste no front-end:
1. Acesse o front-end de transferência
2. Selecione: Sepolia → Terra Classic
3. Digite o valor
4. **O erro NÃO deve aparecer mais!**
5. O custo será calculado corretamente

---

**Tempo estimado**: 5-10 minutos  
**Custo de gas**: ~$2-5 USD em Sepolia ETH  
**Dificuldade**: ⭐⭐☆☆☆ (Fácil)
