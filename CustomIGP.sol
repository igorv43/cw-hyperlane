// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.13;

/**
 * @title CustomIGP
 * @notice IGP personalizado compatível com Hyperlane para configurar taxas do Terra Classic
 * @dev Implementa a interface IPostDispatchHook do Hyperlane
 */
contract CustomIGP {
    
    address public owner;
    address public beneficiary;
    
    // Configurações de gas por domain
    struct DomainGasConfig {
        address gasOracle;
        uint96 gasOverhead;
    }
    
    mapping(uint32 => DomainGasConfig) public destinationConfigs;
    
    // Eventos
    event GasPayment(
        bytes32 indexed messageId,
        uint256 gasAmount,
        uint256 payment
    );
    
    event DestinationGasConfigSet(
        uint32 indexed destination,
        address gasOracle,
        uint96 gasOverhead
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
     * @notice Configura oracle e overhead para um destination domain
     */
    function setDestinationGasConfigs(
        uint32[] calldata destinations,
        address[] calldata gasOracles,
        uint96[] calldata gasOverheads
    ) external onlyOwner {
        require(
            destinations.length == gasOracles.length &&
            destinations.length == gasOverheads.length,
            "length mismatch"
        );
        
        for (uint256 i = 0; i < destinations.length; i++) {
            destinationConfigs[destinations[i]] = DomainGasConfig({
                gasOracle: gasOracles[i],
                gasOverhead: gasOverheads[i]
            });
            
            emit DestinationGasConfigSet(
                destinations[i],
                gasOracles[i],
                gasOverheads[i]
            );
        }
    }
    
    /**
     * @notice Calcula o custo de gas para um destination
     */
    function quoteDispatch(
        bytes calldata,
        bytes calldata message
    ) external view returns (uint256) {
        // Parse destination from message (primeiros 4 bytes são o destination domain)
        uint32 destination = uint32(bytes4(message[0:4]));
        
        DomainGasConfig memory config = destinationConfigs[destination];
        require(config.gasOracle != address(0), "destination not supported");
        
        // Estimar gas (pode ser ajustado conforme necessário)
        uint256 gasAmount = 200000;
        
        return _quoteGasPayment(destination, gasAmount, config);
    }
    
    /**
     * @notice Hook chamado após dispatch da mensagem
     */
    function postDispatch(
        bytes calldata metadata,
        bytes calldata message
    ) external payable {
        // Parse destination
        uint32 destination = uint32(bytes4(message[0:4]));
        
        DomainGasConfig memory config = destinationConfigs[destination];
        require(config.gasOracle != address(0), "destination not supported");
        
        uint256 gasAmount = 200000;
        uint256 requiredPayment = _quoteGasPayment(destination, gasAmount, config);
        
        require(msg.value >= requiredPayment, "insufficient payment");
        
        // Extract messageId from metadata (últimos 32 bytes)
        bytes32 messageId;
        assembly {
            messageId := calldataload(add(metadata.offset, sub(metadata.length, 32)))
        }
        
        emit GasPayment(messageId, gasAmount, msg.value);
        
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
        uint256 gasAmount,
        DomainGasConfig memory config
    ) internal view returns (uint256) {
        uint256 totalGas = gasAmount + config.gasOverhead;
        
        // Chamar oracle
        (bool success, bytes memory data) = config.gasOracle.staticcall(
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
        
        // Calcular custo: (totalGas * gasPrice * exchangeRate) / 10^18
        return (totalGas * uint256(gasPrice) * uint256(exchangeRate)) / 1e18;
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
