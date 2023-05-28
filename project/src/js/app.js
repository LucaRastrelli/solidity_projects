var waitingForID = false;
var waitingForJoin = false;
var waitingForSync = false;
var waitingForSet = false;
var IDGame = 0;
var ethOffer = 0;
var boardDimension = 0;
var grid = [];
var clickOnShip = false;
var vertical = false;
var ship;
var shipDimension = 0;
var adding = 1;

App = {
  web3Provider: null,
  contracts: {},
  account: "0x0",

  init: async function() {
    return await App.initWeb3();
  },

  initWeb3: async function() {
    if (window.ethereum) {
      App.web3Provider = window.ethereum;
      try {
        await window.ethereum.enable();
      }
      catch(error) {
        console.error("User denied account access");
      }
    }
    else if (window.web3) {
      App.web3Provider = window.web3.currentProvider;
    }
    else {
      App.web3Provider = new Web3.provider.HttpProvider("http://localhost:7545");
    }
    web3 = new Web3(App.web3Provider);
    return App.initContract();
  },

  initContract: function() {
    web3.eth.getCoinbase(function(err, account) {
      if(err == null) {
          App.account = account;
          $("#accountId").html(account);
      }
    });
    $.getJSON("Battleship.json", function(data) {
      var BattleshipArtifact = data;    //Get the contract artifact and initialize it
      App.contracts.Battleship = TruffleContract(BattleshipArtifact);
      App.contracts.Battleship.setProvider(App.web3Provider);

      return App.listenForEvents();
    });
    return App.bindEvents();
  },

  newGame: function() {
    var battleshipInstance;
    App.contracts.Battleship.deployed().then(function (instance) {
      battleshipInstance = instance;
      waitingForID = true;
      boardDimension = document.getElementById("boardDimension").value;
      if (boardDimension < 2) boardDimension = 2;
      else if(boardDimension > 10) boardDimension = 10;
      return battleshipInstance.newGame(boardDimension, {from: App.account});
    }).catch(function(err) {
      console.error(err.message);
    });
  },

  bindEvents: function() {
    $(document).on('click', '#new', App.newGame);
    $(document).on('click', '#join', App.joinGame);
  },

  joinGame: function() {
    console.log("joinGame");
    //0: random
    var gameID = document.getElementById("gameID").value;
    var battleshipInstance;
    if(gameID < 0) gameID = 0;
    App.contracts.Battleship.deployed().then(function (instance) {
      battleshipInstance = instance;
      waitingForJoin = true;
      return battleshipInstance.joinGame(gameID, {from: App.account});
    }).catch(function(err) {
      console.error(err.message);
    });
  },

  bet: function() {
    var offer = document.getElementById("bet").value;
    if (offer <= 0) offer = 1;
    App.contracts.Battleship.deployed().then(function (instance) {
      return instance.bet(IDGame, offer, {from: App.account});
    }).catch(function (err) {
      console.error(err.message);
    });

  },

  pay: function() {
    App.contracts.Battleship.deployed().then(function (instance) {
      waitingForSet = true;
      return instance.pay(IDGame, {from: App.account, value: ethOffer.toString() + "000000000000000000"});
    }).catch(function (err) {
      console.error(err.message);
    });
  },

  rotate: function() {
    var ships = document.getElementsByClassName('ship-container');
    if (ships[0].classList.contains('vertical')) {
      // Se la nave è orizzontale, ruotala in verticale
      ships[0].classList.remove('vertical');
    } else {
      // Se la nave è verticale, ruotala in orizzontale
      ships[0].classList.add('vertical');
    }
  },

  placeShip: function(shipID) {
    clickOnShip = true;
    var ships = document.getElementsByClassName('ship-container');
    vertical = ships[0].classList.contains('vertical');

    for (var i = 0; i < ships[0].children.length; i++){
      ship = ships[0].children[i];
      if(parseInt(ship.dataset.id) == shipID)
        break;
    }
    shipDimension = parseInt(ship.dataset.width);
    
    if(vertical) {
      adding = boardDimension;
    }
    else adding = 1;
  },

  shipOnCell: function(event) {
    if(!clickOnShip) return;
    
    const targetCell = event.target;
    var targetId = parseInt(targetCell.id);
    if(!vertical) {
      var i = Math.floor(targetId / boardDimension);
      var j = Math.floor((targetId + shipDimension - 1) / boardDimension);
      if(i != j) return; // se non sono sulla stessa riga return
    }
    else {
      var j = targetId + (boardDimension * (shipDimension - 1));
      if (j > boardDimension * boardDimension) return; //se j è più grande della board return;
    }

    for (var z = 0; z < shipDimension; z++) {
      var index = targetId + (z*adding);
      if(grid[index] == 1) {
        return;
      }
    }
    
    for (var z = 0; z < shipDimension; z++) {
      var index = targetId + (z*adding);
      const cell = document.getElementById(index);
      cell.style.backgroundColor = "green";
      grid[index] = 1;
    }

    clickOnShip = false;
    ship.remove();
    
    var ships = document.getElementsByClassName('ship-container');
    if(ships[0].children.length == 0) {}
  },

  listenForEvents: function() {
    App.contracts.Battleship.deployed().then(function (instance) {
      instance.NewGameCreated(function (err, result) {
        if(waitingForID == false) return;
        if(result.args.player != App.account) return;
        if(err) {
          console.error(err);
        }
        waitingForID = false;
        IDGame = result.args.idGame.toNumber();
        console.log(IDGame);
        $('.splash-container').find('button').remove();
        $('.splash-container').find('input').remove();
        $('.splash-container').find('button').remove();

        $('.splash-container').append("<div class='waiting-phase'</div>");
        $('.waiting-phase').append("Game ID: ");
        $('.waiting-phase').append(result.args.idGame.toNumber());
        $('.waiting-phase').append('<br>Waiting for player...');
        waitingForJoin = true;
          
      });

      instance.JoinedGame(function (err, result) {
        if(err) {
          console.error(err);
        }
        if(waitingForJoin == false) return;
        if(result.args.enemy == App.account) {
          IDGame = result.args.idGame.toNumber();
        }
        else if(result.args.player == App.account ) {
          if(result.args.idGame.toNumber() != IDGame) return;
        }
        else return;
        waitingForJoin = false;
        waitingForSync = true;
        boardDimension = result.args.boardDimension.toNumber()
        $('.splash-container').find('button').remove();
        $('.splash-container').find('input').remove();
        $('.waiting-phase').remove();

        $('.splash-container').append("<div class='sync-phase'></div>");

        $('.sync-phase').append("Game ID ");
        $('.sync-phase').append(IDGame);
        $('.sync-phase').append(" is starting. Choose how many ETH you want to bet: ");
        $('.sync-phase').append('<input type="number" id="bet" placeholder="ETH" min="1" value="1">');
        $('.sync-phase').append('<br></br>');
        $('.sync-phase').append('<button class="btn splash-btn" id="bet-btn">Bet</button>');
        $(document).on('click', '#bet-btn', App.bet);
        $('.sync-phase').append('<br></br>');
        $('.sync-phase').append('<div class="decision"</div>');

        $('.decision').append('<div class="offer"</div>');
        $('.offer').append('Your adversary is still thinking...');

      });
      
      instance.OfferReceived(function (err, result) {
        if(err) {
          console.error(err);
        }
        if(waitingForSync == false) return;
        if(result.args.idGame.toNumber() != IDGame) return;
        if(result.args.bidder == App.account) return; //ignora l'event se ho fatto io la proposta
        
        ethOffer = result.args.offer.toNumber();

        $('.offer').remove();
        $('.decision').append('<div class="offer"</div>');
        $('.offer').append('Your adversary propose: ');
        $('.offer').append(ethOffer);
        $('.offer').append(' ETH');
      });

      instance.CommonOffer(function (err, result) {
        if(err) {
          console.error(err);
        }
        if(result.args.idGame.toNumber() != IDGame) return;
        if(waitingForSync == false) return;
        waitingForSync = false;
        ethOffer = result.args.offer.toNumber();
        $('.offer').remove();
        $('.decision').remove();
        $('.sync-phase').remove();

        $('.splash-container').append("<div class='pay-phase'></div>");

        $('.pay-phase').append("You agreed to bet: ");
        $('.pay-phase').append(ethOffer);
        $('.pay-phase').append(" ETH");

        $('.pay-phase').append('<button class="btn splash-btn" id="pay-btn" value=' + ethOffer.toString() + '>Pay</button>');
        $(document).on('click', '#pay-btn', App.pay);
      });

      instance.SetGame(function (err, result) {
        if(err) {
          console.error(err);
        }
        if(result.args.idGame.toNumber() != IDGame) return;
        if(waitingForSet == false) return;
        waitingForSet = false;

        for (let i = 0; i < boardDimension * boardDimension; i++) {
          grid.push(0);
        }

        $('.pay-phase').remove();
        $('.splash-container').append("<div class='board-phase'></div>");
        $('.board-phase').append("<table id='gridTable'></table>");

        const table = document.getElementById("gridTable");
        var cellID = 0;
        for(var i = 0; i < boardDimension; i++) {
            const tr = document.createElement("tr");
          for(var j = 0; j < boardDimension; j++){
            const td = document.createElement("td");
            td.setAttribute('id', cellID);
            td.setAttribute('value', 0);
            cellID++;
            td.addEventListener('click', App.shipOnCell);
            tr.appendChild(td);
          };
          table.appendChild(tr);
        };
        
        $('.board-phase').append("<div class='ship-container'></div>");

        $.getJSON('../ships.json', function(data) {    
          for (i = 0; i < data.length; i ++) {
            $('.ship-container').append("<span class='" + data[i].name + "' data-id=" + data[i].id + " data-width=" + data[i].width + " onclick=App.placeShip("+data[i].id+")></span>");
          }
        });
        $('.board-phase').append("<button class='btn splash-btn' id='rotateButton'>Rotate</button>");
        $(document).on('click', '#rotateButton', App.rotate);


      });
    });
  }
};

$(function() {
  $(window).load(function() {
    App.init();
  });
});
