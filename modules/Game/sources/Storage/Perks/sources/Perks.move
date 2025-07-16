module deployer::testPerksV8{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;
    use deployer::testCore42::{Self as Core, Value, ValueString, Perk, PerkString };


    struct Perk_Database has copy, drop, key, store {database: vector<Perk>}



    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_VAR_NOT_INNITIALIZED: u64 = 2;
    const ERROR_TX_DOESNT_EXISTS: u64 = 3;

    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

   fun init_module(address: &signer) {

        let deploy_addr = signer::address_of(address);

        if (!exists<Perk_Database>(deploy_addr)) {
          move_to(address, Perk_Database { database: vector::empty()});
        };

    }

public entry fun addPerk(address: &signer, perkID: u8, typeID: u8,name: String, cost: u8, cooldown: u8, valueIDs: vector<u8>, valueIsEnemy: vector<bool>, valueAmount: vector<u16>) acquires Perk_Database {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);
    does_perk_exists(perkID);
    let perk_db = borrow_global_mut<Perk_Database>(OWNER);
    let perk = Core::make_perk(perkID, name, typeID, cost, cooldown, Core::make_multiple_values(valueIDs, valueIsEnemy, valueAmount));
    vector::push_back(&mut perk_db.database, perk);
}

    #[view]
    public fun viewPerks(): vector<PerkString> acquires Perk_Database {
        let perk_list = borrow_global<Perk_Database>(OWNER);
        let length = vector::length(&perk_list.database);
        let i = 0;  
        let vect = vector::empty<PerkString>();

        while (i < length) {
            let perk_ref = vector::borrow(&perk_list.database, i);
            vector::push_back(&mut vect, Core::make_string_perk(perk_ref, calculate_required_perk(perk_ref)));
            i = i + 1;
        };

        move vect
    }

    #[view]
    public fun viewPerkByID(id: u8): PerkString acquires Perk_Database {
        let perk_list = borrow_global<Perk_Database>(OWNER);
        let length = vector::length(&perk_list.database);
        let i = 0;

        while (i < length) {
            let perk_ref = vector::borrow(&perk_list.database, i);
            if (Core::get_perk_id(perk_ref) == id) {
                return Core::make_string_perk(perk_ref, calculate_required_perk(perk_ref))
            };
            i = i + 1;
        };

        // You might want to abort or return a default if not found
        abort(1) // or define a specific error code
    }

    #[view]
    public fun viewPerksByType(typeID: u8): vector<PerkString> acquires Perk_Database {
        let perk_list = borrow_global<Perk_Database>(OWNER);
        let list = perk_list.database;
        let len = vector::length(&list);

        let vect = vector::empty<PerkString>();
        while(len > 0){
            let perk = vector::borrow_mut(&mut list, len-1);
            let _prk = calculate_required_perk(perk);
            if(Core::get_perk_typeID(perk) == typeID){
                vector::push_back(&mut vect, Core::make_string_perk(perk,_prk));
            };
            len = len-1;
        };

        move vect
    }
    fun does_perk_exists(_perk: u8) acquires Perk_Database {
        let perk_list = borrow_global<Perk_Database>(OWNER);
        let list = perk_list.database;
        let len = vector::length(&list);
        while(len > 0){
            let perk = vector::borrow_mut(&mut list, len-1);
            if(Core::get_perk_id(perk) == _perk){
                abort(000)
            };
            len = len-1;
        };
    }

    fun calculate_required_perk(perk: &Perk): u8{
        if((Core::get_perk_stamina(perk) + Core::get_perk_cooldown(perk)) < 5){
            return 1
        } else {
            return ((Core::get_perk_stamina(perk) + Core::get_perk_cooldown(perk)) / 5)
        }
    }

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
