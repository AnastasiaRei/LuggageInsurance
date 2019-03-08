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
    uint premium= 100000000000000000 wei;
    State public state;
    uint timeContractActivated;
    uint public balance;
    uint public revokeTimeLimit = 14 days;
    uint public timeDifference;
    uint public timeLimitLuggageLost = 90 minutes;
    uint public timeLimitForPayOut = 30 minutes;
    
    modifier onlyBy(address _account) {
        require(msg.sender == _account, "Sender not authorized.");
        _;
    }
    
     modifier ifState(State _state) {
        require(_state == state);
        _;
    }
    
    modifier ifLanded() {
        require(flight.landed);
        _;
    }
        
    constructor() public payable{
        insuree = Insuree(false, msg.sender);
        state = State.inactive;
    }
    
    function setFlight(
        string memory flightNumber,
        uint departureDay
    ) public onlyBy(insuree.addressInsuree) ifState(State.inactive){
        flight = Flight(
            flightNumber,
            departureDay,
            false,
            0, 
            true
        );
    }
    
    function payPremium() public payable onlyBy(insuree.addressInsuree) ifState(State.inactive) {
        require(flight.initialized);
        require(msg.value == premium);
        balance += msg.value;
        state = State.active;
        timeContractActivated = now;
    }

    function checkInLuggage(string memory _luggageID) public onlyBy(addressOracle) ifState(State.active) {
        require(!luggage.initialized);
        luggage = Luggage(_luggageID, false, 0, true);
    }
    
    function revokeContract() public onlyBy(insuree.addressInsuree) ifState(State.active) {
        require(now <= timeContractActivated + revokeTimeLimit);
        require(!insuree.boarded);
        insuree.addressInsuree.transfer(balance);
        state = State.revoked;
    }
    
    function boardingPassenger(address _addressInsuree) public onlyBy(addressOracle) {
        require(_addressInsuree == insuree.addressInsuree);
        require(luggage.initialized);
        require(!insuree.boarded);
        insuree.boarded = true;
    }
    
    function setFlightState(string memory flightState) public onlyBy(addressOracle) {
        require(insuree.boarded);
        require(!flight.landed);
        if(compareStrings(flightState, "landed")){
            flight.landed = true;
            flight.timeLanded = now;
            //setTimeOut function that triggers checkcailm function 1 hours after time landed
        }else {
            //ask oracle again in some time
        }
    }
    
    function setLuggageState(string memory _luggageID, bool _onBelt) public onlyBy(addressOracle) ifState(State.active) ifLanded() {
        require(compareStrings(_luggageID, luggage.id));
        require(!luggage.onBelt);
        if(_onBelt == true){
            luggage.onBelt = true;
            luggage.timeOnBelt = now;
            checkClaim();
        }
    }
    
    function checkClaim() public ifState(State.active) ifLanded() {
        // check both cases of delay and lost
        if(luggage.onBelt) {
            timeDifference = luggage.timeOnBelt - flight.timeLanded;
            if (timeDifference > timeLimitForPayOut) {
                insuree.addressInsuree.transfer(balance);
                state = State.closed;
            } else {
                addressInsurance.transfer(balance);
                state = State.closed;
            }
        } else if(now > flight.timeLanded + timeLimitLuggageLost){
             insuree.addressInsuree.transfer(balance);
             state = State.closed;
        }
    }
    
    function getState() public view returns (State, bool, bool, bool, bool){
        return (state, flight.landed, flight.initialized, luggage.onBelt, luggage.initialized);
    }
    
    function compareStrings(string memory a, string memory b) internal pure returns (bool){
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
    
    function() external payable { }
} 