App = {
  web3Provider: null,
  contracts: {},

  init: async function() {
    // Load ships.
    $.getJSON('../ships.json', function(data) {
      var shipsRow = $('#shipsRow');
      var shipTemplate = $('#shipTemplate');

      for (i = 0; i < data.length; i ++) {
        shipTemplate.find('.panel-title').text(data[i].name);
        shipTemplate.find('.ship-width').text(data[i].width);

        shipsRow.append(shipTemplate.html());
      }
    });

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

  newGame: function(event) {
    event.preventDefault();

    console.log("newGame");
    var gameID;
    var battleshipInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if(error) { console.log(error);}
      var account = accounts[0];

      web3.eth.getCoinbase(function(error, coinbase) {
        if (error) {
          console.log(error);
        }
        if (coinbase) {
          account = coinbase; // Utilizza l'indirizzo dell'utente effettivo come account
        }
      });

      console.log(account)
      App.contracts.Battleship.deployed().then(function (instance) {
        battleshipInstance = instance;
        return battleshipInstance.newGame({from: account});
      }).then(function () {
        
        battleshipInstance.NewGameCreated(function (err, result) {
          if(err) {
            return error(err);
          }
          var gameIDNumber = result.args.idGame.toNumber();
          if(gameIDNumber > 0) {
            gameID = gameIDNumber;
            console.log(gameID);
          }
        })
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  },

  bindEvents: function() {
    $(document).on('click', '.splash-btn', App.newGame);
  },

  initContract: function() {
    $.getJSON("Battleship.json", function(data) {
      var BattleshipArtifact = data;    //Get the contract artifact and initialize it
      App.contracts.Battleship = TruffleContract(BattleshipArtifact);

      App.contracts.Battleship.setProvider(App.web3Provider);
      
      return;
    });
    return App.bindEvents();
  }
};

$(function() {
  $(window).load(function() {
    App.init();
  });
});
