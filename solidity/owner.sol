// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Owner{

    address public owner;

    mapping(address => bool) Validator;

    address public FeeCollector = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        constructor(address _owner)
    {
        owner = _owner;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    modifier validator() {
        require(Validator[msg.sender] == true, "Only the validator can perform this action..");
        _;
    }

    /*function addValidator(address newValidator) public onlyOwner{
        require(Validator[newValidator] == false, "Address is already a validator.");
        Validator[newValidator] = true;
    }

    function removeValidator(address newValidator) public onlyOwner{
        require(Validator[newValidator] == true, "Address is not marked as validator.");
        Validator[newValidator] = false;
    }*/
}
