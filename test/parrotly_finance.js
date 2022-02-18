const Parrotly = artifacts.require("Parrotly");
const time_travel = require("./helpers/time_travel");
const { assert } = require("chai");
const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const truffleAssert = require('truffle-assertions');
chai.use(chaiAsPromised);

contract("Parrotly", (accounts) => {
  const deployer = accounts[0];
  const _serviceWallet = "0x8973e1f6897d9bBe1C369c974f36771f75931863";
  const _deadWallet = "0x000000000000000000000000000000000000dEaD";
  const _totalSupply = 1000000000000000000000000000000;
  var contract;
  var contract_address;
  var snapShot;
  var snapshotId;

  beforeEach("Setup contract", async () => {
    contract = await Parrotly.new();
    contract_address = contract.address;
  });

  // Constructor
  
  context ("With initial deployment", async () => {
    it("Sets basic token information", async function () {
      assert.equal(await contract.name(), "Parrotly");
      assert.equal(await contract.symbol(), "PBIRB");
      assert.equal(await contract.totalSupply(), _totalSupply);
      assert.equal(await contract.decimals(), 18);
      assert.equal(await contract.serviceWallet(), _serviceWallet);
      assert.equal(await contract.buyFee(), 4);
      assert.equal(await contract.sellFee(), 2);
    });

    it ("Excludes from fees Deployer, Contract and the Service Wallet", async function () {
      assert.isTrue(await contract.getAddressExemptFromFees(deployer));
      assert.isTrue(await contract.getAddressExemptFromFees(contract_address));
      assert.isTrue(await contract.getAddressExemptFromFees(_serviceWallet));
    });
  });

  // External

  context ("#addDexSwapAddress", async () => {
    it ("Set and address as MarketPair", async () => {
      await contract.addDexSwapAddress(accounts[1], true);
      assert.isTrue(await contract.getDexSwapAddress(accounts[1]));
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

  context ("#exemptAddressFromFees", async () => {
    it("Add wallet to exemptAddressFromFees", async () => {
      assert.isFalse(await contract.getAddressExemptFromFees(accounts[1]));
      await contract.exemptAddressFromFees(accounts[1], true);
      assert.isTrue(await contract.getAddressExemptFromFees(accounts[1]));
    });

    it ("Cannot add an address with the same value", async () => {
      await contract.exemptAddressFromFees(accounts[1], true); // Add it first

      await truffleAssert.fails(
        contract.exemptAddressFromFees(accounts[1], true),
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

    it ("cannot be called once fees are disabled", async () => {
      await contract.updateBuyFee(0);
      await contract.updateSellFee(0);

      await truffleAssert.fails(
        contract.removeFees(),
        "Fees are permanently disabled"
      );
    });
  });

  context ("#restoreFees", async () => {
    it ("returns all the fees at the value before their removal", async () => {
      await contract.removeFees(); // Remove all the fees first
      await contract.restoreFees();
      assert.equal(await contract.buyFee(), 4);
      assert.equal(await contract.sellFee(), 2);
    });

    it ("buy fee is not affected once set to 0", async () => {
      await contract.updateBuyFee(0);
      await contract.restoreFees();
      assert.equal(await contract.buyFee(), 0);
    });

    it ("sell fee is not affected once set to 0", async () => {
      await contract.updateSellFee(0);
      await contract.restoreFees();
      assert.equal(await contract.sellFee(), 0);
    });

    it ("cannot be called once fees are disabled", async () => {
      await contract.updateBuyFee(0);
      await contract.updateSellFee(0);

      await truffleAssert.fails(
        contract.restoreFees(),
        "Fees are permanently disabled"
      );
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

    it ("is disabled after being set to 0", async () => {
      await contract.updateBuyFee(0);
      await truffleAssert.fails(
          contract.updateBuyFee(0),
          "Buy fee is permanently disabled"
      );
    });
  });

  context ("#updateServiceWallet", async () => {
    beforeEach('Update the service wallet', async () => {
      await contract.updateServiceWallet(accounts[1]);
    });

    it ("Changes the serviceWallet address and exclude it from the fees", async () => {
      assert.equal(await contract.serviceWallet(), accounts[1]);
      assert.equal(await contract.getAddressExemptFromFees(accounts[1]), true);
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

    it ("cannot be increased higher than the current tax", async () => {
      await contract.updateSellFee(1);
      await truffleAssert.fails(
          contract.updateSellFee(2),
          "Cannot increase the fee"
      );
    });

    it ("is disabled after being set to 0", async () => {
      await contract.updateSellFee(0);
      await truffleAssert.fails(
          contract.updateSellFee(0),
          "Sell fee is permanently disabled"
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

      it ("transfers and allow without any fees if sender is owner", async () => {
        await contract.transfer(accounts[1], 10000000, { from: accounts[0] });
        assert.equal(await contract.balanceOf(accounts[1]), 10000000);
      });

      it ("transfers and allow without any fees if sender is exempt", async () => {
        await contract.transfer(accounts[1], 10000000, { from: accounts[0] });
        await contract.exemptAddressFromFees(accounts[1], true);
        await contract.transfer(accounts[2], 10000000, { from: accounts[1] });
        assert.equal(await contract.balanceOf(accounts[2]), 10000000);
      });
    });

    context ("When the trading is enabled for less than or equal to 2 blocks and sender is NOT owner", async () => {
      beforeEach("Activate Trading", async () => {
        await contract.transfer(accounts[1], 1000, { from: accounts[0] });
        await contract.transfer(accounts[4], 1000, { from: accounts[0] });
        await contract.addDexSwapAddress(accounts[1], true);
        await contract.addDexSwapAddress(accounts[3], true);
        await contract.enableTrading();
        snapShot = await time_travel.takeSnapshot();
        snapshotId = snapShot['result'];
      });

      it ("Sets the buy tax to 99%", async () => {
        await time_travel.revertToSnapShot(snapshotId);

        await contract.transfer(accounts[2], 1000, { from: accounts[1] });
        
        assert.equal(await contract.balanceOf(accounts[2]), 10);
        assert.equal(await contract.balanceOf(_serviceWallet), 990);
      });

      it ("Sets the sell tax to 99%", async () => {
        await time_travel.revertToSnapShot(snapshotId);

        await contract.transfer(accounts[3], 1000, { from: accounts[4] });
        
        assert.equal(await contract.balanceOf(accounts[3]), 10);
        assert.equal(await contract.balanceOf(_deadWallet), 990);
      });      
    });

    context ("When the trading is enabled for more than 2 blocks and sender is NOT owner", async () => {
      beforeEach("Activate Trading", async () => {
        await contract.transfer(accounts[1], 1000, { from: accounts[0] });
        await contract.transfer(accounts[4], 1000, { from: accounts[0] });
        await contract.addDexSwapAddress(accounts[1], true);
        await contract.addDexSwapAddress(accounts[3], true);
        await contract.enableTrading();
        snapShot = await time_travel.takeSnapshot();
        snapshotId = snapShot['result'];
      });
  
      it ("Ensures 99% buy tax is disabled", async () => {
        await time_travel.revertToSnapShot(snapshotId);
  
        await time_travel.advanceBlock();
        await time_travel.advanceBlock();
        await time_travel.advanceBlock();
  
        await contract.transfer(accounts[2], 1000, { from: accounts[1] });
        
        assert.equal(await contract.balanceOf(accounts[2]), 960);
        assert.equal(await contract.balanceOf(_serviceWallet), 40);
      });

      it ("Ensures 99% sell tax is disabled", async () => {
        await time_travel.revertToSnapShot(snapshotId);
  
        await time_travel.advanceBlock();
        await time_travel.advanceBlock();
        await time_travel.advanceBlock();
  
        await contract.transfer(accounts[3], 1000, { from: accounts[4] });
        
        assert.equal(await contract.balanceOf(accounts[3]), 980);
        assert.equal(await contract.balanceOf(_deadWallet), 20);
      });      
    });
  });

  context ("#transfer", async () => {
    beforeEach("Activate Trading", async () => {
      await contract.transfer(accounts[1], 10000000, { from: accounts[0] });
      await contract.enableTrading();

      await time_travel.advanceBlock();
      await time_travel.advanceBlock();
    });

    context ("When the sender or receiver are exempt from fees", async () => {
      beforeEach('Adds address as exempt from fees', async () => {
        await contract.exemptAddressFromFees(accounts[1], true);
      });

      it ("Sends the token without any fee", async () => {
        assert.isTrue(await contract.getAddressExemptFromFees(accounts[1]));
        await contract.transfer(accounts[2], 10000000, { from: accounts[1] });
        assert.equal(await contract.balanceOf(accounts[2]), 10000000);
      });
    });

    context ("When the sender AND receiver are NOT a dex swap address (see _dexSwapAddresses)", async () => {
      it ("Sends the token without any fee", async () => {
        assert.isFalse(await contract.getDexSwapAddress(accounts[0]));
        assert.isFalse(await contract.getDexSwapAddress(accounts[1]));

        await contract.transfer(accounts[2], 10000000, { from: accounts[1] });
        assert.equal(await contract.balanceOf(accounts[2]), 10000000);
      });
    });

    context ("When the sender is a dex swap address", async () => {
      beforeEach("Add accounts[1] as dex swap address", async () => {
        await contract.addDexSwapAddress(accounts[1], true);
        await contract.transfer(accounts[2], 10000000, { from: accounts[1] });
      });

      it ("Sends PBIRB amount minus the BUY fees to the recipient", async () => {
        assert.equal(await contract.balanceOf(accounts[2]), 9600000);
      });

      it ("Sends fees from the original amount to the Service wallet", async () => {
        assert.equal(await contract.balanceOf(_serviceWallet), 400000);
      });
    });

    context ("When the recipient is a dex swap address", async () => {
      beforeEach("Add accounts[1] as dex swap address", async () => {
        await contract.addDexSwapAddress(accounts[2], true);
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