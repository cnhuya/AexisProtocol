// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Owner{

    address public owner;
    address public FeeCollector = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        constructor(address _owner)
    {
        owner = _owner;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    function setOwner()internal onlyOwner{}
}
