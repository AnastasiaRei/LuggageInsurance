pragma solidity ^0.5.4;

contract LuggageInsuranceContract {
    address addressInsuree;
    address addressInsurance;
    string flightNumber;
    uint departureTime;
    uint arrivalTime;
    string departureAirport;
    uint premium= 100 wei;
    string public status;
    uint public balance;
        
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

    function compareStrings(string memory a, string memory b) internal pure returns (bool){
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
    
    function() external payable { }
} 