contract SubUser {

    address public user;

    // pointer used to find a free slot in m_subUsers
    uint public m_numSubUsers;

    // list of subUsers
    uint[256] m_subUsers;
    uint constant c_maxsubUsers = 250;
    // index on the list of subUsers to allow reverse lookup
    mapping(uint => uint) m_subUserIndex;

    event SubUserChanged(address indexed oldOwner, address indexed newOwner);
    event SubUserAdded(address indexed newOwner);
    event SubUserRemoved(address indexed oldOwner);

    function SubUser() {
        user = msg.sender;
    }

    modifier onlyUser {
        if (msg.sender == user)
            _
    }

    function isSubUser(address _addr) returns (bool) {
        return m_subUserIndex[uint(_addr)] > 0;
    }

    function isAUser(address _addr) returns (bool) {
        return _addr == user || isSubUser(_addr);
    }

    // Replaces a subUser `_from` with another `_to`.
    function changeSubUser(address _from, address _to) onlyUser external {
        if (isSubUser(_to)) return;
        uint subUserIndex = m_subUserIndex[uint(_from)];
        if (subUserIndex == 0) return;

        m_subUsers[subUserIndex] = uint(_to);
        m_subUserIndex[uint(_from)] = 0;
        m_subUserIndex[uint(_to)] = subUserIndex;
        SubUserChanged(_from, _to);
    }
    function addSubUser(address _subUser) onlyUser external {
        if (isSubUser(_subUser)) return;

        if (m_numSubUsers >= c_maxsubUsers)
            reorganizeSubUsers();
        if (m_numSubUsers >= c_maxsubUsers)
            throw;
        m_numSubUsers++;
        m_subUsers[m_numSubUsers] = uint(_subUser);
        m_subUserIndex[uint(_subUser)] = m_numSubUsers;
        SubUserAdded(_subUser);
    }

    function removeSubUser(address _subUser) onlyUser external {
        uint subUserIndex = m_subUserIndex[uint(_subUser)];
        if (subUserIndex == 0) return;

        m_subUsers[subUserIndex] = 0;
        m_subUserIndex[uint(_subUser)] = 0;
        reorganizeSubUsers(); //make sure m_numsubUser is equal to the number of subUsers and always points to the optimal free slot
        SubUserRemoved(_subUser);
    }

    function removeAllSubUsers() internal {
        for (var i = 1; i <= m_numSubUsers; i++)
            m_subUserIndex[m_subUsers[i]] = 0;
        delete m_subUsers;
        m_numSubUsers = 0;
    }

    function reorganizeSubUsers() private {
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
}
