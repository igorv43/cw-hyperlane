// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.13;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/

/**
 * @title TerraClassicIGP
 * @notice Interchain Gas Paymaster configurado especificamente para Terra Classic
 * @dev Baseado no InterchainGasPaymaster oficial do Hyperlane
 */
contract TerraClassicIGP {
    // ============ Constants ============
    
    /// @notice HookType for INTERCHAIN_GAS_PAYMASTER (from IPostDispatchHook)
    uint8 public constant HOOK_TYPE = 4;
    
    /// @notice The scale of gas oracle token exchange rates (from official Hyperlane IGP)
    uint256 internal constant TOKEN_EXCHANGE_RATE_SCALE = 1e10;
    
    /// @notice Terra Classic domain ID
    uint32 public constant TERRA_CLASSIC_DOMAIN = 1325;
    
    // ============ Public Storage ============
    
    address public owner;
    address public beneficiary;
    
    /// @notice Destination domain => token exchange rate
    mapping(uint32 => uint128) public tokenExchangeRate;
    
    /// @notice Destination domain => gas price
    mapping(uint32 => uint128) public gasPrice;
    
    /// @notice Destination domain => gas overhead
    mapping(uint32 => uint96) public gasOverhead;
    
    // ============ Events ============
    
    event RemoteGasDataSet(
        uint32 indexed remoteDomain,
        uint128 tokenExchangeRate,
        uint128 gasPrice
    );
    
    event GasOverheadSet(
        uint32 indexed remoteDomain,
        uint96 gasOverhead
    );
    
    event BeneficiarySet(address indexed beneficiary);
    
    event GasPayment(
        bytes32 indexed messageId,
        uint32 indexed destinationDomain,
        uint256 gasLimit,
        uint256 payment
    );
    
    // ============ Modifiers ============
    
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }
    
    // ============ Constructor ============
    
    /**
     * @param _beneficiary The beneficiary address
     */
    constructor(address _beneficiary) {
        require(_beneficiary != address(0), "invalid beneficiary");
        owner = msg.sender;
        beneficiary = _beneficiary;
        emit BeneficiarySet(_beneficiary);
    }
    
    // ============ External Functions ============
    
    /**
     * @notice Returns the hook type
     * @dev Must return 4 for INTERCHAIN_GAS_PAYMASTER
     */
    function hookType() external pure returns (uint8) {
        return HOOK_TYPE;
    }
    
    /**
     * @notice Returns whether the hook supports metadata
     */
    function supportsMetadata(bytes calldata) external pure returns (bool) {
        return true;
    }
    
    /**
     * @notice Post action after a message is dispatched via the Mailbox
     * @param metadata The metadata required for the hook
     * @param message The message passed from the Mailbox.dispatch() call
     */
    function postDispatch(
        bytes calldata metadata,
        bytes calldata message
    ) external payable {
        // Extract destination domain from message (bytes 41-45)
        uint32 destination = uint32(bytes4(message[41:45]));
        
        // Extract message ID (first 32 bytes of keccak256(message))
        bytes32 messageId = keccak256(message);
        
        // Extract gas limit from metadata (bytes 34-66)
        uint256 gasLimit = uint256(bytes32(metadata[34:66]));
        
        // Calculate required payment
        uint256 requiredPayment = _quoteGasPayment(destination, gasLimit);
        
        require(msg.value >= requiredPayment, "IGP: insufficient payment");
        
        emit GasPayment(messageId, destination, gasLimit, msg.value);
        
        // Refund overpayment if any
        if (msg.value > requiredPayment) {
            // Extract refund address from metadata (bytes 2-34)
            address refundAddress = address(bytes20(metadata[14:34]));
            if (refundAddress != address(0)) {
                payable(refundAddress).transfer(msg.value - requiredPayment);
            }
        }
    }
    
    /**
     * @notice Compute the payment required by the postDispatch call
     * @param metadata The metadata required for the hook
     * @param message The message passed from the Mailbox.dispatch() call
     * @return Quoted payment for the postDispatch call
     */
    function quoteDispatch(
        bytes calldata metadata,
        bytes calldata message
    ) external view returns (uint256) {
        // Extract destination domain from message (bytes 41-45)
        uint32 destination = uint32(bytes4(message[41:45]));
        
        // Extract gas limit from metadata (bytes 34-66)
        uint256 gasLimit = uint256(bytes32(metadata[34:66]));
        
        return _quoteGasPayment(destination, gasLimit);
    }
    
    /**
     * @notice Sets remote gas data for a destination domain
     * @param remoteDomain The remote domain
     * @param _tokenExchangeRate The token exchange rate (scaled by 1e10)
     * @param _gasPrice The gas price on the remote chain
     */
    function setRemoteGasData(
        uint32 remoteDomain,
        uint128 _tokenExchangeRate,
        uint128 _gasPrice
    ) external onlyOwner {
        tokenExchangeRate[remoteDomain] = _tokenExchangeRate;
        gasPrice[remoteDomain] = _gasPrice;
        emit RemoteGasDataSet(remoteDomain, _tokenExchangeRate, _gasPrice);
    }
    
    /**
     * @notice Sets gas overhead for a destination domain
     * @param remoteDomain The remote domain
     * @param _gasOverhead The gas overhead
     */
    function setGasOverhead(
        uint32 remoteDomain,
        uint96 _gasOverhead
    ) external onlyOwner {
        gasOverhead[remoteDomain] = _gasOverhead;
        emit GasOverheadSet(remoteDomain, _gasOverhead);
    }
    
    /**
     * @notice Sets the beneficiary address
     * @param _beneficiary The new beneficiary
     */
    function setBeneficiary(address _beneficiary) external onlyOwner {
        require(_beneficiary != address(0), "invalid beneficiary");
        beneficiary = _beneficiary;
        emit BeneficiarySet(_beneficiary);
    }
    
    /**
     * @notice Transfers the entire native token balance to the beneficiary
     */
    function claim() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "no balance");
        (bool success, ) = beneficiary.call{value: balance}("");
        require(success, "claim failed");
    }
    
    /**
     * @notice Gets the token exchange rate and gas price for a destination domain
     * @param _destinationDomain The destination domain
     * @return _tokenExchangeRate The token exchange rate
     * @return _gasPrice The gas price
     */
    function getExchangeRateAndGasPrice(
        uint32 _destinationDomain
    ) external view returns (uint128 _tokenExchangeRate, uint128 _gasPrice) {
        _tokenExchangeRate = tokenExchangeRate[_destinationDomain];
        _gasPrice = gasPrice[_destinationDomain];
        require(_tokenExchangeRate > 0 && _gasPrice > 0, "not configured");
    }
    
    // ============ Internal Functions ============
    
    /**
     * @notice Quotes the amount of native tokens to pay for interchain gas
     * @param _destinationDomain The destination domain
     * @param _gasLimit The gas limit
     * @return The amount of native tokens required
     */
    function _quoteGasPayment(
        uint32 _destinationDomain,
        uint256 _gasLimit
    ) internal view returns (uint256) {
        uint128 _tokenExchangeRate = tokenExchangeRate[_destinationDomain];
        uint128 _gasPrice = gasPrice[_destinationDomain];
        uint96 _gasOverhead = gasOverhead[_destinationDomain];
        
        require(_tokenExchangeRate > 0 && _gasPrice > 0, "destination not configured");
        
        // Total gas = user gas limit + overhead
        uint256 totalGas = _gasLimit + uint256(_gasOverhead);
        
        // Gas cost in destination native token
        uint256 destinationGasCost = totalGas * uint256(_gasPrice);
        
        // Convert to source native token using exchange rate
        return (destinationGasCost * _tokenExchangeRate) / TOKEN_EXCHANGE_RATE_SCALE;
    }
    
    // ============ Receive Function ============
    
    receive() external payable {}
}
