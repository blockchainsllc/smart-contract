 contract Etherlock {
    event Open();
    event Close();

    function Etherlock(uint _deposit, uint _price, uint _timeBlock) {
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
        user = msg.sender;
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
        if (msg.sender != owner){
            return;
        }
        uint cost = price * (block.timestamp - openTime);
        if (costs() > deposit){
            owner.send(deposit);
            isOpen = 0;
            user = owner;
        }
    }

    address owner;
    uint deposit;
    uint price;
    address user;
    uint isOpen;
    uint openTime;
    uint closeTime;
    uint timeBlock;
}

