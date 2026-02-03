// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

// Interfaces do Hyperlane (caminho completo para deployar via Remix ou Foundry)
interface IPostDispatchHook {
    function hookType() external view returns (uint8);
    function supportsMetadata(bytes calldata metadata) external view returns (bool);
    function postDispatch(bytes calldata metadata, bytes calldata message) external payable;
    function quoteDispatch(bytes calldata metadata, bytes calldata message) external view returns (uint256);
}

interface IGasOracle {
    function getExchangeRateAndGasPrice(uint32 _destinationDomain) external view returns (uint128 tokenExchangeRate, uint128 gasPrice);
}

/**
 * @title TerraClassicIGP
 * @notice IGP simplificado para Terra Classic usando bibliotecas oficiais do Hyperlane
 * @dev Baseado no InterchainGasPaymaster.sol oficial
 */
contract TerraClassicIGP is IPostDispatchHook {
    
    // ============ Constants ============
    
    /// @notice Escala do exchange rate (OFICIAL DO HYPERLANE)
    uint256 internal constant TOKEN_EXCHANGE_RATE_SCALE = 1e10;
    
    /// @notice Gas usage padrão se não especificado no metadata
    uint256 internal constant DEFAULT_GAS_USAGE = 50_000;
    
    /// @notice Hook type para IGP
    uint8 internal constant IGP_HOOK_TYPE = 4; // INTERCHAIN_GAS_PAYMASTER
    
    /// @notice Terra Classic domain
    uint32 internal constant TERRA_CLASSIC_DOMAIN = 1325;
    
    // Offsets da mensagem (do Message.sol oficial)
    uint256 private constant DESTINATION_OFFSET = 41;
    uint256 private constant RECIPIENT_OFFSET = 45;
    
    // Offsets do metadata (do StandardHookMetadata.sol oficial)
    uint8 private constant GAS_LIMIT_OFFSET = 34;
    
    // ============ Storage ============
    
    address public owner;
    address public beneficiary;
    address public gasOracle;
    uint96 public gasOverhead;
    
    // ============ Events ============
    
    event GasPayment(
        bytes32 indexed messageId,
        uint32 indexed destinationDomain,
        uint256 gasAmount,
        uint256 payment
    );
    
    event GasOracleSet(address indexed gasOracle, uint96 gasOverhead);
    event BeneficiarySet(address indexed beneficiary);
    
    // ============ Modifiers ============
    
    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(address _gasOracle, uint96 _gasOverhead, address _beneficiary) {
        require(_gasOracle != address(0), "invalid oracle");
        require(_beneficiary != address(0), "invalid beneficiary");
        
        owner = msg.sender;
        gasOracle = _gasOracle;
        gasOverhead = _gasOverhead;
        beneficiary = _beneficiary;
        
        emit GasOracleSet(_gasOracle, _gasOverhead);
        emit BeneficiarySet(_beneficiary);
    }
    
    // ============ External Functions - IPostDispatchHook ============
    
    /// @inheritdoc IPostDispatchHook
    function hookType() external pure override returns (uint8) {
        return IGP_HOOK_TYPE;
    }
    
    /// @inheritdoc IPostDispatchHook
    function supportsMetadata(bytes calldata) external pure override returns (bool) {
        return true;
    }
    
    /// @inheritdoc IPostDispatchHook
    function quoteDispatch(
        bytes calldata metadata,
        bytes calldata message
    ) external view override returns (uint256) {
        // Extrair destination da mensagem (bytes 41-45)
        uint32 destination = _destination(message);
        
        // Apenas suporta Terra Classic
        require(destination == TERRA_CLASSIC_DOMAIN, "destination not supported");
        
        // Extrair gas limit do metadata (ou usar default)
        uint256 gasLimit = _gasLimit(metadata);
        
        // Total gas = gasLimit + overhead
        uint256 totalGas = gasLimit + uint256(gasOverhead);
        
        // Calcular custo
        return _quoteGasPayment(destination, totalGas);
    }
    
    /// @inheritdoc IPostDispatchHook
    function postDispatch(
        bytes calldata metadata,
        bytes calldata message
    ) external payable override {
        // Calcular messageId
        bytes32 messageId = keccak256(message);
        
        // Extrair destination
        uint32 destination = _destination(message);
        require(destination == TERRA_CLASSIC_DOMAIN, "destination not supported");
        
        // Extrair gas limit
        uint256 gasLimit = _gasLimit(metadata);
        uint256 totalGas = gasLimit + uint256(gasOverhead);
        
        // Calcular pagamento necessário
        uint256 requiredPayment = _quoteGasPayment(destination, totalGas);
        
        require(msg.value >= requiredPayment, "insufficient payment");
        
        // Refund do excesso
        uint256 overpayment = msg.value - requiredPayment;
        if (overpayment > 0) {
            address refundAddr = _refundAddress(metadata, message);
            payable(refundAddr).transfer(overpayment);
        }
        
        emit GasPayment(messageId, destination, totalGas, requiredPayment);
    }
    
    // ============ External Functions - Admin ============
    
    function setGasOracle(address _gasOracle, uint96 _gasOverhead) external onlyOwner {
        require(_gasOracle != address(0), "invalid oracle");
        gasOracle = _gasOracle;
        gasOverhead = _gasOverhead;
        emit GasOracleSet(_gasOracle, _gasOverhead);
    }
    
    function setBeneficiary(address _beneficiary) external onlyOwner {
        require(_beneficiary != address(0), "invalid beneficiary");
        beneficiary = _beneficiary;
        emit BeneficiarySet(_beneficiary);
    }
    
    function claim() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "no balance");
        payable(beneficiary).transfer(balance);
    }
    
    // ============ Internal Functions ============
    
    /**
     * @notice Extrai destination da mensagem (bytes 41-45)
     * @dev Baseado em Message.destination() do Hyperlane
     */
    function _destination(bytes calldata message) internal pure returns (uint32) {
        return uint32(bytes4(message[DESTINATION_OFFSET:RECIPIENT_OFFSET]));
    }
    
    /**
     * @notice Extrai gas limit do metadata (bytes 34-66)
     * @dev Baseado em StandardHookMetadata.gasLimit() do Hyperlane
     */
    function _gasLimit(bytes calldata metadata) internal pure returns (uint256) {
        if (metadata.length < GAS_LIMIT_OFFSET + 32) {
            return DEFAULT_GAS_USAGE;
        }
        return uint256(bytes32(metadata[GAS_LIMIT_OFFSET:GAS_LIMIT_OFFSET + 32]));
    }
    
    /**
     * @notice Extrai refund address do metadata (bytes 66-86)
     * @dev Baseado em StandardHookMetadata.refundAddress() do Hyperlane
     */
    function _refundAddress(
        bytes calldata metadata,
        bytes calldata message
    ) internal pure returns (address) {
        uint256 REFUND_ADDRESS_OFFSET = 66;
        
        // Se metadata não tem refund address, usar sender da mensagem
        if (metadata.length < REFUND_ADDRESS_OFFSET + 20) {
            return _senderAddress(message);
        }
        
        return address(bytes20(metadata[REFUND_ADDRESS_OFFSET:REFUND_ADDRESS_OFFSET + 20]));
    }
    
    /**
     * @notice Extrai sender address da mensagem (bytes 9-41)
     */
    function _senderAddress(bytes calldata message) internal pure returns (address) {
        uint256 SENDER_OFFSET = 9;
        uint256 DESTINATION_OFFSET_LOCAL = 41;
        bytes32 sender = bytes32(message[SENDER_OFFSET:DESTINATION_OFFSET_LOCAL]);
        return address(uint160(uint256(sender)));
    }
    
    /**
     * @notice Calcula o pagamento necessário para o gas
     * @dev Fórmula oficial: (destinationGasCost * tokenExchangeRate) / TOKEN_EXCHANGE_RATE_SCALE
     */
    function _quoteGasPayment(
        uint32 destinationDomain,
        uint256 gasLimit
    ) internal view returns (uint256) {
        // Obter dados do oracle
        (uint128 tokenExchangeRate, uint128 gasPrice) = IGasOracle(gasOracle)
            .getExchangeRateAndGasPrice(destinationDomain);
        
        // Custo total em gas da chain de destino
        uint256 destinationGasCost = gasLimit * uint256(gasPrice);
        
        // Converter para token local (ETH) usando exchange rate
        // IMPORTANTE: usar TOKEN_EXCHANGE_RATE_SCALE (1e10) conforme oficial
        return (destinationGasCost * uint256(tokenExchangeRate)) / TOKEN_EXCHANGE_RATE_SCALE;
    }
    
    // ============ Receive ============
    
    receive() external payable {}
}
