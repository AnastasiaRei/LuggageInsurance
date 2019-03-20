pragma solidity 0.5.5;
import "./InsuranceContractManager.sol";
import "./oraclize/oraclizeAPI_0.5.sol";

contract LuggageInsuranceContract is usingOraclize {
    
    //create a Flight datatype
    struct Flight {
        //flightNumber for insured luggage travel
        string flightNumber;
        //saves day of departure
        string departureDay;
        uint plannedArrival;
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
    //saves the timeLimit for LuggageLost
    
    InsuranceContractManager.InsuranceContractConditions public insuranceContractConditions;
    // only for testing purposes
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

    function payPremium() public payable onlyBy(insuree.addressInsuree) ifState(State.inactive) {
        require(flight.initialized, "Flight must be initialized.");
        require(msg.value == insuranceContractConditions.premium, "Must send exact premium value.");
        balance += msg.value;
        state = State.active;
        timeContractActivated = now;
        emit PaidPremium(insuree.addressInsuree, msg.value, state);
    }
     
    function checkInLuggage(string memory _luggageID) public onlyBy(addressBackend) ifState(State.active) {
        require(!luggage.initialized);
        luggage = Luggage(_luggageID, false, 0, true);
        emit CheckedInLuggage(insuree.addressInsuree, _luggageID);
    }

    function revokeContract() public onlyBy(insuree.addressInsuree) ifState(State.active) {
        require(now <= timeContractActivated + insuranceContractConditions.revokeTimeLimit);
        require(!insuree.boarded, "Insuree must not have been boarded yet.");
        insuree.addressInsuree.transfer(balance);
        state = State.revoked;
        emit RevokedContract(insuree.addressInsuree, balance, state);
    }

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
                //in case there is no delay throw NoClaim and transfer premium to insurance
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
    
    // TODO: do we need? extend with new data
    //getState() function returns State, flight.landed, flight.initialized, luggage.onBelt and luggage.initialized
    function getState() public view returns (State, bool, bool, bool, bool){
        return (state, flight.landed, flight.initialized, luggage.onBelt, luggage.initialized);
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