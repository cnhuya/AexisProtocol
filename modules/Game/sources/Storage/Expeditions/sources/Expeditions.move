module new_dev::testExpeditionsV9{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;
    use deployer::testCore45::{Self as Core, Stat, Material, MaterialString, Item,Expedition, ExpeditionString};

// Structs

    struct ExpeditionString_Database has copy, drop, store, key {database: vector<ExpeditionString>}
    struct Expedition_Database has copy, drop, store, key {database: vector<Expedition>}
    struct UserExpedition has copy,drop,store,key {entry_time: u64, expeditionID: u8}

    #[event]
    struct ExpeditionChange has drop, store {address: address, old_expediiton: ExpeditionString, new_expedition: ExpeditionString}

// Const
    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

// Errors
    const ERROR_NOT_OWNER: u64 = 1;

// On Deploy Event
   fun init_module(address: &signer) {

        let deploy_addr = signer::address_of(address);

        if (!exists<Expedition_Database>(deploy_addr)) {
          move_to(address, Expedition_Database { database: vector::empty()});
        };

    }

// Make


// Entry Functions

      public entry fun registerExpedition(address: &signer, expeditionID: u8, required_level: u8, costMaterialIDs: vector<u8>, costMaterialAmount: vector<u32>,costMaterialPeriod: vector<u64>, rewardMaterialIDs: vector<u8>, rewardMaterialAmounts: vector<u32>, rewardMaterialPeriod: vector<u64>) acquires Expedition_Database {
        let addr = signer::address_of(address);
        assert!(addr == OWNER, ERROR_NOT_OWNER);

        let expedition_db = borrow_global_mut<Expedition_Database>(OWNER);
        let len = vector::length(&expedition_db.database);

        let new_expedition = Core::make_expedition(expeditionID,required_level, Core::make_multiple_rewards(costMaterialIDs, costMaterialAmount, costMaterialPeriod),Core::make_multiple_rewards(rewardMaterialIDs, rewardMaterialAmounts, rewardMaterialPeriod));

        let updated = false;

        while (len > 0) {
            let expedition = vector::borrow_mut(&mut expedition_db.database, len - 1);
            if (Core::get_expedition_ID(expedition) == expeditionID) {
                let old_expedition = *expedition;
                *expedition = new_expedition;

                event::emit(ExpeditionChange {
                    address: signer::address_of(address),
                    old_expediiton: Core::make_string_expedition(&old_expedition),
                    new_expedition: Core::make_string_expedition(&new_expedition),
                });

                updated = true;
                break; // Stop after updating
            };
            len = len - 1;
        };

        if (!updated) {
            vector::push_back(&mut expedition_db.database, new_expedition);
        };
    }

// View Functions

    #[view]
    public fun viewExpeditions(): vector<Expedition> acquires Expedition_Database {
        let expedition_db = borrow_global_mut<Expedition_Database>(OWNER);
        expedition_db.database
    }
    #[view]
    public fun viewExpeditionsString(): vector<ExpeditionString> acquires Expedition_Database {
        let expedition_db = borrow_global_mut<Expedition_Database>(OWNER);
        let len = vector::length(&expedition_db.database);
        let vec = vector::empty<ExpeditionString>();
        while(len > 0){
        let expedition = Core::make_string_expedition(vector::borrow(&expedition_db.database,len-1));
        vector::push_back(&mut vec, expedition);
        len=len-1;
        };
        vec
    }

    #[view]
    public fun viewExpeditionByID_raw(id: u8): Expedition acquires Expedition_Database {
        let expeditions = viewExpeditions();
        let len = vector::length(&expeditions);
        while(len > 0){
            let expedition = vector::borrow(&expeditions, len-1);
            if(Core::get_expedition_ID(expedition) == id){
                return *expedition
            };
            len=len-1;
        };
        abort(087)
    }

    #[view]
    public fun viewExpeditionByID(id: u8): ExpeditionString acquires Expedition_Database {
        let expedition_db = viewExpeditions();
        let length = vector::length(&expedition_db);
        let i = 0;
        while (i < length) {
            let expedition = vector::borrow(&expedition_db, i);
            if(Core::get_expedition_ID(expedition) == id){
                return Core::make_string_expedition(vector::borrow(&expedition_db, i))
            };
            i = i + 1;
        };
        abort(1)
    }

    #[view]
    public fun viewExpeditionByName(name: String): ExpeditionString acquires Expedition_Database {
        let expedition_db = viewExpeditions();
        let length = vector::length(&expedition_db);
        let i = 0;
        while (i < length) {
            let expedition = vector::borrow(&expedition_db, i);
            if(Core::convert_expeditionID_to_String(Core::get_expedition_ID(expedition)) == name){
            return Core::make_string_expedition(vector::borrow(&expedition_db, i))
            };
            i = i + 1;
        };
        abort(1)
    }

    #[view]
    public fun distribute_exped_rewards(id: u8,time_on_exped: u64): vector<Material> acquires Expedition_Database{
        let exped = viewExpeditionByID_raw(id);
        let len = vector::length(&Core::get_expedition_rewards(&exped));
        let vect = vector::empty<Material>();
        while(len > 0){
            let reward = vector::borrow(&Core::get_expedition_rewards(&exped), len-1);
            let time = time_on_exped/(Core::get_reward_period(reward));
            let amount = Core::get_reward_amount(reward)*(time as u32);
            let material = Core::make_material(Core::get_reward_id(reward), amount);
            vector::push_back(&mut vect, material);
            len=len-1;
        };
        move vect

    }


    
    #[view]
    public fun simulate_exped_rewards(id: u8,time_on_exped: u64): vector<MaterialString> acquires Expedition_Database{
       let rewards = distribute_exped_rewards(id, time_on_exped);
       Core::build_materials_with_strings(rewards)
    }

    #[view]
    public fun simulate_exped_rewardsNAME(name: String,time_on_exped: u64): vector<MaterialString> acquires Expedition_Database{
       let rewards = distribute_exped_rewards(convert_name_to_expedition_ID(name), time_on_exped);
       Core::build_materials_with_strings(rewards)
    }

    #[view]
    public fun distribute_exped_costs(id: u8,time_on_exped: u64): vector<Material> acquires Expedition_Database{
        let exped = viewExpeditionByID_raw(id);
        let len = vector::length(&Core::get_expedition_costs(&exped));
        let vect = vector::empty<Material>();
        while(len > 0){
            let cost = vector::borrow(&Core::get_expedition_costs(&exped), len-1);
            let time = time_on_exped/(Core::get_reward_period(cost));
            let amount = Core::get_reward_amount(cost)*(time as u32);
            let material = Core::make_material(Core::get_reward_id(cost), amount);
            vector::push_back(&mut vect, material);
            len=len-1;
        };
        move vect
    }



public fun convert_name_to_expedition_ID(name: String): u8 {
    if (name == utf8(b"Valley")) {
        return 1
    } else if (name == utf8(b"Desert")) {
        return 2
    } else if (name == utf8(b"Frostland")) {
        return 3
    } else if (name == utf8(b"Graveyard")) {
        return 4
    } else if (name == utf8(b"Sea")) {
        return 5
    } else if (name == utf8(b"Underground")) {
        return 6
    } else {
        return 0  // Unknown
    }
}


#[test(account = @0x1, owner = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7)]
public entry fun test(account: signer, owner: signer) acquires Expedition_Database {
    // Print addresses
    print(&utf8(b" ACCOUNT ADDRESS "));
    print(&signer::address_of(&account));

    print(&utf8(b" OWNER ADDRESS "));
    print(&signer::address_of(&owner));

    let source_addr = signer::address_of(&account);

    // Initialize module for owner
    init_module(&owner);

    // Create account for testing
    account::create_account_for_test(source_addr);

    print(&utf8(b" USER STATS "));

    // Call registerExpedition with valid arguments
    registerExpedition(
        &owner,
        1,                      // expeditionID
        1,                      // required_level
        vector[1u8],            // costMaterialIDs
        vector[1u32],           // costMaterialAmount
        vector[100u64],         // costMaterialPeriod
        vector[2u8],            // rewardMaterialIDs
        vector[10u32],          // rewardMaterialAmounts
        vector[200u64]          // rewardMaterialPeriod
    );

    // Print expedition data
    print(&viewExpeditions());
    print(&viewExpeditionByID_raw(1));
    print(&distribute_exped_rewards(1, 99999));
}
}

