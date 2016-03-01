#!/usr/bin/python2

# Use test.py with the single argument of path/to/solc
# and the deploy.js test script will be automatically created for you
# with the latest DAO contract

import argparse
import os
import json
import subprocess
from datetime import datetime
datetime.utcnow()

def compile_contracts(solc):
    print("Compiling the DAO contract...")

    contracts_dir = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
    dao_contract = os.path.join(contracts_dir, "DAO.sol")
    if not os.path.isfile(dao_contract):
        print("DAO contract not found at {}".format(dao_contract))

    if not os.path.isfile(solc):
        print("Could not find solidity solc binary at {}".format(solc))

    data = subprocess.check_output([
        solc,
        os.path.join(contracts_dir, "DAO.sol"),
        "--combined-json",
        "abi,bin"
    ])
    res = json.loads(data)
    contract = res["contracts"]["DAO"]
    DAOCreator = res["contracts"]["DAO_Creator"]
    return contract["abi"], contract["bin"], DAOCreator["abi"], DAOCreator["bin"]

def create_deploy_js(dabi, dbin, cabi, cbin):
    print("Rewritting deploy.js using the compiled contract...")
    f = open("deploy.js", "w")
    f.write(
        """// geth --networkid 123 --nodiscover --maxpeers 0 --genesis ./genesis_block.json --datadir ./data console 2>> out.log.geth

console.log("unlocking accounts")
personal.unlockAccount(web3.eth.accounts[0], "Write here a good, randomly generated, passphrase!");
personal.unlockAccount(web3.eth.accounts[1], "Write here a good, randomly generated, passphrase!");

function checkWork() {
    if (eth.getBlock("pending").transactions.length > 0) {
        if (eth.mining) return;
        console.log("== Pending transactions! Mining...");
        miner.start(1);
    } else {
        miner.stop(0);  // This param means nothing
        console.log("== No transactions! Mining stopped.");
    }
}

var daoContract = web3.eth.contract(""")
    f.write(dabi)
    f.write(""");

console.log("Creating DAOCreator Contract");
var creatorContract = web3.eth.contract(""")
    f.write(cabi)
    f.write(""");
    var _daoCreatorContract = creatorContract.new({from: web3.eth.accounts[0], data: '""");
    f.write(cbin)
    f.write("""',
gas: 3000000
   }, function(e, contract){
       if (e) {
	console.log(e+" at DAOCreator creation!");
       }
       if (typeof contract.address != 'undefined') {
           console.log('DAOCreator mined! address: ' + contract.address + ' transactionHash: ' + contract.transactionHash);
           checkWork();
           var _defaultServiceProvider = web3.eth.acounts[0]/* var of type address here */ ;
           var dao = daoContract.new(
               _defaultServiceProvider,
               contract.address,
               20,
               1556842261,
        {
            from: web3.eth.accounts[0],
            data: '""")
    f.write(dbin)
    f.write(
        """',
            gas: 3000000,
            gasPrice: 500000000000
   }, function(e, contract){
    console.log(e, contract);
    if (typeof contract.address != 'undefined') {
         console.log('DAO Contract mined! address: ' + contract.address + ' transactionHash: ' + contract.transactionHash);
    }
 });
        checkWork();
       }
   });
checkWork();

console.log("mining contract, please wait");""")


if __name__ == "__main__":
    p = argparse.ArgumentParser(description='DAO contracts test helper')
    p.add_argument(
        '--solc',
        required=True,
        help='Full path to the solc binary'
    )
    args = p.parse_args()
    dabi, dbin, cabi, cbin = compile_contracts(args.solc)
    create_deploy_js(dabi, dbin, cabi, cbin)
