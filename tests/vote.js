//loadScript("new_prop.js")

console.log("unlocking accounts")
personal.unlockAccount(eth.accounts[0], "Write here a good, randomly generated, passphrase!")
personal.unlockAccount(eth.accounts[1], "Write here a good, randomly generated, passphrase!")
personal.unlockAccount(eth.accounts[2], "Write here a good, randomly generated, passphrase!")
personal.unlockAccount(eth.accounts[3], "Write here a good, randomly generated, passphrase!")
personal.unlockAccount(eth.accounts[4], "Write here a good, randomly generated, passphrase!")
personal.unlockAccount(eth.accounts[5], "Write here a good, randomly generated, passphrase!")
personal.unlockAccount(eth.accounts[6], "Write here a good, randomly generated, passphrase!")


tx = dao.vote.sendTransaction(0, 1, {from:eth.accounts[0],value:web3.toWei(101, "ether"),gas:900000})
tx = dao.vote.sendTransaction(0, 1, {from:eth.accounts[1],value:web3.toWei(101, "ether"),gas:900000})
tx = dao.vote.sendTransaction(0, 1, {from:eth.accounts[2],value:web3.toWei(101, "ether"),gas:900000})
tx = dao.vote.sendTransaction(0, 1, {from:eth.accounts[3],value:web3.toWei(101, "ether"),gas:900000})
tx = dao.vote.sendTransaction(0, 1, {from:eth.accounts[4],value:web3.toWei(101, "ether"),gas:900000})
tx = dao.vote.sendTransaction(0, 1, {from:eth.accounts[5],value:web3.toWei(101, "ether"),gas:900000})
tx = dao.vote.sendTransaction(0, 1, {from:eth.accounts[6],value:web3.toWei(101, "ether"),gas:900000})



console.log("mining")
miner.start(1); admin.sleepBlocks(1); miner.stop();

console.log(eth.getTransactionReceipt(tx));
