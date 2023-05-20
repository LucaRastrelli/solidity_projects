// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Battleship {
  uint8 constant GRID_SIZE = 10;
  uint256 private nextGameID = 1;

  struct Game {
    bytes32 playerGridHash;
    bytes32 enemyGridHash;
    bool open;        //=false ci sono due giocatori; =true c'è un giocatore
    bool ended;       //=false la partita non è finita; =true la partita è finita
  }

  mapping (uint256 => Game) private games;
  event NewGameCreated(uint256 idGame);

  function newGame() public {
    emit NewGameCreated(nextGameID);
    games[nextGameID].open = true;
    nextGameID++;
  }

  function joinGame(uint gameId) public {} //gestisce sia il random che non

  function attack() public{}

  function checkWinner() private {}

  function endGame() private {}

  function afkPlayer() public {}
}
