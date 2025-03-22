module deployer::explorerv18 {
    use std::signer;
    use std::vector;
    use std::account;
    use std::debug::print;
    use std::string::utf8;
    use std::string;
    use std::timestamp;
    use std::table;
    //use std::features;
    //use supra_framework::event::{Self, EventHandle};
    //use supra_framework::transaction_context;
    friend deployer::governancev38;

    struct EXPLORER has copy, drop, key { totalTX: u256, totalVolume: u256, tvl: u256 }
    struct UTILIZATION has copy, drop, key { fee: u16, utilization: u8 }

    struct COUNTER has key {count: u256}

    struct TRANSACTION has copy, drop, key, store { id: u256, module_address: address, userID: u64, action: vector<u8>, type: vector<u8>, value: u128, fee: u16, success: bool }

    struct TRANSACTIONS_DATABASE has key, store, copy, drop { transactions: vector<TRANSACTION> }
    const DEPLOYER: address = @deployer;

    const MODULE_ADRESS: address = @deployer;

    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_VAR_NOT_INITIALIZED: u64 = 2;
    const ERROR_TX_DOESNT_EXISTS: u64 = 3;

    // Initialize the module
    fun init_module(address: &signer) {
        let deploy_addr = signer::address_of(address);

        if (!exists<EXPLORER>(deploy_addr)) {
            move_to(address, EXPLORER { totalTX: 0, totalVolume: 0, tvl: 0 });
        };

        if (!exists<UTILIZATION>(deploy_addr)) {
            move_to(address, UTILIZATION { fee: 2, utilization: 0 });
        };

        if (!exists<TRANSACTIONS_DATABASE>(deploy_addr)) {
            move_to(address, TRANSACTIONS_DATABASE { transactions: vector::empty()});
        };
    }

    public(friend) fun emitTX(address: &signer, _userID: u64, _action: vector<u8>, _type: vector<u8>, _value: u128, _success: bool) acquires TRANSACTIONS_DATABASE, EXPLORER, UTILIZATION {
        let _owner = DEPLOYER;
        mock_emitTX(address, signer::address_of(address), _userID, _action, _type, _value, _success, _owner);
    }

    // Register a new transaction
    entry fun mock_emitTX(address: &signer, userAdd: address, _userID: u64, _action: vector<u8>, _type: vector<u8>, _value: u128, _success: bool, owner: address ) acquires TRANSACTIONS_DATABASE, EXPLORER, UTILIZATION {
        let addr = signer::address_of(address);
        //assert!(addr == DEPLOYER, ERROR_NOT_OWNER);


        let explorer = borrow_global_mut<EXPLORER>(DEPLOYER);
        let tx_count = explorer.totalTX + 1;

        let utilization = borrow_global_mut<UTILIZATION>(DEPLOYER);
        let _fee = utilization.fee;

        let tx = TRANSACTION {
            id: tx_count,
            module_address: DEPLOYER,
            userID: _userID,
            action: _action,
            type: _type,
            value: _value,
            fee: _fee,
            success: _success,
        };


        let tx_db = borrow_global_mut<TRANSACTIONS_DATABASE>(DEPLOYER);
        vector::push_back(&mut tx_db.transactions, tx);
        explorer.totalVolume = explorer.totalVolume + (_value as u256);

    }


#[view]
    public fun viewTransactions(): vector<TRANSACTION> acquires TRANSACTIONS_DATABASE {
        let tx_db = *borrow_global<TRANSACTIONS_DATABASE>(DEPLOYER);
        let transactions = tx_db.transactions;
        move transactions
    }


    // Test function
    #[test(account = @0x1, owner = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020)]
    public entry fun test(account: signer, owner: signer) acquires TRANSACTIONS_DATABASE, EXPLORER, UTILIZATION {
        init_module(&owner);
        //print(&utf8(b" ACCOUNT ADDRESS "));
        emitTX(&owner, 1, b"SELL", b"ETH 5X", 1000, true);
        print(&viewTransactions());
    }
}