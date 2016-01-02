

console.log("unlocking accounts")
personal.unlockAccount(eth.accounts[0], "Write here a good, randomly generated, passphrase!")
personal.unlockAccount(eth.accounts[1], "Write here a good, randomly generated, passphrase!")
personal.unlockAccount(eth.accounts[2], "Write here a good, randomly generated, passphrase!")
personal.unlockAccount(eth.accounts[3], "Write here a good, randomly generated, passphrase!")
personal.unlockAccount(eth.accounts[4], "Write here a good, randomly generated, passphrase!")
personal.unlockAccount(eth.accounts[5], "Write here a good, randomly generated, passphrase!")
personal.unlockAccount(eth.accounts[6], "Write here a good, randomly generated, passphrase!")



var val_cont = web3.toWei(100000, "ether")    //to be sure we have enough for val + gas 

console.log("completeing crowd sale by buying all the tokens")
dao.buyToken.sendTransaction({from:eth.accounts[0],gas:100000,value:val_cont})
dao.buyToken.sendTransaction({from:eth.accounts[1],gas:100000,value:val_cont})
dao.buyToken.sendTransaction({from:eth.accounts[2],gas:100000,value:val_cont})
dao.buyToken.sendTransaction({from:eth.accounts[3],gas:100000,value:val_cont})
dao.buyToken.sendTransaction({from:eth.accounts[4],gas:100000,value:val_cont})
dao.buyToken.sendTransaction({from:eth.accounts[5],gas:100000,value:val_cont})
dao.buyToken.sendTransaction({from:eth.accounts[6],gas:100000,value:val_cont})


miner.start(1); admin.sleepBlocks(1); miner.stop();
dao.totalAmountReceived.call()

dao.balanceOf(eth.accounts[0])
dao.balanceOf(eth.accounts[1])
dao.balanceOf(eth.accounts[2])
dao.balanceOf(eth.accounts[3])
dao.balanceOf(eth.accounts[4])
dao.balanceOf(eth.accounts[5])
dao.balanceOf(eth.accounts[6])
