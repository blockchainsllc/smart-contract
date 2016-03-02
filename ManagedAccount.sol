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