module deployer::testPerks{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;
    use deployer::testCore20::{Self as Core, Value, ValueString, Perk, PerkString };

    struct Patchnotes_Database has copy, drop, key, store {database: vector<Patch>}
    struct Patch has copy, drop, store {version: String, adjuster: address, duration: u64, start: u64, end:u64}
    struct Proposal has copy, drop, store {proposer: address, patch: Patch, votes}
    struct Votes has copy, drop, store {yes: u256, no: u256}
    struct Vote has copy,drop,store {isYes: bool, value: u256}
    struct Proposers has copy, drop, store {proposers: vector<address>}

    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_VAR_NOT_INNITIALIZED: u64 = 2;
    const ERROR_TX_DOESNT_EXISTS: u64 = 3;

    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

   fun init_module(address: &signer) {

        let deploy_addr = signer::address_of(address);

        if (!exists<Proposers>(deploy_addr)) {
          move_to(address, Proposers { proposers: vector::empty()});
        };

        if (!exists<Patchnotes_Database>(deploy_addr)) {
          move_to(address, Patchnotes_Database { database: vector::empty()});
        };

    }
// Events
    #[event]
    struct AddProposer has drop, store {proposer: address, address: address}

    #[event]
    struct Proposal has drop, store {proposal: Proposal, status: String}



// Making Structs
    public fun makePatch(version: String, adjuster: address, duration: u64) Patch{
        Patch {version: version, adjuster: adjuster, duration: duration, start: timestamp::now_seconds(), end: (timestamp::now_seconds)+duration}
    }

    public fun makeProposal(address: &signer, patch: Patch) Proposal{
        Proposal {proposer: signer::address_of(address), patch}
        }
// Main
    public entry fun Vote(address: &signer, isYes: bool, value: u256){
        let proposers = borrow_global_mut<Perk_Database>(OWNER);
        assert!(isProposer(poposer) == true);
                event::emit(StaminaChange {
                    proposer: signer::address_of(address),
                    address: proposer, 
                });
        vector::push_back(&mut proposers.proposers, proposer);
    }
    public entry fun addProposer(address: &signer, proposer: address){
        let proposers = borrow_global_mut<Perk_Database>(OWNER);
        assert!(isProposer(poposer) == true);
                event::emit(StaminaChange {
                    proposer: signer::address_of(address),
                    address: proposer, 
                });
        vector::push_back(&mut proposers.proposers, proposer);
    }

    public entry fun CreateProposal(address: &signer, version: String, adjuster: address, duration: u64){
        let patch = makePatch(version, adjuster, duration);
        let proposal = makeProposal(patch);
        let proposers = borrow_global_mut<Perk_Database>(OWNER);
        assert!(isProposer(poposer) == true);
                event::emit(Proposal {
                    proposal: proposal,
                    status: utf8(b"Pending"), 
                });
        vector::push_back(&mut proposers.proposers, proposer);
    }

// View
    #[view]
    public fun viewPerks(): vector<PerkString> acquires Perk_Database {
        let perk_list = borrow_global<Perk_Database>(OWNER);
        let list = perk_list.database;
        let length = vector::length(&list);
        let i = 0;  
        let vect = vector::empty<PerkString>();

        while (i < length) {
            let perk_ref = viewPerkByID(length-1);
            vector::push_back(&mut vect, perk_ref);
            i = i + 1;
        };

        move vect
    }

    #[view]
    public fun viewPerkByID(id: u64): PerkString acquires Perk_Database {
        let perk_list = borrow_global<Perk_Database>(OWNER);
        let list = perk_list.database;
        let length = vector::length(&list);
        let i = 0;

        while (i < length) {
            let perk_ref = vector::borrow(&list, i);
            if (Core::get_perk_id(perk_ref) == id) {
                let perk = viewPerkByName(Core::get_perk_name(perk_ref));
                return perk
            };
            i = i + 1;
        };

        abort(1) // or define a specific error code
    }


    #[view]
    public fun viewPerkByName(name: String): PerkString acquires Perk_Database {
        let perk_list = borrow_global<Perk_Database>(OWNER);
        let list = perk_list.database;
        let length = vector::length(&list);
        let i = 0;

        while (i < length) {
            let perk_ref = vector::borrow(&list, i);
            if (Core::get_perk_name(perk_ref)== name) {
            let _perk = Core::make_string_perk(perk_ref);
            return _perk
            };
            i = i + 1;
        };
        abort(1) 
    }

    #[view]
    public fun viewPerksByType(typeID: u8): vector<Perk> acquires Perk_Database {
        let perk_list = borrow_global<Perk_Database>(OWNER);
        let list = perk_list.database;
        let len = vector::length(&list);

        let vect = vector::empty<Perk>();
        while(len > 0){
            let perk = vector::borrow_mut(&mut list, len-1);
            if(Core::get_perk_typeID(perk) == typeID){
                vector::push_back(&mut vect, *perk);
            };
            len = len-1;
        };

        move list
    }
// Helping Functions
    public fun isProposer(address: address) acquires Proposers{
        let proposers = borrow_global_mut<Perk_Database>(OWNER);
        let len = vector::length(&proposers.proposers);
        if(vector::contains(&proposers.proposers, address) == false){
            return false
        } else{
            return true
        };
    }
// Test
 #[test(account = @0x1, owner = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7)]
     public entry fun test(account: signer, owner: signer) acquires Perk_Database{
        print(&utf8(b" ACCOUNT ADDRESS "));
        print(&account);


        print(&utf8(b" OWNER ADDRESS "));
        print(&owner);


        let source_addr = signer::address_of(&account);
        
        init_module(&owner);

    //typeID: u8, elementID: u8,name: vector<u8>, stamina: u8, damage: u32, desc: String)

        let desc = b"Necromancer can active his special ability which allows him to slowly  <span class=\"notice\">drain enemy</span> soul...";
        let clean = utf8(desc);
        account::create_account_for_test(source_addr); 
        print(&utf8(b" USER STATS "));
        addValue(&owner, 3, true, 47);
        addValue(&owner, 5, false, 3);
        addValue(&owner, 1, true, 10);
        addPerk(
            &owner,
            1,
            utf8(b"testperk"),
            5,
            0,
        );
        print(&viewPerks());
        print(&viewPerksByType(1));
        print(&viewPerkByID(0));
        print(&viewPerkByName(utf8(b"testperk")));
        print(&get_perks_ID_list());
        print(&get_perks_values(utf8(b"testperk")));
        change_Perks_Values(&owner, utf8(b"testperk"),1,100);
        print(&get_perks_values(utf8(b"testperk")));
        change_Perk_Damage(&owner, utf8(b"testperk",),15);
        print(&viewPerkByName(utf8(b"testperk")));
        change_Perk_Stamina(&owner, utf8(b"testperk",),3);
        print(&viewPerkByName(utf8(b"testperk")));
        print(&get_perks_ID_list());
  }
}   