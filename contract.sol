 contract subUser {
    event subUserChanged(address oldOwner, address newOwner);
    event subUserAdded(address newOwner);
    event subUserRemoved(address oldOwner);

    function subUser() {
	    user = msg.sender;
    }

    modifier onlyUser {
        if (msg.sender == user)
            _
    }

    function isSubUser(address _addr) returns (bool) {
        return m_subUserIndex[uint(_addr)] > 0;
    }

    // Replaces an subUser `_from` with another `_to`.
    function changeSubUser(address _from, address _to) onlyUser external {
        if (isSubUser(_to)) return;
        uint subUserIndex = m_subUserIndex[uint(_from)];
        if (subUserIndex == 0) return;

        m_subUsers[subUserIndex] = uint(_to);
        m_subUserIndex[uint(_from)] = 0;
        m_subUserIndex[uint(_to)] = subUserIndex;
        subUserChanged(_from, _to);
    }
    function addSubUser(address _subUser) onlyUser external {
        if (isSubUser(_subUser)) return;

        if (m_numSubUsers >= c_maxsubUsers)
            reorganizeSubUsers();
        if (m_numSubUsers >= c_maxsubUsers)
            return;
        m_numSubUsers++;
        m_subUsers[m_numSubUsers] = uint(_subUser);
        m_subUserIndex[uint(_subUser)] = m_numSubUsers;
        subUserAdded(_subUser);
    }

    function removeSubUser(address _subUser) onlyUser external {
        uint subUserIndex = m_subUserIndex[uint(_subUser)];
        if (subUserIndex == 0) return;

        m_subUsers[subUserIndex] = 0;
        m_subUserIndex[uint(_subUser)] = 0;
        reorganizeSubUsers(); //make sure m_numsubUser is equal to the number of subUsers and always points to the optimal free slot
        subUserRemoved(_subUser);
    }

    function reorganizeSubUsers() private returns (bool) {
        uint free = 1;
        while (free < m_numSubUsers)
        {
            while (free < m_numSubUsers && m_subUsers[free] != 0) free++;
            while (m_numSubUsers > 1 && m_subUsers[m_numSubUsers] == 0) m_numSubUsers--;
            if (free < m_numSubUsers && m_subUsers[m_numSubUsers] != 0 && m_subUsers[free] == 0)
            {
                m_subUsers[free] = m_subUsers[m_numSubUsers];
                m_subUserIndex[m_subUsers[free]] = free;
                m_subUsers[m_numSubUsers] = 0;
            }
        }
    }

    address user;

    // pointer used to find a free slot in m_subUsers
    uint public m_numSubUsers;

    // list of subUsers
    uint[256] m_subUsers;
    uint constant c_maxsubUsers = 250;
    // index on the list of subUsers to allow reverse lookup
    mapping(uint => uint) m_subUserIndex;
}

contract Etherlock is subUser  {
    event Open();
    event Close();

    function Etherlock(uint _deposit, uint _price, uint _timeBlock) subUser() {
        owner = msg.sender;
        isOpen = 0;
        deposit = _deposit;
        price = _price;
        if (_timeBlock == 0){
            timeBlock = 1;
        }
        else{
            timeBlock = _timeBlock;
        }
        openTime = block.timestamp;
	  }

    function setDeposit(uint _deposit) {
        if (msg.sender != owner)  return;
        deposit = _deposit;
    }
    
    function setPrice(uint _price) {
        if (msg.sender != owner) return;
        price = _price;
    }
    
    function setTimeBlock(uint _timeBlock) {
        if (msg.sender != owner) return;
        timeBlock = _timeBlock;
    }
    
    // return cost in wei
    function costs() returns (uint ret) {
            return price * ((block.timestamp - openTime) + timeBlock) / timeBlock;
    }

    function open() {
        if (msg.sender == owner || msg.sender == user) { // reopen
            isOpen += 1;
            Open();
            return;
        }
        if (isOpen > 0 || msg.value < deposit){
            msg.sender.send(msg.value); // give money back
        }
        else {
            isOpen += 1;
            Open();
            openTime = block.timestamp;
            user = msg.sender;
        }
    }
    
    function close() {
        if (isOpen == 0) return;
        if (msg.sender == owner && user == owner) {isOpen = 0; Close(); return;}
        if (msg.sender == user){
            uint cost = costs();
            if (cost > deposit){
                owner.send(deposit);
            }
            else{
                user.send(deposit - cost);
                owner.send(cost);
            }
            isOpen = 0;
            user = owner;
            Close();
        }
    }
    
    function closedByOwner() {
        if (msg.sender != owner) return;
        if (costs() > deposit){
            owner.send(deposit);
            isOpen = 0;
            user = owner;
        }
    }

    function changeOwner(address _newOwner) {
        if (msg.sender != owner) return;
        owner = _newOwner;
    }

    function isUser(address _address) returns (bool) {
        return _address == user;
    }

    function isOwner(address _address) returns (bool) {
        return _address == owner;
    }

    address owner;
    uint deposit;
    uint price;

    uint isOpen;
    uint openTime;
    uint closeTime;
    uint timeBlock;
}
