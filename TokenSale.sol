/*
The user of this contract is fully responsible for compliance with 
present or future regulations of finance, communications and the 
universal rights of digital beings.

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

    /// @notice buy token with `_tokenHolder` as the token holder.
    /// @param _tokenHolder The address of the receiver of the tokens
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
