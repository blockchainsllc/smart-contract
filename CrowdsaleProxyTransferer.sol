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

/* Basic proxy contract which transfers all the value to the DAO by calling its buyTokenProxy-Function.
 This allows Exchanges to simply transfer money to an address which then will be forwarded to the DAO
 */

import "./Crowdfunding.sol";

contract CrowdsaleProxyTransferer {
    address public owner;
    address public dao;

    //constructor 
    function CrowdsaleProxyTransferer(address _owner, address _dao) {
        owner = _owner;
        dao   = _dao;
        
        // just in case somebody already added values to this address, we forward it right now.
        if (this.balance > 0)
           sendValues(this.balance);
    }
    
    // default-function called when values are send.    
    function () {
       sendValues(msg.value);
    }
    
    function sendValues(uint _amount) {
        CrowdfundingInterface funding = CrowdfundingInterface(dao);
        if (now < funding.closingTime()) 
           funding.buyTokenProxy.value(_amount)(owner);
        else if (_amount > 0)
           owner.send(_amount);
    }
}
