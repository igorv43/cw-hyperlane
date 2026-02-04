# 🚀 DEPLOY TERRA CLASSIC IGP - REMIX IDE

## ✅ VALORES CORRETOS (Escala 1e10)

Após análise minuciosa dos contratos oficiais do Hyperlane em `~/hyperlane-monorepo/solidity/contracts`, descobrimos que:

- **TOKEN_EXCHANGE_RATE_SCALE = 1e10** (NÃO 1e18!) 
- Fonte: `InterchainGasPaymaster.sol` linha 51

## 📋 VALORES CALCULADOS CORRETAMENTE

```
Token Exchange Rate: 142,244,393    (escala 1e10 ✅)
Gas Price:           38,325,000,000 WEI (38.325 Gwei)
Gas Overhead:        200,000
Terra Domain:        1325

Custo estimado: ~$0.50 USD por transferência (400k gas total)
```

## 🎯 PASSO A PASSO

### 1️⃣ Abrir Remix IDE

Acesse: https://remix.ethereum.org

### 2️⃣ Criar arquivo TerraClassicIGP.sol

Copie o conteúdo de `/home/lunc/cw-hyperlane/TerraClassicIGP.sol`

**Ou copie diretamente:**

```bash
cat /home/lunc/cw-hyperlane/TerraClassicIGP.sol
```

### 3️⃣ Compilar

- Compiler: Solidity 0.8.13 ou superior
- Optimization: Enabled (200 runs)
- Click "Compile TerraClassicIGP.sol"

### 4️⃣ Deploy

**Environment:** Injected Provider - MetaMask  
**Network:** Sepolia  
**Contract:** TerraClassicIGP

**Constructor Parameters:**

```
_gasOracle:    0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c
_gasOverhead:  200000
_beneficiary:  0x133fD7F7094DBd17b576907d052a5aCBd48dB526
```

### 5️⃣ Verificar o Deploy

Após o deploy bem-sucedido, copie o endereço do contrato (`IGP_ADDRESS`).

### 6️⃣ Associar ao Warp Route

Execute:

```bash
export IGP_ADDRESS="<endereço_do_igp_deployado>"
export SEPOLIA_PRIVATE_KEY="0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5"

cast send 0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4 \
  "setHook(address)" \
  "$IGP_ADDRESS" \
  --rpc-url https://1rpc.io/sepolia \
  --private-key "$SEPOLIA_PRIVATE_KEY"
```

### 7️⃣ Verificar Configuração

```bash
# Verificar hook do Warp Route
cast call 0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4 \
  "hook()(address)" \
  --rpc-url https://1rpc.io/sepolia

# Deve retornar o endereço do IGP deployado
```

## 🔍 POR QUE A ESCALA MUDOU?

**Antes (ERRADO):**
- Exchange Rate: 28,444,000,000,000,000 (escala 1e18)
- Erro: "destination not supported"

**Agora (CORRETO):**
- Exchange Rate: 142,244,393 (escala 1e10)
- Baseado em: `InterchainGasPaymaster.sol` oficial

**Fonte da verdade:**
```solidity
// ~/hyperlane-monorepo/solidity/contracts/hooks/igp/InterchainGasPaymaster.sol
uint256 internal constant TOKEN_EXCHANGE_RATE_SCALE = 1e10; // Linha 51
```

## 📚 ANÁLISE DOS CONTRATOS OFICIAIS

Arquivos analisados:
- `/home/lunc/hyperlane-monorepo/solidity/contracts/hooks/igp/InterchainGasPaymaster.sol`
- `/home/lunc/hyperlane-monorepo/solidity/contracts/hooks/igp/StorageGasOracle.sol`
- `/home/lunc/hyperlane-monorepo/solidity/contracts/libs/Message.sol`
- `/home/lunc/hyperlane-monorepo/solidity/contracts/hooks/libs/StandardHookMetadata.sol`
- `/home/lunc/hyperlane-monorepo/solidity/contracts/interfaces/IGasOracle.sol`

**Descobertas importantes:**

1. **Parsing do Destination** (Message.sol linha 115-119):
   ```solidity
   function destination(bytes calldata _message) internal pure returns (uint32) {
       return uint32(bytes4(_message[DESTINATION_OFFSET:RECIPIENT_OFFSET]));
   }
   // DESTINATION_OFFSET = 41, RECIPIENT_OFFSET = 45
   ```

2. **Extração do Gas Limit** (StandardHookMetadata.sol linha 72-80):
   ```solidity
   function gasLimit(bytes calldata _metadata, uint256 _default) internal pure returns (uint256) {
       if (_metadata.length < GAS_LIMIT_OFFSET + 32) return _default;
       return uint256(bytes32(_metadata[GAS_LIMIT_OFFSET:GAS_LIMIT_OFFSET + 32]));
   }
   // GAS_LIMIT_OFFSET = 34
   ```

3. **Cálculo do Custo** (InterchainGasPaymaster.sol linha 206-213):
   ```solidity
   function quoteGasPayment(uint32 _destinationDomain, uint256 _gasLimit) 
       public view virtual override returns (uint256) {
       (uint128 _tokenExchangeRate, uint128 _gasPrice) = 
           getExchangeRateAndGasPrice(_destinationDomain);
       uint256 _destinationGasCost = _gasLimit * uint256(_gasPrice);
       return (_destinationGasCost * _tokenExchangeRate) / TOKEN_EXCHANGE_RATE_SCALE;
   }
   ```

## ✨ RESULTADO ESPERADO

Após o deploy e associação corretos:

✅ O erro "destination not supported" deve desaparecer  
✅ As transferências de Sepolia para Terra Classic devem funcionar  
✅ O custo será aproximadamente $0.50 USD por transferência

## 🆘 SUPORTE

Se houver problemas:

1. Verifique se o MetaMask está conectado à Sepolia
2. Verifique se há ETH suficiente para gas (~0.01 ETH)
3. Confira se os valores do constructor estão corretos
4. Verifique logs no console do Remix

---

**Data:** 2026-02-03  
**Baseado em:** Hyperlane V3 (monorepo oficial)  
**TOKEN_EXCHANGE_RATE_SCALE:** 1e10 ✅
