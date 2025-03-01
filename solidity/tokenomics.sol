// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^4.0.0
pragma solidity ^0.8.22;

    import {Owner} from "tests/Owner.sol";
    import {AntiWhale} from "tests/antiwhale.sol";
    import {Governance} from "tests/governance.sol";


contract Tokenomics is Owner, AntiWhale, Governance{
    /* Tokenomics settings
        - intialSupply is the initial minted amount of tokens.
        - monthlyInflation is the tokens that will be minted every month for the team, as there is no starting VC.
        - Fee is the burn fee for all TX that apply to everyone.
    */
    uint8 public _decimals;
    uint256 public _intialSupply;
    uint8 public monthlyInflation = 10; // 0.1%
    uint8 public Fee = 25;



    constructor(uint256 _initialSupply)
        //Owner(msg.sender)
    {
        _intialSupply = _initialSupply;
    }


    function viewIntialSupply() public view returns (uint256) {
        return _intialSupply;
    }

    function realSupply() public view returns (uint256) {
        uint256 _realSupply = _intialSupply / 10 ** _decimals;
        return _realSupply;
    }
}
