// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Battleship {
  uint256 private nextGameID = 1;
  uint256 private counter = 0;  //conta il numero di partite aperte
  uint8 shipNumber = 16;

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
  event AttackResponse(uint256 idGame, uint8 response);
  event EndGame(uint256 idGame, address winner);
  event ReceiveBoard(uint256 idGame, address winner);

  event log(bytes32 a, bytes32 b, uint8 target);

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
    games[nextGameID].playerHitSum = shipNumber;
    games[nextGameID].enemyHitSum = shipNumber;
    nextGameID++;
    counter++;
  }

  function joinGame(uint256 gameId) public {   //gestisce sia il random che non
    require(gameId >= 0, "ID must be greater than 0");
    require(gameId < nextGameID, "Game not open");
    require(counter > 0, "No games available");
    require(games[gameId].ended == false, "The game is over");

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
    require(gameId >= 0, "ID must be greater than 0");
    require(gameId < nextGameID, "Game not open");
    require(games[gameId].ended == false, "The game is over");
    if (games[gameId].player != msg.sender && games[gameId].enemy != msg.sender)
      return;
    
    if (games[gameId].playerOffer == games[gameId].enemyOffer) require(games[gameId].playerOffer == 0);
    else require(games[gameId].playerOffer != games[gameId].enemyOffer);

    if (games[gameId].player == msg.sender) games[gameId].playerOffer = offer;
    if (games[gameId].enemy == msg.sender) games[gameId].enemyOffer = offer;

    emit OfferReceived(msg.sender, offer, gameId);

    if (games[gameId].playerOffer == games[gameId].enemyOffer)
      emit CommonOffer(games[gameId].playerOffer, gameId);

  }

  function pay(uint256 gameId) public payable {
    require(gameId >= 0, "ID must be greater than 0");
    require(gameId < nextGameID, "Game not open");
    require(games[gameId].ended == false, "The game is over");  

    if (games[gameId].player == msg.sender) games[gameId].playerPay = true;
    if (games[gameId].enemy == msg.sender) games[gameId].enemyPay = true;

    if(games[gameId].playerPay && games[gameId].enemyPay) emit SetGame(gameId);
  }

  function attack(uint256 gameID, uint8 cellID) public {
    require(gameID >= 0, "ID must be greater than 0");
    require(gameID < nextGameID, "Game not open");
    require(games[gameID].ended == false, "The game is over");
    require(cellID < games[gameID].boardDimension * games[gameID].boardDimension);
    if (games[gameID].player != msg.sender && games[gameID].enemy != msg.sender)
      return;

    emit AttackedCell(gameID, cellID);
  }

  function attackResponse(uint256 gameID, uint8 value, bytes32[] memory merkleProof, uint8 cellID) public payable{
    require(gameID >= 0, "ID must be greater than 0");
    require(gameID < nextGameID, "Game not open");
    require(games[gameID].ended == false, "The game is over");
    if (games[gameID].player != msg.sender && games[gameID].enemy != msg.sender)
      return;

    uint8 target = cellID;
    bytes32 proofRoot = merkleProof[0];
    for(uint i = 1; i < merkleProof.length; i++) {
      if(target%2 == 0) {
        if(proofRoot != merkleProof[i])
          proofRoot = keccak256(abi.encodePacked(proofRoot, merkleProof[i]));
        else
          proofRoot = proofRoot;
      }
      else
        proofRoot = keccak256(abi.encodePacked(merkleProof[i], proofRoot));
      
      target = target / 2;
    }

    if (games[gameID].player == msg.sender) {
      if(games[gameID].playerGridHash != proofRoot) { //player is cheater
        games[gameID].playerHitSum = 0;
        endGame(games[gameID].enemy, games[gameID].playerOffer, gameID);
        return;
      }
      if(value == 1) 
        games[gameID].playerHitSum--;
      emit AttackResponse(gameID, value);

      if(games[gameID].playerHitSum == 0)
        emit ReceiveBoard(gameID, games[gameID].player);
    }
    else if (games[gameID].enemy == msg.sender) {
      if(games[gameID].enemyGridHash != proofRoot) {  //enemy is cheater
        games[gameID].enemyHitSum = 0;
        endGame(games[gameID].player, games[gameID].playerOffer, gameID);
        return;
      }
      if(value == 1) 
        games[gameID].enemyHitSum--;
      emit AttackResponse(gameID, value);

      if(games[gameID].enemyHitSum == 0)
        emit ReceiveBoard(gameID, games[gameID].player);
    }
    
  }

  function checkWinner(uint256 gameID, uint8[] memory winnerBoard) public payable {
    require(gameID >= 0, "ID must be greater than 0");
    require(gameID < nextGameID, "Game not open");
    require(games[gameID].ended == false, "The game is over");
    if (games[gameID].player != msg.sender && games[gameID].enemy != msg.sender)
      return;

    //Controllo che non sia stata chiamata per imbrogliare
    bool caller = false;  //false: enemy; true: player
    if (games[gameID].player == msg.sender) caller = true;

    if(caller) {
      if(games[gameID].enemyHitSum > 0) {           //non ho abbattuto tutte le navi del nemico
        endGame(games[gameID].enemy, games[gameID].playerOffer, gameID);
        return;
      }
    }
    else {
      if(games[gameID].playerHitSum > 0) {          //non ho abbattuto tutte le navi del player
        endGame(games[gameID].player, games[gameID].playerOffer, gameID);
        return;
      }
    }
    uint8 shipsOnBoard = 0;
    for(uint8 i = 0; i < winnerBoard.length; i++) {
      if(winnerBoard[i] == 1) 
        shipsOnBoard++;
    }
    
    if(shipsOnBoard == shipNumber) {
      if(caller) {
        endGame(games[gameID].player, games[gameID].playerOffer, gameID);
        return;
      }
      else {
        endGame(games[gameID].enemy, games[gameID].playerOffer, gameID);
        return;
      }
    }
    else {
      if(caller) {
        endGame(games[gameID].enemy, games[gameID].playerOffer, gameID);
        return;
      }
      else {
        endGame(games[gameID].player, games[gameID].playerOffer, gameID);
        return;
      }
    }

  }

  function endGame(address account, uint8 amount, uint256 gameID) private {
    games[gameID].ended = true;
    payable(account).transfer(amount * 2);
  }

  function afkPlayer() public {}

  function board(uint256 gameID, bytes32 boardHash) public {
    require(gameID < nextGameID);
    require(gameID > 0);
    require(games[gameID].ended == false, "The game is over");
    
    if (games[gameID].player == msg.sender) games[gameID].playerGridHash = boardHash;
    if (games[gameID].enemy == msg.sender) games[gameID].enemyGridHash = boardHash;
    
    if(games[gameID].playerGridHash != 0 && games[gameID].enemyGridHash != 0) emit StartGame(gameID);
  }

}