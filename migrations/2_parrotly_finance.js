const Parrotly = artifacts.require("Parrotly");

module.exports = async function (deployer) {
  await deployer.deploy(Parrotly);
}