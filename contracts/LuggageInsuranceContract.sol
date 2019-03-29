pragma solidity 0.5.5;
import "./InsuranceContractManager.sol";
import "./oraclize/oraclizeAPI_0.5.sol";

contract LuggageInsuranceContract is usingOraclize {
    
    //create a Flight datatype
    struct Flight {
        string flightNumber;
        string departureDay;
        uint plannedArrival;
        bool landed;
        uint timeLanded;
        bool initialized;
    }
    
    //create a Luggage datatype
    struct Luggage {
        string id;
        bool onBelt; 
        uint timeOnBelt;
        bool initialized;
    }
    
    //create a Insuree datatype
    struct Insuree {
        bool boarded;
        address payable addressInsuree;
    }
    
    //overall Contract State
    enum State {
        inactive, active, revoked, closed
    }
    //Claim State
    enum ClaimState{
        none, delay, lost
    }
    
    //store structs
    Flight public flight;
    Luggage public luggage;
    Insuree public insuree;
    
    //save a InsuranceContractManager
    InsuranceContractManager insuranceContractManagerInstance;
    
    address public addressBackend;
    
    //store enum
    State public state;
    ClaimState public claimState;
    //overall contract balance
    uint public balance;
    //saves time when the Smart Contract is activated
    uint timeContractActivated;
    
    //saves the timeDifference between flight.timelanded and luggage.timeOnBelt
    uint public timeDifference;

    InsuranceContractManager.InsuranceContractConditions public insuranceContractConditions;
    //only for testing purposes
    bool public test;
    
    
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
    
    event BoardedPassenger(address indexed addressInsuree, address indexed addressContract);
    event CheckedInLuggage(address indexed addressInsuree, string luggageId);
    event FlightLanded(address addressLuggageContract, address addressInsuree, string flightNumber, string departureDay);
    event LogFlightStatus(string status, string flightNumber, string departureDay);
    event LogNewOraclizeQuery(string description);
    event LuggageOnBelt(string luggageId, uint timeOnBelt);
    event NoClaim(address indexed addressInsuree, address indexed addressContract, State state);
    event PaidPremium(address indexed addressInsuree, uint premium, State state);
    event RevokedContract(address indexed addressInsuree, uint premium, State state);
    event SelectedFlight(
        address indexed addressInsuree,
        address indexed addressContract,
        string flightNumber,
        string departureDay,
        uint plannedArrival
    );

    constructor(
        address payable addressInsuree,
        address backend,
        uint premium,
        uint amountDelay,
        uint amountLost,
        uint revokeTimeLimit,
        uint timeLimitLuggageLost,
        uint timeLimitForPayOut,
        bool isTest
    ) public payable {
        insuree = Insuree(false, addressInsuree);
        insuranceContractManagerInstance = InsuranceContractManager(msg.sender);
        
        insuranceContractConditions = InsuranceContractManager.InsuranceContractConditions(
            premium,
            amountDelay,
            amountLost,
            revokeTimeLimit,
            timeLimitLuggageLost,
            timeLimitForPayOut
        );
        addressBackend = backend;
        state = State.inactive;
        claimState = ClaimState.none;
        test = isTest;
    }
    //sets the Flight details
    function setFlight(
        string memory flightNumber,
        string memory departureDay,
        uint plannedArrival
    ) public onlyBy(insuree.addressInsuree) ifState(State.inactive){
        flight = Flight(
            flightNumber,
            departureDay,
            plannedArrival,
            false,
            0, 
            true
        );
        emit SelectedFlight(
            insuree.addressInsuree,
            address(this),
            flightNumber,
            departureDay,
            plannedArrival
        );
    }
    // transfers premium
    function payPremium() public payable onlyBy(insuree.addressInsuree) ifState(State.inactive) {
        require(flight.initialized, "Flight must be initialized.");
        require(msg.value == insuranceContractConditions.premium, "Must send exact premium value.");
        balance += msg.value;
        state = State.active;
        timeContractActivated = now;
        emit PaidPremium(insuree.addressInsuree, msg.value, state);
    }
    //sets the Luggage details
    function checkInLuggage(string memory _luggageID) public onlyBy(addressBackend) ifState(State.active) {
        require(!luggage.initialized);
        luggage = Luggage(_luggageID, false, 0, true);
        emit CheckedInLuggage(insuree.addressInsuree, _luggageID);
    }
    //revokes the contract and sends the premium back
    function revokeContract() public onlyBy(insuree.addressInsuree) ifState(State.active) {
        require(now <= timeContractActivated + insuranceContractConditions.revokeTimeLimit);
        require(!insuree.boarded, "Insuree must not have been boarded yet.");
        insuree.addressInsuree.transfer(balance);
        state = State.revoked;
        emit RevokedContract(insuree.addressInsuree, balance, state);
    }
    //sets insuree.boarded and triggers requestFlightState()
    function boardingPassenger(address _addressInsuree) public onlyBy(addressBackend) {
        require(_addressInsuree == insuree.addressInsuree, "Must be a valid insuree address.");
        require(luggage.initialized);
        require(!insuree.boarded);
        insuree.boarded = true;
        emit BoardedPassenger(insuree.addressInsuree, address(this));
        uint triggerTimeout = flight.plannedArrival - now;
        if(test) {
            triggerTimeout = 1;
        }
        requestFlightState(triggerTimeout);
    }
    //callback to get the results from oraclize query
    function __callback(bytes32 myid, string memory result) public onlyBy(oraclize_cbAddress()) {
        emit LogFlightStatus(result, flight.flightNumber, flight.departureDay);
        
        if(compareStrings(result, "LD")) {
            flight.landed = true;
            flight.timeLanded = now;
            emit FlightLanded(address(this), insuree.addressInsuree, flight.flightNumber, flight.departureDay);
        } else {
            // update flight state all 10 minutes as long as the flight is not landed
            requestFlightState(600);
        }
    }
    //API Call, asks oraclize to do a query for flightStatus with a certain URL
    function requestFlightState(uint triggerTimeout) private {
        string memory query = strConcat(
            "json(https://orcalize-backend-test.herokuapp.com/flight?api_token=b03bb840bb7b8fe31e0b69ea8c24aab649450c0aa7fe22656cbf1e980a1b729a&flightnumber=",
            flight.flightNumber,
            '&date=',
            flight.departureDay,
            ").data.FlightStatusResource.Flights.Flight.FlightStatus.Code"
        );
        oraclize_query(triggerTimeout, "URL", query);
        emit LogNewOraclizeQuery("Oraclize query was sent, standing by for the answer...");
    }
    //sets luggage.onBelt
    function setLuggageState(string memory _luggageID, bool _onBelt) public onlyBy(addressBackend) ifState(State.active) ifLanded() {
        require(compareStrings(_luggageID, luggage.id), "Must be same luggage id.");
        require(!luggage.onBelt);
        //check state onBelt
        if(_onBelt == true){
            luggage.onBelt = true;
            luggage.timeOnBelt = now;
            emit LuggageOnBelt(_luggageID, luggage.timeOnBelt);
            checkClaim();
        }
    }
    //checks whether a claim is happened and transfers amounts
    function checkClaim() public payable ifState(State.active) ifLanded() {
        //send premium to InsuranceContractManager Account
        insuranceContractManagerInstance.receiveMoney.value(balance)();
         // check luggage delay
        if(luggage.onBelt) {
            timeDifference = luggage.timeOnBelt - flight.timeLanded;
            if (timeDifference > insuranceContractConditions.timeLimitForPayOut) {
                //in case there is an delay transfer insurance amount to insuree
                state = State.closed;
                claimState = ClaimState.delay;
                insuranceContractManagerInstance.payout(insuranceContractConditions.amountDelay);
            } else {
                //in case there is no delay throw NoClaim
                state = State.closed;
                emit NoClaim(insuree.addressInsuree, address(this), state);
            }
            //check luggage lost
        } else if(now > flight.timeLanded + insuranceContractConditions.timeLimitLuggageLost){
            //in case luggage is lost transfer insurance amount to insuree
            state = State.closed;
            claimState = ClaimState.lost;
            insuranceContractManagerInstance.payout(insuranceContractConditions.amountLost);
        }
    }
    
    function getState() public view returns (State, ClaimState, bool, bool, bool, bool){
        return (state, claimState, flight.landed, flight.initialized, luggage.onBelt, luggage.initialized);
    }
    
    function getAddressInsuree() public view returns(address payable) {
        return insuree.addressInsuree;
    }

    // compare strings by their hashes
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function() external payable { }
} 