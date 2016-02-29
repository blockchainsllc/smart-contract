#!/usr/bin/python2

# Use test.py with the single argument of path/to/solc
# and the deploy.js test script will be automatically created for you
# with the latest DAO contract

import argparse
import os
import json
import subprocess


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
    return contract["abi"], contract["bin"]

def create_deploy_js(abi, bin):
    print("Rewritting deploy.js using the compiled contract...")
    f = open("deploy.js", "w")
    f.write(
        """//geth --dev --genesis genesis_block.json --datadir ./data  console 2>> out.log.geth

console.log("unlocking")
personal.unlockAccount(web3.eth.accounts[0], "Write here a good, randomly generated, passphrase!")
personal.unlockAccount(web3.eth.accounts[1], "Write here a good, randomly generated, passphrase!")

console.log("setting service provider and daoCreator")
var mined = 0;
var _defaultServiceProvider = web3.eth.accounts[0]/* var of type address here */ ;
var _daoCreator = web3.eth.accounts[1]/* var of type address here */ ;
var daoContract = web3.eth.contract("""
    )
    f.write(abi)
    f.write(
        """);
var dao = daoContract.new(
        _defaultServiceProvider,
        _daoCreator,
        {
            from: web3.eth.accounts[0],
            data: '"""
    )
    f.write(bin)
    f.write(
        """',
            gas: 3000000,
            gasPrice: 500000000000
   }, function(e, contract){
    console.log(e, contract);
    if (typeof contract.address != 'undefined') {
         console.log('Contract mined! address: ' + contract.address + ' transactionHash: ' + contract.transactionHash);
         mined = 1
    }
 })
console.log("mining contract, please wait")
miner.start(1); admin.sleepBlocks(1); miner.stop();"""
    )


if __name__ == "__main__":
    p = argparse.ArgumentParser(description='DAO contracts test helper')
    p.add_argument(
        'solidity',
        nargs='?',
        help='Full path to the solc binary'
    )
    args = p.parse_args()
    abi, bin = compile_contracts(args.solidity)
    create_deploy_js(abi, bin)

