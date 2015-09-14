contract SlockCrowdfunding {
    
    mapping (address => uint) distro;   // value is amount of wei given to crowdfunding
    mapping (address => uint) payedOut; // value is amount already payed out to supporter
    uint totalWeiReceived;              // total number of wei received in successful crowdfunding, only non-zero after pay out to Slock (sum of all distro[...] )
    uint withdrawn;                     // total amount of wei already withdrawn through supportes (sum of all payedOut[...] )
    uint closingTime;                   // end of crowdfunding
    uint minValue;                      // minimal goal of crowdfunding

    //constructor -  set timeframe and minimal goal for crowdfunding
    function SlockCrowdfunding(uint _minValue, uint _closingTime) {
        minValue = _minValue;
        closingTime = _closingTime;
    }

    // contribute to crowdfunding (fallback function, called when no other function is called, no data given in transaction)
    function(){
        if (block.timestamp <= closingTime) distro[msg.sender] += msg.value;
    }

    // the purpose of this function is the either send all the money to Slock, or in the case the minimal goal was not reached, give back the money to the supporters
    function finalize() external{
        // if called before the end of the crowdfunding, do nothing
        if (block.timestamp < closingTime) return;

        address sender = msg.sender;

        // minimal goal was not reached, give back the money to the supporter
        if (this.balance < minValue && totalWeiReceived == 0 && payedOut[sender] == 0){
            if (sender.send(distro[sender])) payedOut[sender] = 1;
            return;
        }

        // successfull crowdfunding - payout Slock
        if (sender == 0x510c && totalWeiReceived == 0 && this.balance >= minValue){
            totalWeiReceived = this.balance;
            sender.send(totalWeiReceived);
            return;
        }
    }

    // after the crowdfunding is over, this function can be called to get the portion of the fees (which will be paid to this account) according to the contribution made
    function getMyShare() external{
        address sender = msg.sender;
        // as long as totalWeiReceived is zero (prior to finalize), myShare will always be zero (x / 0 = 0).
        uint myShare = (distro[sender] * (this.balance + withdrawn) / totalWeiReceived - payedOut[sender]);
        if (myShare != 0 && sender.send(myShare))
        {
            payedOut[sender] += myShare;
            withdrawn +=myShare;
        }
    }

    // transfer (part of) your contribution to another address
    function transferShare(address _to, uint _share) external returns (bool success) {
	address sender = msg.sender;
	uint fullshare = distro[msg.sender];
	if (_share <= fullshare){
	    distro[msg.sender] -= _share;
		distro[_to] += _share;
		payedOut[_to] += payedOut[msg.sender] * _share / fullshare;
		payedOut[msg.sender] -= payedOut[msg.sender] * _share / fullshare;
		return true;
	}
	return false;
    }
}

