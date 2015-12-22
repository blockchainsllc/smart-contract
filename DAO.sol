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

implement crowdfunding, especially for confirmNewServiceProvider

not allowed to spent Ether if success = false


contract DAO_CreatorBase {
	function createDAO(uint minimumSharesForVoting, uint minutesForDebate, address defaultServiceProvider) returns (DAO newDAO) {}
}
*/
import "StandardToken";
import "Crowdfunding";
import "StandardCrowdfundingToken";

/*
contract DAO_Base is Crowdfunding {
	modifier onlyShareholders {}
	function() {}
	function DAO(uint minimumSharesForVoting, uint minutesForDebate, address defaultServiceProvider) {}
	function newProposal(address recipient, uint etherAmount, string JobDescription, bytes transactionBytecode, bool newServiceProvider) onlyShareholders returns (uint proposalID) {}
	function checkProposalCode(uint proposalNumber, address beneficiary, uint etherAmount, bytes transactionBytecode) constant returns (bool codeChecksOut) {}
	function vote(uint proposalNumber, bool supportsProposal) onlyShareholders returns (uint voteID){}
	function executeProposal(uint proposalNumber, bytes transactionBytecode) returns (int result) {}
	function confirmNewServiceProvider(uint proposalNumber, address newServiceProvider) {}
	function addAllowedAddress(address recipient) external {}
	function isRecipientAllowed(address recipient) internal returns (bool isAllowed) {}
	function createNewDAO(address newServiceProvider) internal returns (DAO_Base newDAO) {}	
}
*/

