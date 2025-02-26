
// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^4.0.0
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    // Declare abc as a state variable
    address public abc;

    constructor()
        ERC20("MyToken", "MTK")
        Ownable(msg.sender)
        ERC20Permit("MyToken")
    {
        _mint(msg.sender, 1000000 * 10 ** decimals());
        // Initialize the state variable abc
        abc = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    }

    // Mint function to allow the owner to mint new tokens
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function realSupply() public view virtual returns (uint256) {
       uint256 _realSupply = totalSupply() / (10 ** decimals());
       return _realSupply;
    }

    // Burn function to allow the owner to burn tokens from any address
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    // Override the transfer function to add custom logic
    function transfer(address to, uint256 amount) public override returns (bool) {
        burn(msg.sender, (amount * 10 ** decimals()) / 100);
        _transfer(msg.sender, to, amount);
        return true;
    }
}