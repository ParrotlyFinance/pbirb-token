const ParrotlyFinance = artifacts.require("ParrotlyFinance");
const helper = require("./helpers/time_travel");
const { assert } = require("chai");
const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const truffleAssert = require('truffle-assertions');
chai.use(chaiAsPromised);

contract("ParrotlyFinance", (accounts) => {
  const deployer = accounts[0];
  const _serviceWallet = "0x049DE3990D8a938d627730696a53B7042782120E";
  const _deadWallet = "0x000000000000000000000000000000000000dEaD";
  const _totalSupply = 1000000000000000000000000000000;
  var contract;
  var contract_address;

  beforeEach('Setup contract', async () => {
    contract = await ParrotlyFinance.new();
    contract_address = contract.address;
  });

  // Constructor
  
  context ("With initial deployment", async () => {
    it("Sets basic token information", async function () {
      var supply = await contract.totalSupply()

      assert.equal(await contract.name(), "ParrotlyFinance");
      assert.equal(await contract.symbol(), "PBIRB");
      assert.equal(await contract.totalSupply(), _totalSupply);
      assert.equal(await contract.decimals(), 18);
      assert.equal(await contract.serviceWallet(), _serviceWallet);
      assert.equal(await contract.buyFee(), 4);
      assert.equal(await contract.sellFee(), 2);
    });

    it ("Excludes from fees Deployer, Contract and the Service Wallet", async function () {
      assert.isTrue(await contract.excludedFromFees(deployer));
      assert.isTrue(await contract.excludedFromFees(contract_address));
      assert.isTrue(await contract.excludedFromFees(_serviceWallet));
    });
  });

  // External

  context ("#setAutomatedMarketMakerPair", async () => {
    it ("Set and address as MarketPair", async () => {
      await contract.setAutomatedMarketMakerPair(accounts[1], true);
      assert.isTrue(await contract.getAutomatedMarketMakerPair(accounts[1]));
    });
  });

  context ("#buyFee", async () => {
    it ("returns the buyFee", async () => {
      assert.equal(await contract.buyFee(), 4);
    });
  });

  context ("#sellFee", async () => {
    it ("returns the sellFee", async () => {
      assert.equal(await contract.sellFee(), 2);
    });
  });

  // Public

  context ("#excludeFromFees", async () => {
    it("Add wallet to excludeFromFees", async () => {
      assert.isFalse(await contract.excludedFromFees(accounts[1]));
      await contract.excludeFromFees(accounts[1], true);
      assert.isTrue(await contract.excludedFromFees(accounts[1]));
    });

    it ("Cannot add an address with the same value", async () => {
      await contract.excludeFromFees(accounts[1], true); // Add it first

      await truffleAssert.fails(
        contract.excludeFromFees(accounts[1], true),
        "Already set to this value"
      );
    });
  });

  context ("#removeFees", async () => {
    it ("Removes all the fees", async () => {
      assert.equal(await contract.buyFee(), 4);
      assert.equal(await contract.sellFee(), 2);
      await contract.removeFees();
      assert.equal(await contract.buyFee(), 0);
      assert.equal(await contract.sellFee(), 0);
    });
  });

  context ("#restoreFees", async () => {
    it ("returns all the fees at the value before their removal", async () => {
      await contract.removeFees(); // Remove all the fees first
      await contract.restoreFees();
      assert.equal(await contract.buyFee(), 4);
      assert.equal(await contract.sellFee(), 2);
    });
  });

  context ("#serviceWallet", async () => {
    it ("Returns the service wallet address", async () => {
      assert.equal(await contract.serviceWallet(), _serviceWallet);
    });
  });

  context ("#updateBuyFee", async () => {
    it ("updates the buy fee", async () => {
        await contract.updateBuyFee(1);
        assert.equal(await contract.buyFee(), 1);
    });

    it ("cannot be set higher than 4", async () => {
        await truffleAssert.fails(
          contract.updateBuyFee(5),
          "Cannot be higher than 4"
        );
    });

    it ("Cannot be increased higher than the current tax", async () => {
        await contract.updateBuyFee(1);
        await truffleAssert.fails(
          contract.updateBuyFee(3),
          "Cannot increase the fee"
        );
    });
  });

  context ("#updateServiceWallet", async () => {
    beforeEach('Update the service wallet', async () => {
      await contract.updateServiceWallet(accounts[1]);
    });

    it ("Changes the serviceWallet address and exclude it from the fees", async () => {
      assert.equal(await contract.serviceWallet(), accounts[1]);
      assert.equal(await contract.excludedFromFees(accounts[1]), true);
    });

    it ("Cannot be updated with the same address", async () => {
        await truffleAssert.fails(
          contract.updateServiceWallet(accounts[1]),
          "Address is already in-use"
        );
    });
  });

  context ("#updateSellFee", async () => {
    it ("updates the sell fee", async () => {
      await contract.updateSellFee(1);
      assert.equal(await contract.sellFee(), 1);
    });

    it ("cannot be set higher than 2", async () => {
      await truffleAssert.fails(
        contract.updateSellFee(3),
        "Cannot be higher than 2"
      );
    });

    it ("Cannot be increased higher than the current tax", async () => {
      await contract.updateSellFee(0);
      await truffleAssert.fails(
          contract.updateSellFee(1),
          "Cannot increase the fee"
      );
    });
  });

  context ("#transfer", async () => {
    context ("When trading is disabled", async () => {
      it ("refuses all transfer", async () => {
        await truffleAssert.fails(
          contract.transfer(accounts[2], 0, { from: accounts[1] }),
          "Trading is not enabled."
        );
      });

      it ("transfers and allow without any fees if sender IS owner", async () => {
        await contract.transfer(accounts[1], 10000000, { from: accounts[0] });
        assert.equal(await contract.balanceOf(accounts[1]), 10000000);
      });
    });

    context ("When the Trading is enable for less than 5 block and send is NOT owner", async () => {
      beforeEach("Activate Trading", async () => {
        await contract.enableTrading();
        await contract.transfer(accounts[1], 10000000, { from: accounts[0] });
      });

      it ("Set the tax to 99%", async () => {
        // Set time 1 seconde after the last block
        const advancement = 1;
        const originalBlock = web3.eth.getBlock('latest');
        await helper.advanceTime(advancement);

        await contract.transfer(accounts[2], 100000, { from: accounts[1] });
        assert(await contract.balanceOf(accounts[2]), 100000);
        assert(await contract.balanceOf(_serviceWallet), 100000);
      });
    });
  });

  context ("#transfer", async () => {
    beforeEach("Activate Trading", async () => {
      await contract.enableTrading();
      await contract.transfer(accounts[1], 10000000, { from: accounts[0] });

      // Time Travel to set the next block timestamp to +100sec
      await helper.advanceTimeAndBlock(100);
    });

    context ("When the sender or receiver are exempt from fees", async () => {
      beforeEach('Adds address as exempt from fees', async () => {
        await contract.excludeFromFees(accounts[1], true);
      });

      it ("Sends the token without any fee", async () => {
        assert.isTrue(await contract.excludedFromFees(accounts[1]));
        await contract.transfer(accounts[2], 10000000, { from: accounts[1] });
        assert.equal(await contract.balanceOf(accounts[2]), 10000000);
      });
    });

    context ("When the sender AND receiver are NOT a Market Pair address (see _automatedMarketMakerPairs)", async () => {
      it ("Sends the token without any fee", async () => {
        assert.isFalse(await contract.getAutomatedMarketMakerPair(accounts[0]));
        assert.isFalse(await contract.getAutomatedMarketMakerPair(accounts[1]));

        await contract.transfer(accounts[2], 10000000, { from: accounts[1] });
        assert(await contract.balanceOf(accounts[2]), 10000000);
      });
    });

    context ("When the sender is a Market Pair Address", async () => {
      beforeEach("Add accounts[1] as Market Pair Address", async () => {
        await contract.setAutomatedMarketMakerPair(accounts[1], true);
        await contract.transfer(accounts[2], 10000000, { from: accounts[1] });
      });

      it ("Sends PBIRB amount minus the BUY fees to the recipient", async () => {
        assert.equal(await contract.balanceOf(accounts[2]), 9600000);
      });

      it ("Sends fees from the original amount to the Service wallet", async () => {
        assert.equal(await contract.balanceOf(_serviceWallet), 400000);
      });
    });

    context ("When the recipient is a Market Pair Address", async () => {
      beforeEach("Add accounts[1] as Market Pair Address", async () => {
        await contract.setAutomatedMarketMakerPair(accounts[2], true);
        await contract.transfer(accounts[2], 10000000, { from: accounts[1] });
      });

      it ("Sends PBIRB amount minus the SELL fees to the recipient", async () => {
        assert.equal(await contract.balanceOf(accounts[2]), 9800000);
      });

      it ("Sends fees from the original amount to the Dead wallet", async () => {
        assert.equal(await contract.balanceOf(_deadWallet), 200000);
      });
    });
  });
});