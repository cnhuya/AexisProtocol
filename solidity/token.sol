// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^4.0.0
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {AntiWhale} from "tests/antiwhale.sol";
import {Governance} from "tests/governance.sol";
import {Tokenomics} from "tests/tokenomics.sol";

contract Aexis is ERC20, ERC20Burnable, ERC20Permit, AntiWhale, Governance, Tokenomics {

    uint256 private intialSupply = 100 * 10 ** decimals();

    // Variables for  public goods, anyone can view when was the lasttime the team claimed tokens and how much.
    uint256 public lastTimeClaimed;
    uint256 public claimed;


    constructor()
        ERC20("Aexis Test", "AXS")
        Governance()
        ERC20Permit("Aexis Test")
        AntiWhale()
        Tokenomics(intialSupply)
    {
        _mint(msg.sender, intialSupply);
        lastTimeClaimed = block.timestamp;
    }



    function transfer(address to, uint256 amount) public override returns (bool) {
        uint256 taxxedAmount = ((amount * Fee) / 100) / 100;
        uint256 _amount = amount - taxxedAmount;
        _transfer(msg.sender, to, _amount);
        _transfer(msg.sender, FeeCollector, taxxedAmount);
        return true;
    }

    function _Tokenomics() public view returns (uint256 _initialSupply, uint256 _actualSupply, uint256 _burned, uint256 _minted, uint256 _claimed) {
        // Return values are named in the function signature
        return (intialSupply, totalSupply(), burned, minted, claimed);
    }

        function checkSnipe() public{
        require(balanceOf(msg.sender) >= 1, "Not enough tokens to call this function");
        burn(1);
        snipe();
        _mint(msg.sender,2);
    }

    function claimInflation() public onlyOwner {
        uint256 currentTime = block.timestamp;
        require(currentTime >= lastTimeClaimed, "Too soon for inflation");
        uint256 daysPassed = (currentTime - lastTimeClaimed);
        uint256 inflationAmount = ((realSupply() * (monthlyInflation) * daysPassed) / (100)) * 10 ** decimals();
        lastTimeClaimed = currentTime;
        claimed += inflationAmount;
        _mint(msg.sender, inflationAmount);
    }


    function _createProposal(uint _code, string memory _name_,string memory _description, string memory _newValue, uint _period_) public onlyOwner {
        // Requires 0.005% of total supply in order to create a proposal.
        uint256 _proposalFee = (uint256(proposalFee) * totalSupply()) / 10 ** 5;
        require(balanceOf(msg.sender) >= _proposalFee, "Not enough tokens to call this function");
        burn(_proposalFee);
        uint256 _now = block.timestamp;
        require(_now> getProposalEnd(proposalCount), "Previous proposal did not end yet"); 
        createProposal(_code, _name_, _description, _newValue, _period_);
        vote(proposalCount, balanceOf(msg.sender) * proposerVotingPower, true);
    }

}
