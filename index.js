const Web3 = require('web3');

const web3 = new Web3('HTTP://127.0.0.1:7545')

web3.eth.getAccounts()
.then(console.log);
web3.eth.getBalance('0xCaeF4B1308d5FDfBB6FD3d8CD56140237D881497')
.then(console.log);
