const ParrotlyFinance = artifacts.require("ParrotlyFinance");

module.exports = async function (deployer) {
  await deployer.deploy(ParrotlyFinance);
}