pragma solidity 0.5.5;
import "./LuggageInsuranceContract.sol";

contract InsuranceContractManager {
    struct InsuranceContractConditions {
        uint premium;
        uint amountDelay;
        uint amountLost;
        uint revokeTimeLimit;
        uint timeLimitLuggageLost;
        uint timeLimitForPayOut;
    }

    address owner;
    mapping(address => LuggageInsuranceContract) public insureeToContractMapping;
    mapping(address => bool) public initializedContracts;
    InsuranceContractConditions public insuranceContractConditions;

    constructor(
        uint premium,
        uint amountDelay,
        uint amountLost,
        uint revokeTimeLimit,
        uint timeLimitLuggageLost,
        uint timeLimitForPayOut
    ) public {
        owner = msg.sender;
        insuranceContractConditions = InsuranceContractConditions(
            premium,
            amountDelay,
            amountLost,
            revokeTimeLimit,
            timeLimitLuggageLost,
            timeLimitForPayOut
        );
    }

    function setContractConditions(
        uint premium,
        uint amountDelay,
        uint amountLost,
        uint revokeTimeLimit,
        uint timeLimitLuggageLost,
        uint timeLimitForPayOut
    ) public {
        require(owner == msg.sender);
        insuranceContractConditions = InsuranceContractConditions(
            premium,
            amountDelay,
            amountLost,
            revokeTimeLimit,
            timeLimitLuggageLost,
            timeLimitForPayOut
        );
    }
    
    function saveContract(address addressInsuree) public {
        insureeToContractMapping[addressInsuree] = LuggageInsuranceContract(msg.sender);
        initializedContracts[msg.sender] = true;
    }
    
    function payout(uint amountToPay) public {
        require(initializedContracts[msg.sender]);
        LuggageInsuranceContract luggageInsuranceContract = LuggageInsuranceContract(msg.sender);
        require(luggageInsuranceContract.state() == LuggageInsuranceContract.State.closed);
        require(luggageInsuranceContract.claimState() != LuggageInsuranceContract.ClaimState.none);
        address payable addressInsuree = luggageInsuranceContract.getAddressInsuree();
        addressInsuree.transfer(amountToPay);
    }
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    function receiveMoney() external payable{ }
}