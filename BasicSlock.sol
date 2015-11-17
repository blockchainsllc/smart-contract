import "SubUser";
import "SlockDAO";

contract Slock is SubUser  {
    
    address public owner;
    uint public deposit;
    uint public price;
    uint public timeBlock;

    uint public openTime;
    uint public closeTime;
    
    bool public isRented;
    bool public isRentable;
    
    bool public isFeeFree;
    
    event Open();
    event Close();
    event Rent(address _user);
    event Return();

    function Slock(uint _deposit, uint _price, uint _timeBlock) SubUser() {
        owner = msg.sender;
        deposit = _deposit;
        price = _price;
        
        if (_timeBlock == 0)
            timeBlock = 1;
        else
            timeBlock = _timeBlock;
            
        openTime = block.timestamp;
        isRented = false;
        isRentable = true;
        isFeeFree = false;
	}
	  
    modifier require(bool _condition)
    {
        if (!_condition) throw;
        _
    }
    
    // be nice to the user and protect him from sending money when it makes no sense
    modifier noMoney()
    {
        if (msg.value > 0) throw;
        _
    }
    
    modifier onlyOwner()
    {
        if (msg.sender != owner) throw;
        _
    }
    
    modifier onlyUsers()
    {
        if (msg.sender != user && !isSubUser(msg.sender)) throw;
        _
    }
    
    // setters

    function setDeposit(uint _deposit) onlyOwner noMoney {
        deposit = _deposit;
    }
    
    function setPrice(uint _price) onlyOwner noMoney {
        price = _price;
    }
    
    function setTimeBlock(uint _timeBlock) onlyOwner noMoney {
        timeBlock = _timeBlock;
    }
    
    function changeOwner(address _newOwner) onlyOwner noMoney {
        owner = _newOwner;
    }
    
    function setRentable(bool _isRentable) onlyOwner noMoney {
        isRentable = _isRentable;
    }
    
    function payOneTimeFee() {
        address daoAdress = 0xaabbccddeeff0011223344556677889900aabbcc; // TODO replace by the DAO address
        if (SlockDAO(daoAdress).payOneTimeFee.value(msg.value)())
            isFeeFree = true;
        else
            throw;
    }
    
    // helpers
    
    // used as interface for other smart contracts, normally this is done by signed whisper messages
    function open() onlyUsers noMoney {
        Open();
    }
    
    function close() onlyUsers noMoney {
        Close();
    }
    
    // return cost in wei
    function costs() noMoney returns(uint) {
            return price * (now - openTime + timeBlock) / timeBlock;
    }
    
    // main functions

    function rent() require(isRentable && !isRented && msg.value == deposit) { // TODO add calendar, seperate rental cost from deposit
        user = msg.sender;
        openTime = block.timestamp;
        isRented = true;
    }
    
    function returnit() onlyUser noMoney {
        uint cost = costs();
        if (cost > deposit)
            cost = deposit;
        else
            user.send(deposit - cost);
            
        if (isFeeFree)
            owner.send(cost);
        else {
            address dao = 0xff; //to be replaced by the DAO address
            uint divisor = SlockDAO(dao).getFeeDivisor();
            dao.send(cost / divisor);
            owner.send(cost - cost / divisor ); 
        }
        
        removeAllSubUsers();
        user = owner;
        isRented = false;
        Close();
    }
    
    function returnToOwner() onlyOwner require(isRented) noMoney {
        uint cost = costs();
        if (cost > deposit){
            if (isFeeFree)
                owner.send(cost);
            else {
                address dao = 0xff; //to be replaced by the DAO address
                uint divisor = SlockDAO(dao).getFeeDivisor();
                dao.send(cost / divisor); // TODO make the 1% fee changeable by the DAO
                owner.send(cost - cost / divisor ); 
            }
            user = owner;
        }
    }
}
