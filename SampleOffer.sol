//Sample contract
contract SampleOffer
{
    uint totalCosts;
    uint oneTimeCosts;
    uint dailyCosts;

    bool signed;
    bool promiseValid;

    address serviceProvider;
    bytes32 hashOfTheContract;
    uint minDailyCosts;
    uint payedOut;

    uint dateOfSignature;
    address client; // address of DAO

    uint public feeDivisor;
    uint public deploymentFee;

    modifier callingRestriction {
        if (promiseValid) {
            if (msg.sender != client) throw;
        }
        else
            if (msg.sender != serviceProvider) throw;
        _
    }

    modifier onlyClient {
        if (msg.sender != client) throw;
        _
    }

    function SampleOffer(address _serviceProvider, bytes32 _hashOfTheContract, uint _totalCosts, uint _oneTimeCosts, uint _minDailyCosts, uint _feeDivisor, uint _deploymentFee) {
        serviceProvider = _serviceProvider;
        hashOfTheContract = _hashOfTheContract;
        totalCosts = _totalCosts;
        oneTimeCosts = _oneTimeCosts;
        minDailyCosts = _minDailyCosts;
        dailyCosts = _minDailyCosts;
        feeDivisor = _feeDivisor;
        deploymentFee = _deploymentFee;
    }

    function sign() {
        if (msg.value < totalCosts && dateOfSignature != 0) throw;
        serviceProvider.send(oneTimeCosts);
        client = msg.sender;
        dateOfSignature = now;
        signed = true;
        promiseValid = true;
    }

    function setDailyCosts(uint _dailyCosts) onlyClient {
        dailyCosts = _dailyCosts;
        if (dailyCosts < minDailyCosts)
            promiseValid = false;
    }
 function returnRemainingMoney() onlyClient {
        if (client.send(this.balance))
            promiseValid = false;        
    }

    function getMonthlyPayment() {
        if (msg.sender != serviceProvider) throw;
        uint amount = (now - dateOfSignature) / (1 days) * dailyCosts - payedOut;
        if (serviceProvider.send(amount))
            payedOut += amount;        
    }

    function setFeeDivisor(uint _feeDivisor) callingRestriction {
        if (_feeDivisor < 50 && msg.sender != client) throw; // 2%
        feeDivisor = _feeDivisor;
    }

    function setDeploymentFee(uint _deploymentFee) callingRestriction {
        if (deploymentFee > 100 ether && msg.sender != client) throw; // TODO, set a max defined by service provider, or ideally oracle (set in euro)
        deploymentFee = _deploymentFee;
    }

    //interface for Slocks
    function payOneTimeFee() returns(bool) {
        if (msg.value >= deploymentFee)
            return true;
        else
            throw;
    }
}
