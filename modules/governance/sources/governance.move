module deployer::governancev1{
  
    use std::signer;
    use std::vector;
    use std::account;
    use std::string;
    use std::timestamp;
    use std::string::String;
    use std::table;
    use std::debug::print;
    use 0x392727cb3021ab76bd867dd7740579bc9e42215d98197408b667897eb8e13a1f::pointsv1;
    use std::string::utf8;
   

    const OWNER: address = @owner;
    const DEPLOYER: address = @deployer;
    const MESSAGER: address = @messager;
    
    const MODULE_ID: u16 = 3;

    const ERROR_MODULE_NOT_INNITIALIZED: u64 = 50;
    const ERROR_CODE_NOT_INNITIALIZED: u64 = 55;
    const ERROR_PROPOSAL_DOESNT_EXISTS: u64 = 60;
    const ERROR_PROPOSAL_NOT_STARTED: u64 = 65;
    const ERROR_PROPOSAL_NOT_ENDED: u64 = 70;
    const ERROR_PROPOSAL_NOT_EXECUTED: u64 = 75;
    const ERROR_MODULE_DOESNT_EXISTS: u64 = 80;
    const ERROR_CODE_IN_THIS_MODULE_DOESNT_EXISTS: u64 = 85;
    const ERROR_PROPOSAL_FINISHED: u64 = 90;
    const ERROR_TIME_NOT_UP: u64 = 95;
    const ERROR_INVALID_HASH: u64 = 100;
    const ERROR_NOT_ENOUGH_BALANCE: u64 = 105;
    const ERROR_USER_DOESNT_EXISTS: u64 = 110;
    const ERROR_ALREADY_VOTED: u64 = 115;
    const ERROR_NOT_OWNER: u64 = 120;
    const ERROR_ADDRESS_DOESNT_EXIST: u64 = 125;
    const ERROR_ADDRESS_ALREADY_HIERARCH: u64 = 130;
    const ERROR_ADDRESS_IS_NOT_HIERARCH: u64 = 135;


    struct PROPOSAL has copy, key, store, drop {id: u32, hash: vector<u8>, proposer: address, modul: u32, code: u16, name: vector<u8>, desc: vector<u8>, start: u64, end: u64, stats: PROPOSAL_STATS, status: PROPOSAL_STATUS, from: vector<u8>, to: vector<u8>}

    struct PROPOSAL_COUNTER has copy, key, store, drop {count: u32}

    struct VOTE has copy, key, store, drop {value: u128, yes: bool}

    struct HIERARCHY has  key, store {council: table::Table<address, HIERARCH>}

    struct HIERARCH has  key, store, drop {address: address, name: vector<u8>, code: u8}

    struct HIERARCH_DATABASE has  key, store {database: vector<address>}

    struct VOTERS_TABLE has key, store { voters: table::Table<u32, table::Table<u16, table::Table<address, VOTE>>>}

    struct MODULE_TABLE has key, store { modules: table::Table<u32, table::Table<u16, PROPOSAL>>}

    struct PROPOSAL_STATS has copy, drop, store, key {totalVotes: u256, yes: u128, no: u128}

    struct PROPOSAL_STATUS has copy, drop, store, key {passed: bool, pending: bool}

    struct HISTORICAL_PROPOSALS has copy, drop, store, key {database: vector<PROPOSAL>}


     entry fun init_module(address: &signer) acquires HIERARCHY, HIERARCH_DATABASE {
        
        let deploy_addr = signer::address_of(address);

        if (!exists<PROPOSAL>(deploy_addr)) {
            let proposal_stats = PROPOSAL_STATS{
                totalVotes: 0,
                yes: 0,
                no: 0,
            };

            let proposal_status = PROPOSAL_STATUS{
                passed: false,
                pending: false,
            };
            move_to(address, PROPOSAL { id: 0, hash: b"0",proposer: @0x0, modul: 0, code: 0, name: vector::empty(), desc: vector::empty(), start: 0, end: 0, stats: proposal_stats, status: proposal_status, from: vector::empty(), to: vector::empty()});
        };

        if (!exists<PROPOSAL_COUNTER>(deploy_addr)) {
            move_to(address, PROPOSAL_COUNTER {count: 0});
        };


        if (!exists<HISTORICAL_PROPOSALS>(deploy_addr)) {
            move_to(address, HISTORICAL_PROPOSALS {database: vector::empty()});
        };


        if (!exists<HIERARCH_DATABASE>(deploy_addr)) {
            move_to(address, HIERARCH_DATABASE {database: vector::empty()});
            let database = borrow_global_mut<HIERARCH_DATABASE>(DEPLOYER);
            vector::push_back(&mut database.database, OWNER);
        };

        if (!exists<MODULE_TABLE>(deploy_addr)) {
            let proposals_table = table::new<u32, table::Table<u16, PROPOSAL>>();
            move_to(address, MODULE_TABLE {modules: proposals_table});
        };

        if (!exists<HIERARCHY>(deploy_addr)) {
            let hierachy_table = table::new<address, HIERARCH>();
            move_to(address, HIERARCHY {council: hierachy_table});
            let table = borrow_global_mut<HIERARCHY>(DEPLOYER);
            let hierarch =  HIERARCH {
                address: deploy_addr,
                name: b"OWNER",
                code: 10,
            };
            table::add(&mut table.council, OWNER, hierarch);
        };

        if (!exists<VOTERS_TABLE>(deploy_addr)) {
            let voters_table = table::new<u32, table::Table<u16, table::Table<address, VOTE>>>();
            move_to(address, VOTERS_TABLE {voters: voters_table});
        };

    }


    public entry fun removeHierarch(address: &signer, _hierarch: address) acquires HIERARCHY, HIERARCH_DATABASE {

        let hierarch_db = borrow_global_mut<HIERARCH_DATABASE>(DEPLOYER);
        let hierarch_table = borrow_global_mut<HIERARCHY>(DEPLOYER);

        if (!table::contains(&hierarch_table.council, _hierarch)) {
            abort(ERROR_ADDRESS_IS_NOT_HIERARCH)
        } else {
            let (contains, index) = vector::index_of(&hierarch_db.database, &_hierarch);
            vector::remove(&mut hierarch_db.database, index);
            table::remove(&mut hierarch_table.council, _hierarch);
        }

    }


    public entry fun addHierarch(address: &signer, _hierarch: address, _name: vector<u8>, _code: u8) acquires HIERARCHY, HIERARCH_DATABASE {

        let hierarch_db = borrow_global_mut<HIERARCH_DATABASE>(DEPLOYER);
        let hierarch_table = borrow_global_mut<HIERARCHY>(DEPLOYER);

        let hierarch = HIERARCH {
            address: _hierarch,
            name: _name,
            code: _code,
        };

        if (!table::contains(&hierarch_table.council, _hierarch)) {
            
            table::add(&mut hierarch_table.council, _hierarch, hierarch);
            vector::push_back(&mut hierarch_db.database, _hierarch);
        } else {
            table::upsert(&mut hierarch_table.council, _hierarch, hierarch);
            //abort(ERROR_ADDRESS_ALREADY_HIERARCH)
        }

    }

    public entry fun vote(address: &signer, modul: u32, code: u16, yes: bool) acquires MODULE_TABLE, HISTORICAL_PROPOSALS, PROPOSAL_COUNTER, VOTERS_TABLE {
        let existing_module = viewProposalByModule(modul, code);
        assert!(existing_module.status.pending == true, ERROR_PROPOSAL_NOT_STARTED);

        let voters_table = borrow_global_mut<VOTERS_TABLE>(DEPLOYER);
        if (!table::contains(&voters_table.voters, modul)) {
            let new_voters_table = table::new<u16, table::Table<address, VOTE>>();
            let new_voter_address_table = table::new<address, VOTE>();

            table::add(&mut voters_table.voters, modul, new_voters_table);
        
            let voter_module = table::borrow_mut(&mut voters_table.voters, modul);
            table::add(voter_module, code, new_voter_address_table);

            let voter = table::borrow_mut(voter_module, code);

            let _vote = VOTE {
                value:  pointsv1::viewBalance(signer::address_of(address)),
                yes: yes,
            };
            table::add(voter, signer::address_of(address), _vote);
            } else {
                let voter_module = table::borrow_mut(&mut voters_table.voters, modul);
                if (!table::contains(voter_module, code)) {
                    let vote = VOTE {
                        value: pointsv1::viewBalance(signer::address_of(address)),
                        yes: yes,
                    };
                    let addr = signer::address_of(address);
                    let proposals_table = table::new<address, VOTE>();
                    table::add(voter_module, code, proposals_table);
                    let voter = table::borrow_mut(voter_module, code);
                    table::add(voter, signer::address_of(address), vote);
                } else {
                    abort(ERROR_ALREADY_VOTED)
                };
        };

        let modules_table = borrow_global_mut<MODULE_TABLE>(DEPLOYER);
        let proposals = table::borrow_mut(&mut modules_table.modules, modul);
        let proposal = table::borrow_mut(proposals, code);
        assert!(pointsv1::viewBalance(signer::address_of(address)) > 0, ERROR_NOT_ENOUGH_BALANCE);
        if(yes == true){
            proposal.stats.yes = proposal.stats.yes + pointsv1::viewBalance(signer::address_of(address));   
        } else {
            proposal.stats.no = proposal.stats.no + pointsv1::viewBalance(signer::address_of(address)); 
        };
        deleteProposal(address, proposal.id);
        let _proposal = *proposal;
        let database = borrow_global_mut<HISTORICAL_PROPOSALS>(DEPLOYER);
        vector::push_back(&mut database.database, _proposal);
    }

    public entry fun updateHash(address: &signer, modul: u32, code: u16, hash: vector<u8>) acquires MODULE_TABLE, PROPOSAL_COUNTER, HISTORICAL_PROPOSALS{
        assert!(signer::address_of(address) == OWNER || signer::address_of(address) == DEPLOYER, ERROR_NOT_OWNER);

        assert!(vector::length(&hash) == 66, ERROR_INVALID_HASH);
        let existing_module = viewProposalByModule(modul, code);

        let modules_table = borrow_global_mut<MODULE_TABLE>(DEPLOYER);
        let proposals = table::borrow_mut(&mut modules_table.modules, modul);
        let proposal = table::borrow_mut(proposals, code);
        proposal.hash = hash;
        deleteProposal(address, proposal.id);
        let _proposal = *proposal;
        let database = borrow_global_mut<HISTORICAL_PROPOSALS>(DEPLOYER);
        vector::push_back(&mut database.database, _proposal);

    }

    entry fun checkProposal(address: &signer, _module: u32, _code: u16) acquires MODULE_TABLE, HISTORICAL_PROPOSALS, PROPOSAL_COUNTER {

        assert!(signer::address_of(address) == OWNER || signer::address_of(address) == DEPLOYER, ERROR_NOT_OWNER);
        let mock_proposal = viewProposalByModule(_module, _code);
        assert!(mock_proposal.end <= timestamp::now_seconds(), ERROR_TIME_NOT_UP);

        let modules_table = borrow_global_mut<MODULE_TABLE>(DEPLOYER);
        let proposals = table::borrow_mut(&mut modules_table.modules, _module);

        let proposal = table::borrow_mut(proposals, _code);
        proposal.status.pending = false;
        if(proposal.stats.yes > proposal.stats.no){
            proposal.status.passed = true;
        }
        else {
            proposal.status.passed = false;
        };
        let _proposal = *proposal;
        deleteProposal(address, proposal.id);
        let database = borrow_global_mut<HISTORICAL_PROPOSALS>(DEPLOYER);
        vector::push_back(&mut database.database, _proposal);
    }

    entry fun innitializeProposal(address: &signer, _name: vector<u8>, _module: u32, _code: u16, _desc: vector<u8>, _period: u8, _from: vector<u8>, _to: vector<u8>) acquires MODULE_TABLE, HISTORICAL_PROPOSALS, PROPOSAL_COUNTER {
        assert!(signer::address_of(address) == OWNER || signer::address_of(address) == DEPLOYER, ERROR_NOT_OWNER);

        let count = borrow_global_mut<PROPOSAL_COUNTER>(DEPLOYER);
        let start_time = timestamp::now_seconds();

        let proposal_stats = PROPOSAL_STATS{
            totalVotes: 0,
            yes: 0,
            no: 0,
        };

        let proposal_status = PROPOSAL_STATUS{
            passed: false,
            pending: true,
        };

        let proposal = PROPOSAL{
            id: count.count,
            hash: b"0x0",
            proposer: signer::address_of(address), 
            modul: _module,
            code: _code,
            name: _name,
            desc: _desc,
            start: start_time,
            end: start_time + (((_period as u64) * 60u64) as u64),
            stats: proposal_stats,
            status: proposal_status,
            from: _from,
            to: _to,
        };

        let modules_table = borrow_global_mut<MODULE_TABLE>(DEPLOYER);
        if (!table::contains(&modules_table.modules, _module)) {
            let proposals_table = table::new<u16, PROPOSAL>();
            table::add(&mut modules_table.modules, _module, proposals_table);
        };

        let proposals = table::borrow_mut(&mut modules_table.modules, _module);

        if (table::contains(proposals, _code)) {
            let existing_proposal = table::borrow(proposals, _code);
            assert!(existing_proposal.end < timestamp::now_seconds(),ERROR_PROPOSAL_NOT_ENDED);
            assert!(existing_proposal.status.pending == true, ERROR_PROPOSAL_NOT_EXECUTED);
        };

        table::add(proposals, _code, proposal);

        let database = borrow_global_mut<HISTORICAL_PROPOSALS>(DEPLOYER);
        vector::push_back(&mut database.database, proposal);

        count.count = count.count + 1;
    }



    public entry fun createProposal(address: &signer, _name: vector<u8>,  _moduleId: u32,  _moduleCode: u16, _desc: vector<u8>, _period: u8, _from: vector<u8>, _to: vector<u8>) acquires PROPOSAL_COUNTER, HISTORICAL_PROPOSALS, MODULE_TABLE
    {
        innitializeProposal(address, _name, _moduleId, _moduleCode, _desc, _period, _from, _to);
    }

    public entry fun changeProposal(address: &signer, _moduleId: u32, _code: u16, _name: vector<u8>, _desc: vector<u8>) acquires MODULE_TABLE {
        assert!(signer::address_of(address) == OWNER || signer::address_of(address) == DEPLOYER, ERROR_NOT_OWNER);

    let modules_table = borrow_global_mut<MODULE_TABLE>(DEPLOYER);
    assert!(table::contains(&modules_table.modules, _moduleId), ERROR_MODULE_NOT_INNITIALIZED);

    let proposals = table::borrow_mut(&mut modules_table.modules, _moduleId);

    assert!(table::contains(proposals, _code), ERROR_CODE_NOT_INNITIALIZED); 

    let data = *table::borrow_mut(proposals, _code);

    assert!(data.end >= timestamp::now_seconds(), ERROR_PROPOSAL_FINISHED);
    assert!(data.status.pending == false, ERROR_PROPOSAL_FINISHED);
    data.name = _name;
    data.desc = _desc;
}
 

   public entry fun deleteProposal(address: &signer, _id:u32)  acquires PROPOSAL_COUNTER, HISTORICAL_PROPOSALS{
        
        assert!(signer::address_of(address) == OWNER || signer::address_of(address) == DEPLOYER, ERROR_NOT_OWNER);

        let counter = borrow_global_mut<PROPOSAL_COUNTER>(DEPLOYER);
        assert!(_id <= counter.count,  ERROR_PROPOSAL_DOESNT_EXISTS);

        let database = borrow_global_mut<HISTORICAL_PROPOSALS>(DEPLOYER);
        vector::remove(&mut database.database, (_id as u64));
    }

    #[view]
    public fun viewProposalById(id: u64): PROPOSAL acquires HISTORICAL_PROPOSALS, PROPOSAL_COUNTER
    {

        let counter = borrow_global_mut<PROPOSAL_COUNTER>(DEPLOYER);
        assert!(id <= (counter.count as u64), ERROR_PROPOSAL_DOESNT_EXISTS);

        let database = borrow_global<HISTORICAL_PROPOSALS>(DEPLOYER);    
        let data = vector::borrow(&database.database, id);

        let _proposal = PROPOSAL{
            id: data.id,
            hash: data.hash,
            proposer: data.proposer, 
            modul: data.modul,
            code: data.code,
            name: data.name,
            desc: data.desc,
            start: data.start,
            end: data.end,
            stats: data.stats,
            status: data.status,
            from: data.from,
            to: data.to,
        };

        move _proposal
    }



    #[view]
    public fun viewHierarch(address: address): (address,vector<u8>,u8) acquires HIERARCHY {
        let hierarchy_table = borrow_global<HIERARCHY>(DEPLOYER); 

        assert!(table::contains(&hierarchy_table.council, address), ERROR_ADDRESS_DOESNT_EXIST);
        let hierarch = table::borrow(&hierarchy_table.council, address);
        (address,hierarch.name, hierarch.code)
    }

    #[view]
    public fun viewHierarchy(): vector<HIERARCH> acquires HIERARCH_DATABASE, HIERARCHY {
        let hierarchy_table = borrow_global<HIERARCHY>(DEPLOYER); 
        let hierarchy_db = borrow_global<HIERARCH_DATABASE>(DEPLOYER); 

        let length = vector::length(&hierarchy_db.database);
        let i = 0;
        let hierarchy_vector = vector::empty();
        print(&length);

        while(length > i){
            print(&length);
            print(&i);
            let hierarch_addr = *vector::borrow(&hierarchy_db.database, length-1);
            let (_address,hierarch, code) = viewHierarch(hierarch_addr);
            let _hierarch = HIERARCH {
                address:_address,
                name: hierarch,
                code: code,
            };

            i = i + 1;
            vector::push_back(&mut hierarchy_vector, _hierarch);
        };
        move hierarchy_vector
    }


    #[view]
    public fun viewProposalByModule(_module: u32, _code: u16): PROPOSAL acquires MODULE_TABLE {
        let modules_table = borrow_global<MODULE_TABLE>(DEPLOYER); 
        assert!(table::contains(&modules_table.modules, _module), ERROR_MODULE_DOESNT_EXISTS); 
        let proposals = table::borrow(&modules_table.modules, _module);
        assert!(table::contains(proposals, _code), ERROR_CODE_IN_THIS_MODULE_DOESNT_EXISTS); 
        let data = *table::borrow(proposals, _code);
        move data
    }


    //id: u32, hash: vector<u8>, proposer: address, modul: u32, code: u16, name: vector<u8>, desc: vector<u8>, start: u64, end: u64, stats: PROPOSAL_STATS, status: PROPOSAL_STATUS, from: vector<u8>, to: vector<u8>
    #[view]
    public fun viewProposalByModule_tuple(_module: u32, _code: u16): (u32,address,u16,bool,bool,vector<u8>,vector<u8>) acquires MODULE_TABLE
    {
        let data = viewProposalByModule(_module, _code);
        (data.id, data.proposer, data.code, data.status.pending, data.status.passed, data.from, data.to)
    }


    #[view]
    public fun viewUserVote(user: address, _module: u32, _code: u16): VOTE acquires VOTERS_TABLE {
        let voters_table = borrow_global<VOTERS_TABLE>(DEPLOYER); 
        assert!(table::contains(&voters_table.voters, _module), ERROR_MODULE_DOESNT_EXISTS); 
        let voters_module = table::borrow(&voters_table.voters, _module);
        assert!(table::contains(voters_module, _code), ERROR_CODE_IN_THIS_MODULE_DOESNT_EXISTS); 
        let voters_code = table::borrow(voters_module, _code);
        assert!(table::contains(voters_code, user), ERROR_USER_DOESNT_EXISTS); 
        let data = *table::borrow(voters_code, user);
        move data
    }

    #[view]
    public fun viewProposals(): vector<PROPOSAL> acquires HISTORICAL_PROPOSALS
    {
            let database = borrow_global_mut<HISTORICAL_PROPOSALS>(DEPLOYER);
            let proposals = database.database;
            move proposals
    }
 
 
    #[test(account = @0x1, owner = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020, acc1 = @0xfff1ffff2fff3ff44ff5)]
    public entry fun test(account: signer, owner: signer, acc1: signer) acquires HIERARCH_DATABASE, HIERARCHY, HISTORICAL_PROPOSALS, PROPOSAL_COUNTER, MODULE_TABLE, VOTERS_TABLE{
        timestamp::set_time_has_started_for_testing(&account);  
        init_module(&owner);
        print(&viewHierarchy());
        createProposal(&owner, b"Change Owner Address", 0, 1, b"Change owner address", 7, b"ahoj", b"cau");
        createProposal(&owner, b"Testing for Module 0000", 0, 5, b"Testing proposal", 7, b"ne", b"ano");
        createProposal(&owner, b"Testing for Module 1", 1, 1, b"Testing proposal", 7, b"100", b"500");
        //changeProposal(&owner, 1, 1, b"TTT", b"asdasdasdasdasdasd");
        updateHash(&owner, 1, 1, b"0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020");
        print(&viewProposalByModule(1,1));
        updateHash(&owner, 1, 1, b"0xc698c251041b8fff1d3d4ea664a70674758e78918938d1b3b237418ff17bffff");
        print(&viewProposalByModule(1,1));
       // print(&viewProposalByModule_tuple(1,1));
        vote(&owner,0,1,false);
        print(&viewUserVote(@0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020, 0,1));
        vote(&owner,0,5,true);
        print(&viewProposalByModule(0,1));
    }
}
