module deployer::governancev4{
  
    use std::signer;
    use std::vector;
    use std::account;
    use std::string;
    use std::timestamp;
    use std::table;
    use std::debug::print;
    use 0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020::hierarchyv4;
    use 0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020::errorsv3;
    use std::string::utf8;

    const OWNER: address = @owner;
    const DEPLOYER: address = @deployer;
    const MESSAGER: address = @messager;
    
    const MODULE_ID: u16 = 3;


    struct CONTRACT has copy, store, key, drop {deployer: address, owner: address, validators: vector<address>}

    struct PROPOSAL has copy, key, store, drop {id: u32, proposer: address, moduleId: u16, moduleCode: u16, name: vector<u8>, desc: vector<u8>, start: u64, end: u64, stats: PROPOSAL_STATS}

    struct PROPOSAL_COUNTER has copy, key, store, drop {count: u32}

    struct VOTE has copy, key, store, drop {validator: address, voted: u8}

    // Ciste teoreticky by to slo udelat tak ze misto u32 by byl vector s bytama (string), kterej by obsahoval jmeno modulu treba? Misto PROPOSAL by byl vector<PROPOSAL> obsahujici 
    // vsechny dany proposals k danymu modulu.
    struct PROPOSAL_TABLE has key, store {proposals: table::Table<u32, PROPOSAL>}

    struct PROPOSAL_STATS has copy, drop, store, key {totalVotes: u128, yes: u64, no: u64}


    struct PROPOSAL_DATABASE has copy, drop, store, key {database: vector<PROPOSAL>}

    entry fun init_module(address: &signer) {
        
        let deploy_addr = signer::address_of(address);

        if (!exists<PROPOSAL>(deploy_addr)) {
            let proposal_stats = PROPOSAL_STATS{
                totalVotes: 0,
                yes: 0,
                no: 0,
            };
            move_to(address, PROPOSAL { id: 0, proposer: @0x0, moduleId: 0, moduleCode: 0, name: vector::empty(), desc: vector::empty(), start: 0, end: 0, stats: proposal_stats});
        };

        if (!exists<PROPOSAL_COUNTER>(deploy_addr)) {
            move_to(address, PROPOSAL_COUNTER {count: 1});
        };

        if (!exists<PROPOSAL_DATABASE>(deploy_addr)) {
            move_to(address, PROPOSAL_DATABASE {database: vector::empty()});
        };

        if (!exists<PROPOSAL_TABLE>(deploy_addr)) {
            let proposals_table = table::new<u32, PROPOSAL>();
            move_to(address, PROPOSAL_TABLE {proposals: proposals_table});
        };

    }

    entry fun innitializeProposal(address: &signer, _name: vector<u8>, _moduleId: u16,  _moduleCode: u16, _desc: vector<u8>, _period: u8) acquires PROPOSAL_TABLE, PROPOSAL_DATABASE, PROPOSAL_COUNTER{

        let addr = signer::address_of(address);

        let owner = hierarchyv4::viewOwner();

        assert!(addr == owner, errorsv3::returnError(1));

        let count = borrow_global_mut<PROPOSAL_COUNTER>(DEPLOYER);

        let start_time = timestamp::now_seconds();

        let proposal_stats = PROPOSAL_STATS{
            totalVotes: 0,
            yes: 0,
            no: 0,
        };

        let proposal = PROPOSAL{
            id: count.count,
            proposer: addr, 
            moduleId: _moduleId,
            moduleCode: _moduleCode,
            name: _name,
            desc: _desc,
            start: start_time,
            end: start_time + (((_period as u64) * 86400u64) as u64),
            stats: proposal_stats,
        };
        let proposal_table = borrow_global_mut<PROPOSAL_TABLE>(DEPLOYER);
        table::upsert(&mut proposal_table.proposals, count.count, proposal);



        let database = borrow_global_mut<PROPOSAL_DATABASE>(DEPLOYER);
        vector::push_back(&mut database.database, proposal);

        count.count = count.count + 1;
    }


    public entry fun createProposal(address: &signer, _name: vector<u8>,  _moduleId: u16,  _moduleCode: u16, _desc: vector<u8>, _period: u8) acquires PROPOSAL_COUNTER, PROPOSAL_DATABASE, PROPOSAL_TABLE
    {
        innitializeProposal(address, _name, _moduleId, _moduleCode, _desc, _period);
    }

