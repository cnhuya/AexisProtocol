// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^4.0.0
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {AntiWhale} from "tests/antiwhale.sol";
import {Governance} from "tests/governance.sol";

contract Aexis is ERC20, ERC20Burnable, ERC20Permit, AntiWhale, Governance {

    uint256 private intialSupply = 111 * 10 ** decimals();
    uint256 public lastTimeClaimed;
    uint256 public claimed;

    constructor()
        ERC20("Aexis Test", "AXS")
        Governance()
        ERC20Permit("Aexis Test")
        AntiWhale()
    {
        _mint(msg.sender, intialSupply);
        lastTimeClaimed = block.timestamp;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        // 100 * 25) / 100 ) / 100
        uint256 taxxedAmount = ((amount * Fee) / 100) / 100;
        uint256 _amount = amount - taxxedAmount;
        _transfer(msg.sender, to, _amount);
        _transfer(msg.sender, FeeCollector, taxxedAmount/2);
        burn(taxxedAmount/2);
        addUserStats(msg.sender, amount/100);
        return true;
    }

    function _Tokenomics() public view returns (uint256 _initialSupply, uint256 _actualSupply, uint256 _burned, uint256 _minted, uint256 _claimed) {
        return (intialSupply, totalSupply(), burned, minted, claimed);
    }

    function claimInflation() public onlyOwner {
        uint256 currentTime = block.timestamp;
        require(currentTime >= lastTimeClaimed, "Too soon for inflation");
        uint256 daysPassed = (currentTime - lastTimeClaimed);
        uint256 inflationAmount = ((intialSupply * (monthlyInflation) * daysPassed) / (100));
        lastTimeClaimed = currentTime;
        claimed += inflationAmount;
        _mint(msg.sender, inflationAmount);
    }

    function check(uint _code) internal onlyOwner{
        uint256 _proposalFee =  totalSupply() / uint256(proposalFee);
        require(balanceOf(msg.sender) >= _proposalFee, "Not enough tokens to call this function");
        burn(_proposalFee);
        uint256 _now = block.timestamp;
        require(_now> getProposalEnd(_code), "Previous proposal did not end yet"); 
    }

    function createProposalUint(uint _code, string memory _name_,string memory _description, uint256 _data, uint _period_) public onlyOwner {
        check(_code);
        createUintProposal(_code, _name_, _description, _data, _period_);
        vote(proposalCount, balanceOf(msg.sender) + (balanceOf(msg.sender) / proposerVotingPower), true);
    }

    function createProposalAddress(uint _code, string memory _name_,string memory _description, address _data, uint _period_) public onlyOwner {
        check(_code);
        createAddressProposal(_code, _name_, _description, _data, _period_);
        vote(proposalCount, balanceOf(msg.sender) + (balanceOf(msg.sender) / proposerVotingPower), true);
    }

    function claimPoints() public {
        UserStats storage stats = users[msg.sender];
        require(getUserPoints(msg.sender) > 0, "Not enough points to claim!");
        uint256 timeHolding = (block.timestamp / 86400) - (stats.holderSince / 86400);
        // 10000 + 100 * 5 = 10500 total points
        uint256 amount = getUserPoints(msg.sender) + (getUserPoints(msg.sender)/100)*timeHolding;
        stats.points = 0;
        transferFrom(FeeCollector, msg.sender, amount);
    }

    function Vote(uint _code, bool isYes) public{
        require(getProposalEnd(_code) > block.timestamp, "Proposal already finished");
        require(balanceOf(msg.sender) >= minimumVotingPower, "Invalid balance to vote.");
        vote(_code, balanceOf(msg.sender),isYes);
        burn(minimumVotingPower);
        addUserStats(msg.sender, minimumVotingPower);
    }

}
