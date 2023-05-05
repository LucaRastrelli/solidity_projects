const Adoption = artifacts.require("Adoption");

//truffle create test TestAdoption
//per testare: $truffle test

contract("Adoption", function (accounts) {
  let adoption;
  let expectedPetId;
  
  before (async() => {
    adoption = await Adoption.deployed();
  });

  describe("Adopting a pet and retrieveing account addresses", async() => {
    before("Adopt a pet using accounts[0]", async () => {
      await adoption.adopt(8, { from: accounts[0] });
      expectedAdopter = accounts[0];
    });

    it("Can fetch the address of an owner by pet id", async() => {
      const adopter = await adoption.adopters(8);
      assert.equal(adopter, expectedAdopter, "The owner of the adopted should be the first account");
    });
  })
});
