pragma solidity 0.5.5;

contract InsuranceContract {
    InsuranceMgmt mgmtInstance;
    address payable public addressInsuree;
    bool public isDelayed;
    
    constructor(address payable addressMgmtInstance) public {
        addressInsuree = msg.sender;
        mgmtInstance = InsuranceMgmt(addressMgmtInstance);
        mgmtInstance.saveContract(addressInsuree);
    }
    function setDelay() public {
        isDelayed = true;
    } 
    function sendMoney()public payable {
        mgmtInstance.receiveMoney.value(msg.value)();
    }
    function triggerPayout()public {
        mgmtInstance.payout();
    }
}

contract InsuranceMgmt {
    mapping(address => InsuranceContract) public insureeToContractMapping;
    mapping(address => bool) public initializedContracts;
    
    function saveContract(address addressInsuree) public {
        insureeToContractMapping[addressInsuree] = InsuranceContract(msg.sender);
        initializedContracts[msg.sender] = true;
    }
    function payout() public {
        require(initializedContracts[msg.sender]);
        InsuranceContract insuranceContract = InsuranceContract(msg.sender);
        require(insuranceContract.isDelayed());
        insuranceContract.addressInsuree().transfer(1000000000000000000);
    }
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    function receiveMoney() external payable{ }
}