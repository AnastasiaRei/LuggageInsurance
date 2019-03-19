const jsonrpc = "2.0";
const id = 0;
const callback = () => {
  console.log("logg");
};

const send = (method, params = []) =>
  web3.currentProvider.send({ id, jsonrpc, method, params, callback });

const timeTravel = async seconds => {
  await send("evm_increaseTime", [seconds]);
  await send("evm_mine");
};

module.exports = timeTravel;