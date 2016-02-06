//Sample contract

import "./DAO.sol";

contract SampleOffer
{
    uint totalCosts;
    uint oneTimeCosts;
    uint dailyCosts;

    bool promiseValid;

    address serviceProvider;
    bytes32 hashOfTheContract;
    uint minDailyCosts;
    uint paidOut;

    uint dateOfSignature;
    DAO client; // address of DAO

    uint public feeDivisor;
    uint public deploymentFee;

    modifier callingRestriction {
        if (promiseValid) {
            if (msg.sender != address(client)) throw;
        }
        else
            if (msg.sender != serviceProvider) throw;
        _
    }

    modifier onlyClient {
        if (msg.sender != address(client)) throw;
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
        if (!serviceProvider.send(oneTimeCosts)) throw;
        client = DAO(msg.sender);
        dateOfSignature = now;
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
        uint amount = (now - dateOfSignature) / (1 days) * dailyCosts - paidOut;
        if (serviceProvider.send(amount))
            paidOut += amount;
    }

    function setFeeDivisor(uint _feeDivisor) callingRestriction {
        if (_feeDivisor < 50 && msg.sender != address(client)) throw; // 2%
        feeDivisor = _feeDivisor;
    }

    function setDeploymentFee(uint _deploymentFee) callingRestriction {
        if (deploymentFee > 100 ether && msg.sender != address(client)) throw; // TODO, set a max defined by service provider, or ideally oracle (set in euro)
        deploymentFee = _deploymentFee;
    }

    // interface for Slocks
    function payOneTimeFee() returns(bool) {
        if (msg.value < deploymentFee)
            throw;
        if (promiseValid) {
            if (client.getReward.value(msg.value)()) return true;
            else throw;
        }
        else {
            if (serviceProvider.send(msg.value)) return true;
            else throw;
        }
    }

    // pay fee
    function () returns(bool) {
        if (promiseValid) {
            if (client.getReward.value(msg.value)()) return true;
            else throw;
        }
        else {
            if (serviceProvider.send(msg.value)) return true;
            else throw;
        }
    }
}
