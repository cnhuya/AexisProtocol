module testing::utilizationv4{

    use std::debug::print;
    use std::string::utf8;
    use std::string;
    use std::timestamp; 
    use std::account;
    use std::signer;

    struct UTILIZATION has copy, drop, key { fee: u8, utilization: u8}

  const ERROR_NOT_OWNER: u64 = 1;
  const ERROR_VAR_NOT_INNITIALIZED: u64 = 2;
  const ERROR_TX_DOESNT_EXISTS: u64 = 3;

  const OWNER: address = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020;

   fun init_module(address: &signer) {

        let deploy_addr = signer::address_of(address);

        if (!exists<UTILIZATION>(deploy_addr)) {
          move_to(address, UTILIZATION { fee: 0, utilization: 0});
        };
    }

    public entry fun updateUtilization(address: &signer, _fee: u8, _utilization: u8) acquires UTILIZATION{
        let addr = signer::address_of(address);
        assert!(addr == OWNER, ERROR_NOT_OWNER);

        let utilization = borrow_global_mut<UTILIZATION>(OWNER);

        utilization.fee = _fee;
        utilization.utilization = _utilization;

    }

    #[view]
    public fun view_Utilization():UTILIZATION acquires UTILIZATION{

        let utilization = borrow_global_mut<UTILIZATION>(OWNER);

        let _utilization = UTILIZATION{
            fee: utilization.fee,
            utilization: utilization.utilization,
        };

        print(&_utilization);

        move _utilization
    }
 #[test(account = @0x1, owner = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020)]
     public entry fun test(account: signer, owner: signer) acquires UTILIZATION{
        //view function to view contract info
        //let timespan: u32 = 5000;
        print(&utf8(b" ACCOUNT ADDRESS "));
        print(&account);


        print(&utf8(b" OWNER ADDRESS "));
        print(&owner);


        let source_addr = signer::address_of(&account);
        
        init_module(&owner);

        account::create_account_for_test(source_addr); 
        print(&utf8(b" USER STATS "));
        view_Utilization();
        updateUtilization(&owner, 1, 50);
        view_Utilization();
        //assert!(open.o != 0, 1024);

  }
}   
