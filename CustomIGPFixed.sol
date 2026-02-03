// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.13;

/**
 * @title CustomIGPFixed
 * @notice IGP corrigido - sempre usa destination 1325 (Terra Classic)
 */
contract CustomIGPFixed {
    
    address public owner;
    address public beneficiary;
    
    // Configuração fixa para Terra Classic
    address public constant TERRA_ORACLE = 0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c;
    uint32 public constant TERRA_DOMAIN = 1325;
    uint96 public constant GAS_OVERHEAD = 200000;
    
    event GasPayment(
        bytes32 indexed messageId,
        uint256 gasAmount,
        uint256 payment
    );
    
    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }
    
    constructor(address _beneficiary) {
        owner = msg.sender;
        beneficiary = _beneficiary;
    }
    
    /**
     * @notice Calcula o custo de gas - sempre para Terra Classic
     */
    function quoteDispatch(
        bytes calldata,
        bytes calldata
    ) external view returns (uint256) {
        return _quoteGasPayment(TERRA_DOMAIN, GAS_OVERHEAD);
    }
    
    /**
     * @notice Hook chamado após dispatch da mensagem
     */
    function postDispatch(
        bytes calldata metadata,
        bytes calldata
    ) external payable {
        uint256 requiredPayment = _quoteGasPayment(TERRA_DOMAIN, GAS_OVERHEAD);
        
        require(msg.value >= requiredPayment, "insufficient payment");
        
        // Extract messageId from metadata (últimos 32 bytes)
        bytes32 messageId;
        if (metadata.length >= 32) {
            assembly {
                messageId := calldataload(add(metadata.offset, sub(metadata.length, 32)))
            }
        }
        
        emit GasPayment(messageId, GAS_OVERHEAD, msg.value);
        
        // Enviar fundos para beneficiary
        if (msg.value > 0) {
            payable(beneficiary).transfer(msg.value);
        }
    }
    
    /**
     * @notice Calcula custo de gas interno
     */
    function _quoteGasPayment(
        uint32 destination,
        uint256 gasAmount
    ) internal view returns (uint256) {
        // Chamar oracle
        (bool success, bytes memory data) = TERRA_ORACLE.staticcall(
            abi.encodeWithSignature(
                "getExchangeRateAndGasPrice(uint32)",
                destination
            )
        );
        
        require(success, "oracle call failed");
        
        (uint128 exchangeRate, uint128 gasPrice) = abi.decode(
            data,
            (uint128, uint128)
        );
        
        // Calcular custo: (gasAmount * gasPrice * exchangeRate) / 10^18
        return (gasAmount * uint256(gasPrice) * uint256(exchangeRate)) / 1e18;
    }
    
    /**
     * @notice Retorna o tipo do hook (requerido pelo Hyperlane)
     */
    function hookType() external pure returns (uint8) {
        return 2; // Hook type for IGP
    }
    
    /**
     * @notice Verifica se suporta metadata
     */
    function supportsMetadata(bytes calldata) external pure returns (bool) {
        return true;
    }
    
    /**
     * @notice Atualiza beneficiário
     */
    function setBeneficiary(address _beneficiary) external onlyOwner {
        require(_beneficiary != address(0), "invalid beneficiary");
        beneficiary = _beneficiary;
    }
    
    /**
     * @notice Permite receber ETH
     */
    receive() external payable {}
}
