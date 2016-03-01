# Decentralized Autonomous Organization


## What is it? 
A generic DAO (Decentralized Autonomous Organization) written in Solidity to run on the Ethereum block chain.

## How it works
The DAO starts with a crowd funding period during which anyone who sends ether to the contract address gets token. At the end of this period if the amount required is not raised the ether is refunded. If the amount required is raised the ether will stay in the DAO.

The DAO then decided what address to send the funds to based upon voting. 1 token 1 vote.

Income to the DAO is provided by applications through the work of its service provider.

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

## Licensing
Please see the file called LICENSE.

## Contacts
[slack](https://slockit.slack.com/messages/dao-fication/)

