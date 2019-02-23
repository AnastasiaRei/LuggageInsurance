pragma solidity ^0.5.4;

contract LuggageInsuranceContract {
    address addressInsuree;
    address addressInsurance;
    string flightNumber;
    uint departureTime;
    uint arrivalTime;
    string departureAirport;
        
    constructor(
        address _addressInsuree,
        string memory _flightNumber,
        uint _departureTime,
        uint _arrivalTime,
        string memory _departureAirport
    ) public{
       addressInsuree = _addressInsuree;
       addressInsurance = msg.sender;
       flightNumber = _flightNumber;
       departureTime = _departureTime;
       arrivalTime = _arrivalTime;
       departureAirport = _departureAirport;
    }
} 