# Luggage Insurance Smart Contract Example

An insuree is able to procure a luggage Insurance Contract for a certain luggage and flight. The InsuranceContractManager created the luggageInsuranceContracts for this use case and manages them. After the flight is executed and the airplane landed there will be a check for a potential claim. Is the luggage is delayed or lost there will be a transfer of the insuranceAmount to the insuree. 

## Installation

This setup requires a working [node.js environment](https://nodejs.org/en/download/).

1. Clone this repository

   `$git clone https://github.com/AnastasiaRei/LuggageInsurance.git luggage-insurance`

2. Navigate to the folder

   `$cd luggage-insurance`

3. Install the truffle developer tools

   `npm install -g truffle`

4. Install all required packages

   `npm install`

## Running Truffle

Truffle provides you with a local blockchain you can use for local development and helpful tools such as compiling your smart contracts, migrating them to your local blockchain and running tests.

Start the local ethereum blockchain with

`$truffle develop`.

You will see following output:

```
Truffle Develop started at http://127.0.0.1:9545/

Accounts:
(0) 0xcbe1617f9a69e059afc1a8d4437ac5a1cd7a4ca7
(1) 0x53596f35f2d765e637c53aa02240a91d4188f3c6
(2) 0xbb143481ddf23bc5006b2887eeb2a71482ebd08b
(3) 0xb6ab4ee63ac3a7113fd54445819b63b500603092
(4) 0x921ea70d91edf40a60c9d433b21e1ff7ba3fa32f
(5) 0x872cc5944c1ffce807d6d885e7bd18b2d4d73760
(6) 0xf153408f6e3b08dc6aba9966063aed5141981a74
(7) 0x15af5fa3484abe9374ac6e8a772284040405bda3
(8) 0x2a040b49deac25a2ca5ec277c3af7b16e065acd9
(9) 0xcb9ec4ed2f014de614447641a06ab57ee2cec02d

Private Keys:
(0) 9a69e25de77fd50aa7c5dce2f11210f0eec2577507b3c47546d99badf120c638
(1) 41191657e6b7c22030b7add336b477657923ee0c90ef9ace5b9e1da8fbbe3075
(2) 49ac1a93ea7c6afa8b3b05d9b49eb0d92d9e8a78ef94afe76d941d8feea1da2e
(3) 1231eae83042a1354c939f12aef07f57ffd65cac3268b890c8665719ea259b18
(4) f122337e1371869df8dbb91cfb981d40a1a09295c160ba42296d95f3d82cdaf5
(5) e825cb6cc6edb14329fb59f3dba27dd6a11b4775c36d0a4d468cfed9fdcafdc1
(6) cde772fc5e601fa25308c1755b3b90758e75f4e44a2b88b9b249e100a421c087
(7) 1a295a338b7efad198f9a465c5b879989c6a458a7defad35937d1fa61313349f
(8) 095a8c92089756a8da3dc902b7c0e29f7e2090e9db159768c5f667b8970e8570
(9) 82ff99deb601f710f4f13bec31cbc005db7e00ac0fa8edf7fbaa7ace639d3f7b

Mnemonic: seat clip ivory ladder claw thrive ability trend kitten opera round merge

⚠️  Important ⚠️  : This mnemonic was created for you by Truffle. It is not secure.
Ensure you do not use it on production blockchains, or else you risk losing funds.
```

You can compile the smart contracts by typing `compile` inside the truffle developer console.

```
truffle(develop)> compile

Compiling your contracts...
===========================
> Everything is up to date, there is nothing to compile.

truffle(develop)> compile

Compiling your contracts...
===========================
> Compiling ./contracts/InsuranceContractManager.sol
> Compiling ./contracts/LuggageInsuranceContract.sol
> Compiling ./contracts/Migrations.sol
> Compiling ./contracts/oraclize/oraclizeAPI_0.5.sol
```

You can migrate the smart contracts into the local truffle blockchain by typing `migrate` inside the truffle developer console.

```
truffle(develop)> migrate

Starting migrations...
======================
> Network name:    'develop'
> Network id:      5777
> Block gas limit: 6721975


1_initial_migration.js
======================

   Deploying 'Migrations'
   ----------------------
   > transaction hash:    0x99db2fc5f01f9ff507fac7d7d06fab3ea91826f5863ac5a9d60901edb001b0a4
   > Blocks: 0            Seconds: 0
   > contract address:    0xeC16B3806477053AD4f55e4b90E81a6db68CA6a8
   > account:             0xCbe1617f9A69e059Afc1a8d4437aC5a1cd7a4CA7
   > balance:             99.75577032
   > gas used:            273162
   > gas price:           20 gwei
   > value sent:          0 ETH
   > total cost:          0.00546324 ETH


   > Saving migration to chain.
   > Saving artifacts
   -------------------------------------
   > Total cost:          0.00546324 ETH


2_add_insurance_contract_manager.js
===================================

   Deploying 'InsuranceContractManager'
   ------------------------------------
   > transaction hash:    0x22f55fd451c1c1237926bcf92e4961ee429a2703b185b75e0871ea3e16e2777f
   > Blocks: 0            Seconds: 0
   > contract address:    0xEC8Dc7BCC2707Ac4582c247BF608E953B115a512
   > account:             0xCbe1617f9A69e059Afc1a8d4437aC5a1cd7a4CA7
   > balance:             99.6423909
   > gas used:            5626943
   > gas price:           20 gwei
   > value sent:          0 ETH
   > total cost:          0.11253886 ETH


   > Saving migration to chain.
   > Saving artifacts
   -------------------------------------
   > Total cost:          0.11253886 ETH


Summary
=======
> Total deployments:   2
> Final cost:          0.1180021 ETH
```

## Running tests

In order to run the test you need to [open the truffle developer tools](##running-truffle). As soon as this is started, open another terminal window in the same directory.
You will

`$npm run bridge`

It is up and running if you see the following:

```
$npm run bridge

> luggage-insurance@1.0.0 bridge /Users/cheyer/Code/LuggageInsurance
> ethereum-bridge -a 9 -H 127.0.0.1 -p 9545 --dev

Please wait...
[2019-03-23T18:05:43.623Z] WARN --dev mode active, contract myid checks and pending queries are skipped, use this only when testing, not in production
[2019-03-23T18:05:43.623Z] INFO you are running ethereum-bridge - version: 0.6.2
[2019-03-23T18:05:43.624Z] INFO saving logs to: ./bridge.log
[2019-03-23T18:05:43.624Z] INFO using active mode
[2019-03-23T18:05:43.624Z] INFO Connecting to eth node http://127.0.0.1:9545
[2019-03-23T18:05:45.084Z] INFO connected to node type EthereumJS TestRPC/v2.5.1/ethereum-js
[2019-03-23T18:05:45.414Z] WARN Using 0xcb9ec4ed2f014de614447641a06ab57ee2cec02d to query contracts on your blockchain, make sure it is unlocked and do not use the same address to deploy your contracts
[2019-03-23T18:05:45.499Z] INFO deploying the oraclize connector contract...
[2019-03-23T18:05:55.832Z] INFO connector deployed to: 0x974accb85a6823167d8bf0f541ae8c0dfe3db6cd
[2019-03-23T18:05:55.916Z] INFO deploying the address resolver with a deterministic address...
[2019-03-23T18:06:16.799Z] INFO address resolver (OAR) deployed to: 0x6f485c8bf6fc43ea212e93bbf8ce046c7f1cb475
[2019-03-23T18:06:16.800Z] INFO updating connector pricing...
[2019-03-23T18:06:27.468Z] INFO successfully deployed all contracts
[2019-03-23T18:06:27.473Z] INFO instance configuration file saved to /Users/cheyer/Code/LuggageInsurance/node_modules/ethereum-bridge/config/instance/oracle_instance_20190323T190627.json

Please add this line to your contract constructor:

OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);

[2019-03-23T18:06:27.477Z] WARN re-org block listen is disabled
[2019-03-23T18:06:27.477Z] INFO Listening @ 0x974accb85a6823167d8bf0f541ae8c0dfe3db6cd (Oraclize Connector)

(Ctrl+C to exit)
```

Now navigate back to the truffle developer tools and run the tests by running this command:

`truffle(develop)> test`

You will see something like this:

```
Contract: InsuranceContractManager
    ✓ should deploy with the correct insurance conditions
    ✓ the owner should change the insurance conditions (73ms)
    ✓ should change backend address (58ms)
    ✓ should get balance
    ✓ should receive money (48ms)
    ✓ should create the InsuranceContract (86ms)

  Contract: InsuranceContractManager
    - should calaculate gas cost of InsuranceContractManger related functions

  Contract: LuggageInsuranceContract
    ✓ front end can get contract's states
    ✓ insuree can set flight (112ms)
    ✓ insuree can pay premium (157ms)
    ✓ backend can check in luggage (151ms)
    ✓ backend can board passenger (13122ms)
    ✓ insuree cannot revoke after boarding (303ms)
    ✓ insuree can revoke (130ms)
    ✓ oracle can set flight data (12660ms)
    ✓ backend can set luggage state (12981ms)
    ✓ check claim: no claim (17855ms)
    ✓ check claim: delayed (22688ms)
    ✓ check claim: lost (17826ms)

  Contract: LuggageInsuranceContract
    - should calaculate gas cost of LuggageInsuranceContract related functions


  18 passing (2m)
  2 pending
```
