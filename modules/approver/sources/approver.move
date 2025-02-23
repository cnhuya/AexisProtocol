module testing::approverv5{
  
    use std::signer;
    use std::vector;
    use std::account;
    use std::string;
    use std::timestamp;
    use std::table;
    use std::debug::print;
    use std::string::utf8;

    
    // A wallet thats designed to hold the contract structs permanently.
    const DEPLOYER: address = @testing;

    // A wallet thats designed to update values such as ratio, or change who the messager/oracle/vault is.
    // The private key wont be stored on any backed for higher level of security.
    const OWNER: address = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020;

    // A wallet which purpose is to request updates
    const MESSANGER: address = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020;
    
    // ERROR CODES
    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_NOT_MESSAGER: u64 = 2;
    const ERROR_ADDRESS_IS_ALREADY_MESSAGER: u64 = 3;
    const ERROR_CHANGE_ALREADY_REQUESTED: u64 = 4;
    const ERROR_CHANGE_ALREADY_ALLOWED: u64 = 5;
    const ERROR_ALLOWANCE_NOT_MATURE: u64 = 6;
    const ERROR_MODULE_ALREADY_INNITILIAZED: u64 = 7;
    const ERROR_MODULE_NOT_INNITIALIZED: u64 = 8;
    const ERROR_CHANGE_NOT_ALLOWED: u64 = 9;
    
    struct CONTRACT has key, drop, store,copy {deployer: address, owner: address, approver: address}

    struct UPGRADE has key, drop, store, copy {requested: bool, allowed: bool, timestamp: u64, maturity: u64, code: u16, moduleID: u16, moduleAddress: address}

    struct MODULES_UPRAGE_TABLE has key, store {modules: table::Table<u16, UPGRADE>}

    fun init_module(address: &signer) acquires MODULES_UPRAGE_TABLE, CONTRACT{

        //let addr = signer::address_of(address);


        if (!exists<UPGRADE>(DEPLOYER)) {
            move_to(address, UPGRADE {requested: false, allowed: false, timestamp: 0, maturity: 0, code:0, moduleID: 0, moduleAddress: @0x0});
        };

        if (!exists<MODULES_UPRAGE_TABLE>(DEPLOYER)) {
            let users_table = table::new<u16, UPGRADE>();
            move_to(address, MODULES_UPRAGE_TABLE { modules: users_table });
        };

        if (!exists<CONTRACT>(DEPLOYER)) {
            move_to(address, CONTRACT { deployer: DEPLOYER, owner: OWNER, approver: MESSANGER });
        };

        innitializeModule(address, 0, DEPLOYER);
    }

    public entry fun changeApprover(address: &signer, _newApprover: address) acquires CONTRACT, MODULES_UPRAGE_TABLE{

        let addr = signer::address_of(address);

        let approver = viewApprover();
        let owner = viewOwner();
        assert!(addr == owner, ERROR_NOT_OWNER);
        assert!(_newApprover !=  approver, ERROR_ADDRESS_IS_ALREADY_MESSAGER);

        let upgrade = viewAllowance(0);

        let time = timestamp::now_seconds();
        assert!(upgrade.maturity <= time, ERROR_ALLOWANCE_NOT_MATURE);
        assert!(upgrade.allowed == true, ERROR_CHANGE_NOT_ALLOWED);

        let contract = borrow_global_mut<CONTRACT>(DEPLOYER);
        contract.approver = _newApprover;
    }


    public entry fun innitializeModule(address: &signer, _moduleID: u16, _addr: address) acquires MODULES_UPRAGE_TABLE, CONTRACT{
        let addr = signer::address_of(address);

        let owner = viewOwner();
        assert!(addr == owner, ERROR_NOT_OWNER);    

        let upgrade_table = borrow_global_mut<MODULES_UPRAGE_TABLE>(DEPLOYER);


        if (table::contains(&upgrade_table.modules, _moduleID)) {
            abort ERROR_MODULE_ALREADY_INNITILIAZED
        }
        else{
            let _upgrade = UPGRADE {
                requested: false,
                allowed: false,
                timestamp: 0,
                maturity: 0,
                code: 0,
                moduleID: _moduleID,
                moduleAddress: _addr,
            };
            table::add(&mut upgrade_table.modules, _moduleID, _upgrade); 
        }
    }

    public entry fun requestChange(address: &signer, _moduleID: u16, _code: u16) acquires MODULES_UPRAGE_TABLE, CONTRACT{

        let addr = signer::address_of(address);

        let messager = viewApprover();
        assert!(addr == messager, ERROR_NOT_MESSAGER);

        let changes_table = borrow_global_mut<MODULES_UPRAGE_TABLE>(DEPLOYER);
        assert!(table::contains(&changes_table.modules, _moduleID), ERROR_MODULE_NOT_INNITIALIZED);
        let data = *table::borrow(&changes_table.modules, _moduleID);

        assert!(data.requested != true, ERROR_CHANGE_ALREADY_REQUESTED);
        assert!(data.allowed != true, ERROR_CHANGE_ALREADY_ALLOWED);

        let time = timestamp::now_seconds();

            let _upgrade = UPGRADE {
                requested: true,
                allowed: false,
                timestamp: time,
                maturity: time + 60480,
                code: _code,
                moduleID: _moduleID,
                moduleAddress: data.moduleAddress,
            };

             table::upsert(&mut changes_table.modules, _moduleID, _upgrade);
    }
 
    #[view]
    public fun viewAllowance(_moduleID: u16): UPGRADE acquires MODULES_UPRAGE_TABLE
    {
        let changes_table = borrow_global<MODULES_UPRAGE_TABLE>(DEPLOYER); // Explicit return, but still no local variable

        if (table::contains(&changes_table.modules, _moduleID)) {
            let data = *table::borrow(&changes_table.modules, _moduleID);
            
            if(data.timestamp >= data.maturity){

                let _upgrade = UPGRADE {
                    requested: data.requested,
                    allowed: true,
                    timestamp: data.timestamp,
                    maturity: data.maturity,
                    code: data.code,
                    moduleID: _moduleID,
                    moduleAddress: data.moduleAddress,
                };
                move _upgrade
            }
            else{
                let _upgrade = UPGRADE {
                    requested: data.requested,
                    allowed: false,
                    timestamp: data.timestamp,
                    maturity: data.maturity,
                    code: data.code,
                    moduleID: _moduleID,
                    moduleAddress: data.moduleAddress,
                };
                move _upgrade
            }
            
        } 
        else {
            abort ERROR_MODULE_NOT_INNITIALIZED
        }
    }

    public fun viewContract(): CONTRACT acquires CONTRACT
    {

        let deployer = viewDeployer();
        let owner = viewOwner();
        let approver = viewApprover();

        let contract = CONTRACT{
            deployer: deployer,
            owner: owner,
            approver: approver,
        };

        move contract
    }

    #[view]
    public fun viewApprover(): address acquires CONTRACT
    {
        let _contract = borrow_global_mut<CONTRACT>(DEPLOYER);
        let approver = _contract.approver;
        move approver
    }

    #[view]
    public fun viewDeployer(): address acquires CONTRACT
    {
        let _contract = borrow_global_mut<CONTRACT>(DEPLOYER);
        let deployer = _contract.deployer;
        move deployer
    }
    
    #[view]
    public fun viewOwner(): address acquires CONTRACT
    {
        let _contract = borrow_global_mut<CONTRACT>(DEPLOYER);
        let owner = _contract.owner;
        move owner
    }

    #[test(account = @0x1, owner = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020)]
    public entry fun test(account: signer, owner: signer) acquires MODULES_UPRAGE_TABLE, CONTRACT {
        timestamp::set_time_has_started_for_testing(&account);  
        init_module(&owner);
        innitializeModule(&owner, 1, @0x000f);

        let _viewAllowance1 = viewAllowance(1);
        print(&_viewAllowance1);

        requestChange(&owner, 1, 5);

        let _viewAllowance2 = viewAllowance(1);
        print(&_viewAllowance2);

        let _viewAllowance1 = viewAllowance(0);
        print(&_viewAllowance1);
        
        let contract = viewContract();
        print(&contract);
    }
}