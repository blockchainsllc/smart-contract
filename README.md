# Decentralized Autonomous Organization


## What is it? 
A generic DAO (Decentralized Autonomous Organization) written in Solidity to run on the Ethereum block chain. It was designed to enable the IOT slock.it DAO. But it can be used to run a generic DAO.                  

## How it works
The DAO starts with 30 days of crowd funding during which anyone who sends 1 ether to the contract address gets 1 token. At the end of this period if the amount required is not raised the ether is refunded. If the amount required is raised the ether is transfered to the DAO.

The DAO then decided what address to send the funds to based upon voting. 1 token 1 vote.

Income to the DAO is provided by applications in that pay a free to utalize slock.its infrastructure. This income is divided as dividend to token holders.

Protections have been included to defend against 51% attack.


### Solidity files
#### DAO
##### TokenSale.sol: 
Basic Token Sale contract for crowd funding. 

##### DAO.sol:
Generic contract for a decentralized autonomous organisation to decide how to use the raised funds. 

##### Token.sol: 
Most, basic default, standardised Token contract
Original taken from [ConsenSys](https://github.com/ConsenSys/Tokens/blob/master/Token_Contracts/contracts/Standard_Token.sol)
which is based on [standardised APIs](https://github.com/ethereum/wiki/wiki/Standardized_Contract_APIs)

#### DAO interactions
The following contracts interact with the DAO

#####SampleOffer.sol

#####BasicSlock.sol

#####ManagedAccount.sol

#####SubUser.sol

#### Boiler Plate

#####DAOTokenSaleProxyTransferer.sol

## Deployments
The DAO is currently deployed on the testnet send **testether** to 0x15727bcd0ac224a39eb8c0c7a9f849f03b374 address to buy tokens. 

## Licensing
Please see the file called LICENSE.

## Contacts
[slack](https://slockit.slack.com/messages/dao-fication/)

