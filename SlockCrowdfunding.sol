contract SlockCrowdfunding
{
    
    mapping (address => uint) distro;   // value is amount of wei (smallest unit of ether) given in crowdsale by an individual supporter
    mapping (address => uint) payedOut; // value is amount of wei already payed out to the individual supporter
    uint totalWeiReceived;              // total number of wei received if the crowdsale is successful, only non-zero after pay out to Slock (sum of all distro[...] )
    uint withdrawn;                     // total amount of wei already withdrawn through supporters (sum of all payedOut[...] )
    uint closingTime;                   // end of crowdsale
    uint minValue;                      // minimal goal of crowdsale

    //constructor -  set timeframe and minimal goal initiating the crowdsale 
    function SlockCrowdfunding(uint _minValue, uint _closingTime) {
        minValue = _minValue;
        closingTime = _closingTime;
    }

    // contribute to the crowdsale (fallback function, called when no other function is called, no data given in transaction). It is also called when receiving money from the Slock smart contract
    function()
    {
        if (now <= closingTime) distro[msg.sender] += msg.value;
    }

    // if the minimal goal was not reached, give back the money to the supporters
    function refund() external
    {
         if (now > closingTime && this.balance < minValue && totalWeiReceived == 0 || payedOut[msg.sender] == 0 )
         {
             if (msg.sender.send(distro[msg.sender])) payedOut[msg.sender] = 1;
         }
    }
    //the purpose of this function is to send all the money to Slock GmbH (The Slock Trustees) if the crowdsale is successful.
    function finalize() external
    {
        if (now > closingTime && msg.sender == 0x510c && totalWeiReceived == 0 && this.balance >= minValue)
        {
            if (msg.sender.send(totalWeiReceived)) totalWeiReceived = this.balance;
        }
    }

    // after the crowdsale is over, this function can be called to get the portion of the fees (which will be paid to this account) according to the contribution made
    function receiveDividends()
    {
        address sender = msg.sender;
        // as long as totalWeiReceived is zero (prior to finalize), myShare will always be zero since x / 0 = 0 in the EVM.
        uint myShareInPercent = distro[sender] / totalWeiReceived;
        uint totalDividends = this.balance + withdrawn;
        uint myDividends = myShareInPercent * totalDividends - payedOut[sender];
        if (myDividends != 0 && sender.send(myDividends))
        {
            payedOut[sender] += myDividends;
            withdrawn +=myDividends;
        }
    }

    // transfer (part of) your contribution to another address
    function transfer(uint _value, address _to) external returns (bool _success)
    {
        receiveDividends();
        address sender = msg.sender;
	    uint myShares = distro[msg.sender];
	    if (_value <= myShares){
		    distro[msg.sender] -= _value;
		    distro[_to] += _value;
		    uint fraction =  _value / myShares;
		    payedOut[_to] += payedOut[msg.sender] * fraction;
		    payedOut[msg.sender] -= payedOut[msg.sender] * fraction;
		    _success =  true;
	    }
	_success = false;
    }

    function balanceOf(address _addr) constant returns (uint _r)
    {
        _r = distro[_addr];
    }
}

