# 🚀 Deploy CustomIGP Compatível com Hyperlane

## 🎯 Objetivo

Deployar um IGP personalizado que:
- ✅ É compatível com a interface IPostDispatchHook do Hyperlane
- ✅ Usa seu Oracle configurado para Terra Classic
- ✅ Pode ser associado ao Warp Route via `setHook()`

---

## 📋 Informações do Sistema

### Contratos Oficiais Hyperlane (Sepolia)
- **Mailbox**: `0xfFAEF09B3cd11D9b20d1a19bECca54EEC2884766`
- **IGP Oficial**: `0x6f2756380FD49228ae25Aa7F2817993cB74Ecc56`
- **Validator Announce**: `0xE6105C59480a1B7DD3E4f28153aFdbE12F4CfCD9`
- **Merkle Tree Hook**: `0x4917a9746A7B6E0A57159cCb7F5a6744247f2d0d`
- **ISM (alterado)**: `0x81c12361c6f7024E6f67f7284B361Ed59003cFB1`

### Seus Contratos
- **Oracle**: `0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c` ✅
- **Warp Route**: `0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4` ✅
- **Owner**: `0x133fD7F7094DBd17b576907d052a5aCBd48dB526` ✅

### Configuração do Oracle (Terra Classic)
- **Domain**: 1325
- **Exchange Rate**: `28,444,000,000,000,000`
- **Gas Price**: `38,325,000,000` (38.325 uluna)

---

## 🔧 Passo a Passo no Remix IDE

### 1️⃣ Abrir Remix (30 segundos)

1. Acesse: **https://remix.ethereum.org**
2. Conecte MetaMask
3. Selecione rede: **Sepolia**
4. Verifique saldo: Mínimo 0.01 ETH

### 2️⃣ Criar Arquivo do Contrato (1 min)

1. No painel esquerdo, clique em **"contracts"**
2. Clique com botão direito → **"New File"**
3. Nome: `CustomIGP.sol`
4. Cole o código do arquivo `CustomIGP.sol`

**O código já está pronto em**: `/home/lunc/cw-hyperlane/CustomIGP.sol`

```bash
# Visualizar o código:
cat /home/lunc/cw-hyperlane/CustomIGP.sol
```

### 3️⃣ Compilar (30 segundos)

1. Clique no ícone **"Solidity compiler"** (3º ícone, painel esquerdo)
2. **Compiler version**: Selecione `0.8.13` ou superior (ex: `0.8.23`)
3. Marque ✅ **"Enable optimization"**
4. **Runs**: `200` (padrão)
5. Clique em **"Compile CustomIGP.sol"**
6. Aguarde: ✓ **compiled successfully**

### 4️⃣ Deploy do Contrato (1 min)

1. Clique no ícone **"Deploy & run transactions"** (4º ícone)
2. **Environment**: Selecione `Injected Provider - MetaMask`
3. **Account**: Deve mostrar `0x133fD...dB526`
4. **Gas limit**: `3000000`
5. **Contract**: Selecione `CustomIGP - CustomIGP.sol`

**Parâmetros do Constructor**:
- **_BENEFICIARY**: `0x133fD7F7094DBd17b576907d052a5aCBd48dB526`

6. Clique em **"transact"**
7. Confirme no MetaMask
8. Aguarde confirmação (~15-30 segundos)
9. **✅ COPIE O ENDEREÇO DO CONTRATO DEPLOYADO**

### 5️⃣ Configurar IGP para Terra Classic (1 min)

No Remix, no contrato deployado (seção "Deployed Contracts"):

1. Expanda o contrato `CustomIGP`
2. Encontre a função **`setDestinationGasConfigs`**
3. Preencha os arrays (formato JSON):

```json
destinations: [1325]
gasOracles: ["0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c"]
gasOverheads: [200000]
```

**Formato para o Remix** (cole nos campos):
- **destinations**: `[1325]`
- **gasOracles**: `["0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c"]`
- **gasOverheads**: `[200000]`

4. Clique em **"transact"**
5. Confirme no MetaMask
6. Aguarde confirmação

### 6️⃣ Verificar Configuração (30 segundos)

No Remix, expanda o contrato e teste:

1. Função **`destinationConfigs`**
2. Digite: `1325`
3. Clique em **"call"**
4. Resultado esperado:
   - `gasOracle`: `0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c`
   - `gasOverhead`: `200000`

---

## 🔗 Associar IGP ao Warp Route

### Método 1: Via Terminal (Recomendado)

