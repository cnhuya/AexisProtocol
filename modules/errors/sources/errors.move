    module deployer::errorsv3{
    
        use std::signer;
        use std::vector;
        use std::account;
        use std::string;
        use std::timestamp;
        use std::table;
        use std::debug::print;
        use 0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020::hierarchyv4;

        // A wallet thats designed to hold the contract struct permanently.
        const DEPLOYER: address = @deployer;
        // A wallet thats designed to update values such as ratio, or change who the messager/oracle/vault is.
        // The private key wont be stored on any backed for higher level of security.
        const OWNER: address = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020;
        // The private key wont be stored on any backed for higher level of security.
        const MESSANGER: address = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020;
        // ERROR CODES


        // MODULE ID
        const MODULE_ID: u16 = 2;

        struct ERROR has key, store, drop, copy {id: u64, name: vector<u8>, desc: vector<u8>}

        struct ERROR_COUNTER has key, store, drop,copy {count: u64}

        struct CONTRACT has key, drop, store,copy {deployer: address, owner: address, errors: u64}

        struct ERROR_TABLE has key, store {errors: table::Table<u64, ERROR>}

        struct ERROR_DATABASE has key, store {database: vector<ERROR>}


        fun init_module(address: &signer) {

            //let addr = signer::address_of(address);

            if (!exists<ERROR>(DEPLOYER)) {
                move_to(address, ERROR {id: 0, name: vector::empty(), desc: vector::empty()});
            };

            if (!exists<ERROR_COUNTER>(DEPLOYER)) {
                move_to(address, ERROR_COUNTER {count: 0});
            };


            if (!exists<ERROR_TABLE>(DEPLOYER)) {
                let errors_table = table::new<u64, ERROR>();
                move_to(address, ERROR_TABLE { errors: errors_table });
            };

            if (!exists<ERROR_DATABASE>(DEPLOYER)) {
                move_to(address, ERROR_DATABASE { database: vector::empty() });
            };

            if (!exists<CONTRACT>(DEPLOYER)) {
                move_to(address, CONTRACT { deployer: DEPLOYER, owner: OWNER, errors: 0});
            };
        }


        entry fun innitiliazeError(address: &signer, _name: vector<u8>, _desc: vector<u8>) acquires ERROR_COUNTER, ERROR_TABLE, ERROR_DATABASE{

             let addr = signer::address_of(address);

            let error_counter = borrow_global_mut<ERROR_COUNTER>(DEPLOYER);
            error_counter.count = error_counter.count + 1;

            let error_table = borrow_global_mut<ERROR_TABLE>(DEPLOYER);

            let error = ERROR {
                id: error_counter.count,
                name: _name,
                desc: _desc,
            };
            let database = borrow_global_mut<ERROR_DATABASE>(DEPLOYER);
            vector::push_back(&mut database.database, error);
            table::upsert(&mut error_table.errors, error_counter.count, error);

        }

        public entry fun addError(address: &signer, _name: vector<u8>, _desc: vector<u8>) acquires ERROR_TABLE, ERROR_COUNTER, ERROR_DATABASE
        {
            let addr = signer::address_of(address);
            let owner = hierarchyv4::viewOwner();
            assert!(addr == owner, returnError(1));

            innitiliazeError(address, _name, _desc);
        }


        entry fun innitiliazeChangingError(address: &signer, _name: vector<u8>, _desc: vector<u8>, _id: u64) acquires ERROR_TABLE, ERROR_DATABASE{

             let addr = signer::address_of(address);

            let error_table = borrow_global_mut<ERROR_TABLE>(DEPLOYER);

            let error = ERROR {
                id: _id,
                name: _name,
                desc: _desc,
            };
            let database = borrow_global_mut<ERROR_DATABASE>(DEPLOYER);
            vector::push_back(&mut database.database, error);
            table::upsert(&mut error_table.errors, _id, error);

        }

        public entry fun editError(address: &signer, _name: vector<u8>, _desc: vector<u8>, _id: u64) acquires ERROR_TABLE, ERROR_DATABASE
        {
            let addr = signer::address_of(address);
            let owner = hierarchyv4::viewOwner();
            assert!(addr == owner, returnError(1));

            innitiliazeChangingError(address, _name, _desc, _id);
        }

        #[view]
        public fun viewErrors(): vector<ERROR> acquires ERROR_DATABASE
        {
            let database = borrow_global<ERROR_DATABASE>(DEPLOYER); // Explicit return, but still no local variable
            let data = database.database;
            move data
        }

        #[view]
        public fun returnError(_errorID: u64): u64 acquires ERROR_TABLE
        {

            let error_table = borrow_global<ERROR_TABLE>(DEPLOYER); // Explicit return, but still no local variable
            let data = *table::borrow(&error_table.errors, _errorID);
            let error_id = data.id;
            move error_id
        }

        #[view]
        public fun viewError(_errorID: u64): ERROR acquires ERROR_TABLE
        {
            let error_table = borrow_global<ERROR_TABLE>(DEPLOYER); // Explicit return, but still no local variable
            let data = *table::borrow(&error_table.errors, _errorID);
            move data
        }


        #[view]
        public fun viewContract(): CONTRACT acquires CONTRACT, ERROR_COUNTER
        {

            let deployer = viewDeployer();
            let owner = viewOwner();
            let error_counter = borrow_global_mut<ERROR_COUNTER>(DEPLOYER);
            let contract = CONTRACT{
                deployer: deployer,
                owner: owner,
                errors: error_counter.count,
            };

            move contract
        }


        #[view]
        public fun viewDeployer(): address acquires CONTRACT
        {
            let _contract = borrow_global_mut<CONTRACT>(DEPLOYER);
            let deployer = _contract.deployer;
            move deployer
        }

        #[view]
        public fun viewOwner(): address
        {
            let owner = hierarchyv4::viewOwner();
            move owner
        }
    
        #[test(account = @0x1, owner = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020)]
        #[expected_failure(abort_code = 4008)]
        public entry fun test(account: signer, owner: signer) acquires CONTRACT, ERROR_DATABASE, ERROR_TABLE, ERROR_COUNTER{
            timestamp::set_time_has_started_for_testing(&account);  
            init_module(&owner);
            let contract = viewContract();
            print(&contract);
            addError(&owner, b"NOT_OWNER", b"The signer does not have the permission to call this function.");
            addError(&owner, b"NOT_MESSAGER", b"The signer does not have the permission to call this function.");
            let _viewErrors = viewErrors();
            print(&_viewErrors);
            let _viewError = viewError(1);
            print(&_viewError);
            let _viewerror1 = returnError(1);
            print(&_viewerror1);
            editError(&owner, b"EDITED ERROR", b"The signer does not have theThe signer does not have the permission to call this function. permission to call this funThe signer does not have the permission to call this function.ction.", 1);
            let _viewErrors2 = viewErrors();
            print(&_viewErrors2);
            let abc = hierarchyv4::viewDeployer();
            print(&abc);
        }
    }