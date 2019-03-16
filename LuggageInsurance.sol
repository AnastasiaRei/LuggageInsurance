pragma solidity 0.5.5;
import "./InsuranceContractManager.sol";

contract LuggageInsuranceContract {
    
    //create a Flight datatype
    struct Flight {
        //flightNumber for insured luggage travel
        string flightNumber;
        //saves day of departure
        uint departureDay;
        //saves state flight landed in destination airport
        bool landed;
        //saves timestamp the flight is landed
        uint timeLanded;
        //flight is initialized
        bool initialized;
    }
    
    //create a Luggage datatype
    struct Luggage {
        //saves luggageID
        string id;
        //is the luggage onBelt in destination airport
        bool onBelt; 
        //saves timestamp when luggage is on belt
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
    
    enum ClaimState{
        none, delay, lost
    }
    
    //store structs
    Flight public flight;
    Luggage public luggage;
    Insuree public insuree;
    
    // save a InsuranceContractManager
    InsuranceContractManager insuranceContractManagerInstance;
    
    address private addressOracle = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    //premium
    uint premium= 5 ether;
    //store enum
    State public state;
    ClaimState public claimState;
    //overall contract balance
    uint public balance;
    //saves time when the Smart Contract is activated
    uint timeContractActivated;
    //saves the timeLimit for a revoke
    uint public revokeTimeLimit = 14 days;
    //saves the timeDifference between flight.timelanded and luggage.timeOnBelt
    uint public timeDifference;
    //saves the timeLimit for LuggageLost
    uint public timeLimitLuggageLost = 90 minutes;
    //saves the timeLimit for PayOut
    uint public timeLimitForPayOut = 20 seconds;
    
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
    event NoClaim(uint _balance, State _state);
    
    //constructor 
    constructor(address payable addressInsuranceContractManager) public payable{
        require(addressOracle != msg.sender);
        insuree = Insuree(false, msg.sender);
        insuranceContractManagerInstance = InsuranceContractManager(addressInsuranceContractManager);
        insuranceContractManagerInstance.saveContract(insuree.addressInsuree);
        state = State.inactive;
        claimState = ClaimState.none;
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
        //throw Event ContractCreated() 
        emit ContractCreated(msg.sender, state);
    }
    //payPremium() function
    function payPremium() public payable onlyBy(insuree.addressInsuree) ifState(State.inactive) {
        require(flight.initialized);
        require(msg.value == premium);
        balance += msg.value;
        state = State.active;
        timeContractActivated = now;
         //throw Event PremiumPaid() 
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
        //compare the hashes of two strings in order to find out whether status is landed
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
        //check state onBelt
        if(_onBelt == true){
            luggage.onBelt = true;
            luggage.timeOnBelt = now;
            checkClaim();
        }
    }
    function checkClaim() public payable ifState(State.active) ifLanded() {
        //send premium to InsuranceContractManager Account
        insuranceContractManagerInstance.receiveMoney.value(balance)();
         // check luggage delay
        if(luggage.onBelt) {
            timeDifference = luggage.timeOnBelt - flight.timeLanded;
            if (timeDifference > timeLimitForPayOut) {
                //in case there is an delay throw InsuranceAmountPaid() and transfer insurance amount to insuree
                state = State.closed;
                claimState = ClaimState.delay;
                insuranceContractManagerInstance.payout();
                emit InsuranceAmountPaid(balance, insuree.addressInsuree, state);
            } else {
                //in case there is no delay throw NoClaim and transfer premium to insurance
                state = State.closed;
                emit NoClaim(balance, state);
            }
            //check luggage lost
        } else if(now > flight.timeLanded + timeLimitLuggageLost){
            //in case luggage is lost throw InsuranceAmountPaid and transfer insurance amount
            state = State.closed;
            claimState = ClaimState.lost;
            insuranceContractManagerInstance.payout();
            emit InsuranceAmountPaid(balance, insuree.addressInsuree, state);
        }
    }
    
    //getState() function returns State, flight.landed, flight.initialized, luggage.onBelt and luggage.initialized
    function getState() public view returns (State, bool, bool, bool, bool){
        return (state, flight.landed, flight.initialized, luggage.onBelt, luggage.initialized);
    }
    
    function getAddressInsuree() public view returns(address payable) {
        return insuree.addressInsuree;
    }
    //compareStrings() function to compare strings by their hashes
    function compareStrings(string memory a, string memory b) internal pure returns (bool){
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
    //fallback function
    function() external payable { }
} 