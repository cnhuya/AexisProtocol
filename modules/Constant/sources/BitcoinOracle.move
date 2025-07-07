module deployer::testConstant{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;

// Structs

    struct ConstantDatabase has copy,store,drop,key {database: vector<Constant>}
    struct Constant has copy,store,drop,key {name: String, value: u256}


// Const
    const OWNER: address = @deployer;

// Errors
    const ERROR_CONSTANT_ALREADY_EXISTS: u64 = 1;
    const ERROR_CONSTANT_DOES_NOT_EXIST: u64 = 2;
    const ERROR_NOT_ADMIN: u64 = 3;

// On Deploy Event
   fun init_module(address: &signer) {
        if (!exists<ConstantDatabase>(signer::address_of(address))) {
          move_to(address, ConstantDatabase { database: vector::empty<Constant>()});
        };
    }

// Entry Functions
public entry fun registerConstant(address: &signer, constant_name: String, value: u256) acquires ConstantDatabase {
    assert!(signer::address_of(address) == OWNER,ERROR_NOT_ADMIN);
    let db = borrow_global_mut<ConstantDatabase>(OWNER);
    vector::push_back(&mut db.database, make_constant(constant_name, value));
}

public entry fun removeConstant(address: &signer, constant_name: String) acquires ConstantDatabase {
    assert!(signer::address_of(address) == OWNER,ERROR_NOT_ADMIN);
    let db = borrow_global_mut<ConstantDatabase>(OWNER); 
    let i = 0;
    let len = vector::length(&db.database);
        while (i < len) {
            let item_ref = vector::borrow(&db.database, i);
            if (item_ref.name == constant_name) {
                vector::remove(&mut db.database, i);
            };
            i = i + 1;
        };
    abort ERROR_CONSTANT_DOES_NOT_EXIST
}

public entry fun change_constant(address: &signer, constant_name: String, new_value: u256) acquires ConstantDatabase {
    assert!(signer::address_of(address) == OWNER, 100);

    let db = borrow_global_mut<ConstantDatabase>(OWNER);
    let len = vector::length(&db.database);
    let i = 0;

    while (i < len) {
        let constant_ref = vector::borrow_mut(&mut db.database, i);
        if (constant_ref.name == constant_name) {
            constant_ref.value = new_value;
            return
        };
        i = i + 1;
    };

    abort ERROR_CONSTANT_DOES_NOT_EXIST
}


// View Functions
#[view]
public fun viewConstants(): vector<Constant> acquires ConstantDatabase {
    let player_db = borrow_global<ConstantDatabase>(OWNER);
    player_db.database
}

#[view]
public fun viewConstant(constant_name: String): Constant acquires ConstantDatabase {
    let db = borrow_global_mut<ConstantDatabase>(OWNER);
    let len = vector::length(&db.database);
    let i = 0;

    while (i < len) {
        let constant_ref = vector::borrow_mut(&mut db.database, i);
        if (constant_ref.name == constant_name) {
            return *constant_ref
        };
        i = i + 1;
    };

    abort (ERROR_CONSTANT_DOES_NOT_EXIST)
}

// Util Functions
    // Make
        fun make_constant(name: String, value: u256): Constant {
            Constant { name: name, value: value }
        }

    // Asserts
        fun assert_constant_does_not_exists(constant_name: String) acquires ConstantDatabase {
            let constant_db = borrow_global_mut<ConstantDatabase>(OWNER);
            let len = vector::length(&constant_db.database);
            while(len>0){
                let _constant = vector::borrow_mut(&mut constant_db.database, len-1);
                assert!(_constant.name != constant_name, ERROR_CONSTANT_ALREADY_EXISTS);
                len=len-1;
            };
        }

#[test(account = @0x1, owner = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7)]
public entry fun test(account: signer, owner: signer) acquires ConstantDatabase {
    print(&utf8(b" ACCOUNT ADDRESS "));
    print(&account);

    print(&utf8(b" OWNER ADDRESS "));
    print(&owner);

    let source_addr = signer::address_of(&account);
    init_module(&owner);
    account::create_account_for_test(source_addr);

    print(&utf8(b" USER STATS "));

  
}}

