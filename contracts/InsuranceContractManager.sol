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

    event CreatedContract(address indexed addressInsuree, address indexed addressContract);
    event SendPayout(address indexed addressInsuree, uint amount, LuggageInsuranceContract.ClaimState claimState);
    event ReceivedMoney(address indexed sender, uint amount);

    address owner;
    address addressBackend;
    mapping(address => LuggageInsuranceContract) public insureeToContractMapping;
    mapping(address => bool) public initializedContracts;
    InsuranceContractConditions public insuranceContractConditions;

    constructor(
        address _addressBackend,
        uint premium,
        uint amountDelay,
        uint amountLost,
        uint revokeTimeLimit,
        uint timeLimitLuggageLost,
        uint timeLimitForPayOut
    ) public {
        owner = msg.sender;
        addressBackend = _addressBackend;
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
        require(owner == msg.sender, 'Owner must change contract conditions.');
        insuranceContractConditions = InsuranceContractConditions(
            premium,
            amountDelay,
            amountLost,
            revokeTimeLimit,
            timeLimitLuggageLost,
            timeLimitForPayOut
        );
    }
    
    function setBackendAddress(address _addressBackend) public {
        require(owner == msg.sender, 'Owner must change backend address.');
        addressBackend = _addressBackend;
    }

    function createContract(bool test) public returns(address) {
        address payable addressInsuree = msg.sender;
        LuggageInsuranceContract insuranceContract = new LuggageInsuranceContract(
            addressInsuree,
            addressBackend,
            insuranceContractConditions.premium,
            insuranceContractConditions.amountDelay,
            insuranceContractConditions.amountLost,
            insuranceContractConditions.revokeTimeLimit,
            insuranceContractConditions.timeLimitLuggageLost,
            insuranceContractConditions.timeLimitForPayOut,
            test
        );
        insureeToContractMapping[addressInsuree] = insuranceContract;
        
        address addressInsuranceContract = address(insuranceContract);
        initializedContracts[addressInsuranceContract] = true;
        emit CreatedContract(addressInsuree, addressInsuranceContract);
        return addressInsuranceContract;
    }

    function payout(uint amountToPay) public {
        require(initializedContracts[msg.sender]);
        LuggageInsuranceContract luggageInsuranceContract = LuggageInsuranceContract(msg.sender);
        require(luggageInsuranceContract.state() == LuggageInsuranceContract.State.closed);
        LuggageInsuranceContract.ClaimState claimState = luggageInsuranceContract.claimState();
        require(claimState != LuggageInsuranceContract.ClaimState.none);
        address payable addressInsuree = luggageInsuranceContract.getAddressInsuree();
        addressInsuree.transfer(amountToPay);
        emit SendPayout(addressInsuree,  amountToPay, claimState);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function receiveMoney() external payable {
        emit ReceivedMoney(msg.sender, msg.value);
    }
}
