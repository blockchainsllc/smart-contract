/*
This contract is intended for educational purposes, you are fully responsible
for compliance with present or future regulations of finance, communications
and the universal rights of digital beings.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org>

*/

/* Basic crowdsale contract. Allows to sell Tokens for the price of one Ether */

import "./Token.sol";

contract CrowdfundingInterface {

    uint public closingTime;                   // end of crowdfunding
    uint public minValue;                      // minimal goal of crowdfunding
    bool public funded;                        // true if project is funded, false otherwise
    uint public weiRaised;                     // total amount of wei raised (needs to be calculated at the end by the DAO), for gasReasons to do not accumulate it during the presale

    /// @dev Constructor setting the minimal target and the end of the crowdsale
    /// @param _minValue Minimal value for a successful crowdfunding
    /// @param _closingTime Date (in unix time) of the end of the crowdsale
    //  function Crowdfunding(uint _minValue, uint _closingTime); // its commented out only because the constructor can not be overloaded

    /// @notice Buy token with `msg.sender` as the beneficiary. One ether creates one token (same base units)
    function () returns (bool success);

    /// @notice Buy token with `_beneficiary` as the beneficiary. One ether creates one token (same base units)
    /// @param _beneficiary The beneficary of the token bought with ether
    function buyTokenProxy(address _beneficiary) returns (bool success);

    /// @notice returns true if the user is allowed to invest
    function isAcceptingFunds() returns (bool open);
    
    
    /// @notice Refund `msg.sender` in the case of a not successful crowdfunding
    function refund();

    event Funded(uint value);
    event SoldToken(address indexed to, uint value);
    event Refund(address indexed to, uint value);
}

contract Crowdfunding is CrowdfundingInterface, Token {

    function Crowdfunding(uint _minValue, uint _closingTime) {
        closingTime = _closingTime;
        minValue = _minValue;
    }


    function () returns (bool success) {
        return buyTokenProxy(msg.sender);
    }

    function isAcceptingFunds() returns (bool open) {
       return now < closingTime;
    }

    function buyTokenProxy(address _beneficiary) returns (bool success) {
        if (now < closingTime && msg.value > 0) {
            uint token = (tokenPriceMultiplier() * msg.value) / 10;
            balances[_beneficiary] += token; // TODO: change the price of a Token during the sale
            totalSupply += token;
            SoldToken(_beneficiary, token);
            if (totalSupply >= minValue && !funded) {
                funded = true;
                Funded(totalSupply);
            }
            return true;
        }
        throw;
    }


    function refund() {
         if (now > closingTime
             && !funded
             && msg.sender.send(balances[msg.sender])) // execute refund
         {
             totalSupply -= balances[msg.sender];
             balances[msg.sender] = 0;
             Refund(msg.sender, msg.value);
         }
    }

    function calcWeiRaised() {
        if (now < closingTime || !funded || weiRaised != 0) throw;
        weiRaised = this.balance;
    }

    function tokenPriceMultiplier() internal returns(uint multiplier) {
        if (now < closingTime - 2 weeks)
            return 10;
        else if (now < closingTime - 4 days)
            return 5 + ((closingTime - now) / (1 days) - 4) / 2; // TODO Test!
        else return 5;
    }
}
