// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Battleship {
  uint8 constant GRID_SIZE = 10;
  uint256 private nextGameID = 1;

  struct Game {
    bytes32 playerGridHash;
    bytes32 enemyGridHash;
    bool isActive;
  }

  mapping (uint256 => Game) private games;

  function newGame() public returns (uint8) {}

  function joinGame(uint gameId) public {} //gestisce sia il random che non

  function attack() public{}

  function checkWinner() private {}

  function endGame() private {}

  function afkPlayer() public {}
}
