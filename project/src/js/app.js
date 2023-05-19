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

  initContract: function() {
    $.getJSON("Battleship.json", function(data) {
      var BattleshipArtifact = data;    //Get the contract artifact and initialize it
      App.contracts.Battleship = TruffleContract(BattleshipArtifact);

      App.contracts.Battleship.setProvider(App.web3Provider);
      
    });
  }
};

$(function() {
  $(window).load(function() {
    App.init();
  });
});
