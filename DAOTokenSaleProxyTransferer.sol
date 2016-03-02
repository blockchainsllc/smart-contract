/*
This file is part of the DAO.

The DAO is free software: you can redistribute it and/or modify
it under the terms of the GNU lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The DAO is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the DAO.  If not, see <http://www.gnu.org/licenses/>.
*/


/* 
Basic proxy contract which transfers all the value to the DAO by calling its buyTokenProxy-Function.
This allows Exchanges to simply transfer money to an address which then will be forwarded to the DAO
*/

import "./TokenSale.sol";

contract DAOTokenSaleProxyTransferer {
    address public owner;
    address public dao;

    //constructor 
    function DAOTokenSaleProxyTransferer(address _owner, address _dao) {
        owner = _owner;
        dao   = _dao;
        
        // just in case somebody already added values to this address, we will forward it right now.
        sendValues();
    }
    
    // default-function called when values are send.    
    function () {
       sendValues();
    }
    
    function sendValues() {
        if (this.balance == 0) return;
        
        TokenSaleInterface funding = TokenSaleInterface(dao);
        if (now > funding.closingTime() || !funding.buyTokenProxy.value(this.balance)(owner))
           owner.send(this.balance);
    }
}
