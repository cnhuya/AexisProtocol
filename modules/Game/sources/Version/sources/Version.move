module new_dev::testVersion {
    use std::debug::print;
    use std::string::{String, utf8};
    use std::signer;
    use std::account;
    use std::timestamp; 
    use std::option::{Self, Option};
    use supra_framework::event;

    use new_dev::testPoints12::{Self as Points};
    use deployer::testConstantV4::{Self as Constant};
    use new_dev::testConstantAddressV4::{Self as ConstantAddress};

     const ERROR_NOT_PROPOSER: u64 = 1;
     const ERROR_PROPOSAL_ENDED: u64 = 2;
// Structs
    struct Version has copy, key, drop, store {version: String, time: u64, maintenance: u64}
    struct Proposal has copy, key, drop, store {proposer: address, version: String, time: u64, yes: u64, no: u64, veto: u64, period: u64, status: String, passed: bool}

    struct CurrentProposal has copy, key, drop, store {proposal: Proposal}

    struct PointsAccess has key {
        cap: Points::AccessCap,
    }

    /// Vote event
    #[event]
    struct VoteEvent has copy, drop, store {
        address: address,
        amount: u64,
        type: String,
    }

    /// Proposal Creation event
    #[event]
    struct ProposalCreatedEvent has copy, drop, store {
        proposal: Proposal,
    }

    /// Proposal End event
    #[event]
    struct ProposalEndedEvent has copy, drop, store {
        proposal: Proposal,
    }

    fun get_admin(): address {
        ConstantAddress::get_constantAddress_value(&ConstantAddress::viewConstant(utf8(b"Version"), utf8(b"Proposer")))
    }

// Initialize stats
    fun init_module(address: &signer) {
        assert!(signer::address_of(address) == get_admin(), ERROR_NOT_PROPOSER);


        if (!exists<Version>(get_admin())) {
            move_to(address, Version { version: utf8(b"0.1"), time: timestamp::now_seconds(), maintenance:0 });
        };

        let cap = Points::grant_cap(address);
        move_to(address, PointsAccess { cap });


    }

// Restricted functions
//    struct Proposal has copy, key, drop, store {id: u64, proposer: address, time: u64, yes: u64, no: u64, veto: u64, period: u64, status: String}
    public entry fun propose(signer: &signer, version: String, period: u64){
        assert!(signer::address_of(signer) == get_admin(), ERROR_NOT_PROPOSER);

        let proposal = Proposal {proposer: signer::address_of(signer), version: version, time: timestamp::now_seconds(), yes:0, no:0, veto:0, period: period, status: utf8(b"Active"), passed: false};

        if (!exists<CurrentProposal>(get_admin())) {
            move_to(signer, CurrentProposal { proposal: proposal });
        };

        event::emit(ProposalCreatedEvent { proposal });

    }

    public fun vote_yes(signer: &signer) acquires CurrentProposal, PointsAccess, Version{
        let current_proposal = borrow_global_mut<CurrentProposal>(get_admin());
        let points_access = borrow_global_mut<PointsAccess>(get_admin());
        let proposal = current_proposal.proposal;

        let amount = Points::view_points(signer::address_of(signer));

        let proposal_duration = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Version"),utf8(b"proposal_duration"))) as u64);
        if(proposal.time+proposal_duration > timestamp::now_seconds()){
            evaluate_proposal();
        };
        proposal.yes = proposal.yes + amount;
        let fee = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Version"),utf8(b"proposal_fee"))) as u64);
        Points::give_points(signer, &points_access.cap, fee*2, fee);

        event::emit(VoteEvent { address: signer::address_of(signer),amount: amount, type: utf8(b"Yes"),
        });
    }

    fun evaluate_proposal() acquires Version, CurrentProposal {
        let admin = get_admin();
        let version_ref = borrow_global_mut<Version>(admin);
        let current_proposal_ref = borrow_global_mut<CurrentProposal>(admin);
        let proposal = &current_proposal_ref.proposal;

        if (proposal.yes >= proposal.no) {
            *version_ref = Version { version: proposal.version,time: timestamp::now_seconds(),maintenance: timestamp::now_seconds() + proposal.period,};
            let x = move_from<CurrentProposal>(admin);
            event::emit(ProposalEndedEvent { proposal: x.proposal });
        }
    }

// View functions
    #[view]
    public fun view_current_version(): Version acquires Version{
        *borrow_global<Version>(get_admin())
    }

    #[view]
    public fun view_current_proposal(): option::Option<CurrentProposal> acquires CurrentProposal {
        let admin = get_admin();
        if (exists<CurrentProposal>(admin)) {
            let proposal_ref = borrow_global<CurrentProposal>(admin);
            option::some(*proposal_ref)
        } else {
            option::none<CurrentProposal>()
        }
    }

 #[test(account = @0x1, owner = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7)]
     public entry fun test(account: signer, owner: signer){
        print(&utf8(b" ACCOUNT ADDRESS "));
        print(&account);


        print(&utf8(b" OWNER ADDRESS "));
        print(&owner);


        let source_addr = signer::address_of(&account);
        
        init_module(&owner);

    }


}

