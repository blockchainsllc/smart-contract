/*
This creates a Democratic Autonomous Organization. Membership is based
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

import "./Crowdfunding.sol";

contract DAOInterface {
    modifier onlyShareholders {}

    /// @dev Constructor setting the default service provider and the address for the contract able to create another DAO
    /// @param _defaultServiceProvider The default service provider
    /// @param _daoCreator The contract able to (re)create this DAO
    //  function DAO(address _defaultServiceProvider, DAO_Creator _daoCreator);  // its commented out only because the constructor can not be overloaded

    /// @notice `msg.sender` creates a proposal to send `_amount` Wei to `_recipient` with the transaction data `_transactionBytecode`. (If this is true: `_newServiceProvider`, then this is a proposal the set `_recipient` as the new service provider)
    /// @param _recipient The address of the recipient of the proposed transaction
    /// @param _amount The amount of Wei to be sent with the proposed transaction
    /// @param _description A string describing the proposal
    /// @param _transactionBytecode The data of the proposed transaction
    /// @param _newServiceProvider A bool defining whether this proposal is about a new service provider or not
    /// @return The proposal ID. Needed for voting on the proposal
    function newProposal(address _recipient, uint _amount, string _description, bytes _transactionBytecode, bool _newServiceProvider) onlyShareholders returns (uint _proposalID);

    /// @notice Check that the proposal with the ID `_proposalID` matches a transaction which sends `_amount` with this data: `_transactionBytecode` to `_recipient`
    /// @param _proposalID The proposal ID
    /// @param _recipient The recipient of the proposed transaction
    /// @param _amount The amount of Wei to be sent with the proposed transaction
    /// @param _transactionBytecode The data of the proposed transaction
    /// @return Whether the proposal ID matches the transaction data or not
    function checkProposalCode(uint _proposalID, address _recipient, uint _amount, bytes _transactionBytecode) constant returns (bool _codeChecksOut);

    /// @notice Vote on proposal `_proposalID` with `_supportsProposal`
    /// @param _proposalID The proposal ID
    /// @param _supportsProposal Yes/No - support of the proposal
    /// @return The proposal ID.
    function vote(uint _proposalID, bool _supportsProposal) onlyShareholders returns (uint _voteID);

    /// @notice Checks whether proposal `_proposalID` with transaction data `_transactionBytecode` has been voted for or rejected, and executes the transaction in the case it has been voted for.
    /// @param _proposalID The proposal ID
    /// @param _transactionBytecode The data of the proposed transaction
    /// @return Whether the proposed transaction has been executed or not
    function executeProposal(uint _proposalID, bytes _transactionBytecode) returns (bool _success);

    /// @notice ATTENTION! I confirm to move my remaining funds to a new DAO with `_newServiceProvider` as the new service provider, as has been proposed in proposal `_proposalID`. This will burn the portion of my tokens according to the funds the DAO has already spent. This can not be undone and will split the DAO into two DAO's, with two underlying tokens.
    /// @param _proposalID The proposal ID
    /// @param _newServiceProvider The new service provider of the new DAO
    /// @dev This function, when called for the first time for this proposal, will create a new DAO and send the portion of the remaining funds which can be attributed to the sender to the new DAO. It will also burn the tokens of the sender according the unspent funds of the DAO.
    function confirmNewServiceProvider(uint _proposalID, address _newServiceProvider);

    /// @notice add new possible recipient `_recipient` for transactions from the DAO (through proposals)
    /// @param _recipient New recipient address
    /// @dev Can only be called by the current service provider
    function addAllowedAddress(address _recipient) external;

    /// @notice change the deposit needed to make a proposal to `_proposalDeposit`
    /// @param _proposalDeposit New proposal deposit
    function changeProposalDeposit(uint _proposalDeposit) external;

    event ProposalAdded(uint proposalID, address recipient, uint amount, string description);
    event Voted(uint proposalID, bool position, address voter);
    event ProposalTallied(uint proposalID, bool result, uint quorum, bool active);
    event NewServiceProvider(address _newServiceProvider);
    event AllowedRecipientAdded(address _recipient);

    // Contract Variables and events
    Proposal[] public proposals;
    uint public numProposals;
    uint public rewards;

    address public serviceProvider;
    address[] public allowedRecipients;

    mapping (address => uint256) public rewardRights;  //only used for splits
    uint public extraRewardRights;

    // deposit in Ether to be paid for each proposal
    uint public proposalDeposit;

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
        uint proposalDeposit;
        bool newServiceProvider;
        uint splitBalance;
        DAO newDAO;
        Vote[] votes;
        mapping (address => bool) voted;
        address creator;
    }

    struct Vote {
        bool inSupport;
        address voter;
    }
}

// The DAO contract itself
contract DAO is DAOInterface, Token, Crowdfunding {

    // modifier that allows only shareholders to vote and create new proposals
    modifier onlyShareholders {
        if (balanceOf(msg.sender) == 0) throw;
            _
    }


    function getReward() returns(bool) {
        rewards += msg.value;
        return true;
    }

    function DAO(address _defaultServiceProvider, DAO_Creator _daoCreator, uint _minValue, uint _closingTime) Crowdfunding(_minValue, _closingTime) {
        serviceProvider = _defaultServiceProvider;
        daoCreator = _daoCreator;
        proposalDeposit = 100 ether;
    }


    function newProposal(address _recipient, uint _amount, string _description, bytes _transactionBytecode, bool _newServiceProvider) onlyShareholders returns (uint _proposalID) {
        // check sanity
        if (_newServiceProvider && (_amount != 0 || _transactionBytecode.length != 0 || _recipient == serviceProvider)) {
            throw;
        }
        else if (!isRecipientAllowed(_recipient)) throw;

        if (!funded || msg.value < proposalDeposit) throw;

        _proposalID = proposals.length++;
        Proposal p = proposals[_proposalID];
        p.recipient = _recipient;
        p.amount = _amount;
        p.description = _description;
        p.proposalHash = sha3(_recipient, _amount, _transactionBytecode);
        p.votingDeadline = now + debatingPeriod(_newServiceProvider, _amount);
        p.openToVote = true;
        //p.proposalPassed = false; // that's default
        //p.numberOfVotes = 0;
        p.newServiceProvider = _newServiceProvider;
        p.creator = msg.sender;
        p.proposalDeposit = msg.value;
        ProposalAdded(_proposalID, _recipient, _amount, _description);
        numProposals = _proposalID + 1;
    }


    function checkProposalCode(uint _proposalNumber, address _recipient, uint _amount, bytes _transactionBytecode) constant returns (bool _codeChecksOut) {
        Proposal p = proposals[_proposalNumber];
        return p.proposalHash == sha3(_recipient, _amount, _transactionBytecode);
    }


    function vote(uint _proposalNumber, bool _supportsProposal) onlyShareholders returns (uint _voteID) {
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
        // Check if the proposal can be executed
        if (now < p.votingDeadline  // has the voting deadline arrived?
            || !p.openToVote        // has it been already executed?
            || p.newServiceProvider // new service provider proposal get confirmed not executed
            || p.proposalHash != sha3(p.recipient, p.amount, _transactionBytecode)) // Does the transaction code match the proposal?
            throw;

        // tally the votes
        uint quorum = 0;
        uint yea = 0;
        uint nay = 0;

        for (uint i = 0; i < p.votes.length; ++i) {
            Vote v = p.votes[i];
            uint voteWeight = balanceOf(v.voter);
            quorum += voteWeight;
            if (v.inSupport)
                yea += voteWeight;
            else
                nay += voteWeight;
        }

        // execute result
        if (quorum >= minQuorum(p.newServiceProvider, p.amount) && yea > nay) {
            if (!p.creator.send(p.proposalDeposit)) throw;
            if (!p.recipient.call.value(p.amount)(_transactionBytecode)) throw;  // Without this throw, the creator of the proposal can repeat this, and get so much fund.
            p.openToVote = false;
            p.proposalPassed = true;
            _success = true;
        } else if (quorum >= minQuorum(p.newServiceProvider, p.amount) && nay >= yea) {
            p.openToVote = false;
            p.proposalPassed = false;
            if (!p.creator.send(p.proposalDeposit)) throw;
        }

        // fire event
        ProposalTallied(_proposalNumber, _success, quorum, p.openToVote);
    }

    function confirmNewServiceProvider(uint _proposalNumber, address _newServiceProvider) onlyShareholders {
        Proposal p = proposals[_proposalNumber];
        // sanity check
        if (now < p.votingDeadline  // has the voting deadline arrived?
            || now > p.votingDeadline + 41 days
            || p.proposalHash != sha3(_newServiceProvider, 0, 0) // Does the transaction code match the proposal?
            || !p.newServiceProvider // is it a new service provider proposal
            || p.recipient != _newServiceProvider) //(not needed)
            throw;

        // if not already happend, create new DAO and store the current balance
        if (address(p.newDAO) == 0) {
            p.newDAO = createNewDAO(_newServiceProvider);
            if (this.balance < p.proposalDeposit) throw;
            p.splitBalance = this.balance - p.proposalDeposit;
        }

        if (msg.sender == p.creator && p.creator.send(p.proposalDeposit)) {
            p.proposalDeposit = 0;
        }

        Transfer(msg.sender, 0, balances[msg.sender]); // this transfer will happen in 2 steps below

        // burn tokens
        uint tokenToBeBurned = (balances[msg.sender] * p.splitBalance) / (total_supply + rewards);
        if (balances[msg.sender] < tokenToBeBurned) { // This happens when the DAO has had incomes not counted in `rewards`.
            total_supply -= balances[msg.sender];
            balances[msg.sender] = 0;
        } else {
            total_supply -= tokenToBeBurned;
            balances[msg.sender] -= tokenToBeBurned;
        }

        // move funds and assign new Tokens
        uint fundsToBeMoved = (balances[msg.sender] * p.splitBalance) / total_supply; // total_supply equals the initial amount of tokens created
        if (p.newDAO.buyTokenProxy.value(fundsToBeMoved).gas(52225)(msg.sender) == false) throw; // TODO test gas costs

        rewardRights[address(p.newDAO)] += balances[msg.sender];
        extraRewardRights += balances[msg.sender];
        total_supply -= balances[msg.sender];
        balances[msg.sender] = 0;
    }


    function changeProposalDeposit(uint _proposalDeposit) external {
        if (msg.sender != address(this) || _proposalDeposit > this.balance / 10) throw;
        proposalDeposit = _proposalDeposit;
    }


    function addAllowedAddress(address _recipient) external {
        if (msg.sender != serviceProvider) throw;
        allowedRecipients.push(_recipient);
    }


    function isRecipientAllowed(address _recipient) internal returns (bool _isAllowed) {
        if (_recipient == serviceProvider || _recipient == address(this))
            return true;
        for (uint i = 0; i < allowedRecipients.length; ++i) {
            if (_recipient == allowedRecipients[i])
                return true;
        }
        return false;
    }


    function debatingPeriod(bool _newServiceProvider, uint _value) internal returns (uint _debatingPeriod) {
        if (_newServiceProvider)
            return 61 days;
        else
            return 1 weeks + (_value * 31 days) / (total_supply + rewards);
    }


    function minQuorum(bool _newServiceProvider, uint _value) internal returns (uint _minQuorum) {
        if (_newServiceProvider)
            throw;
        else
            return total_supply / 5 + _value / 3;
    }


    function createNewDAO(address _newServiceProvider) internal returns (DAO _newDAO) {
        NewServiceProvider(_newServiceProvider);
        return daoCreator.createDAO(_newServiceProvider, daoCreator, 0, now + 42 days);
    }
}

contract DAO_Creator {
    function createDAO(address _defaultServiceProvider, DAO_Creator _daoCreator, uint _minValue, uint _closingTime) returns (DAO _newDAO) {
        return new DAO(_defaultServiceProvider, _daoCreator, _minValue, _closingTime);
    }
}
