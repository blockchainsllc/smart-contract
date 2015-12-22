import "StandardToken";

contract Crowdfunding is StandardToken {
	uint closingTime;                   // end of crowdfunding
	uint minValue;                      // minimal goal of crowdfunding
	uint totalAmountReceived;
	bool success;
	
	function Crowdfunding(uint _minValue, uint _closingTime) {
		closingTime = _closingTime;
		minValue = _minValue;
	}
	
	function receiveEther() {
		receiveEtherProxy(msg.sender);
	}
	
	function receiveEtherProxy(address originalSender) {
		if (now > closingTime)
			throw;
		balances[msg.sender] += msg.value;		
		totalAmountReceived += msg.value;
		if (totalAmountReceived >= minValue && !success)
			success = true;
	}
	
	// in the case the minimal goal was not reached, give back the money to the supporters
	function refund()
   	{
        	if (now > closingTime 
			&& this.balance < minValue 
			&& !success
			&& msg.sender.send(balances[msg.sender])) // execute refund 
		{
             		balances[msg.sender] = 0;
         	}
    	}	
}
