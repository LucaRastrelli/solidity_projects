const Adoption = artifacts.require("../contracts/Adoption.sol");
//Vai al contratto, prendilo e mandalo nella blockchain

module.exports = function (instance) {
    instance.deploy(Adoption);
}