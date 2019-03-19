const conditions = require("./InsuranceContractConditions");
const InsuranceContractManager = artifacts.require("InsuranceContractManager");

module.exports = function(deployer, network, accounts) {
  const accountBackend = accounts[3];

  deployer.deploy(
    InsuranceContractManager,
    accountBackend,
    conditions.premium,
    conditions.amountDelay,
    conditions.amountLost,
    conditions.revokeTimeLimit,
    conditions.timeLimitLuggageLost,
    conditions.timeLimitForPayOut
  );
};