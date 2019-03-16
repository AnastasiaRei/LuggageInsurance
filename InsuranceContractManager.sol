pragma solidity 0.5.5;
import "./LuggageInsuranceContract.sol";

contract InsuranceContractManager {
    address owner;
    mapping(address => LuggageInsuranceContract) public insureeToContractMapping;
    mapping(address => bool) public initializedContracts;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function saveContract(address addressInsuree) public {
        insureeToContractMapping[addressInsuree] = LuggageInsuranceContract(msg.sender);
        initializedContracts[msg.sender] = true;
    }
    
    function payout() public {
        require(initializedContracts[msg.sender]);
        LuggageInsuranceContract luggageInsuranceContract = LuggageInsuranceContract(msg.sender);
        require(luggageInsuranceContract.state() == LuggageInsuranceContract.State.closed);
        require(luggageInsuranceContract.claimState() != LuggageInsuranceContract.ClaimState.none);
        address payable addressInsuree = luggageInsuranceContract.getAddressInsuree();
        addressInsuree.transfer(1 ether);
    }
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    function receiveMoney() external payable{ }
}