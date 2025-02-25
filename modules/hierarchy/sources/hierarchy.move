module deployer::hierarchyv4{
  
    use std::signer;
    use std::vector;
    use std::account;
    use std::string;
    use std::timestamp;
    use std::table;
    use std::debug::print;
    

    const OWNER: address = @owner;
    const DEPLOYER: address = @deployer;
    const VALIDATOR1: address = @validator;
    
    // ERROR CODES
    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_ADDRESS_ALREADY_VALIDATOR: u64 = 2;
    const ERROR_ADDRESS_ALREADY_REQUESTED: u64 = 3;
    const ERROR_OWNER_CANT_BE_VALIDATOR: u64 = 4;
    const ERROR_ADDRESS_IS_NOT_VALIDATOR: u64 = 5;
    const ERROR_DEPLOYER_CANT_BE_VALIDATOR: u64 = 6;


    struct CONTRACT has copy, store, key, drop {deployer: address, owner: address, validators: vector<address>}

    struct VALIDATOR has copy, key, store, drop {isValidator: bool, isRequested: bool}


    entry fun init_module(address: &signer) acquires CONTRACT{

        if (!exists<CONTRACT>(DEPLOYER)) {
            move_to(address, CONTRACT {deployer: DEPLOYER, owner: OWNER, validators: vector::empty()});
            let contract = borrow_global_mut<CONTRACT>(DEPLOYER);
            vector::push_back(&mut contract.validators, VALIDATOR1);
        };

        if (!exists<VALIDATOR>(DEPLOYER)) {
            move_to(address, VALIDATOR {isValidator: false, isRequested: false});
        };
    }

    entry fun innitializeRequest(address: &signer) acquires CONTRACT, VALIDATOR{

        let addr = signer::address_of(address);

        if (!exists<VALIDATOR>(addr)) {
            move_to(address, VALIDATOR {isValidator: false, isRequested: true});
        };

        let owner = viewOwner();
        assert!(addr != owner, ERROR_OWNER_CANT_BE_VALIDATOR);

        let deployer = viewDeployer();
        assert!(addr != deployer, ERROR_OWNER_CANT_BE_VALIDATOR);

        let validator = borrow_global_mut<VALIDATOR>(addr);
        assert!(validator.isValidator == false, ERROR_ADDRESS_ALREADY_VALIDATOR);

        assert!(validator.isRequested == true, ERROR_ADDRESS_ALREADY_REQUESTED);

        validator.isRequested = true;
    }


    entry fun innitializeValidator(address: &signer, validator: address) acquires CONTRACT, VALIDATOR{

        let addr = signer::address_of(address);

        let owner = viewOwner();
        assert!(addr == owner, ERROR_NOT_OWNER);

        let validator = borrow_global_mut<VALIDATOR>(validator);
        assert!(validator.isValidator == false, ERROR_ADDRESS_ALREADY_VALIDATOR);

        assert!(validator.isRequested == true, ERROR_ADDRESS_ALREADY_REQUESTED);

        validator.isRequested = false;
        validator.isValidator = true;
    }

    public entry fun requestToBeValidator(address: &signer) acquires CONTRACT, VALIDATOR
    {
        innitializeRequest(address);
    }

    public entry fun allowValidator(address: &signer, validator: address) acquires CONTRACT, VALIDATOR
    {
        innitializeValidator(address, validator);
    }
 
    #[view]
    public fun viewContract(): CONTRACT acquires CONTRACT
    {

        let deployer = viewDeployer();
        let owner = viewOwner();
        let validators = viewValidators();

        let contract = CONTRACT{
            deployer: deployer,
            owner: owner,
            validators: validators,
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
    public fun viewOwner(): address acquires CONTRACT
    {
        let _contract = borrow_global_mut<CONTRACT>(DEPLOYER);
        let owner = _contract.owner;
        move owner
    }

    #[view]
    public fun viewValidators(): vector<address> acquires CONTRACT
    {
        let _contract = borrow_global_mut<CONTRACT>(DEPLOYER);
        let validators = _contract.validators;
        move validators
    }

    #[view]
    public fun viewValidator(validator: address): VALIDATOR acquires VALIDATOR
    {
        if (!exists<VALIDATOR>(validator)) {
           abort(ERROR_ADDRESS_IS_NOT_VALIDATOR)
        };

        let validator = *borrow_global_mut<VALIDATOR>(validator);
        move validator
    }

    
    #[view]
    public fun returnValidator(validator: address): address acquires VALIDATOR
    {
        if (!exists<VALIDATOR>(validator)) {
           abort(ERROR_ADDRESS_IS_NOT_VALIDATOR)
        };

        let _validator = *borrow_global_mut<VALIDATOR>(validator);
        let isValidator = _validator.isValidator;
        assert!(isValidator == true, returnError(5));
        move validator
    }


    
    
    

 
 
    #[test(account = @0x1, owner = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020, acc1 = @0xfff1ffff2fff3ff44ff5)]
    public entry fun test(account: signer, owner: signer, acc1: signer) acquires CONTRACT, VALIDATOR {
        timestamp::set_time_has_started_for_testing(&account);  
        init_module(&owner);
        let contract = viewContract();
        print(&contract);
        requestToBeValidator(&acc1, );
        let contract = viewContract();
        //viewValidator(@0xfffaff);
        allowValidator(&owner, @0xfff1ffff2fff3ff44ff5);
        let validator = viewValidator(@0xfff1ffff2fff3ff44ff5);
       // requestToBeValidator(&acc1, );
        print(&validator);
    }
}
