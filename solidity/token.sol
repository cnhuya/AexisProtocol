// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^4.0.0
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol"; 
import {AntiWhale} from "tests/antiwhale.sol";


contract Aexis is ERC20, ERC20Burnable, Ownable, ERC20Permit, AntiWhale {
    address public FeeCollector = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    uint8 public monthlyInflation = 10; // 0.1%
    uint8 public Fee = 25;
    uint256 public lastTimeClaimed;
    uint256 public difference;
    uint256 private abc = 100 * 10 ** decimals();

    constructor()
        ERC20("Aexis Test", "AXS")
        Ownable(msg.sender)
        ERC20Permit("Aexis Test")
        AntiWhale(abc) // Correct constructor invocation
    {
        mint(msg.sender, abc);
        lastTimeClaimed = block.timestamp;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function realSupply() public view returns (uint256) {
        uint256 _realSupply = totalSupply() / 10 ** decimals();
        return _realSupply;
    }

    function burn(address from, uint256 amount) public onlyOwner { // Override burn
        _burn(from, amount);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        uint256 taxxedAmount = ((amount * Fee) / 100) / 100;
        uint256 _amount = amount - taxxedAmount;
        _transfer(msg.sender, to, _amount);
        _transfer(msg.sender, FeeCollector, taxxedAmount);
        return true;
    }


    function checkSnipe() public{
        require(balanceOf(msg.sender) >= 1, "Not enough tokens to call this function");
        burn(msg.sender,1);
        snipe();
        mint(msg.sender,2);
    }

    function inflation() public onlyOwner {
        uint256 currentTime = block.timestamp;
        require(currentTime >= lastTimeClaimed, "Too soon for inflation");
        uint256 daysPassed = (currentTime - lastTimeClaimed);
        uint256 inflationAmount = ((realSupply() * (monthlyInflation) * daysPassed) / (100)) * 10 ** decimals();
        difference = daysPassed;
        lastTimeClaimed = currentTime;
        _mint(msg.sender, inflationAmount);
    }
}