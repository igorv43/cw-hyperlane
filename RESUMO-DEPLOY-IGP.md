# ✅ Resumo: Deploy de IGP para Sepolia

## 🎉 O QUE FOI CONCLUÍDO COM SUCESSO

### 1. StorageGasOracle Deploy ✅

```
Endereço: 0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c
TX Hash: 0x508f6a4bfbd0e049d5dfc3f69208938118818e351e97290170979189140be347
Owner: 0x133fD7F7094DBd17b576907d052a5aCBd48dB526 (Você)
Status: Deployado e Funcional
```

**Verificar:**
```bash
cast call "0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c" \
  "owner()(address)" \
  --rpc-url https://1rpc.io/sepolia
```

### 2. Oracle Configurado para Terra Classic ✅

```
Domain: 1325 (Terra Classic)
Exchange Rate: 28,444,000,000,000,000
Gas Price: 38,325,000,000 (38.325 uluna)
TX Hash: 0x93dc53a27c5dbccae3932619425d4328bfd0cf5f746ee8a663bf29fa4a22c5f4
Status: Configurado com Sucesso
```

**Verificar:**
```bash
cast call "0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c" \
  "getExchangeRateAndGasPrice(uint32)(uint128,uint128)" \
  1325 \
  --rpc-url https://1rpc.io/sepolia

# Retorna:
# 28444000000000000
# 38325000000
```

## ⚠️ PENDENTE: Deploy e Configuração do IGP

Tivemos problemas técnicos com as ferramentas de deploy. Aqui estão as opções para concluir:

### OPÇÃO 1: Usar IGP Existente do Hyperlane (Mais Rápido) ⭐

O Hyperlane já tem um IGP deployado em Sepolia que podemos configurar:

```bash
IGP_EXISTING="0x6f2756380FD49228ae25Aa7F2817993cB74Ecc56"

# Associar ao Warp Route
cast send "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4" \
  "setHook(address)" \
  "$IGP_EXISTING" \
  --private-key "0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5" \
  --rpc-url "https://1rpc.io/sepolia"
```

**Prós:**
- ✅ Rápido e simples
- ✅ Usa infraestrutura oficial
- ✅ Já está testado e funcionando

**Contras:**
- ❌ Não podemos configurar o Oracle (não somos owner)
- ❌ Pode não ter Terra Classic configurado

### OPÇÃO 2: Deploy Manual do IGP via Remix IDE (Recomendado)

**Passo a Passo:**

1. **Acesse Remix IDE**: https://remix.ethereum.org

2. **Crie um novo arquivo** `SimpleIGP.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOracle {
    function getExchangeRateAndGasPrice(uint32 remoteDomain)
        external view returns (uint128 tokenExchangeRate, uint128 gasPrice);
}

contract SimpleIGP {
    address public owner;
    address public beneficiary;
    mapping(uint32 => address) public gasOracles;
    mapping(uint32 => uint96) public gasOverheads;
    
    event GasPayment(bytes32 indexed messageId, uint256 gasAmount, uint256 payment);
    
    constructor(address _owner, address _beneficiary) {
        owner = _owner;
        beneficiary = _beneficiary;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    function setDestinationGasConfig(
        uint32 remoteDomain,
        address gasOracle,
        uint96 gasOverhead
    ) external onlyOwner {
        gasOracles[remoteDomain] = gasOracle;
        gasOverheads[remoteDomain] = gasOverhead;
    }
    
    function quoteGasPayment(uint32 destinationDomain, uint256 gasAmount)
        public view returns (uint256)
    {
        address oracle = gasOracles[destinationDomain];
        require(oracle != address(0), "No oracle");
        
        (uint128 exchangeRate, uint128 gasPrice) = IOracle(oracle)
            .getExchangeRateAndGasPrice(destinationDomain);
        
        uint256 totalGas = gasAmount + gasOverheads[destinationDomain];
        return (totalGas * gasPrice * exchangeRate) / 1e18;
    }
    
    function payForGas(
        bytes32 messageId,
        uint32 destinationDomain,
        uint256 gasAmount,
        address refundAddress
    ) external payable {
        uint256 requiredPayment = quoteGasPayment(destinationDomain, gasAmount);
        require(msg.value >= requiredPayment, "Insufficient payment");
        emit GasPayment(messageId, gasAmount, msg.value);
        if (msg.value > requiredPayment) {
            payable(refundAddress).transfer(msg.value - requiredPayment);
        }
    }
    
    function postDispatch(bytes calldata, bytes calldata) external payable {}
    function quoteDispatch(bytes calldata, bytes calldata) external pure returns (uint256) { return 0; }
    function hookType() external pure returns (uint8) { return 4; }
    function claim() external { payable(beneficiary).transfer(address(this).balance); }
    receive() external payable {}
}
```