```bash
# Substitua [IGP_ADDRESS] pelo endereço do passo 4
export IGP_ADDRESS="0xSEU_IGP_DEPLOYADO_AQUI"

cast send "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4" \
  "setHook(address)" \
  "$IGP_ADDRESS" \
  --private-key "0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5" \
  --rpc-url "https://1rpc.io/sepolia" \
  --legacy
```

### Método 2: Via Remix IDE

1. No Remix, vá em **"At Address"**
2. Cole o endereço do Warp Route: `0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4`
3. Clique em **"At Address"**
4. Expanda o contrato do Warp Route
5. Encontre a função **`setHook`**
6. Digite o endereço do seu IGP
7. Clique em **"transact"**
8. Confirme no MetaMask

---

## ✅ Verificação Completa

Execute o script de verificação:

```bash
export IGP_ADDRESS="0xSEU_IGP_AQUI"
./verificar-igp-sepolia.sh
```

Ou manualmente:

### 1. Verificar Hook do Warp Route
```bash
cast call "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4" \
  "hook()(address)" \
  --rpc-url "https://1rpc.io/sepolia"
```
**Esperado**: Seu endereço IGP

### 2. Verificar Configuração do IGP
```bash
cast call "$IGP_ADDRESS" \
  "destinationConfigs(uint32)((address,uint96))" \
  1325 \
  --rpc-url "https://1rpc.io/sepolia"
```
**Esperado**: Oracle + Overhead

### 3. Testar Quote de Dispatch
```bash
# Criar uma mensagem dummy para teste
MESSAGE="0x0000052d" # Domain 1325 em hex

cast call "$IGP_ADDRESS" \
  "quoteDispatch(bytes,bytes)(uint256)" \
  "0x" \
  "$MESSAGE" \
  --rpc-url "https://1rpc.io/sepolia"
```
**Esperado**: Um número (custo em wei)

---

## 📊 Resumo do Deploy

Após completar, você terá:

| Item | Status |
|------|--------|
| **CustomIGP** | ✅ Deployado |
| **Configurado para Terra Classic** | ✅ Domain 1325 |
| **Oracle conectado** | ✅ `0x7113...eC9c` |
| **Gas Overhead** | ✅ 200000 |
| **Hook do Warp Route** | ✅ Apontando para CustomIGP |
| **Owner** | ✅ Você (`0x133f...dB526`) |

---

## 🎉 Pronto!

Agora você pode fazer transferências **Sepolia → Terra Classic** sem erros!

### Testar Transferência

1. Acesse seu frontend do Warp Route
2. Tente enviar tokens de Sepolia para Terra Classic
3. O erro "Configured IGP doesn't support domain 1325" **NÃO** deve mais aparecer
4. A transferência deve calcular o custo de gas corretamente

---

## 🐛 Troubleshooting

### Erro: "MailboxClient: invalid contract setting"
- **Causa**: IGP não implementa interface IPostDispatchHook corretamente
- **Solução**: Use o `CustomIGP.sol` (já tem todas as interfaces necessárias)

### Erro: "destination not supported"
- **Causa**: Domain 1325 não foi configurado
- **Solução**: Execute novamente o passo 5 (setDestinationGasConfigs)

### Erro: "oracle call failed"
- **Causa**: Oracle não está configurado ou endereço incorreto
- **Solução**: Verifique se Oracle `0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c` está deployado

### MetaMask: "Transaction may fail"
- **Causa**: Pode ser estimativa de gas conservadora
- **Solução**: Verifique os parâmetros e confirme (se tiver certeza)

---

## 📝 Diferenças entre CustomIGP e SimpleIGP

| Feature | SimpleIGP | CustomIGP |
|---------|-----------|-----------|
| **Interface Hyperlane** | ❌ Básica | ✅ Completa (IPostDispatchHook) |
| **postDispatch()** | ❌ | ✅ |
| **quoteDispatch()** | ❌ | ✅ |
| **hookType()** | ❌ | ✅ |
| **supportsMetadata()** | ❌ | ✅ |
| **Compatível com Warp Route** | ⚠️ Parcial | ✅ Total |

**Conclusão**: Use `CustomIGP.sol` para garantir compatibilidade total com o Hyperlane!

---

## 📚 Arquivos de Referência

- `/home/lunc/cw-hyperlane/CustomIGP.sol` - Código do contrato
- `/home/lunc/cw-hyperlane/verificar-igp-sepolia.sh` - Script de verificação
- `/home/lunc/cw-hyperlane/CONFIGURAR-WARP-LUNC-SEPOLIA.md` - Documentação completa

---

**Boa sorte com o deploy! 🚀**

**Tempo estimado total**: ~5 minutos ⏱️
