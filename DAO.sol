/*
This creates a Democractic Autonomous Organization. Membership is based 
on ownership of custom tokens, which are used to vote on proposals.

This contract is intended for educational purposes, you are fully responsible 
for compliance with present or future regulations of finance, communications 
and the universal rights of digital beings.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org>

*/

/*
TODO:
better debatingPeriod mechanism (based on amount, min, max, ...)
include tx.data in proposal?
min quorum / deposit


*/

import "Crowdfunding.sol";

contract DAOInterface {
	modifier onlyShareholders {}

	function newProposal(address _recipient, uint _etherAmount, string _description, bytes _transactionBytecode, bool _newServiceProvider) onlyShareholders returns (uint _proposalID) {}
	function checkProposalCode(uint _proposalID, address _recipient, uint _etherAmount, bytes _transactionBytecode) constant returns (bool _codeChecksOut) {}
	function vote(uint _proposalID, bool supportsProposal) onlyShareholders returns (uint _voteID){}
	function executeProposal(uint _proposalID, bytes transactionBytecode) returns (bool _success) {}
	function confirmNewServiceProvider(uint _proposalID, address newServiceProvider) {}
	function addAllowedAddress(address _recipient) external {}
	
	event ProposalAdded(uint proposalID, address recipient, uint amount, string description);
    event Voted(uint proposalID, bool position, address voter);
    event ProposalTallied(uint proposalID, bool result, uint quorum, bool active);
	event NewServiceProvider(address _newServiceProvider);
	event AllowedRecipientAdded(address _recipient);
}

