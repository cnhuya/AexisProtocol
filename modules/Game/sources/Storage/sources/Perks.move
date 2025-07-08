module deployer::testPerks1{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;
    use deployer::testCore31::{Self as Core, Value, ValueString, Perk, PerkString };

    /*
    element | id

    fire = 1
    poison = 2
    ice = 3
    lightning = 4 
    dark magic = 5
    water = 6
    curse = 7




    */

    struct Perk_Database has copy, drop, key, store {database: vector<Perk>}





    #[event]
    struct ValueChange has drop, store {address: address, name: String, valueName: String, isBuff: bool, from: u8, to: u8}

    #[event]
    struct DamageChange has drop, store {address: address, name: String, isBuff: bool, from: u32, to: u32}

    #[event]
    struct StaminaChange has drop, store {address: address, name: String, isBuff: bool, from: u8, to: u8}

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


public entry fun change_Perk_Stamina(address: &signer, name: String, new_value: u8) acquires Perk_Database{
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);

    let perk_list = borrow_global_mut<Perk_Database>(OWNER);
    let list = &mut perk_list.database;
    let length = vector::length(list);
    let i = 0;
    let from = 0;
    let to = 0;
    let isBuff;
        while (i < length) {
        let perk = vector::borrow_mut(list, i);
        if (Core::get_perk_name(perk) == name) {
            from = Core::get_perk_stamina(perk);
            Core::change_perk_stamina(perk, new_value);

            if(new_value > from){
                isBuff = true;
            }   else{
                isBuff = false;
            };

            event::emit(StaminaChange {
                address: signer::address_of(address),
                name: name,
                isBuff: isBuff,
                from: from,
                to: new_value,
            });
        };
        i = i + 1;
    };
}

public entry fun change_Perk_Damage(address: &signer, name: String, new_value: u32) acquires Perk_Database {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);

    let perk_list = borrow_global_mut<Perk_Database>(OWNER);
    let list = &mut perk_list.database;
    let length = vector::length(list);
    let i = 0;
    let from = 0;
    let to = 0;
    let isBuff;
        while (i < length) {
        let perk = vector::borrow_mut(list, i);
        if (Core::get_perk_name(perk) == name) {
            from = Core::get_perk_damage(perk);
            Core::change_perk_damage(perk, new_value);
            if(new_value > from){
                isBuff = true;
            }   else{
                isBuff = false;
            };

            event::emit(DamageChange {
                address: signer::address_of(address),
                name: name,
                isBuff: isBuff,
                from: from,
                to: new_value,
            });

        };
        i = i + 1;
    };
}


public entry fun change_Perks_Values(address: &signer, name: String, valueID: u8, new_value: u8) acquires Perk_Database {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);

    let perk_list = borrow_global_mut<Perk_Database>(OWNER);
    let list = perk_list.database;
    let length = vector::length(&list);
    let i = 0;
    let from = 0;
    let to = 0;
    let isBuff;
        while (i < length) {
        let perk = vector::borrow_mut(&mut list, i);
        if (Core::get_perk_name(perk) == name){
            let values = Core::get_perk_values(perk);
            let values_len = vector::length(&values);
            while (values_len > 0){
                let value = vector::borrow_mut(&mut values, values_len-1);
                if(Core::get_value_ID(value) == valueID){
                    from = Core::get_value_value(value);
                    Core::change_value_amount(value, new_value);
                };
                values_len = values_len-1;
            };

            if(new_value > from){
                isBuff = true;
            }   else{
                isBuff = false;
            };
            event::emit(ValueChange {
                address: signer::address_of(address),
                name: name,
                valueName: Core::convert_valueID_to_String(valueID),
                isBuff: isBuff,
                from: from,
                to: new_value,
            });
        };
        i = i + 1;
    };
}

public entry fun addPerk(address: &signer, typeID: u8,name: String, stamina: u8, damage: u32) acquires Perk_Database {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);
    let perk_list = borrow_global_mut<Perk_Database>(OWNER);
    let list = perk_list.database;
    let perk_length = vector::length(&list);
    //let perk = Core::make_perk(perk_length, name, typeID, stamina, damage, Core::extract_value_list(address));
    //vector::push_back(&mut list, perk);
}

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

    // You might want to abort or return a default if not found
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