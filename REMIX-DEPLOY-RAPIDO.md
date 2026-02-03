# 🚀 DEPLOY RÁPIDO DO IGP VIA REMIX (5 MINUTOS)

## ⚡ Passo a Passo Ultra-Rápido

### 1️⃣ Abrir Remix e Criar Arquivo (1 min)

1. Acesse: **https://remix.ethereum.org**
2. Clique em "contracts" no painel esquerdo
3. Clique com botão direito → "New File"
4. Nome: `SimpleIGP.sol`
5. Cole o código abaixo:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract SimpleIGP {
    address public owner;
    address public beneficiary;
    mapping(uint32 => address) public gasOracles;
    mapping(uint32 => uint256) public destinationGasOverhead;
    
    event DestinationGasConfigSet(uint32 indexed remoteDomain, address gasOracle, uint256 gasOverhead);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    constructor(address _owner, address _beneficiary) {
        require(_owner != address(0), "Invalid owner");
        require(_beneficiary != address(0), "Invalid beneficiary");
        owner = _owner;
        beneficiary = _beneficiary;
    }
    
    function setDestinationGasConfig(uint32 remoteDomain, address gasOracle, uint256 gasOverhead) external onlyOwner {
        require(gasOracle != address(0), "Invalid oracle");
        gasOracles[remoteDomain] = gasOracle;
        destinationGasOverhead[remoteDomain] = gasOverhead;
        emit DestinationGasConfigSet(remoteDomain, gasOracle, gasOverhead);
    }
    
    function quoteGasPayment(uint32 destinationDomain, uint256 gasAmount) public view returns (uint256) {
        address oracle = gasOracles[destinationDomain];
        require(oracle != address(0), "Configured IGP doesn't support domain");
        uint256 overhead = destinationGasOverhead[destinationDomain];
        uint256 totalGas = gasAmount + overhead;
        (bool success, bytes memory data) = oracle.staticcall(abi.encodeWithSignature("getExchangeRateAndGasPrice(uint32)", destinationDomain));
        require(success, "Oracle call failed");
        (uint128 exchangeRate, uint128 gasPrice) = abi.decode(data, (uint128, uint128));
        return (totalGas * gasPrice * exchangeRate) / 1e18;
    }
    
    function payForGas(bytes32 messageId, uint32 destinationDomain, uint256 gasAmount, address refundAddress) external payable {
        uint256 requiredPayment = quoteGasPayment(destinationDomain, gasAmount);
        require(msg.value >= requiredPayment, "Insufficient payment");
        if (msg.value > requiredPayment) {
            payable(refundAddress).transfer(msg.value - requiredPayment);
        }
    }
    
    function claim() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds");
        payable(beneficiary).transfer(balance);
    }
    
    receive() external payable {}
}
```

### 2️⃣ Compilar (30 segundos)

1. Clique no ícone **"Solidity compiler"** (3º ícone no painel esquerdo)
2. Versão: Selecione **`0.8.13`** ou superior
3. Marque **"Enable optimization"**
4. Clique em **"Compile SimpleIGP.sol"**
5. Aguarde: ✓ compiled successfully

### 3️⃣ Deploy (1 min)

1. Clique no ícone **"Deploy & run"** (4º ícone)
2. Environment: **`Injected Provider - MetaMask`**
3. Conecte MetaMask (Sepolia)
4. Em "Deploy", preencha:
   - `_OWNER`: `0x133fD7F7094DBd17b576907d052a5aCBd48dB526`
   - `_BENEFICIARY`: `0x133fD7F7094DBd17b576907d052a5aCBd48dB526`
5. Clique em **"transact"**
6. Confirme no MetaMask
7. **COPIE O ENDEREÇO DO CONTRATO DEPLOYADO** ✅

### 4️⃣ Configurar Terra Classic (1 min)

1. No Remix, expanda o contrato deployado (Deployed Contracts)
2. Encontre `setDestinationGasConfig`
3. Preencha:
   - `remoteDomain`: `1325`
   - `gasOracle`: `0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c`
   - `gasOverhead`: `200000`
4. Clique em **"transact"**
5. Confirme no MetaMask

### 5️⃣ Associar ao Warp Route (1 min)

**Copie o endereço do IGP** e execute no terminal:

```bash
export IGP_ADDRESS="SEU_ENDEREÇO_AQUI"

cast send "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4" \
  "setHook(address)" \
  "$IGP_ADDRESS" \
  --private-key "0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5" \
  --rpc-url "https://1rpc.io/sepolia" \
  --legacy
```

### 6️⃣ Verificar (30 segundos)

```bash
./verificar-igp-sepolia.sh
```

---

## ✅ PRONTO!

Agora você pode fazer transferências Sepolia → Terra Classic! 🎉

---

## 📱 Screenshots de Referência

### Deploy no Remix:
```
Contract: SimpleIGP
_OWNER: 0x133fD7F7094DBd17b576907d052a5aCBd48dB526
_BENEFICIARY: 0x133fD7F7094DBd17b576907d052a5aCBd48dB526
[transact] ← Clique aqui
```

### Configurar:
```
setDestinationGasConfig
remoteDomain: 1325
gasOracle: 0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c
gasOverhead: 200000
[transact] ← Clique aqui
```

---

**Tempo total: ~5 minutos** ⏱️
