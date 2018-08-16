var StringHandler = artifacts.require("StringHandler");
var DNote = artifacts.require("DNote");
var DNoteDelegator = artifacts.require("DNoteDelegator")

module.exports = function (deployer) {
    // deploy the StringHandler lib
    deployer.deploy(StringHandler);

    // deploy the DNote contract
    deployer.link(StringHandler, DNote);
    deployer.deploy(DNote);

    //deploy the DNoteDelegator contract
    deployer.deploy(DNoteDelegator)
}