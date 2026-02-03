# 🚀 Deploy IGP para Sepolia via Remix IDE

Este guia mostra como deployar um InterchainGasPaymaster (IGP) personalizado para suportar transferências Terra Classic ↔ Sepolia.

---

## 🎯 Objetivo

Deployar um IGP configurado para:
- **Domain Terra Classic**: 1325
- **Oracle**: `0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c`
- **Gas Overhead**: 200000

Depois, associar este IGP ao Warp Route: `0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4`

---

## 📋 Pré-requisitos

- ✅ MetaMask instalado e conectado à Sepolia
- ✅ Saldo em ETH na Sepolia (pelo menos 0.02 ETH)
- ✅ Conta: `0x133fD7F7094DBd17b576907d052a5aCBd48dB526`
- ✅ Oracle deployado: `0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c`

---

## 🔧 Passo 1: Preparar Contrato no Remix

### 1.1. Acesse Remix IDE

Abra: https://remix.ethereum.org

### 1.2. Crie Novo Arquivo

1. No painel esquerdo, clique em "contracts"
2. Clique com botão direito e selecione "New File"
3. Nome do arquivo: `SimpleIGP.sol`

### 1.3. Cole o Código do Contrato

```solidity
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.13;

/**
 * @title SimpleIGP
 * @notice Interchain Gas Paymaster simplificado para Sepolia → Terra Classic
 * @dev Baseado no contrato InterchainGasPaymaster do Hyperlane
 */
contract SimpleIGP {
    // Owner do contrato
    address public owner;
    
    // Beneficiário dos pagamentos de gas
    address public beneficiary;
    
    // Mapping: domain → oracle address
    mapping(uint32 => address) public gasOracles;
    
    // Mapping: domain → gas overhead
    mapping(uint32 => uint256) public destinationGasOverhead;
    
    // Events
    event GasPayment(
        bytes32 indexed messageId,
        uint32 indexed destinationDomain,
        uint256 gasAmount,
        uint256 payment
    );
    
    event DestinationGasConfigSet(
        uint32 indexed remoteDomain,
        address gasOracle,
        uint256 gasOverhead
    );
    
    event BeneficiarySet(address beneficiary);
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    // Constructor
    constructor(address _owner, address _beneficiary) {
        require(_owner != address(0), "Invalid owner");
        require(_beneficiary != address(0), "Invalid beneficiary");
        owner = _owner;
        beneficiary = _beneficiary;
        emit OwnershipTransferred(address(0), _owner);
        emit BeneficiarySet(_beneficiary);
    }
    
    /**
     * @notice Configura gas oracle e overhead para um domain
     * @param remoteDomain Domain de destino (ex: 1325 para Terra Classic)
     * @param gasOracle Endereço do StorageGasOracle
     * @param gasOverhead Gas overhead adicional
     */
    function setDestinationGasConfig(
        uint32 remoteDomain,
        address gasOracle,
        uint256 gasOverhead
    ) external onlyOwner {
        require(gasOracle != address(0), "Invalid oracle");
        gasOracles[remoteDomain] = gasOracle;
        destinationGasOverhead[remoteDomain] = gasOverhead;
        emit DestinationGasConfigSet(remoteDomain, gasOracle, gasOverhead);
    }
    
    /**
     * @notice Calcula custo de gas para um domain
     * @param destinationDomain Domain de destino
     * @param gasAmount Quantidade de gas estimada
     * @return Custo em wei
     */
    function quoteGasPayment(
        uint32 destinationDomain,
        uint256 gasAmount
    ) public view returns (uint256) {
        address oracle = gasOracles[destinationDomain];
        require(oracle != address(0), string(abi.encodePacked("Configured IGP doesn't support domain ", uint2str(destinationDomain))));
        
        uint256 overhead = destinationGasOverhead[destinationDomain];
        uint256 totalGas = gasAmount + overhead;
        
        // Chama o oracle para obter exchange rate e gas price
        (bool success, bytes memory data) = oracle.staticcall(
            abi.encodeWithSignature("getExchangeRateAndGasPrice(uint32)", destinationDomain)
        );
        require(success, "Oracle call failed");
        
        (uint128 exchangeRate, uint128 gasPrice) = abi.decode(data, (uint128, uint128));
        
        // Calcula: (totalGas * gasPrice * exchangeRate) / 10^18
        return (totalGas * gasPrice * exchangeRate) / 1e18;
    }
    
    /**
     * @notice Paga por gas de mensagem cross-chain
     * @param messageId ID da mensagem
     * @param destinationDomain Domain de destino
     * @param gasAmount Quantidade de gas
     */
    function payForGas(
        bytes32 messageId,
        uint32 destinationDomain,
        uint256 gasAmount,
        address refundAddress
    ) external payable {
        uint256 requiredPayment = quoteGasPayment(destinationDomain, gasAmount);
        require(msg.value >= requiredPayment, "Insufficient payment");
        
        emit GasPayment(messageId, destinationDomain, gasAmount, msg.value);
        
        // Reembolsar excesso
        if (msg.value > requiredPayment) {
            payable(refundAddress).transfer(msg.value - requiredPayment);
        }
    }
    
    /**
     * @notice Saca fundos para o beneficiário
     */
    function claim() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to claim");
        payable(beneficiary).transfer(balance);
    }
    
    /**
     * @notice Atualiza beneficiário
     * @param newBeneficiary Novo endereço do beneficiário
     */
    function setBeneficiary(address newBeneficiary) external onlyOwner {
        require(newBeneficiary != address(0), "Invalid beneficiary");
        beneficiary = newBeneficiary;
        emit BeneficiarySet(newBeneficiary);
    }
    
    /**
     * @notice Transfere ownership
     * @param newOwner Novo owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    // Helper function para converter uint para string
    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }
    
    // Fallback para receber ETH
    receive() external payable {}
}
```

