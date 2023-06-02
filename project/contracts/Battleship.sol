// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Battleship {
  uint256 private nextGameID = 1;
  uint256 private counter = 0;  //conta il numero di partite aperte

  struct Game {
    address player;
    address enemy;    //address(0): non c'è il giocatore
    uint8 boardDimension;
    bytes32 playerGridHash;
    bytes32 enemyGridHash;
    bool ended;       //false: la partita non è finita; true: la partita è finita
    uint8 playerOffer;
    uint8 enemyOffer;
    bool playerPay;   //false: il giocatore non ha pagato
    bool enemyPay;    //false: enemy non ha pagato
    uint8 playerHitSum; 
    uint8 enemyHitSum;
  }

  mapping (uint256 => Game) private games;
  event NewGameCreated(address player, uint256 idGame);
  event JoinedGame(address player, address enemy, uint256 idGame, uint8 boardDimension);
  event OfferReceived(address bidder, uint8 offer, uint256 idGame);
  event CommonOffer(uint8 offer, uint256 idGame);
  event SetGame(uint256 idGame);
  event StartGame(uint256 idGame);
  event AttackedCell(uint256 idGame, uint8 cell);

  function newGame(uint8 dimension) public {
    emit NewGameCreated(msg.sender, nextGameID);
    games[nextGameID].player = msg.sender;
    games[nextGameID].enemy = address(0);
    games[nextGameID].boardDimension = dimension;
    games[nextGameID].ended = false;
    games[nextGameID].playerOffer = 0;
    games[nextGameID].enemyOffer = 0;
    games[nextGameID].playerGridHash = 0;
    games[nextGameID].enemyGridHash = 0;
    games[nextGameID].playerPay = false;
    games[nextGameID].enemyPay = false;
    games[nextGameID].playerHitSum = 16;
    games[nextGameID].enemyHitSum = 16;
    nextGameID++;
    counter++;
  }

  function joinGame(uint256 gameId) public {   //gestisce sia il random che non
    require(gameId >= 0, "ID must be greater than 0");
    require(gameId < nextGameID, "Game not open");
    require(counter > 0, "No games available");

    //randomness
    if(gameId == 0) {
      bytes32 bhash = blockhash(block.number - 1);
      bytes memory bytesArray = new bytes(32);
      for (uint i; i < 32; i++) {
          bytesArray[i] = bhash[i];
      }
      bytes32 rand = keccak256(bytesArray);
      uint256 index = uint256(rand) % counter + 1;

      for(uint256 j = 1; j < nextGameID; j++) {
        if(index == 0) {
          break;
        }
        if(games[j].enemy == address(0)) {
          index--;
          if(games[j].player != msg.sender)   //un giocatore non può unirsi alla sua stessa partita
            gameId = j;
        }
      }
      if(gameId == 0)
        revert("Match not found");
    }
    //not random
    else {
      if(games[gameId].player == msg.sender)
        revert("You cannot join your own game"); 
      if(games[gameId].enemy != address(0))
        revert("Game already has two players");      
    }
    games[gameId].enemy = msg.sender;
    counter--;
    emit JoinedGame(games[gameId].player, msg.sender, gameId, games[gameId].boardDimension);
  } 

  function bet(uint256 gameId, uint8 offer) public {
    
    if (games[gameId].playerOffer == games[gameId].enemyOffer) require(games[gameId].playerOffer == 0);
    else require(games[gameId].playerOffer != games[gameId].enemyOffer);

    if (games[gameId].player == msg.sender) games[gameId].playerOffer = offer;
    if (games[gameId].enemy == msg.sender) games[gameId].enemyOffer = offer;

    emit OfferReceived(msg.sender, offer, gameId);

    if (games[gameId].playerOffer == games[gameId].enemyOffer) {
      emit CommonOffer(games[gameId].playerOffer, gameId);
    }

  }

  function pay(uint256 gameId) public payable {
    require(gameId >= 0, "ID must be greater than 0");
    require(gameId < nextGameID, "Game not open");    

    if (games[gameId].player == msg.sender) games[gameId].playerPay = true;
    if (games[gameId].enemy == msg.sender) games[gameId].enemyPay = true;

    if(games[gameId].playerPay && games[gameId].enemyPay) emit SetGame(gameId);
  }

  function attack(uint256 gameID, uint8 cellID) public {
    require(gameID >= 0, "ID must be greater than 0");
    require(gameID < nextGameID, "Game not open");
    require(cellID < games[gameID].boardDimension * games[gameID].boardDimension);

    emit AttackedCell(gameID, cellID);
  }

  function attackResponse() private {}

  function checkWinner() private {}

  function endGame() private {}

  function afkPlayer() public {}

  function board(uint256 gameID, bytes32 boardHash) public {
    require(gameID < nextGameID);
    require(gameID > 0);
    
    if (games[gameID].player == msg.sender) games[gameID].playerGridHash = boardHash;
    if (games[gameID].enemy == msg.sender) games[gameID].enemyGridHash = boardHash;
    
    if(games[gameID].playerGridHash != 0 && games[gameID].enemyGridHash != 0) emit StartGame(gameID);
  }

}