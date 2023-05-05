// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Adoption {
  //Permettiamo al massimo 16 adozioni
  address[16] public adopters;

  function adopt(uint petId) public returns (uint) {
    //Sono possibili solo 16 adozioni, quindi devo controllare che il numero rientri in questo intervallo
    require(petId >= 0 && petId <= 15);

    //set the adopter's address to the respective slot in the adopter's array
    adopters[petId] = msg.sender;

    //return the id of the pet that was adopted
    return petId;
  }

  //memory vuol dire che lo salvi in memoria locale e lo distruggi appena esci dalla funzione
  //memory: qualsiasi cosa ritorno, non verrà salvata nella blockchain
  //view: non modifica nulla del contratto
  function getAdopters() public view returns (address[16] memory) {
    //rSemplicemente ritorna la versiona più aggiornata dell'array
    return adopters;
  }
}
