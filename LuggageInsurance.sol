pragma solidity ^0.5.4;

contract LuggageInsuranceContract {
    
    struct Flight{
        string flightNumber;
        uint departureTime;
        uint arrivalTime;
        string departureAirport;
        bool landed;
    }
    
    Flight public flight;
    address addressInsurance;
    address addressInsuree;
    address addressOracle = 0x72C396cBE08ed7cE86EB84C2E25Cd6800aC7d7f4;
    uint premium= 100 wei;
    string public status;
    uint public balance;
    string public luggageID;
        
    constructor(address _addressInsuree) public payable{
        addressInsuree = _addressInsuree;
        addressInsurance = msg.sender;
        status = "initialized";
    }
    
    function setFlight(
        string memory flightNumber,
        uint departureTime,
        uint arrivalTime,
        string memory departureAirport
    ) public {
        require(msg.sender == addressInsurance);
        require(compareStrings(status, "initialized"));
        flight = Flight(flightNumber, departureTime, arrivalTime, departureAirport,false);
        status = "flightSet";
    }
    
    function payPremium() public payable{
        require(msg.sender == addressInsuree);
        require(compareStrings(status, "flightSet"));
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
    
    function setFlightStatus(string memory flightStatus) public{
        require(msg.sender == addressOracle);
        require(compareStrings(status, "boarded"));
        if(compareStrings(flightStatus, "landed")){
            status = "landed";
            flight.landed = true;
        }else{
            //ask oracle again in some time
        }
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool){
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
    
    function() external payable { }
} 