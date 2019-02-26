pragma solidity ^0.5.4;

contract LuggageInsuranceContract {
    
    struct Flight {
        string flightNumber;
        uint departureDay;
        bool landed;
        uint timeLanded;
        bool initialized;
    }
    
    struct Luggage {
        string id;
        bool onBelt; 
        uint timeOnBelt;
        bool initialized;
    }
    
    struct Insuree {
        bool boarded;
        address payable addressInsuree;
    }
    
    enum State {
        inactive, active, revoked, closed
    }
    
    Flight public flight;
    Luggage public luggage;
    Insuree public insuree;
    address payable addressInsurance = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
    address addressOracle = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    uint premium= 5 ether;
    State public status;
    uint public balance;
    uint public timeDifference;
    //in Sec
    uint public timeLimitForPayOut = 30;
        
    constructor() public payable{
        insuree = Insuree(false, msg.sender);
        status = State.inactive;
    }
    
    function setFlight(
        string memory flightNumber,
        uint departureDay
    ) public {
        require(msg.sender == insuree.addressInsuree);
        require(status == State.inactive);
        flight = Flight(
            flightNumber,
            departureDay,
            false,
            0, 
            true
        );
    }
    
    function payPremium() public payable{
        require(msg.sender == insuree.addressInsuree);
        require(flight.initialized);
        require(status == State.inactive);
        require(msg.value == premium);
        balance += msg.value;
        status = State.active;
    }

    function checkInLuggage(string memory _luggageID) public{
        require(msg.sender == addressOracle);
        require(status == State.active);
        require(!luggage.initialized);
        luggage = Luggage(_luggageID, false, 0, true);
    }
    
    function revokeContract() public{
        require(msg.sender == insuree.addressInsuree);
        require(status == State.active);
        require(!insuree.boarded);
        insuree.addressInsuree.transfer(balance);
        status = State.revoked;
    }
    
    function boardingPassenger(address _addressInsuree) public{
        require(msg.sender == addressOracle);
        require(_addressInsuree == insuree.addressInsuree);
        require(luggage.initialized);
        require(!insuree.boarded);
        insuree.boarded = true;
    }
    
    function setFlightStatus(string memory flightStatus) public{
        require(msg.sender == addressOracle);
        require(insuree.boarded);
        if(compareStrings(flightStatus, "landed")){
            flight.landed = true;
            flight.timeLanded = now;
        }else {
            //ask oracle again in some time
        }
    }
    
    function setLuggageStatus(string memory _luggageID, bool _onBelt) public{
        require(status == State.active);
        require(msg.sender == addressOracle);
        require(flight.landed);
        require(compareStrings(_luggageID, luggage.id));
        if(_onBelt == true){
            luggage.onBelt = true;
            luggage.timeOnBelt = now;
            checkClaim();
        }
    }
    
    function checkClaim() private {
        require(status == State.active);
        require(flight.landed);
        // check both cases of delay and lost
        if(luggage.onBelt) {
            timeDifference = luggage.timeOnBelt - flight.timeLanded;
            if (timeDifference > timeLimitForPayOut) {
                insuree.addressInsuree.transfer(balance);
                status = State.closed;
            } else {
                addressInsurance.transfer(balance);
                status = State.closed;
            }
        }
    }
    
    function compareStrings(string memory a, string memory b) internal pure returns (bool){
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
    
    function() external payable { }
} 