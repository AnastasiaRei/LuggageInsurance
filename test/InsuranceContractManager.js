const catchRevert = require("./exceptions.js");
const conditions = require("../migrations/InsuranceContractConditions");
const InsuranceContractManager = artifacts.require(
  "./InsuranceContractManager.sol"
);

contract("InsuranceContractManager", accounts => {
  let insuranceContractManager;
  const owner = accounts[0];
  const insuree = accounts[1];
  const notOwner = accounts[2];
  const backend = accounts[3];

  beforeEach("setup new insurance contract manager", async () => {
    insuranceContractManager = await InsuranceContractManager.deployed();
  });

  it("should deploy with the correct insurance conditions", async () => {
    const deployedConditions = await insuranceContractManager.insuranceContractConditions();
    assert.equal(deployedConditions.premium, conditions.premium);
    assert.equal(deployedConditions.amountDelay, conditions.amountDelay);
    assert.equal(deployedConditions.amountLost, conditions.amountLost);
    assert.equal(
      deployedConditions.revokeTimeLimit,
      conditions.revokeTimeLimit
    );
    assert.equal(
      deployedConditions.timeLimitLuggageLost,
      conditions.timeLimitLuggageLost
    );
    assert.equal(
      deployedConditions.timeLimitForPayOut,
      conditions.timeLimitForPayOut
    );
  });

  it("the owner should change the insurance conditions", async () => {
    await catchRevert(
      insuranceContractManager.setContractConditions(
        conditions.premium,
        conditions.amountDelay,
        conditions.amountLost,
        conditions.revokeTimeLimit,
        conditions.timeLimitLuggageLost,
        conditions.timeLimitForPayOut,
        { from: notOwner }
      ),
      "Owner must change contract conditions."
    );

    insuranceContractManager.setContractConditions(
      conditions.premium,
      conditions.amountDelay,
      conditions.amountLost,
      conditions.revokeTimeLimit,
      conditions.timeLimitLuggageLost,
      100,
      { from: owner }
    );

    const deployedConditions = await insuranceContractManager.insuranceContractConditions();
    assert.equal(deployedConditions.premium, conditions.premium);
    assert.equal(deployedConditions.amountDelay, conditions.amountDelay);
    assert.equal(deployedConditions.amountLost, conditions.amountLost);
    assert.equal(
      deployedConditions.revokeTimeLimit,
      conditions.revokeTimeLimit
    );
    assert.equal(
      deployedConditions.timeLimitLuggageLost,
      conditions.timeLimitLuggageLost
    );
    assert.equal(deployedConditions.timeLimitForPayOut, 100);
  });

  it("should change backend address", async () => {
    await catchRevert(
      insuranceContractManager.setBackendAddress(backend, { from: notOwner }),
      "Owner must change backend address."
    );
    await insuranceContractManager.setBackendAddress(backend);
  });

  it("should get balance", async () => {
    const balance = await insuranceContractManager.getBalance();
    assert.equal(balance, 0);
  });

  it("should receive money", async () => {
    const value = 10000;
    await insuranceContractManager.receiveMoney({ value, from: owner });
    const balance = await insuranceContractManager.getBalance();
    assert.equal(balance, value);
  });

  it("should create the InsuranceContract", async () => {
    await insuranceContractManager.createContract({
      from: insuree
    });

    const addressContract = await insuranceContractManager.insureeToContractMapping(
      insuree
    );

    const isContractInitialized = await insuranceContractManager.initializedContracts(
      addressContract
    );

    assert.equal(isContractInitialized, true);
  });
});