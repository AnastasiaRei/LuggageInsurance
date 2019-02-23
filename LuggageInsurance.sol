pragma solidity ^0.5.4;

contract LuggageInsuranceContract {
    address addressInsurance;
    address addressInsuree;
    address addressOracle = 0x72C396cBE08ed7cE86EB84C2E25Cd6800aC7d7f4;
    /*
    string flightNumber;
    uint departureTime;
    uint arrivalTime;
    string departureAirport;
    */
    uint premium= 100 wei;
    string public status;
    uint public balance;
    string public luggageID;
        
    constructor(
        address _addressInsuree
        /*
        string memory _flightNumber,
        uint _departureTime,
        uint _arrivalTime,
        string memory _departureAirport
        */
    ) public payable{
        addressInsuree = _addressInsuree;
        addressInsurance = msg.sender;
        status = "initialized";
        /*
        flightNumber = _flightNumber;
        departureTime = _departureTime;
        arrivalTime = _arrivalTime;
        departureAirport = _departureAirport;
        */
    }
    
    function payPremium() public payable{
        require(msg.sender == addressInsuree);
        require(compareStrings(status, "initialized"));
        require(msg.value == premium);
        balance += msg.value;
        status = "paid";
    }

    function checkInLuggage(string memory _luggageID) public{
        require(msg.sender == addressOracle);
        require(compareStrings(status, "paid"));
        luggageID = _luggageID;
        status = "checkedIn";
    }
    
    function boardingPassenger(address _addressInsuree) public{
        require(msg.sender == addressOracle);
        require(_addressInsuree == addressInsuree);
        require(compareStrings(status, "checkedIn"));
        status = "boarded";
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool){
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
    
    function() external payable { }
} 