// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



contract Governance {
    struct Proposal {
        uint id;
        string name;
        string description;
        uint256 start;
        uint256 end;
        uint voteCount;
        bool executed;
    }

    struct Voter {
        bool voted;
        uint vote;
    }

    // Mapping to store proposals
    mapping(uint => Proposal) public proposals;

    // Mapping to store voters
    mapping(address => Voter) public voters;


    // Address of the contract owner
    address public owner;

    // Event to emit when a new proposal is created
    event ProposalCreated(uint id, string description);

    // Event to emit when a vote is cast
    event VoteCast(address voter, uint proposalId);

    // Event to emit when a proposal is executed
    event ProposalExecuted(uint id);

    // Modifier to restrict access to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    // Constructor to set the owner
    constructor() {
        owner = msg.sender;
    }


    // Function to create a new proposal
    function createProposal(uint _proposalId, string memory _name_, string memory _description,uint _period_) internal virtual onlyOwner {
        uint256 _now = block.timestamp;
        uint _end = _now + _period_;
        proposals[_proposalId] = Proposal(_proposalId,_name_,_description,_now,_end, 0, false);
        emit ProposalCreated(_proposalId, _description);
    }

    // Function to vote on a proposal
    function vote(uint _proposalId, uint amount) internal virtual {
        require(!voters[msg.sender].voted, "You have already voted");
        require(_proposalId > 0, "Invalid proposal ID");

        voters[msg.sender].voted = true;
        voters[msg.sender].vote = _proposalId;
        proposals[_proposalId].voteCount += amount;

        emit VoteCast(msg.sender, _proposalId);
    }

    // Function to execute a proposal
    function executeProposal(uint _proposalId) public onlyOwner {
        require(_proposalId > 0, "Invalid proposal ID");
        require(!proposals[_proposalId].executed, "Proposal already executed");

        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);
    }

    // Function to get the details of a proposal
    function getProposal(uint _proposalId) public view returns (uint, string memory, string memory, uint,uint,uint, bool) {
        require(_proposalId > 0, "Invalid proposal ID");
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.id, proposal.name, proposal.description, proposal.voteCount,proposal.end,proposal.start, proposal.executed);
    }
}
