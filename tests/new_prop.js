console.log("unlocking accounts")
personal.unlockAccount(eth.accounts[0], "Write here a good, randomly generated, passphrase!")

prop_tx = dao.newProposal.sendTransaction(eth.accounts[0], web3.toWei(100, "ether") , "test thing", '000010101', 0, {from:eth.accounts[0],gas:1000000,value:web3.toWei(101, "ether")})

console.log(prop_tx)

console.log("mineing")
miner.start(1); admin.sleepBlocks(1); miner.stop();

console.log(eth.getTransactionReceipt(prop_tx))
id = dao.numProposals.call()