/* The democracy contract itself */
contract DAO is StandardCrowdfundingToken{

    /* Contract Variables and events */
    uint public minimumQuorum;
    uint public debatingPeriodInMinutes;
    Proposal[] public proposals;
    uint public numProposals;
	
	uint totalReceivedFunds;
	
	address serviceProvider;
	address[] allowedRecipients;

    event ProposalAdded(uint proposalID, address recipient, uint amount, string description);
    event Voted(uint proposalID, bool position, address voter);
    event ProposalTallied(uint proposalID, int result, uint quorum, bool active);
    
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
		totalReceivedFunds += msg.value;
	}
	    
    /* First time setup */
    function DAO(uint minimumSharesForVoting, uint minutesForDebate, address defaultServiceProvider) {
        if (minimumSharesForVoting == 0 ) minimumSharesForVoting = 1;
        minimumQuorum = minimumSharesForVoting;
        debatingPeriodInMinutes = minutesForDebate;
		serviceProvider = defaultServiceProvider;
    }	

    /* Function to create a new proposal */
    function newProposal(address recipient, uint etherAmount, string JobDescription, bytes transactionBytecode, bool newServiceProvider) onlyShareholders returns (uint proposalID) {
		// check sanityy
		if (newServiceProvider) {
			if (etherAmount != 0 || transactionBytecode.length != 0 || recipient == serviceProvider)
				throw;
		}
        else if (!isRecipientAllowed(recipient)) throw;
		
		proposalID = proposals.length++;
        Proposal p = proposals[proposalID];
        p.recipient = recipient;
        p.amount = etherAmount;
        p.description = JobDescription;
        p.proposalHash = sha3(recipient, etherAmount, transactionBytecode);
        p.votingDeadline = now + debatingPeriodInMinutes * 1 minutes;
        p.openToVote = true;
        p.proposalPassed = false;
        p.numberOfVotes = 0;
		p.newServiceProvider = newServiceProvider;
        ProposalAdded(proposalID, recipient, etherAmount, JobDescription);
        numProposals = proposalID + 1;
    }
    
    /* function to check if a proposal code matches */
    function checkProposalCode(uint proposalNumber, address beneficiary, uint etherAmount, bytes transactionBytecode) constant returns (bool codeChecksOut) {
        Proposal p = proposals[proposalNumber];
        return p.proposalHash == sha3(beneficiary, etherAmount, transactionBytecode);
    }
    
    /* */
    function vote(uint proposalNumber, bool supportsProposal) onlyShareholders returns (uint voteID){
        Proposal p = proposals[proposalNumber];
        if (p.voted[msg.sender] == true) throw;
        
        voteID = p.votes.length++;
        p.votes[voteID] = Vote({inSupport: supportsProposal, voter: msg.sender});
        p.voted[msg.sender] = true;
        p.numberOfVotes = voteID +1;
        Voted(proposalNumber,  supportsProposal, msg.sender);
    }
	
    
    function executeProposal(uint proposalNumber, bytes transactionBytecode) returns (int result) {
        Proposal p = proposals[proposalNumber];
        /* Check if the proposal can be executed */
        if (now < p.votingDeadline  /* has the voting deadline arrived? */ 
            || !p.openToVote        /* has it been already executed? */
            || p.proposalHash != sha3(p.recipient, p.amount, transactionBytecode) /* Does the transaction code match the proposal? */
		    || p.newServiceProvider) // is it a new service provider proposale
            throw;

        /* tally the votes */
        uint quorum = 0;
        uint yea = 0; 
        uint nay = 0;
        
        for (uint i = 0; i <  p.votes.length; ++i) {
            Vote v = p.votes[i];
            uint voteWeight = balanceOf(v.voter); 
            quorum += voteWeight;
            if (v.inSupport) {
                yea += voteWeight;
            } else {
                nay += voteWeight;
            }
        }
        /* execute result */
        if (quorum > minimumQuorum && yea > nay ) {
            // has quorum and was approved
            p.recipient.call.value(p.amount*1000000000000000000)(transactionBytecode);
            p.openToVote = false;
            p.proposalPassed = true;
        } else if (quorum > minimumQuorum && nay > yea) {
            p.openToVote = false;
            p.proposalPassed = false;
        } 
        /* Fire Events */
        ProposalTallied(proposalNumber, result, quorum, p.openToVote);
    }
	
	
	function confirmNewServiceProvider(uint proposalNumber, address newServiceProvider) {
		Proposal p = proposals[proposalNumber];
		// sanity check
		if (now < p.votingDeadline  /* has the voting deadline arrived? */ 
            || !p.openToVote        /* has it been already executed? */
            || p.proposalHash != sha3(p.recipient, p.amount, 0) /* Does the transaction code match the proposal? */
		    || !p.newServiceProvider // is it a new service provider proposale
			|| p.recipient != newServiceProvider)
            throw;
		
		// if not already happend, create new DAO
		if (address(p.newDAO) == 0)
			p.newDAO = createNewDAO(newServiceProvider);
		
		// move funds and asign new Tokens
//		p.newDAO.receiveEtherProxy.value(balanceOf(msg.sender) * this.balance / totalReceivedFunds)(msg.sender);
		
		// burn Slock tokens
		balances[msg.sender] *= (1 - this.balance / totalReceivedFunds);
	}
	
	// add allowed address (new contract/offer) to array of allowed recipients
	function addAllowedAddress(address recipient) external {
		if (msg.sender == serviceProvider)
			allowedRecipients.push(recipient);
	}
	
	// check whether recipient is serviceProvider or an address provided by him
	function isRecipientAllowed(address recipient) internal returns (bool isAllowed) {		
		if  (recipient == serviceProvider)
			return true;
		for (uint i = 0; i <  allowedRecipients.length; ++i) {
			if (recipient == allowedRecipients[i])
				return true;
		}
		return false;
	}
	
	function createNewDAO(address newServiceProvider) internal returns (DAO newDAO) {
		DAO_Creator creator;
		creator = DAO_Creator(msg.sender); //this is wrong
		return creator.createDAO(minimumQuorum, debatingPeriodInMinutes, newServiceProvider);
	}
}

contract DAO_Creator {
	function createDAO(uint minimumSharesForVoting, uint minutesForDebate, address defaultServiceProvider) returns (DAO newDAO) {
		return new DAO(minimumSharesForVoting, minutesForDebate, defaultServiceProvider);
	}
}
