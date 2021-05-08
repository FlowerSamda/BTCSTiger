var STiger = artifacts.require("./STiger.sol");
var Ownable = artifacts.require("./Ownable.sol");
var Context = artifacts.require("./Context.sol");

var owner = web3.eth.accounts[0];

module.exports = function(deployer) {
  deployer.deploy(STiger, owner);
}