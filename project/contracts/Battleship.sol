// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Battleship {
  uint8 constant GRID_SIZE = 10;
  uint256 private nextGameID = 1;

  struct Game {
    bytes32 playerGridHash;
    bytes32 enemyGridHash;
    bool open;        //=0 ci sono due giocatori; =1 c'è un giocatore
    bool ended;       //=0 la partita non è finita; =1 la partita è finita
  }

  mapping (uint256 => Game) private games;
  event NewGameCreated(uint256 idGame);

  function newGame() public {
    emit NewGameCreated(nextGameID);
    nextGameID++;
  }

  function joinGame(uint gameId) public {} //gestisce sia il random che non

  function attack() public{}

  function checkWinner() private {}

  function endGame() private {}

  function afkPlayer() public {}
}