/* The democracy contract itself */
contract DAO is DAOInterface, Token, Crowdfunding(500000 ether, now + 42 days) {  // I would rather use the dynamic initialization instead of the static one (see construcitor), but doesn't work yet, due to a bug in Solidity

    /* Contract Variables and events */
    Proposal[] public proposals;
    uint public numProposals;
    uint dividends;

	address serviceProvider;
	address[] allowedRecipients;
	
	// deposit in Ether to be paid for each proposal
	uint proposalDeposit;
	
	DAO_Creator daoCreator;
    
    struct Proposal {
        address recipient;
        uint amount;
        string description;
        uint votingDeadline;
        bool openToVote;
        bool proposalPassed;
        uint numberOfVotes;
        bytes32 proposalHash;
		bool newServiceProvider;
		DAO newDAO;
        Vote[] votes;
        mapping (address => bool) voted;
		address creator;
    }

    struct Vote {
        bool inSupport;
        address voter;
    }
    
    /* modifier that allows only shareholders to vote and create new proposals */
    modifier onlyShareholders {
        if (balanceOf(msg.sender) == 0) throw;
        	_
    }
	

	function() {
		dividends += msg.value;
	}
	
    /* First time setup */
    
    // I would rather use the dynamic initialization instead of the static one (see declaration above), but doesn't work yet, due to a bug in Solidity
    //function DAO(address defaultServiceProvider, DAO_Creator _daoCreator, uint _minValue, uint _closingTime) Crowdfunding(_minValue, _closingTime) {
    function DAO(address _defaultServiceProvider, DAO_Creator _daoCreator) {
		serviceProvider = _defaultServiceProvider;
		daoCreator = _daoCreator;
		proposalDeposit = 100 ether;
    }

    /* Function to create a new proposal */
    function newProposal(address _recipient, uint _etherAmount, string _description, bytes _transactionBytecode, bool _newServiceProvider) onlyShareholders returns (uint _proposalID) {
		// check sanity
		if (_newServiceProvider && (_etherAmount != 0 || _transactionBytecode.length != 0 || _recipient == serviceProvider)) {
			throw;
		}
        else if (!isRecipientAllowed(_recipient)) throw;
		
        if (!funded || msg.value < proposalDeposit) throw;
		
		_proposalID = proposals.length++;
        Proposal p = proposals[_proposalID];
        p.recipient = _recipient;
        p.amount = _etherAmount;
        p.description = _description;
        p.proposalHash = sha3(_recipient, _etherAmount, _transactionBytecode);
		p.votingDeadline = now + debatingPeriod(_newServiceProvider, _etherAmount * 1 ether);
        p.openToVote = true;
        p.proposalPassed = false;
        p.numberOfVotes = 0;
		p.newServiceProvider = _newServiceProvider;
		p.creator = msg.sender;
        ProposalAdded(_proposalID, _recipient, _etherAmount, _description);
        numProposals = _proposalID + 1;
    }
    
    /* function to check if a proposal code matches */
    function checkProposalCode(uint _proposalNumber, address _recipient, uint _etherAmount, bytes _transactionBytecode) constant returns (bool _codeChecksOut) {
        Proposal p = proposals[_proposalNumber];
        return p.proposalHash == sha3(_recipient, _etherAmount, _transactionBytecode);
    }

	
	/* function to vote on proposal */
	function vote(uint _proposalNumber, bool _supportsProposal) onlyShareholders returns (uint _voteID){
		Proposal p = proposals[_proposalNumber];
        if (p.voted[msg.sender] == true) throw;
        
        _voteID = p.votes.length++;
        p.votes[_voteID] = Vote({inSupport: _supportsProposal, voter: msg.sender});
        p.voted[msg.sender] = true;
        p.numberOfVotes = _voteID + 1;
        Voted(_proposalNumber, _supportsProposal, msg.sender);
	}
	
    
    function executeProposal(uint _proposalNumber, bytes _transactionBytecode) returns (bool _success) {
        Proposal p = proposals[_proposalNumber];
        /* Check if the proposal can be executed */
        if (now < p.votingDeadline  /* has the voting deadline arrived? */ 
            || !p.openToVote        /* has it been already executed? */
            || p.proposalHash != sha3(p.recipient, p.amount, _transactionBytecode) /* Does the transaction code match the proposal? */
		    || p.newServiceProvider) // is it a new service provider proposal
            throw;

        /* tally the votes */
        uint quorum = 0;
        uint yea = 0; 
        uint nay = 0;
        
        for (uint i = 0; i <  p.votes.length; ++i) {
            Vote v = p.votes[i];
            uint voteWeight = balanceOf(v.voter); 
            quorum += voteWeight;
            if (v.inSupport)
                yea += voteWeight;
            else
                nay += voteWeight;            
        }
        /* execute result */
        if (quorum >= minQuorum(p.newServiceProvider, p.amount) && yea > nay ) {
            // has quorum and was approved
			if (p.recipient.call.value(p.amount * 1 ether)(_transactionBytecode)) {
            	p.openToVote = false;
            	p.proposalPassed = true;
				_success = true;
				p.creator.send(proposalDeposit);
			}
        } else if (quorum >= minQuorum(p.newServiceProvider, p.amount) && nay > yea) {
            p.openToVote = false;
            p.proposalPassed = false;
			p.creator.send(proposalDeposit);
        } 
        /* Fire Events */
        ProposalTallied(_proposalNumber, _success, quorum, p.openToVote);
    }
	
	
	function confirmNewServiceProvider(uint _proposalNumber, address _newServiceProvider) {
		Proposal p = proposals[_proposalNumber];
		// sanity check
		if (now < p.votingDeadline  /* has the voting deadline arrived? */ 
            || p.proposalHash != sha3(p.recipient, 0, 0) /* Does the transaction code match the proposal? */
		    || !p.newServiceProvider // is it a new service provider proposale
			|| p.recipient != _newServiceProvider)
            throw;
		
		// if not already happend, create new DAO
		if (address(p.newDAO) == 0)
			p.newDAO = createNewDAO(_newServiceProvider);
		
		// move funds and assign new Tokens
		p.newDAO.buyTokenProxy.value(balanceOf(msg.sender) * this.balance / (totalAmountReceived + dividends))(msg.sender);
		
		// burn Slock tokens
		balances[msg.sender] *= (1 - this.balance / (totalAmountReceived + dividends));
	}
	
	// add allowed address (new contract/offer) to array of allowed recipients
	function addAllowedAddress(address _recipient) external {
		if (msg.sender == serviceProvider)
			allowedRecipients.push(_recipient);
	}
	
	// add allowed address (new contract/offer) to array of allowed recipients
	function changeProposalDeposit(uint _proposalDeposit) external {
		if (msg.sender == serviceProvider)
			proposalDeposit = _proposalDeposit;
	}
	
	// check whether recipient is serviceProvider or an address provided by him
	function isRecipientAllowed(address recipient) internal returns (bool _isAllowed) {		
		if  (recipient == serviceProvider)
			return true;
		for (uint i = 0; i < allowedRecipients.length; ++i) {
			if (recipient == allowedRecipients[i])
				return true;
		}
		return false;
	}
	
	function debatingPeriod(bool _newServiceProvider, uint _value) internal returns (uint _debatingPeriod) {
		if (_newServiceProvider)
			return 61 days;
		else 
			return 1 weeks + (_value * 31 days) / totalAmountReceived;
	}
	
	function minQuorum(bool _newServiceProvider, uint _value) internal returns (uint _minQuorum) {
		if (_newServiceProvider)
			return totalAmountReceived / 2;
		else 
			return totalAmountReceived / 5 + _value / 3;
	}
	
	function createNewDAO(address _newServiceProvider) internal returns (DAO _newDAO) {
		NewServiceProvider(_newServiceProvider);
		return daoCreator.createDAO(_newServiceProvider, daoCreator);
	}
}

contract DAO_Creator {
	function createDAO(address _defaultServiceProvider, DAO_Creator _daoCreator) returns (DAO _newDAO) {
		return new DAO(_defaultServiceProvider, _daoCreator);
	}
}
