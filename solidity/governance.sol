// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

    import {Owner} from "tests/Owner.sol";
    import {Infinity} from "tests/infinity.sol";

contract Governance is Owner, Infinity{
    struct Proposal {
        uint id;
        uint code;
        string name;
        string description;
        bytes data; 
        uint256 start;
        uint256 end;
        uint yes;
        uint no;
        uint8 state;
    }

    constructor()
        Owner(msg.sender)
        Infinity()
    {

    }

    struct Voter {
        mapping(uint => bool) proposalVotes;
        uint vote;
    }

    // Mapping to store proposals
    mapping(uint => Proposal) public proposals;

    // Mapping to store voters
    mapping(address => Voter) public voters;

    uint256 proposalCount;

    uint32 public proposalFee = 40000; // essencially a 0.0025%
    uint32 proposerVotingPower = 50;
    uint32 internal minimumVotingPower = 100;

    event ProposalCreated(uint id, string description);

    event VoteCast(address voter, uint proposalId);

    event ProposalExecuted(uint id);


    // Governance Codes (ABSOLUTELY DO NOT TOUCH, HIGH RISK, COULD BREAK EVERYTHING, OR EXPLOITS COULD ARISE.)
    uint8 code_changeOwner = 1;
    uint8 code_addValidator = 2;
    uint8 code_removeValidator = 3;
    uint8 code_changeFeeCollector = 4;
    uint8 code_changeInflation = 5;
    uint8 code_changeFee = 6;
    uint8 code_purposeMint = 7;
    uint8 code_changeProposalFee = 8;
    uint8 code_changeProposerVotingPower = 9;
    uint8 code_changePointsForTX = 10;
    uint8 code_changePointsForVolumePercentage = 11;
    uint8 code_changeMinimumValueForHolderDetection = 12;
    uint8 code_changeMinimumVotingPower = 13;

    
    function createAddressProposal(uint _code, string memory _name_, string memory _description, address _newValue, uint _period_) internal onlyOwner {
        bytes memory encodedValue = abi.encode(_newValue);
        _createProposal(_code, _name_, _description, encodedValue, _period_);
    }

    function createUintProposal(uint _code, string memory _name_, string memory _description, uint _newValue, uint _period_) internal onlyOwner {
        bytes memory encodedValue = abi.encode(_newValue);
        _createProposal(_code, _name_, _description, encodedValue, _period_);
    }

    function _createProposal(uint _code, string memory _name_, string memory _description, bytes memory _data, uint _period_) internal virtual {
        uint256 _now = block.timestamp;
        uint _end = _now + _period_;
        proposals[_code] = Proposal(proposalCount, _code, _name_, _description, _data, _now, _end, 0, 0, 1);
        proposalCount++;
        emit ProposalCreated(_code, _description);
    }

    function vote(uint _proposalId, uint amount, bool isYes) internal virtual {
        
        require(!voters[msg.sender].proposalVotes[_proposalId], "You have already voted on this proposal");
        
        voters[msg.sender].proposalVotes[_proposalId] = true;
        
        if(isYes == true){
            proposals[_proposalId].yes += amount;
        }
        else{
            proposals[_proposalId].no += amount;
        }
        
        emit VoteCast(msg.sender, _proposalId);
}


    function requirements(uint8 _code) internal virtual onlyOwner {
        require(getProposalEnd(_code) >= getProposalStart(_code), "Proposal not finished");
        require(getProposalYes(_code) >= getProposalNo(_code), "Not enough Yes votes");
    }

    function changeOwner() public onlyOwner  {
        requirements(code_changeOwner);
        address newOwner = getProposalAddressValue(code_changeOwner);
        owner = newOwner;
    }

    function allowValidator() public onlyOwner  {
        requirements(code_addValidator);
        address newValidator = getProposalAddressValue(code_addValidator);
        Validator[newValidator] = false;
    }

    function removeValidator() public onlyOwner  {
        requirements(code_removeValidator);
        address newValidator = getProposalAddressValue(code_removeValidator);
        Validator[newValidator] = false;
    }

    function changeFeeCollector() public onlyOwner  {
        requirements(code_changeFeeCollector);
        address newFeeCollector = getProposalAddressValue(code_changeFeeCollector);
        FeeCollector = newFeeCollector;
    }

    function changeInflation() public onlyOwner  {
        requirements(code_changeInflation);
        uint newMonthlyInflation = getProposalUintValue(code_changeInflation);
        monthlyInflation = uint8(newMonthlyInflation);
    }

    function changeFee() public onlyOwner  {
        requirements(code_changeFee);
        uint newFee = getProposalUintValue(code_changeFee);
        Fee = uint8(newFee);
    }
    
   /* function allowMint() public onlyOwner  {
        require(getProposalResult(code_purposeMint) == 2, "Proposal not finished");
        require(getProposalYes(code_purposeMint) >= getProposalNo(code_purposeMint), "Not enough Yes votes");

        uint mintValue = getProposalUintValue(code_purposeMint);
        //_mint(owner, mintValue);
    }*/

    function changeProposalFee() public onlyOwner  {
        requirements(code_changeProposalFee);
        uint newProposalFee = getProposalUintValue(code_changeProposalFee);
        proposalFee = uint8(newProposalFee);
    }

    function changeProposalVotingPower() public onlyOwner  {
        requirements(code_changeProposerVotingPower);
        uint newProposerVotingPower = getProposalUintValue(code_changeProposerVotingPower);
        proposerVotingPower = uint8(newProposerVotingPower);
    }

    function changePointsForTX() public onlyOwner  {
        requirements(code_changePointsForTX);
        uint newPointsForTX = getProposalUintValue(code_changePointsForTX);
        pointsForTX = uint8(newPointsForTX);
    }    

    function changePointsForVolumePercentage() public onlyOwner  {
        requirements(code_changePointsForVolumePercentage);
        uint newPointsForVolumePercentage = getProposalUintValue(code_changePointsForVolumePercentage);
        pointsForVolumePercentage = uint8(newPointsForVolumePercentage);
    }        

    function changeMinimumValueForHolderDetection() public onlyOwner  {
        requirements(code_changeMinimumValueForHolderDetection);
        uint newMinimumValueForHolderDetection = getProposalUintValue(code_changeMinimumValueForHolderDetection);
        MinimumValueForHolderDetection = uint8(newMinimumValueForHolderDetection);
    }      

    function changeMiminimumVotingPower() public onlyOwner  {
        requirements(code_changeMinimumVotingPower);
        uint newMiminimumVotingPower = getProposalUintValue(code_changeMinimumVotingPower);
        minimumVotingPower = uint8(newMiminimumVotingPower);
    }      

    // Function to get the details of a proposal
    function getProposal(uint _proposalId) public view returns (uint id, uint code, string memory name_, string memory description, bytes memory data, uint256 start, uint256 end, uint yes, uint no, uint8 state) {
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.id, proposal.code, proposal.name, proposal.description, proposal.data, proposal.start, proposal.end, proposal.yes, proposal.no, proposal.state);
    }

    function getProposalName(uint _proposalId) internal view returns (string memory){
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.name);
    }

    function getProposalDesc(uint _proposalId) internal view returns (string memory){
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.description);
    }

    function getProposalYes(uint _proposalId) public view returns (uint256){
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.yes);
    }

    function getProposalNo(uint _proposalId) public view returns (uint256){
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.no);
    }

    function getProposalStats(uint _proposalId) public view returns (uint256 Yes, uint256 No){
        return (getProposalYes(_proposalId), getProposalNo(_proposalId));
    }

    function getProposalAddressValue(uint _proposalId) public view returns (address) {
        return abi.decode(proposals[_proposalId].data, (address));
    }

    function getProposalUintValue(uint _proposalId) public view returns (uint) {
        return abi.decode(proposals[_proposalId].data, (uint));
    }

    function getProposalEnd(uint _proposalId) public view returns (uint256){
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.end);
    }

    function getProposalStart(uint _proposalId) public view returns (uint256){
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.start);
    }

    function getProposalResult(uint _proposalId) internal view returns (uint8){
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.state);
    }
    function getProposalCount() public view returns (uint256){
        return proposalCount;
    }
}
