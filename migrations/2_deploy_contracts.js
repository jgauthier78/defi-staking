const ERC20TokenAT1 = artifacts.require("ERC20TokenAT1");
const ERC20TokenAT2 = artifacts.require("ERC20TokenAT2");
const AlyraStaking = artifacts.require("AlyraStaking");

module.exports = function (deployer) {
  deployer.deploy(ERC20TokenAT1, "1000000000000000");
  deployer.deploy(ERC20TokenAT2, "2000000000000000");
  deployer.deploy(AlyraStaking);
};
