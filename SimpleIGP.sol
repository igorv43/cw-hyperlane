// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title SimpleIGP
 * @notice Interchain Gas Paymaster simplificado para Sepolia → Terra Classic
 */
contract SimpleIGP {
    address public owner;
    address public beneficiary;
    
    mapping(uint32 => address) public gasOracles;
    mapping(uint32 => uint256) public destinationGasOverhead;
    
    event DestinationGasConfigSet(
        uint32 indexed remoteDomain,
        address gasOracle,
        uint256 gasOverhead
    );
    
    event GasPayment(
        bytes32 indexed messageId,
        uint32 indexed destinationDomain,
        uint256 gasAmount,
        uint256 payment
    );
    
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
    
    function quoteGasPayment(
        uint32 destinationDomain,
        uint256 gasAmount
    ) public view returns (uint256) {
        address oracle = gasOracles[destinationDomain];
        require(oracle != address(0), "Configured IGP doesn't support domain");
        
        uint256 overhead = destinationGasOverhead[destinationDomain];
        uint256 totalGas = gasAmount + overhead;
        
        (bool success, bytes memory data) = oracle.staticcall(
            abi.encodeWithSignature("getExchangeRateAndGasPrice(uint32)", destinationDomain)
        );
        require(success, "Oracle call failed");
        
        (uint128 exchangeRate, uint128 gasPrice) = abi.decode(data, (uint128, uint128));
        
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
        
        emit GasPayment(messageId, destinationDomain, gasAmount, msg.value);
        
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
