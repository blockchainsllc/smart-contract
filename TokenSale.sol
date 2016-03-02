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
Basic Token Sale contract
*/

import "./Token.sol";

contract TokenSaleInterface {

    uint public closingTime;                   // end of token sale
    uint public minValue;                      // minimal goal of token sale
    bool public funded;                        // true if project is funded, false otherwise

    /// @dev Constructor setting the minimal target and the end of the Token Sale
    /// @param _minValue Minimal value for a successful Token Sale
    /// @param _closingTime Date (in unix time) of the end of the Token Sale
    //  function TokenSale(uint _minValue, uint _closingTime);

    /// @notice buy Token with `_tokenHolder` as the Token holder.
    /// @param _tokenHolder The address of the receiver of the Tokens
    function buyTokenProxy(address _tokenHolder) returns (bool success);

    /// @notice Refund `msg.sender` in the case of a not successful Token Sale
    function refund();

    event Funded(uint value);
    event SoldToken(address indexed to, uint amount);
    event Refund(address indexed to, uint value);
}

contract TokenSale is TokenSaleInterface, Token {

    function TokenSale(uint _minValue, uint _closingTime) {
        closingTime = _closingTime;
        minValue = _minValue;
    }


    function buyTokenProxy(address _tokenHolder) returns (bool success) {
        if (now < closingTime && msg.value > 0) {
            uint token = msg.value;
            balances[_tokenHolder] += token;
            totalSupply += token;
            SoldToken(_tokenHolder, token);
            if (totalSupply >= minValue && !funded) {
                funded = true;
                Funded(totalSupply);
            }
            return true;
        }
        throw;
    }


    function refund() noEther {
        if (now > closingTime
            && !funded
            && msg.sender.send(balances[msg.sender])) // execute refund
        {
            Refund(msg.sender, balances[msg.sender]);
            totalSupply -= balances[msg.sender];
            balances[msg.sender] = 0;
        }
    }
}
