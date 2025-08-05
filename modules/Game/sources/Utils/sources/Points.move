module deployer::testPoints6 {
    use std::debug::print;
    use std::string::{String, utf8};
    use std::signer;
    use std::account;
    use std::vector;
    use supra_framework::coin::{Self};
    use supra_framework::supra_coin::{Self, SupraCoin};
    use deployer::testStats6::{Self as Stats};

// Structs
    struct Points has copy, key, drop, store {amount: u64}
    struct HolderDB has copy, store, key, drop {holders: vector<address>}
    
    struct Holder has copy, key, drop {address: address, amount: u64}

    struct AccessCap has store {}

    struct CapHolder has key {
        cap: Stats::AccessCap,
    }

    const ADMIN: address = @deployer; 
    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;
    const DESTINATION: address = @0x1ca524aa1ac448f3fa9d9a6ff9988c1cfd79a36480cd0e03cb3a7cdeb0c29034;
    
// Initialize stats
    fun init_module(address: &signer) {
        assert!(signer::address_of(address) == ADMIN, 1000);
        let cap = Stats::grant_cap(address);
        move_to(address, CapHolder { cap });

        if (!exists<Points>(signer::address_of(address))) {
            move_to(address, HolderDB { holders: vector::empty<address>()});
        }
    }

// Grant capability to trusted modules
    public fun grant_cap(caller: &signer): AccessCap {
        let addr = signer::address_of(caller);
        assert!(addr == OWNER, 999);
        AccessCap {}
    }

// Entry function
    public entry fun test_give_points(signer: &signer, amount: u64) acquires Points, CapHolder, HolderDB{
        give_points(signer,amount);
    }

// Restricted functions
    public fun give_points(signer: &signer, amount: u64) acquires Points, CapHolder, HolderDB{
        init_points_storage(signer);
        let holder = borrow_global<CapHolder>(ADMIN); // Always use the fixed address
        let points = borrow_global_mut<Points>(signer::address_of(signer));
        coin::transfer<SupraCoin>(signer, DESTINATION, amount*100);
        Stats::add_points(&holder.cap, (amount as u256));
        points.amount = points.amount + amount;
    }

    public fun give_points_free(signer: &signer, amount: u64) acquires Points, CapHolder, HolderDB{
        init_points_storage(signer);
        let holder = borrow_global<CapHolder>(ADMIN); // Always use the fixed address
        let points = borrow_global_mut<Points>(signer::address_of(signer));
        Stats::add_points(&holder.cap, (amount as u256));
        points.amount = points.amount + amount;
    }

// View functions
    #[view]
    public fun view_points(address: address): u64 acquires Points{
        let points = *borrow_global<Points>(address);
        points.amount
    }

    #[view]
    public fun view_holders(): vector<Holder> acquires Points, HolderDB{
        let holderDB = borrow_global<HolderDB>(ADMIN);
        let len = vector::length(&holderDB.holders);
        let vect = vector::empty<Holder>();
        while(len > 0){
            let address = *vector::borrow(&holderDB.holders, len-1);
            let points = borrow_global<Points>(address);
            let holder = Holder {address: address, amount: points.amount};
            vector::push_back(&mut vect, holder);
        };
        move vect
    }

// Utils
    fun init_points_storage(signer: &signer) acquires HolderDB{
        if (!exists<Points>(signer::address_of(signer))) {
                let holderDB = borrow_global_mut<HolderDB>(signer::address_of(signer));
                vector::push_back(&mut holderDB.holders, signer::address_of(signer));
                move_to(signer, Points { amount: 0});
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

