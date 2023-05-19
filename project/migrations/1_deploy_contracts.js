const Battleship = artifacts.require("../contracts/Battleship.sol");
//Vai al contratto, prendilo e mandalo nella blockchain

module.exports = function (instance) {
    instance.deploy(Battleship);
}