// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

    import {Owner} from "tests/Owner.sol";
    import {Infinity} from "tests/infinity.sol";

contract Governance is Owner, Infinity{

    enum DataType {
        Address,
        Uint
    }

    struct Proposal {
        uint id;
        uint code;
        string name;
        string description;
        bytes data; 
        bytes prevData;
        bool isAdress;
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
    mapping(uint => Proposal) public proposalsDatabase;

    // Mapping to store voters
    mapping(address => Voter) public voters;

    uint256 proposalCount = 1;

    uint32 internal proposalFee = 40000; // essencially a 0.0025%
    uint32 internal proposerVotingPower = 50;
    uint32 internal minimumVotingPower = 100;
    uint256 internal mintAllowance = 0;

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
        address oldAddress;
       if (_code == 1) {
            oldAddress = owner;
        } else if (_code == 2) {

        } else if (_code == 3) {

        }  else if (_code == 4) {
             oldAddress = FeeCollector;
        } 
        bytes memory encodedOldValue = abi.encode(oldAddress);
        _createProposal(_code, _name_, _description, encodedValue,encodedOldValue,true, _period_);
    }

    function createUintProposal(uint _code, string memory _name_, string memory _description, uint _newValue, uint _period_) internal onlyOwner {
        bytes memory encodedValue = abi.encode(_newValue);
        uint oldValue;
       if (_code == 5) {
            oldValue = viewInflation();
        } else if (_code == 6) {
            oldValue = viewFee();
        } else if (_code == 7) {
            oldValue = mintAllowance;
        }  else if (_code == 8) {
             oldValue = proposalFee;
        }  else if (_code == 9) {
             oldValue = proposerVotingPower;
        }  else if (_code == 10) {
             oldValue = pointsForTX;
        }  else if (_code == 11) {
             oldValue = pointsForVolumePercentage;
        }  else if (_code == 12) {
             oldValue = MinimumValueForHolderDetection;
        }  else if (_code == 13) {
             oldValue = minimumVotingPower;
        }  
        bytes memory encodedOldValue = abi.encode(oldValue);
        _createProposal(_code, _name_, _description, encodedValue, encodedOldValue,false, _period_);
    }

    function _createProposal(uint _code, string memory _name_, string memory _description, bytes memory _data, bytes memory _olddata, bool _isAdress, uint _period_) internal virtual {
        uint256 _now = block.timestamp;
        uint _end = _now + _period_;
        proposalsDatabase[proposalCount] = Proposal(proposalCount, _code, _name_, _description, _data,_olddata, _isAdress, _now, _end, 0, 0, 1);
        proposals[_code] = Proposal(proposalCount, _code, _name_, _description, _data,_olddata, _isAdress, _now, _end, 0, 0, 1);
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
        
        addUserStats(msg.sender, minimumVotingPower);
        emit VoteCast(msg.sender, _proposalId);
}


    function requirements(uint8 _code) internal virtual onlyOwner {
        require(block.timestamp >= getProposalEnd(_code) , "Proposal not finished");
        require(getProposalYes(_code) >= getProposalNo(_code), "Not enough Yes votes");
    }

    function closeProposal(uint8 _code) internal onlyOwner {
        Proposal storage proposal = proposals[_code];
        require(getProposalResult(_code) != 2, "Proposal already ended.");
        proposal.state = 2;
    }

    function changeOwner() public onlyOwner  {
        requirements(code_changeOwner);
        address newOwner = getProposalAddressValue(code_changeOwner);
        closeProposal(code_changeOwner);
        owner = newOwner;
    }

    function allowValidator() public onlyOwner  {
        requirements(code_addValidator);
        address newValidator = getProposalAddressValue(code_addValidator);
        closeProposal(code_addValidator);
        Validator[newValidator] = true;
    }

    function removeValidator() public onlyOwner  {
        requirements(code_removeValidator);
        address newValidator = getProposalAddressValue(code_removeValidator);
        closeProposal(code_addValidator);
        Validator[newValidator] = false;
    }

    function changeFeeCollector() public onlyOwner  {
        requirements(code_changeFeeCollector);
        address newFeeCollector = getProposalAddressValue(code_changeFeeCollector);
        closeProposal(code_addValidator);
        FeeCollector = newFeeCollector;
    }

    function changeInflation() public onlyOwner  {
        requirements(code_changeInflation);
        uint newMonthlyInflation = getProposalUintValue(code_changeInflation);
        closeProposal(code_addValidator);
        monthlyInflation = uint8(newMonthlyInflation);
    }

    function changeFee() public onlyOwner  {
        requirements(code_changeFee);
        uint newFee = getProposalUintValue(code_changeFee);
        closeProposal(code_addValidator);
        _Fee = uint8(newFee);
    }
    
    function _allowMint() internal onlyOwner  {
        require(getProposalResult(code_purposeMint) == 2, "Proposal not finished");
        require(getProposalYes(code_purposeMint) >= getProposalNo(code_purposeMint), "Not enough Yes votes");

        uint mintValue = getProposalUintValue(code_purposeMint);
        mintAllowance = mintValue;
    }

    function changeProposalFee() public onlyOwner  {
        requirements(code_changeProposalFee);
        uint newProposalFee = getProposalUintValue(code_changeProposalFee);
        closeProposal(code_addValidator);
        proposalFee = uint8(newProposalFee);
    }

    function changeProposalVotingPower() public onlyOwner  {
        requirements(code_changeProposerVotingPower);
        uint newProposerVotingPower = getProposalUintValue(code_changeProposerVotingPower);
        closeProposal(code_addValidator);
        proposerVotingPower = uint8(newProposerVotingPower);
    }

    function changePointsForTX() public onlyOwner  {
        requirements(code_changePointsForTX);
        uint newPointsForTX = getProposalUintValue(code_changePointsForTX);
        closeProposal(code_addValidator);
        pointsForTX = uint8(newPointsForTX);
    }    

    function changePointsForVolumePercentage() public onlyOwner  {
        requirements(code_changePointsForVolumePercentage);
        uint newPointsForVolumePercentage = getProposalUintValue(code_changePointsForVolumePercentage);
        closeProposal(code_addValidator);
        pointsForVolumePercentage = uint8(newPointsForVolumePercentage);
    }        

    function changeMinimumValueForHolderDetection() public onlyOwner  {
        requirements(code_changeMinimumValueForHolderDetection);
        uint newMinimumValueForHolderDetection = getProposalUintValue(code_changeMinimumValueForHolderDetection);
        closeProposal(code_addValidator);
        MinimumValueForHolderDetection = uint8(newMinimumValueForHolderDetection);
    }      

    function changeMiminimumVotingPower() public onlyOwner  {
        requirements(code_changeMinimumVotingPower);
        uint newMiminimumVotingPower = getProposalUintValue(code_changeMinimumVotingPower);
        closeProposal(code_addValidator);
        minimumVotingPower = uint8(newMiminimumVotingPower); 
    }      
    
    // Function to get the details of a proposal
    function getProposal(uint _proposalId) public view returns (uint id, uint code, string memory name_, string memory description, bytes memory data, uint256 start, uint256 end, uint yes, uint no, uint8 state) {
        Proposal memory proposal = proposals[_proposalId];
        bytes memory abc;
        if(proposal.isAdress == true){
            address decodedValue = abi.decode(proposals[_proposalId].data, (address)); 
            abc = abi.encodePacked(decodedValue); // Use abi.encodePacked()
        }
        else{
            uint decodedValue = abi.decode(proposals[_proposalId].data, (uint)); 
            abc = abi.encodePacked(decodedValue); // Use abi.encodePacked()
        }
        return (proposal.id, proposal.code, proposal.name, proposal.description, abc, proposal.start, proposal.end, proposal.yes, proposal.no, proposal.state);
    }

    function getProposalName(uint _proposalId) internal view returns (string memory){
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.name);
    }

    function getProposalDesc(uint _proposalId) internal view returns (string memory){
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.description);
    }

    function getProposalYes(uint _proposalId) internal view returns (uint256){
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.yes);
    }

    function getProposalNo(uint _proposalId) internal view returns (uint256){
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

    function getProposalEnd(uint _proposalId) internal view returns (uint256){
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.end);
    }

    function getProposalStart(uint _proposalId) internal view returns (uint256){
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

    function viewProposalFee() internal view virtual returns (uint256 Proposal_Fee) {
        return (proposalFee);
    }

    function viewProposerVotingPower() internal view virtual returns (uint256 Proposer_Voting_Power) {
        return (proposerVotingPower);
    }

    function viewMinimumVotingPower() internal view virtual returns (uint256 Minimum_Voting_Power) {
        return (minimumVotingPower);
    }

    
    function infoSettingsProposals() public view virtual returns (uint256 Proposal_Fee, uint256 Proposer_Voting_Power, uint256 Minimum_Voting_Power) {
        return (viewProposalFee(), viewProposerVotingPower(), viewMinimumVotingPower());
    }
}
