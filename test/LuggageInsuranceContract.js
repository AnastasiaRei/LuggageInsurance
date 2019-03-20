const Web3 = require("web3");
const catchRevert = require("./exceptions.js");
const timeTravel = require("./timeTravel.js");
const { waitForEvent } = require("./utils");
const conditions = require("../migrations/InsuranceContractConditions");
const web3 = new Web3(
  new Web3.providers.WebsocketProvider("ws://localhost:9545")
);
const InsuranceContractManager = artifacts.require(
  "./InsuranceContractManager.sol"
);
const LuggageInsuranceContract = artifacts.require(
  "./LuggageInsuranceContract.sol"
);

contract("LuggageInsuranceContract", accounts => {
  const insuree = accounts[1];
  const notInsuree = accounts[2];
  const backend = accounts[3];
  const flightNumber = "LH1234";
  const departureDay = 1234;
  const plannedArrival = 2345;
  const luggageId = "luggage-id";
  const premium = conditions.premium;
  let instance;
  let addressContract;
  let instanceMethods;
  let instanceEvents;

  beforeEach("setup new insurance contract", async () => {
    const insuranceContractManager = await InsuranceContractManager.deployed();

    await insuranceContractManager.createContract({
      from: insuree
    });

    addressContract = await insuranceContractManager.insureeToContractMapping(
      insuree
    );
    // console.log("insuree", insuree);
    // console.log("manager", insuranceContractManager.address);

    instance = await LuggageInsuranceContract.at(addressContract);

    // console.log("meine gute", instance);
    // console.log("meine methods", instance.methods);
    // console.log("meine events", instance.events);

    const contract = instance.contract;

    const { methods, events } = new web3.eth.Contract(
      contract._jsonInterface,
      contract._address
    );
    // console.log("methods", methods);
    // console.log("events", events);
    instanceMethods = methods;
    instanceEvents = events;

    const state = await instance.state();
    assert.equal(state, 0);
  });

  it("insuree can set flight", async () => {
    await catchRevert(
      instance.setFlight("LH123", 1234, 2345, {
        from: notInsuree
      }),
      "Sender not authorized."
    );

    await instance.setFlight(flightNumber, departureDay, plannedArrival, {
      from: insuree
    });
    const flight = await instance.flight();
    assert.equal(flight.flightNumber, flightNumber);
    assert.equal(flight.departureDay, departureDay);
    assert.equal(flight.plannedArrival, plannedArrival);
    assert.equal(flight.landed, false);
  });

  it("insuree can pay premium", async () => {
    await instance.setFlight(flightNumber, departureDay, plannedArrival, {
      from: insuree
    });

    await catchRevert(
      instance.payPremium({
        from: notInsuree
      }),
      "Sender not authorized."
    );

    await catchRevert(
      instance.payPremium({
        from: insuree
      }),
      "Must send exact premium value."
    );

    instance.payPremium({
      from: insuree,
      value: premium
    });

    const balance = await instance.balance();
    assert.equal(balance, premium);
    const state = await instance.state();
    assert.equal(state, 1);
  });

  it("backend can check in luggage", async () => {
    await instance.setFlight(flightNumber, departureDay, plannedArrival, {
      from: insuree
    });
    instance.payPremium({
      from: insuree,
      value: premium
    });

    await catchRevert(
      instance.checkInLuggage(luggageId, {
        from: insuree
      }),
      "Sender not authorized."
    );

    await instance.checkInLuggage(luggageId, {
      from: backend
    });

    const luggage = await instance.luggage();
    assert.equal(luggage.id, luggageId);
    assert.equal(luggage.initialized, true);
  });

  it("backend can board passenger", async () => {
    await instance.setFlight(flightNumber, departureDay, plannedArrival, {
      from: insuree
    });
    instance.payPremium({
      from: insuree,
      value: premium
    });
    await instance.checkInLuggage(luggageId, {
      from: backend
    });

    await catchRevert(
      instance.boardingPassenger(insuree, {
        from: insuree
      }),
      "Sender not authorized."
    );

    await catchRevert(
      instance.boardingPassenger(backend, {
        from: backend
      }),
      "Must send address of insuree."
    );

    await instance.boardingPassenger(insuree, {
      from: backend
    });

    const {
      returnValues: { description }
    } = await waitForEvent(instanceEvents.LogNewOraclizeQuery);

    assert.strictEqual(
      description,
      "Oraclize query was sent, standing by for the answer...",
      "Oraclize query incorrectly logged!"
    );

    const {
      returnValues: { status }
    } = await waitForEvent(instanceEvents.LogFlightStatus);
    assert.equal(status, "LD");

    const {
      returnValues: { addressLuggageContract, addressInsuree }
    } = await waitForEvent(instanceEvents.FlightLanded);
    assert.equal(addressLuggageContract, addressContract);
    assert.equal(addressInsuree, insuree);

    const flightStatus = await instance.flightStatus();
    assert.equal(flightStatus, "LD");

    const insur = await instance.insuree();
    assert.equal(insur.boarded, true);
  });

  it("insuree cannot revoke after boarding", async () => {
    await instance.setFlight(flightNumber, departureDay, plannedArrival, {
      from: insuree
    });
    instance.payPremium({
      from: insuree,
      value: premium
    });
    await instance.checkInLuggage(luggageId, {
      from: backend
    });
    await instance.boardingPassenger(insuree, {
      from: backend
    });

    await catchRevert(
      instance.revokeContract({ from: insuree }),
      "Insuree must not have been boarded yet."
    );
  });

  // TODO check real transaction value flow
  it("insuree can revoke", async () => {
    await instance.setFlight(flightNumber, departureDay, plannedArrival, {
      from: insuree
    });
    instance.payPremium({
      from: insuree,
      value: premium
    });
    await instance.checkInLuggage(luggageId, {
      from: backend
    });

    // const instanceBalanceBefore = await instance.balance();
    // const insureeBalanceBefore = await web3.eth.getBalance(insuree);
    await instance.revokeContract({ from: insuree });
    // const instanceBalanceAfter = await instance.balance();
    // const insureeBalanceAfter = await web3.eth.getBalance(insuree);

    const state = await instance.state();
    assert.equal(state, 2);
    // assert.equal(
    //   instanceBalanceAfter,
    //   instanceBalanceBefore - conditions.premium
    // );
    // assert.equal(
    //   insureeBalanceAfter,
    //   insureeBalanceBefore + conditions.premium
    // );
  });

  // TODO oracle and interval
  it("oracle can set flight data", async () => {
    await instance.setFlight(flightNumber, departureDay, plannedArrival, {
      from: insuree
    });
    instance.payPremium({
      from: insuree,
      value: premium
    });
    await instance.checkInLuggage(luggageId, {
      from: backend
    });
    await instance.boardingPassenger(insuree, {
      from: backend
    });

    const {
      returnValues: { status }
    } = await waitForEvent(instanceEvents.LogFlightStatus);
    assert.equal(status, "LD");

    const flight = await instance.flight();
    assert.equal(flight.landed, true);
  });

  it("backend can set luggage state", async () => {
    await instance.setFlight(flightNumber, departureDay, plannedArrival, {
      from: insuree
    });
    instance.payPremium({
      from: insuree,
      value: premium
    });
    await instance.checkInLuggage(luggageId, {
      from: backend
    });
    await instance.boardingPassenger(insuree, {
      from: backend
    });

    const {
      returnValues: { status }
    } = await waitForEvent(instanceEvents.LogFlightStatus);
    assert.equal(status, "LD");

    await catchRevert(
      instance.setLuggageState(luggageId, true, {
        from: insuree
      }),
      "Sender not authorized."
    );
    await catchRevert(
      instance.setLuggageState("luggageId", true, {
        from: backend
      }),
      "Must be same luggage id."
    );

    await instance.setLuggageState(luggageId, true, {
      from: backend
    });

    const luggage = await instance.luggage();
    assert.equal(luggage.onBelt, true);
  });

  it("check claim: no claim", async () => {
    await instance.setFlight(flightNumber, departureDay, plannedArrival, {
      from: insuree
    });
    instance.payPremium({
      from: insuree,
      value: premium
    });
    await instance.checkInLuggage(luggageId, {
      from: backend
    });
    await instance.boardingPassenger(insuree, {
      from: backend
    });

    const {
      returnValues: { status }
    } = await waitForEvent(instanceEvents.LogFlightStatus);
    assert.equal(status, "LD");

    await instance.setLuggageState(luggageId, true, {
      from: backend
    });

    const state = await instance.state();
    const claimState = await instance.claimState();
    assert.equal(state, 3);
    assert.equal(claimState, 0);
  });

  it("check claim: delayed", async () => {
    await instance.setFlight(flightNumber, departureDay, plannedArrival, {
      from: insuree
    });
    instance.payPremium({
      from: insuree,
      value: premium
    });
    await instance.checkInLuggage(luggageId, {
      from: backend
    });
    await instance.boardingPassenger(insuree, {
      from: backend
    });

    const {
      returnValues: { status }
    } = await waitForEvent(instanceEvents.LogFlightStatus);
    assert.equal(status, "LD");

    await timeTravel(conditions.timeLimitForPayOut + 1);

    await instance.setLuggageState(luggageId, true, {
      from: backend
    });

    const state = await instance.state();
    const claimState = await instance.claimState();
    assert.equal(state, 3);
    assert.equal(claimState, 1);
  });

  it("check claim: lost", async () => {
    await instance.setFlight(flightNumber, departureDay, plannedArrival, {
      from: insuree
    });
    instance.payPremium({
      from: insuree,
      value: premium
    });
    await instance.checkInLuggage(luggageId, {
      from: backend
    });
    await instance.boardingPassenger(insuree, {
      from: backend
    });

    const {
      returnValues: { status }
    } = await waitForEvent(instanceEvents.LogFlightStatus);
    assert.equal(status, "LD");

    await timeTravel(conditions.timeLimitLuggageLost + 1);

    await instance.checkClaim({
      from: backend
    });

    const state = await instance.state();
    const claimState = await instance.claimState();
    assert.equal(state, 3);
    assert.equal(claimState, 2);
  });
});