---

## 🔨 Passo 2: Compilar o Contrato

### 2.1. Abra o Compilador

No painel esquerdo, clique no ícone **"Solidity compiler"** (terceiro ícone)

### 2.2. Configure o Compilador

- **Compiler version**: Selecione `0.8.13` ou superior (ex: `0.8.23`)
- **EVM Version**: `default`
- **Enable optimization**: ✅ Marque esta opção
- **Runs**: `200` (padrão)

### 2.3. Compile

Clique no botão **"Compile SimpleIGP.sol"**

✅ Se aparecer **"✓ compiled successfully"**, prossiga para o próximo passo.

❌ Se houver erros, verifique se copiou o código completo corretamente.

---

## 🚀 Passo 3: Deploy do Contrato

### 3.1. Abra Deploy & Run

No painel esquerdo, clique no ícone **"Deploy & run transactions"** (quarto ícone)

### 3.2. Configure o Deploy

- **Environment**: Selecione `Injected Provider - MetaMask`
- **Account**: Deve aparecer seu endereço `0x133fD7F7094DBd17b576907d052a5aCBd48dB526`
- **Gas Limit**: `3000000` (3M)
- **Contract**: Selecione `SimpleIGP - SimpleIGP.sol`

### 3.3. Defina os Parâmetros do Constructor

No campo **"Deploy"**, você verá dois campos:

1. **_OWNER** (address): `0x133fD7F7094DBd17b576907d052a5aCBd48dB526`
2. **_BENEFICIARY** (address): `0x133fD7F7094DBd17b576907d052a5aCBd48dB526`

### 3.4. Execute o Deploy

1. Clique no botão **"transact"** (ou **"Deploy"**)
2. MetaMask abrirá uma janela de confirmação
3. Verifique:
   - Network: **Sepolia**
   - Gas fee: ~0.005-0.01 ETH
4. Clique em **"Confirm"**

### 3.5. Aguarde Confirmação

- A transação aparecerá na área inferior do Remix
- Aguarde a confirmação na blockchain (~15-30 segundos)
- ✅ Quando confirmado, o contrato aparecerá em **"Deployed Contracts"**

### 3.6. Copie o Endereço do Contrato

- Clique no ícone **📋 copy** ao lado do contrato deployado
- **Salve este endereço!** Exemplo: `0xABCD...1234`

---

## ⚙️ Passo 4: Configurar o IGP

### 4.1. Expandir Contrato Deployado