3. **Compilar**:
   - Compiler: 0.8.13+
   - Optimization: Enabled

4. **Deploy**:
   - Environment: Injected Provider - MetaMask
   - Network: Sepolia
   - Constructor Parameters:
     - `_owner`: `0x133fD7F7094DBd17b576907d052a5aCBd48dB526`
     - `_beneficiary`: `0x133fD7F7094DBd17b576907d052a5aCBd48dB526`

5. **Configurar o IGP**:
   ```
   Função: setDestinationGasConfig
   Parâmetros:
   - remoteDomain: 1325
   - gasOracle: 0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c
   - gasOverhead: 200000
   ```

6. **Associar ao Warp Route**:
   ```
   No contrato: 0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4
   Função: setHook
   Parâmetro: [endereço do IGP deployado]
   ```

### OPÇÃO 3: Usar Hyperlane CLI (Oficial)

```bash
# Instalar Hyperlane CLI
npm install -g @hyperlane-xyz/cli

# Deploy IGP
hyperlane deploy igp \
  --chain sepolia \
  --key 0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5
```

## 📊 Configurações Prontas

Quando deployar o IGP, use estas configurações:

```
Oracle Address: 0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c
Terra Domain: 1325
Gas Overhead: 200000

Exchange Rate (já configurado no Oracle): 28,444,000,000,000,000
Gas Price (já configurado no Oracle): 38,325,000,000
```

## 🔍 Verificações Pós-Deploy

Após deployar e configurar o IGP:

1. **Verificar Oracle no IGP:**
```bash
cast call "[IGP_ADDRESS]" \
  "gasOracles(uint32)(address)" \
  1325 \
  --rpc-url https://1rpc.io/sepolia

# Deve retornar: 0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c
```

2. **Testar Quote de Gas:**
```bash
cast call "[IGP_ADDRESS]" \
  "quoteGasPayment(uint32,uint256)(uint256)" \
  1325 200000 \
  --rpc-url https://1rpc.io/sepolia

# Deve retornar um valor em wei
```

3. **Verificar Hook do Warp Route:**
```bash
cast call "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4" \
  "hook()(address)" \
  --rpc-url https://1rpc.io/sepolia

# Deve retornar: [endereço do IGP]
```

## 💡 Recomendação Final

Para ambiente de teste, **OPÇÃO 2 (Remix IDE)** é a mais confiável:
- ✅ Interface visual
- ✅ Fácil de usar
- ✅ Sem problemas de ferramentas
- ✅ Você terá controle total

Leva apenas 5-10 minutos e você pode acompanhar cada passo visualmente!

## 📞 Links Úteis

- **Remix IDE**: https://remix.ethereum.org
- **Seu Oracle**: https://sepolia.etherscan.io/address/0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c
- **Warp Route**: https://sepolia.etherscan.io/address/0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4
- **MetaMask**: Importe sua private key para usar no Remix

---

**Status**: Oracle ✅ Deployado e Configurado | IGP ⏳ Pendente
