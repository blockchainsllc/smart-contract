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

/*Most, basic default, standardised Token contract. No "pre-mine". Tokens need to be created by a derived contract (e.g. crowdsale)

Original taken from gist.github.com/simondlr/9a9c658d4f5f8c2e88fd
which is based on standardised APIs: https://github.com/ethereum/wiki/wiki/Standardized_Contract_APIs
.*/

contract TokenInterface {
    function transfer(uint _value, address _to) returns (bool _success) {}
    function transferFrom(address _from, uint _value, address _to) returns (bool _success) {}
    function balanceOf(address _addr) constant returns (uint _r) {}
    function approve(address _addr) returns (bool _success) {}
    function unapprove(address _addr) returns (bool _success) {}
    function isApprovedFor(address _target, address _proxy) constant returns (bool _r) {}   
    function approveOnce(address _addr, uint256 _maxValue) returns (bool _success) {}
    function isApprovedOnceFor(address _target, address _proxy) constant returns (uint _maxValue) {}
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event AddressApproval(address indexed addr, address indexed proxy, bool result);
    event AddressApprovalOnce(address indexed addr, address indexed proxy, uint256 value);
}

contract Token is TokenInterface {

    //explicitly not publicly accessible. Should rely on methods for purpose of standardization.
    mapping (address => uint) balances;
    mapping (address => mapping (address => bool)) approved;
    mapping (address => mapping (address => uint256)) approved_once;
	
    function transfer(uint _value, address _to) returns (bool _success) {
        if (balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
		else
			return false;
    }

    function transferFrom(address _from, uint _value, address _to) returns (bool _success) {
        if (balances[_from] >= _value) {
            bool transfer = false;
            if (approved[_from][msg.sender]) {
                transfer = true;
            } 
			else if (_value <= approved_once[_from][msg.sender]) {
                    transfer = true;
                    approved_once[_from][msg.sender] = 0; //reset                
            }

            if (transfer == true) {
                balances[_from] -= _value;
                balances[_to] += _value;
                Transfer(_from, _to, _value);
                return true;
            } 
			else
				return false;
        }
		else
			return false;
    }

    function balanceOf(address _addr) constant returns (uint _r) {
        return balances[_addr];
    }

    function approve(address _addr) returns (bool _success) {
        approved[msg.sender][_addr] = true;
        AddressApproval(msg.sender, _addr, true);
        return true;
    }
    
    function unapprove(address _addr) returns (bool _success) {
        approved[msg.sender][_addr] = false;
        approved_once[msg.sender][_addr] = 0;
        //debatable whether to include...
        AddressApproval(msg.sender, _addr, false);
        AddressApprovalOnce(msg.sender, _addr, 0);
    }
    
    function isApprovedFor(address _target, address _proxy) constant returns (bool _r) {
        return approved[_target][_proxy];
    }

    function approveOnce(address _addr, uint256 _maxValue) returns (bool _success) {
        approved_once[msg.sender][_addr] = _maxValue;
        AddressApprovalOnce(msg.sender, _addr, _maxValue);
        return true;
    }

    function isApprovedOnceFor(address _target, address _proxy) constant returns (uint _maxValue) {
        return approved_once[_target][_proxy];
    }
}
