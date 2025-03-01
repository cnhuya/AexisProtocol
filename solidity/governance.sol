// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


    import {Owner} from "tests/Owner.sol";

    /* TODO LIST
    
    - AUTOMATIC PROPOSAL VOTING ON LAST VOTE?, LIKE IT WOULD CHECK WHENEVER END > START AND IF END > NOW THEN PROPOSAL STATE = 3?
    - ADD FUNCTION TO GET NUMBER OF VOTERS ON A PROPOSAL?
    
    - VOTING POWER = TOKEN BALANCE / 10 ?
    - EVENTS -> PROPOSAL CREATED, VOTE CAST, PROPOSAL EXECUTED
    - REWARDS FOR VOTERS?
    
    */


contract Governance is Owner{
    struct Proposal {
        uint id;
        uint code;
        string name;
        string description;
        string newValue;
        uint256 start;
        uint256 end;
        uint Yes;
        uint No;
        uint8 state;

        // state 1 - started
        // state 2 - finished
        // state 0 - not innitialized

    }

    constructor()
        Owner(msg.sender)
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

    // Proposal Variables, the proposalFee is (value of variable)5 / (stable)10*5, its basically 0.00X%
    uint8 public proposalFee = 5;
    uint8 proposerVotingPower = 2;

    event ProposalCreated(uint id, string description);

    event VoteCast(address voter, uint proposalId);

    event ProposalExecuted(uint id);



    // Governance Codes (ABSOLUTELY DO NOT TOUCH, HIGH RISK, COULD BREAK EVERYTHING, OR EXPLOITS COULD ARISE.)
    uint8 code_changeOwner = 1;
    uint8 code_changeFeeCollector = 2;
    uint8 code_changeInflation = 3;
    uint8 code_changeFee = 4;
    uint8 code_purposeMint = 5;
    uint8 code_changeProposalFee = 6;
    uint8 code_changeProposerVotingPower = 7;

    // Function to create a new proposal
    function createProposal(uint _code, string memory _name_, string memory _description, string memory _newValue, uint _period_) internal virtual onlyOwner {
        uint256 _now = block.timestamp;
        uint _end = _now + _period_;
        proposals[proposalCount] = Proposal(proposalCount,_code,_name_,_description, _newValue, _now,_end, 0,0, 1);
        proposalCount++;
        emit ProposalCreated(proposalCount, _description);
    }

    function vote(uint _proposalId, uint amount, bool isYes) internal virtual {
        // Check if the proposal ID is valid
        
        // Check if the user has already voted on this specific proposal
        require(!voters[msg.sender].proposalVotes[_proposalId], "You have already voted on this proposal");
        
        // Mark that the user has voted on this specific proposal
        voters[msg.sender].proposalVotes[_proposalId] = true;
        
        // Store the vote
        if(isYes == true){
            proposals[_proposalId].Yes += amount;
        }
        else{
            proposals[_proposalId].No += amount;
        }
        
        emit VoteCast(msg.sender, _proposalId);
}

    // Function to execute a proposal
    function executeProposal(uint _proposalId) public onlyOwner {
        require(_proposalId > 0, "Invalid proposal ID");
        require(proposals[_proposalId].state != 1, "Proposal already executed");

        proposals[_proposalId].state = 2;
        emit ProposalExecuted(_proposalId);
    }


/*    // Governance Codes (ABSOLUTELY DO NOT TOUCH, HIGH RISK, COULD BREAK EVERYTHING, OR EXPLOITS COULD ARISE.)
    uint8 changeOwner = 1;
    uint8 changeFeeCollector = 2;
    uint8 changeInflation = 3;
    uint8 changeFee = 4;
    uint8 purposeMint = 5;
    uint8 changeProposalFee = 6;
    uint8 changeProposerVotingPower = 7;*/

    function changeOwner(address newOwner) public onlyOwner  {
        require(getProposalResult(code_changeOwner) == 2, "Proposal not finished");
        require(getProposalYes(code_changeOwner) >= getProposalNo(code_changeOwner), "Not enough Yes votes");
        owner = newOwner;
    }

    function changeFeeCollector(address newFeeCollector) public onlyOwner  {
        require(getProposalResult(code_changeFeeCollector) == 2, "Proposal not finished");
        require(getProposalYes(code_changeFeeCollector) >= getProposalNo(code_changeFeeCollector), "Not enough Yes votes");
        FeeCollector = newFeeCollector;
    }

    // Function to get the details of a proposal
    function getProposal(uint _proposalId) public view returns (Proposal memory) {
       // require(_proposalId > 0, "Invalid proposal ID");
        Proposal memory proposal = proposals[_proposalId];
        return (proposal);
    }

    function getProposalName(uint _proposalId) internal view returns (string memory){
      //  require(_proposalId > 0, "Invalid proposal ID");
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.name);
    }

    function getProposalDesc(uint _proposalId) internal view returns (string memory){
       // require(_proposalId > 0, "Invalid proposal ID");
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.description);
    }

    function getProposalYes(uint _proposalId) public view returns (uint256){
       // require(_proposalId > 0, "Invalid proposal ID");
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.Yes);
    }

    function getProposalNo(uint _proposalId) public view returns (uint256){
       // require(_proposalId > 0, "Invalid proposal ID");
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.No);
    }


    function getProposalStats(uint _proposalId) public view returns (uint256 Yes, uint256 No){
       // require(_proposalId > 0, "Invalid proposal ID");
        return (getProposalYes(_proposalId), getProposalNo(_proposalId));
    }


    function getProposalNewValue(uint _proposalId) internal view returns (string memory){
      //  require(_proposalId > 0, "Invalid proposal ID");
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.newValue);
    }

    function getProposalEnd(uint _proposalId) internal view returns (uint256){
      //  require(_proposalId > 0, "Invalid proposal ID");
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.end);
    }

    function getProposalStart(uint _proposalId) internal view returns (uint256){
      //  require(_proposalId > 0, "Invalid proposal ID");
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.start);
    }

    function getProposalResult(uint _proposalId) internal view returns (uint8){
       // require(_proposalId > 0, "Invalid proposal ID");
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.state);
    }
    function getProposalCount() public view returns (uint256){
        return proposalCount;
    }
}