No painel **"Deployed Contracts"**, clique na seta ao lado do endereço do seu IGP para expandir as funções.

### 4.2. Configurar Domain Terra Classic

1. Encontre a função **`setDestinationGasConfig`**
2. Preencha os campos:
   - **remoteDomain** (uint32): `1325`
   - **gasOracle** (address): `0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c`
   - **gasOverhead** (uint256): `200000`

3. Clique no botão **"transact"**
4. Confirme a transação no MetaMask
5. Aguarde confirmação

### 4.3. Verificar Configuração

1. Encontre a função **`gasOracles`** (botão laranja/view)
2. Digite o domain: `1325`
3. Clique no botão **"call"**
4. Resultado esperado: `0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c`

✅ Se retornar o endereço do Oracle, a configuração está correta!

---

## 🔗 Passo 5: Associar IGP ao Warp Route

Agora você precisa configurar o Warp Route para usar seu IGP.

### Opção A: Via Remix IDE

1. No Remix, vá em **"At Address"**
2. Cole o endereço do Warp Route: `0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4`
3. Clique em **"At Address"**
4. Se o contrato não carregar, use a Opção B (cast)

### Opção B: Via Terminal (Recomendado)

Abra o terminal e execute:

```bash
# Substitua [IGP_DEPLOYADO] pelo endereço do seu IGP
export IGP_ADDRESS="0xSEU_IGP_AQUI"
export WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
export PRIVATE_KEY="0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5"

cast send "$WARP_ROUTE" \
  "setHook(address)" \
  "$IGP_ADDRESS" \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "https://1rpc.io/sepolia" \
  --legacy
```

✅ Se a transação for bem-sucedida, prossiga para a verificação.

---

## ✅ Passo 6: Verificar Tudo

### 6.1. Verificar Hook do Warp Route

```bash
cast call "0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4" \
  "hook()(address)" \
  --rpc-url "https://1rpc.io/sepolia"
```

**Resultado esperado**: Deve retornar o endereço do seu IGP.

### 6.2. Verificar Oracle no IGP

```bash
cast call "$IGP_ADDRESS" \
  "gasOracles(uint32)(address)" \
  1325 \
  --rpc-url "https://1rpc.io/sepolia"
```

**Resultado esperado**: `0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c`

### 6.3. Testar Quote de Gas

```bash
cast call "$IGP_ADDRESS" \
  "quoteGasPayment(uint32,uint256)(uint256)" \
  1325 200000 \
  --rpc-url "https://1rpc.io/sepolia"
```

**Resultado esperado**: Um número grande (custo em wei). Exemplo: `1093650000000000000000` (~1093 ETH equivalente em LUNC)

---

## 🎉 Pronto!

Agora você pode testar a transferência Sepolia → Terra Classic novamente!

### 📊 Resumo do Deploy

| Item | Valor |
|------|-------|
| **IGP Address** | `[ANOTE AQUI]` |
| **Oracle** | `0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c` |
| **Domain** | 1325 (Terra Classic) |
| **Gas Overhead** | 200000 |
| **Warp Route** | `0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4` |
| **Owner** | `0x133fD7F7094DBd17b576907d052a5aCBd48dB526` |

---

## 🐛 Troubleshooting

### Erro: "Only owner"
- Certifique-se de estar usando a conta `0x133fD7F7094DBd17b576907d052a5aCBd48dB526`

### Erro: "Insufficient payment"
- O pagamento de gas é calculado em LUNC e pode ser alto
- Verifique se o exchange rate está correto no Oracle

### Erro: "Oracle call failed"
- Verifique se o Oracle está deployado: `0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c`
- Verifique se o domain 1325 está configurado no Oracle

### MetaMask não conecta
- Certifique-se de estar na rede **Sepolia**
- Tente desconectar e reconectar MetaMask no Remix

---

## 📝 Notas Importantes

- ⚠️ **Guarde o endereço do IGP deployado!**
- ⚠️ **Você é o owner** - só você pode configurar o IGP
- ⚠️ **Verifique os valores** antes de confirmar transações
- ⚠️ **Teste com valores pequenos** primeiro

---

**Boa sorte com o deploy! 🚀**
