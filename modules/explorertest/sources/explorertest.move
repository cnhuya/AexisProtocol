module deployer::explorertest {
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
    use deployer::explorerv18;

    const DEPLOYER: address = @deployer;

    const MODULE_ADRESS: address = @deployer;

    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_VAR_NOT_INITIALIZED: u64 = 2;
    const ERROR_TX_DOESNT_EXISTS: u64 = 3;

    // Initialize the module
    fun init_module(address: &signer) {
    }

    entry fun mock_funtest(address: &signer, _userID: u64, _action: vector<u8>, _type: vector<u8>, _value: u128, _success: bool) {
        //explorerv18::emitTX(address, _userID, _action, _type, _value, _success)
    }

    public entry fun funtest(address: &signer, _userID: u64, _action: vector<u8>, _type: vector<u8>, _value: u128, _success: bool) {
        mock_funtest(address, _userID, _action, _type, _value, _success);
    }


    // Test function
    #[test(account = @0x1, owner = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020)]
    public entry fun test(account: signer, owner: signer)  {
        init_module(&owner);
        //print(&utf8(b" ACCOUNT ADDRESS "));
        funtest(&owner, 1, b"SELL", b"ETH 5X", 1000, true);
    }
}