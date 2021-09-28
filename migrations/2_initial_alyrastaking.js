const AlyraStaking = artifacts.require("AlyraStaking");

module.exports = function (deployer) {
  deployer.deploy(AlyraStaking);
};
