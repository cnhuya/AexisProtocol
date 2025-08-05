module deployer::testRacesV5{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;
    use deployer::testCore45::{Self as Core, Value, ValueString, Race, RaceString };

    struct Race_Database has copy,drop,store,key {database: vector<Race>}


    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_VAR_NOT_INNITIALIZED: u64 = 2;
    const ERROR_TX_DOESNT_EXISTS: u64 = 3;

    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

    #[event]
    struct RaceChange has drop, store {address: address, old_race: RaceString, new_race: RaceString}

   fun init_module(address: &signer) {

        let deploy_addr = signer::address_of(address);

        if (!exists<Race_Database>(deploy_addr)) {
          move_to(address, Race_Database { database: vector::empty()});
        };

    }

public entry fun addRace(address: &signer, raceID: u8, valueIDs: vector<u8>, valueIsEnemies: vector<bool>, valueValues: vector<u16>) acquires Race_Database, {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);
    let race_db = borrow_global_mut<Race_Database>(OWNER);
    let len = vector::length(&race_db.database);

    let new_race = Core::make_race(raceID, Core::make_multiple_values(valueIDs, valueIsEnemies, valueValues));

    let updated = false;

    while (len > 0) {
        let race = vector::borrow_mut(&mut race_db.database, len - 1);
        if (Core::get_race_id(race) == raceID) {
            let old_race = *race;
            *race = new_race;

            event::emit(RaceChange {
                address: signer::address_of(address),
                old_race: Core::make_string_race(&old_race),
                new_race: Core::make_string_race(&new_race),
            });

            updated = true;
            break;
        };
        len = len - 1;
    };

    if (!updated) {
        vector::push_back(&mut race_db.database, new_race);
    };
}

fun does_race_exists(raceID: u8): bool acquires Race_Database{
    let race_db = borrow_global_mut<Race_Database>(OWNER);
    let len = vector::length(&race_db.database);
    while(len>0){
        let race = vector::borrow(&race_db.database, len-1);
        if(Core::get_race_id(race) == raceID){
            return true
        };
        len=len-1;
    };
    return false
}

#[view]
public fun viewRaces(): vector<RaceString> acquires Race_Database {
    let ability_db = borrow_global<Race_Database>(OWNER);
    let length = vector::length(&ability_db.database);
    let i = 0;
    let vect = vector::empty<RaceString>();
    while (i < length) {
        let race = vector::borrow(&ability_db.database, i);
        let _ability = Core::make_string_race(race);
        vector::push_back(&mut vect, _ability);
        i = i + 1;
    };
    move vect 
}

#[view]
public fun viewRace(raceName: String): RaceString acquires Race_Database {
    let race_db = borrow_global<Race_Database>(OWNER);
    let length = vector::length(&race_db.database);
    let i = 0;
  
    while (i < length) {
        let race = vector::borrow(&race_db.database, i);
        if (Core::get_race_name(race) == raceName) {
            return Core::make_string_race(race)
        };
        i = i + 1;
    };
    abort(1) 
}



 #[test(account = @0x1, owner = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7)]
     public entry fun test(account: signer, owner: signer) acquires Race_Database{
        print(&utf8(b" ACCOUNT ADDRESS "));
        print(&account);


        print(&utf8(b" OWNER ADDRESS "));
        print(&owner);


        let source_addr = signer::address_of(&account);
        
        init_module(&owner);


        let desc = b"Necromancer can active his special ability which allows him to slowly  <span class=\"notice\">drain enemy</span> soul...";
        let clean = utf8(desc);
        account::create_account_for_test(source_addr); 
        print(&utf8(b" USER STATS "));
        addRace(&owner, 1,(vector[3u8, 1u8, 2u8]: vector<u8>),(vector[true, true, false]: vector<bool>),(vector[3u16, 1u16, 2u16]: vector<u16>));
        print(&viewRaces());
        print(&viewRace(utf8(b"Human")));
    }
}   
