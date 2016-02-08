import "./Token.sol";

contract DAO_Creator {
    function createDAO(address _defaultServiceProvider, DAO_Creator _daoCreator, uint _minValue, uint _closingTime) returns (DAOInterface _newDAO);
}

contract DAOInterface is TokenInterface {
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
        DAOInterface newDAO;
        Vote[] votes;
        mapping (address => bool) voted;
        address creator;
    }

    struct Vote {
        bool inSupport;
        address voter;
    }
}

contract rewardsAccount {
    DAOInterface dao; // the DAO which wants to pay out rewards
    uint accumulatedRewards;

    function PayOutRewards(address _dao){
        dao = DAOInterface(_dao);
    }

    function(){
        accumulatedRewards += msg.value;
    }
	
	function payOut(address _recipient, uint _amount) returns (bool){
		if (msg.sender != address(dao)) throw;
		_recipient.send(_amount);
		return true;
	}
}