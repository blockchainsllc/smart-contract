contract SlockCrowdfunding {

    //constructor -  set timeframe and minimal goal for crowdfunding
    function SlockCrowdfunding(uint _minValue, uint _closingTime) {
        minValue = _minValue;
        closingTime = _closingTime;
    }

    // contribute to crowdfunding
    function(){
        if (block.timestamp < closingTime)
            distro(msg.sender) += msg.value;
    }

    // the purpose of this function is the either send all the money to Slock, or in the case the the minimal goal was not reached, give back the money to the supporters
    function finalize() external{
        // if called before the end of the crowdfunding, do nothing
        if (block.timestamp < closingTime) return;

        address sender = msg.sender;

        // minimal goal was not reached, give back the money to the supporters
        if (this.balance < minValue && !success && !payedOut(sender)){
            if (sender.send(distro(sender))) payedOut(sender) = 1;
            return;
        }

        // successfull crowdfunding - payout Slock
        if (sender == 0xourAccount && !success && this.balance >= minValue){
            totalWeiRecevied = this.balance;
            sender.send(totalWeiReceived);
            success = true;
            return;
        }

        // if there is still money left after one year, let Slock be able to transfer it (we could remove that)
        if ((sender == 0xourAccount) && !totalWeiRecevied && time > closingTime + year){
            sender.send(this.balance);
        }
    }

    // after the crowdfunding is over, this function can be called to get the portion of the fees (which will be paid to this account) according to the contribution made
    function getMyShare() external{
        address sender = msg.sender;
        // as long as totalWeiReceived is zero (prior to finalize), myShare will always be zero.
        uint myShare = (distro(sender) * (this.balance + withdrawn) / totalWeiReceived - payedOut(sender));
        if (sender.send(myShare))
        {
            payedOut(sender) += myShare;
            withdrawn +=myShare;
        }
    }

    mapping (address => uint) distro;  // value is amount of wei given to crowdfunding
    const uint totalWeiReceived;
    mapping (address => uint) payedOut;
    uint withdrawn;
    uint closingTime;
    uint minValue;
    bool success;
}

