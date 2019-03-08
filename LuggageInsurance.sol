pragma solidity ^0.5.4;

contract LuggageInsuranceContract {
    
    //create a Flight datatype
    struct Flight {
        //flightNumber for insured luggage travel
        string flightNumber;
        //day of departure
        uint departureDay;
        //flight landed in destination airport
        bool landed;
        //time the flight landed
        uint timeLanded;
        //flight is initialized
        bool initialized;
    }
    
    //create a Luggage datatype
    struct Luggage {
        //luggageID
        string id;
        //is the luggage onBelt in destination airport
        bool onBelt; 
        //timeOnBelt
        uint timeOnBelt;
        //luggage is initialized
        bool initialized;
    }
    
    //create a Insuree datatype
    struct Insuree {
        //insuree is boarded in departure airport
        bool boarded;
        //addressInsuree
        address payable addressInsuree;
    }
    
    // create a State enum 
    enum State {
        //contract inactive till premium not paid, after premium paid active, can be revoked and is closed when insuree or insurance address gets balance
        inactive, active, revoked, closed
    }
    
    //store structs
    Flight public flight;
    Luggage public luggage;
    Insuree public insuree;
    
    //addresse
    address payable private addressInsurance = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
    address private addressOracle = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    //premium
    uint premium= 5 ether;
    //store enum
    State public state;
    //overall contract balance
    uint public balance;
    //time specific storage variables
    uint timeContractActivated;
    uint public revokeTimeLimit = 14 days;
    uint public timeDifference;
    uint public timeLimitLuggageLost = 90 minutes;
    uint public timeLimitForPayOut = 30 minutes;
    
    //modifier for onlyBy condition
    modifier onlyBy(address _account) {
        require(msg.sender == _account, "Sender not authorized.");
        _;
    }
    //modifier for ifState condition
     modifier ifState(State _state) {
        require(_state == state);
        _;
    }
    //modifier for ifLanded condition
    modifier ifLanded() {
        require(flight.landed);
        _;
    }
    
    //event to show a contract for a certain addressInsuree was created
    event ContractCreated(address indexed _addressInsuree, State _state);
    //event to show premium was paid and contract activated
    event PremiumPaid(uint _premium, State _state);
    //event to show insurance amount was paid to insuree
    event InsuranceAmountPaid(uint _balance, address _addressInsuree, State _state);
    //event to show there was no claim as premium was paid to insurance
    event NoClaim(uint _balance, State state);
    
    //constructor 
    constructor() public payable{
        require(addressOracle != msg.sender);
        require(addressInsurance != msg.sender);
        insuree = Insuree(false, msg.sender);
        state = State.inactive;
        //throw Event ContractCreated() 
        emit ContractCreated(msg.sender, state);
    }
    //setFlight() function
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
    //payPremium() function
    function payPremium() public payable onlyBy(insuree.addressInsuree) ifState(State.inactive) {
        require(flight.initialized);
        require(msg.value == premium);
        balance += msg.value;
        state = State.active;
        timeContractActivated = now;
        emit PremiumPaid(msg.value, state);
    }
    //checkInLuggage() function
    function checkInLuggage(string memory _luggageID) public onlyBy(addressOracle) ifState(State.active) {
        require(!luggage.initialized);
        luggage = Luggage(_luggageID, false, 0, true);
    }
    //revokeContract() function
    function revokeContract() public onlyBy(insuree.addressInsuree) ifState(State.active) {
        require(now <= timeContractActivated + revokeTimeLimit);
        require(!insuree.boarded);
        insuree.addressInsuree.transfer(balance);
        state = State.revoked;
    }
    //boardingPassenger() function
    function boardingPassenger(address _addressInsuree) public onlyBy(addressOracle) {
        require(_addressInsuree == insuree.addressInsuree);
        require(luggage.initialized);
        require(!insuree.boarded);
        insuree.boarded = true;
    }
    //setFlightState() function
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
    //setLuggageState() function
    function setLuggageState(string memory _luggageID, bool _onBelt) public onlyBy(addressOracle) ifState(State.active) ifLanded() {
        require(compareStrings(_luggageID, luggage.id));
        require(!luggage.onBelt);
        if(_onBelt == true){
            luggage.onBelt = true;
            luggage.timeOnBelt = now;
            checkClaim();
        }
    }
    //checkClaim() function
    function checkClaim() public payable ifState(State.active) ifLanded() {
        // check both cases of delay and lost
        if(luggage.onBelt) {
            timeDifference = luggage.timeOnBelt - flight.timeLanded;
            if (timeDifference > timeLimitForPayOut) {
                emit InsuranceAmountPaid(balance, insuree.addressInsuree, state);
                insuree.addressInsuree.transfer(balance);
                state = State.closed;
            } else {
                emit NoClaim(balance, state);
                addressInsurance.transfer(balance);
                state = State.closed;
            }
        } else if(now > flight.timeLanded + timeLimitLuggageLost){
            emit InsuranceAmountPaid(balance, insuree.addressInsuree, state);
             insuree.addressInsuree.transfer(balance);
             state = State.closed;
        }
    }
    //getState() function 
    function getState() public view returns (State, bool, bool, bool, bool){
        return (state, flight.landed, flight.initialized, luggage.onBelt, luggage.initialized);
    }
    //compareStrings() function to compare strings with their hashes
    function compareStrings(string memory a, string memory b) internal pure returns (bool){
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
    //fallback function
    function() external payable { }
} 