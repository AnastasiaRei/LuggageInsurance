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

const flightNumber = "LH2037";
const departureDay = "2019-03-23";
const plannedArrival = 2345;
const luggageId = "luggage-id";
const { premium } = conditions;

contract("LuggageInsuranceContract", accounts => {
  const insuree = accounts[1];
  const notInsuree = accounts[2];
  const backend = accounts[3];
  let instance;
  let addressContract;
  let instanceMethods;
  let instanceEvents;

  beforeEach("setup new insurance contract", async () => {
    const insuranceContractManager = await InsuranceContractManager.deployed();

    await insuranceContractManager.createContract(true, {
      from: insuree
    });

    addressContract = await insuranceContractManager.insureeToContractMapping(
      insuree
    );

    instance = await LuggageInsuranceContract.at(addressContract);

    const { contract } = instance;

    const { methods, events } = new web3.eth.Contract(
      contract._jsonInterface,
      contract._address
    );

    instanceMethods = methods;
    instanceEvents = events;

    const state = await instance.state();
    assert.equal(state, 0);
  });

  it("front end can get contract's states", async () => {
    const state = await instance.getState();

    assert.equal(state[0], 0);
    assert.equal(state[1], 0);
    assert.equal(state[2], false);
    assert.equal(state[3], false);
    assert.equal(state[4], false);
    assert.equal(state[5], false);
  });

  it("insuree can set flight", async () => {
    await catchRevert(
      instance.setFlight("LH123", "1234", 2345, {
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
      "Must be a valid insuree address."
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

    const flight = await instance.flight();
    assert.equal(flight.landed, true);

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

    await instance.revokeContract({ from: insuree });

    const state = await instance.state();
    assert.equal(state, 2);
  });

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

contract.skip("LuggageInsuranceContract", accounts => {
  const insuree = accounts[1];
  const backend = accounts[3];

  it("should calaculate gas cost of LuggageInsuranceContract related functions", async () => {
    InsuranceContractManager.web3.eth.getGasPrice(async (error, result) => {
      const gasPrice = Number(result);
      console.log(`Gas Price is ${gasPrice} wei`);

      const insuranceContractManager = await InsuranceContractManager.deployed();

      await insuranceContractManager.createContract(true, {
        from: insuree
      });

      const addressContract = await insuranceContractManager.insureeToContractMapping(
        insuree
      );

      const instance = await LuggageInsuranceContract.at(addressContract);

      const { contract } = instance;

      const { events } = new web3.eth.Contract(
        contract._jsonInterface,
        contract._address
      );

      const priceGetState = await instance.getState.estimateGas();
      const priceState = await instance.state.estimateGas();
      const priceClaimState = await instance.claimState.estimateGas();
      const priceFlight = await instance.flight.estimateGas();
      const priceLuggage = await instance.luggage.estimateGas();
      const priceInsuree = await instance.insuree.estimateGas();
      const priceGetAddressInsuree = await instance.getAddressInsuree.estimateGas();
      const priceBalance = await instance.balance.estimateGas();
      const priceTimeDifference = await instance.timeDifference.estimateGas();
      const priceSetFlight = await instance.setFlight.estimateGas(
        flightNumber,
        departureDay,
        plannedArrival,
        {
          from: insuree
        }
      );
      await instance.setFlight(flightNumber, departureDay, plannedArrival, {
        from: insuree
      });
      const pricePayPremium = await instance.payPremium.estimateGas({
        from: insuree,
        value: premium
      });
      instance.payPremium({
        from: insuree,
        value: premium
      });

      const priceRevoke = await instance.revokeContract.estimateGas({
        from: insuree
      });

      const priceCheckInLuggage = await instance.checkInLuggage.estimateGas(
        luggageId,
        {
          from: backend
        }
      );
      await instance.checkInLuggage(luggageId, {
        from: backend
      });

      const priceBoardingPassenger = await instance.boardingPassenger.estimateGas(
        insuree,
        {
          from: backend
        }
      );
      await instance.boardingPassenger(insuree, {
        from: backend
      });

      console.log("getState", priceGetState);
      console.log("state", priceState);
      console.log("claimState", priceClaimState);
      console.log("flight", priceFlight);
      console.log("luggage", priceLuggage);
      console.log("insuree", priceInsuree);
      console.log("balance", priceBalance);
      console.log("timeDifference", priceTimeDifference);
      console.log("getAddressInsuree", priceGetAddressInsuree);
      console.log("setFlight", priceSetFlight);
      console.log("payPremium", pricePayPremium);

      console.log("revokeContract", priceRevoke);
      console.log("checkInLuggage", priceCheckInLuggage);
      console.log("boardingPassenger", priceBoardingPassenger);

      const {
        returnValues: { status }
      } = await waitForEvent(events.LogFlightStatus);
      assert.equal(status, "LD");

      const priceCheckClaim = await instance.checkClaim.estimateGas();
      console.log("checkClaim", priceCheckClaim);

      await timeTravel(conditions.timeLimitForPayOut + 1);

      const priceSetLuggageState = await instance.setLuggageState.estimateGas(
        luggageId,
        true,
        {
          from: backend
        }
      );
      console.log("setLuggageState", priceSetLuggageState);

      assert.equal(gasPrice, 2000000000);
    });
  });
});
