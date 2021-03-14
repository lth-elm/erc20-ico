var OFAToken = artifacts.require("OFAToken");

module.exports = function(deployer) {
  deployer.deploy(OFAToken);
};