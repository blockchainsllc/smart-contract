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


Basic account, managed by another contract
*/

contract ManagedAccountInterface {
    address public owner;
    uint public accumulatedInput;

    function payOut(address _recipient, uint _amount) returns (bool);

    event PayOut(address _recipient, uint _amount);
}

contract ManagedAccount is ManagedAccountInterface{

    function ManagedAccount(address _owner){
        owner = _owner;
    }

    function(){
        accumulatedInput += msg.value;
    }

    function payOut(address _recipient, uint _amount) returns (bool){
        if (msg.sender != owner || msg.value > 0) throw;
        if (_recipient.send(_amount)){
            PayOut(_recipient, _amount);
            return true;
        }
        else
            return false;
    }
}