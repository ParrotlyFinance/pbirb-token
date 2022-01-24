// const ParrotlyFinance = artifacts.require("ParrotlyFinance");
// const { assert } = require("chai");
// const chai = require("chai");
// const chaiBN = require('chai-bn');
// const chaiAsPromised = require("chai-as-promised");
// const truffleAssert = require('truffle-assertions');
// chai.use(chaiAsPromised);
// const expect = chai.expect;

// contract("ParrotlyFinance", (accounts) => {
//   const deployer = accounts[0];
//   const _serviceWallet = "0x049DE3990D8a938d627730696a53B7042782120E";
//   const _totalSupply = 1000000000000000000000000000000;
//   var contract;
//   var contract_address;

//   beforeEach('Setup contract', async () => {
//     contract = await ParrotlyFinance.deployed();
//     contract_address = contract.address;
//   });

//   context ("With initial deployment", async () => {
//     it("Sets basic token information", async function () {
//       var supply = await contract.totalSupply()

//       assert.equal(await contract.name(), "ParrotlyFinance");
//       assert.equal(await contract.symbol(), "PBIRB");
//       assert.equal(await contract.totalSupply(), _totalSupply);
//       assert.equal(await contract.decimals(), 18);
//       assert.equal(await contract.serviceWallet(), _serviceWallet);
//       assert.equal(await contract.buyFee(), 4);
//       assert.equal(await contract.sellFee(), 2);
//     });

//     it ("Excludes from fees Deployer, Contract and the Service Wallet", async function () {
//       assert.isTrue(await contract.excludedFromFee(deployer));
//       assert.isTrue(await contract.excludedFromFee(contract_address));
//       assert.isTrue(await contract.excludedFromFee(_serviceWallet));
//     });
//   });

//   context ("#buyFee", async () => {
//     it ("returns the buyFee", async () => {
//       assert.equal(await contract.buyFee(), 4);
//     });
//   });

//   context ("#excludeFromFees", async () => {
//     const excludedAddress = "0x0000000000000000000000000000000000000001";

//     it("Add wallet to excludeFromFees", async () => {
//       assert.isFalse(await contract.excludedFromFee(excludedAddress));
//       await contract.excludeFromFees(excludedAddress, true);
//       assert.isTrue(await contract.excludedFromFee(excludedAddress));
//     });

//     it ("Cannot add an address with the same value", async () => {
//       await truffleAssert.fails(
//         contract.excludeFromFees(excludedAddress, true),
//         "This address is already set with this value."
//       );
//     });
//   });

//   context ("#excludedFromFees", async () => {
//     const excludedAddress = "0x0000000000000000000000000000000000000002";

//     it ("returns false if address IS NOT excluded from fee", async () => {
//       await contract.excludeFromFees(excludedAddress, false);
//     });

//     it ("returns true if address IS excluded from fee", async () => {
//       assert.isFalse(await contract.excludedFromFee(excludedAddress));
//       await contract.excludeFromFees(excludedAddress, true);
//       assert.isTrue(await contract.excludedFromFee(excludedAddress));
//     });
//   });

//   context ("#removeFees", async () => {
//     it ("Removes all the fees", async () => {
//       assert.equal(await contract.buyFee(), 4);
//       assert.equal(await contract.sellFee(), 2);
//       await contract.removeFees();
//       assert.equal(await contract.buyFee(), 0);
//       assert.equal(await contract.sellFee(), 0);
//     });
//   });

//   context ("#restoreFees", async () => {
//     before('Disable Fees', async () => {
//       await contract.removeFees();
//     });

//     it ("returns all the fees at the value before their removal", async () => {
//       assert.equal(await contract.buyFee(), 0);
//       assert.equal(await contract.sellFee(), 0);
//       await contract.restoreFees();
//       assert.equal(await contract.buyFee(), 4);
//       assert.equal(await contract.sellFee(), 2);
//     });
//   });

//   context ("#sellFee", async () => {
//     it ("returns the sellFee", async () => {
//       assert.equal(await contract.sellFee(), 2);
//     });
//   });

//   context ("#serviceWallet", async () => {
//     it ("Removes all the fees", async () => {
//       assert.equal(await contract.serviceWallet(), _serviceWallet);
//     });
//   });

//   context ("#updateBuyFee", async () => {
//     it ("cannot be set higher than 4", async () => {
//       await truffleAssert.fails(
//         contract.updateBuyFee(5),
//         "Buy tax cannot be higher than 4%"
//       );
//     });

//     it ("updates the buy fee", async () => {
//       const {0: buyFee, 1: previousBuyFee} = await contract.updateBuyFee.call(1, { from: deployer });
//       assert.equal(buyFee, 1);
//       assert.equal(previousBuyFee, 4);
//     });
//   });

//   context ("#updateServiceWallet", async () => {
//     const newWallet = "0x0000000000000000000000000000000000001111";

//     before('Update the service wallet', async () => {
//       await contract.updateServiceWallet(newWallet);
//     });

//     it ("Changes the serviceWallet address and exclude it from the fees", async () => {
//       assert.equal(await contract.serviceWallet(), newWallet);
//       assert.equal(await contract.excludedFromFee(newWallet), true);
//     });
//   });

//   context ("#updateSellFee", async () => {
//     it ("cannot be set higher than 2", async () => {
//       await truffleAssert.fails(
//         contract.updateSellFee(3),
//         "Sell tax cannot be higher than 2%"
//       );
//     });

//     it ("updates the sell fee", async () => {
//       const {0: sellFee, 1: previousSellFee} = await contract.updateSellFee.call(1, { from: deployer });
//       assert.equal(sellFee, 1);
//       assert.equal(previousSellFee, 2);
//     });
//   });
// });