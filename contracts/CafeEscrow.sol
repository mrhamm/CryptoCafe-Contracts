pragma solidity ^0.8.0;

contract CafeEscrow{

    mapping ( address => bool ) withdrawals;


    function depositFunds() public payable returns(bool){
        if(msg.value!=0){
            return true;
        } else{
            return false;
        }
    }

    function takeAllowance() public returns(bool){
        require(withdrawals[msg.sender]==false,'Sorry, you already were given an allowance');
        address payable Address = payable(msg.sender);
        Address.transfer(200000000000000000);
        withdrawals[msg.sender]= true;
        return true;
    }

    
}