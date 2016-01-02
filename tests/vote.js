//loadScript("new_prop.js")

console.log("unlocking accounts")
personal.unlockAccount(eth.accounts[0], "Write here a good, randomly generated, passphrase!")

tx = dao.vote.sendTransaction(id, 1, {from:eth.accounts[0],value:web3.toWei(101, "ether")})

console.log("mining")
miner.start(1); admin.sleepBlocks(1); miner.stop();

console.log(eth.getTransactionReceipt(tx));