    public entry fun changeProposal(address: &signer, _proposalId: u32, _name: vector<u8>,  _desc: vector<u8>) acquires PROPOSAL_TABLE, PROPOSAL_DATABASE, PROPOSAL_COUNTER {

        let addr = signer::address_of(address);
        let owner = hierarchyv4::viewOwner();
        assert!(addr == owner, errorsv3::returnError(1));
        //let data = *table::borrow(&changes_table.modules, _moduleID);

        //let changes_table = borrow_global_mut<MODULES_UPRAGE_TABLE>(DEPLOYER);
        //assert!(table::contains(&changes_table.modules, _moduleID), ERROR_MODULE_NOT_INNITIALIZED);
        //let data = *table::borrow(&changes_table.modules, _moduleID);

        let proposal_table = borrow_global_mut<PROPOSAL_TABLE>(DEPLOYER);
        assert!(table::contains(&proposal_table.proposals, _proposalId), 500);
        let proposal = *table::borrow(&proposal_table.proposals, _proposalId);


        let proposal = PROPOSAL{
            id: _proposalId,
            proposer: proposal.proposer, 
            moduleId: proposal.moduleId,
            moduleCode: proposal.moduleCode,
            name: _name,
            desc: _desc,
            start: proposal.start,
            end: proposal.end,
            stats: proposal.stats,
        };

        if (table::contains(&proposal_table.proposals, _proposalId)) {
           table::upsert(&mut proposal_table.proposals, _proposalId, proposal);
        }
        else{
            table::add(&mut proposal_table.proposals, _proposalId, proposal); 
        };

        let database = *borrow_global_mut<PROPOSAL_DATABASE>(DEPLOYER);
        deleteProposal(address, _proposalId);
        vector::push_back(&mut database.database, proposal);
    }

    public entry fun deleteProposal(address: &signer, _id:u32)  acquires PROPOSAL_COUNTER, PROPOSAL_DATABASE{
        
        let addr = signer::address_of(address);

        let owner = hierarchyv4::viewOwner();

        assert!(addr == owner, errorsv3::returnError(1));

        let counter = borrow_global_mut<PROPOSAL_COUNTER>(DEPLOYER);
        assert!(_id <= counter.count,  errorsv3::returnError(2));

        let database = borrow_global_mut<PROPOSAL_DATABASE>(DEPLOYER);
        vector::remove(&mut database.database, (_id as u64));
    }

    //  voted -->
    // 0 = did not vote
    // 1 = voted for yes
    // 2 = voted for no
    public entry fun vote(address: &signer, _proposalId: u16, vote: u8){

        let addr = signer::address_of(address);

        let owner = hierarchyv4::viewOwner();

    }
 
    #[view]
    public fun viewContract(): CONTRACT 
    {

        let deployer = viewDeployer();
        let owner = viewOwner();
        let validators = hierarchyv4::viewValidators();

        let contract = CONTRACT{
            deployer: deployer,
            owner: owner,
            validators: validators,
        };

        move contract
    }

    #[view]
    public fun viewDeployer(): address 
    {
        let deployer = hierarchyv4::viewDeployer();
        move deployer
    }

    #[view]
    public fun viewOwner(): address 
    {
        let owner = hierarchyv4::viewOwner();
        move owner
    }



    #[view]
    public fun viewProposal(id: u64): PROPOSAL acquires PROPOSAL_DATABASE, PROPOSAL_COUNTER
    {

        let counter = borrow_global_mut<PROPOSAL_COUNTER>(DEPLOYER);
        assert!(id <= (counter.count as u64), id);

        let database = borrow_global<PROPOSAL_DATABASE>(DEPLOYER);    
        let data = vector::borrow(&database.database, id);

        let _proposal = PROPOSAL{
            id: data.id,
            proposer: data.proposer, 
            moduleId: data.moduleId,
            moduleCode: data.moduleCode,
            name: data.name,
            desc: data.desc,
            start: data.start,
            end: data.end,
            stats: data.stats,
        };

        move _proposal
    }

    #[view]
    public fun viewProposals(): vector<PROPOSAL> acquires PROPOSAL_DATABASE
    {
        let database = borrow_global_mut<PROPOSAL_DATABASE>(DEPLOYER);
        let proposals = database.database;
        move proposals
    }
 
 
    #[test(account = @0x1, owner = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020, acc1 = @0xfff1ffff2fff3ff44ff5)]
    public entry fun test(account: signer, owner: signer, acc1: signer) acquires PROPOSAL_DATABASE, PROPOSAL_COUNTER, PROPOSAL_TABLE {
        timestamp::set_time_has_started_for_testing(&account);  
        init_module(&owner);

    //(address: &signer, _name: vector<u8>, _desc: vector<u8>, _period: u8)
        //innitializeProposal(address, _name, _moduleId, _moduleCode, _desc, _period);
        createProposal(&owner, b"Change Owner Address", 10, 5, b"A proposal which purpose is to change the owner address which is currently 0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020, to 0xfff1ffff2fff3ff44ff5", 7);
        let proposal = viewProposal(0);
        print(&proposal);
        changeProposal(&owner, 0, b"TEST", b"A");
        createProposal(&owner, b"Testing Proposal", 1, 5, b"This is a testing proposal, the purpose is blackhole...", 7);
         let proposals = viewProposals();
         print(&proposals);
    }
}