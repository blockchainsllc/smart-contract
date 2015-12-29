/*
This creates a Democractic Autonomous Organization. Membership is based 
on ownership of custom tokens, which are used to vote on proposals.

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

/*Basic crowdsale contract. Allows to sale Tokens for the price of one Ether */

import "Token.sol";

contract CrowdfundingInterface {
	function Crowdfunding(uint _minValue, uint _closingTime) {}
	function buyToken() {}
	function buyTokenProxy(address _beneficiary) {}
	function refund() {}
	
	event Funded(uint value);
	event SoldToken(address to, uint value);
	event Refund(address to, uint value);
}

contract Crowdfunding is CrowdfundingInterface, Token {
	uint public closingTime;                   // end of crowdfunding
    uint public minValue;                      // minimal goal of crowdfunding
	uint public totalAmountReceived;
	bool public funded;
	
	function Crowdfunding(uint _minValue, uint _closingTime) {
		closingTime = _closingTime;
		minValue = _minValue;
	}
	
	function buyToken() {
		buyTokenProxy(msg.sender);
	}
	
	function buyTokenProxy(address _beneficiary) {
		if (now < closingTime) {
			balances[_beneficiary] += msg.value;		
			totalAmountReceived += msg.value;
			SoldToken(_beneficiary, msg.value);
			if (totalAmountReceived >= minValue && !funded) {
				funded = true;
				Funded(totalAmountReceived);
			}
		}
	}
	
	// in the case the minimal goal was not reached, give back the Ether to the supporters
    function refund() {
         if (now > closingTime 
			 && !funded
			 && msg.sender.send(balances[msg.sender])) // execute refund 
         {
             balances[msg.sender] = 0;
			 Refund(msg.sender, msg.value);
         }
    }
}