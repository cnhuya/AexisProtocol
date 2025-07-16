module deployer::testExpeditionsV2{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;
    use deployer::testCore42::{Self as Core, Stat, Material, Item,Expedition, ExpeditionString};

// Structs

    struct ExpeditionString_Database has copy, drop, store, key {database: vector<ExpeditionString>}
    struct Expedition_Database has copy, drop, store, key {database: vector<Expedition>}
    struct UserExpedition has copy,drop,store,key {entry_time: u64, expeditionID: u8}

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
        assert!(expedition_exists(expeditionID) == false,5);
        let expedition_db = borrow_global_mut<Expedition_Database>(OWNER);
        let expedition = Core::make_expedition(expeditionID, required_level, Core::make_multiple_rewards(costMaterialIDs, costMaterialAmount,costMaterialPeriod), Core::make_multiple_rewards(rewardMaterialIDs, rewardMaterialAmounts,rewardMaterialPeriod));
        vector::push_back(&mut expedition_db.database, expedition);
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
        let expedition_db = borrow_global_mut<Expedition_Database>(OWNER);
        let len = vector::length(&expedition_db.database);
        while(len < 0){
            let expedition = vector::borrow(&expedition_db.database, len-1);
            if(Core::get_expedition_ID(expedition) == id){
                return *expedition
            };
            len=len-1;
        };
        abort(000)
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

// Util Functions
    fun expedition_exists(id: u8): bool acquires Expedition_Database{
        let expedition_db = borrow_global_mut<Expedition_Database>(OWNER);
        let len = vector::length(&expedition_db.database);
        let exists:bool = false;
        while (len>0){
            let expedition = vector::borrow(&expedition_db.database, len-1);
            if(Core::get_expedition_ID(expedition) == id){
                exists = true;
            };
            len=len-1;
        };
        exists
    }

    fun distribute_exped_rewards(id: u8,time_on_exped: u64): vector<Material> acquires Expedition_Database{
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

    
    fun distribute_exped_costs(id: u8,time_on_exped: u64): vector<Material> acquires Expedition_Database{
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


#[test(account = @0x1, owner = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7)]
public entry fun test(account: signer, owner: signer) acquires Class_Database {
    print(&utf8(b" ACCOUNT ADDRESS "));
    print(&account);

    print(&utf8(b" OWNER ADDRESS "));
    print(&owner);

    let source_addr = signer::address_of(&account);
    init_module(&owner);
    account::create_account_for_test(source_addr);

    print(&utf8(b" USER STATS "));

    // Sample passive data
    let passive_name = vector[utf8(b"passive1"), utf8(b"passive2")];
    let passive_valueIDs = vector[vector[1u8], vector[2u8]];
    let passive_valueIsEnemies = vector[vector[true], vector[false]];
    let passive_valueValues = vector[vector[10u8], vector[20u8]];
    let passive_valueTimes = vector[vector[100u64], vector[200u64]];

    // Sample active data
    let active_name = vector[utf8(b"active1"), utf8(b"active2")];
    let active_cooldown = vector[5u8, 6u8];
    let active_stamina = vector[10u8, 20u8];
    let active_damage = vector[50u16, 100u16];
    let active_valueIDs = vector[vector[3u8], vector[4u8]];
    let active_valueIsEnemies = vector[vector[true], vector[false]];
    let active_valueValues = vector[vector[7u8], vector[8u8]];

    createClass(
        &owner,
        1, // classID
        passive_name,
        passive_valueIDs,
        passive_valueIsEnemies,
        passive_valueValues,
        passive_valueTimes,
        active_name,
        active_cooldown,
        active_stamina,
        active_damage,
        active_valueIDs,
        active_valueIsEnemies,
        active_valueValues
    );

        createClass(
        &owner,
        2, // classID
        passive_name,
        passive_valueIDs,
        passive_valueIsEnemies,
        passive_valueValues,
        passive_valueTimes,
        active_name,
        active_cooldown,
        active_stamina,
        active_damage,
        active_valueIDs,
        active_valueIsEnemies,
        active_valueValues
    );

        createClass(
        &owner,
        3, // classID
        passive_name,
        passive_valueIDs,
        passive_valueIsEnemies,
        passive_valueValues,
        passive_valueTimes,
        active_name,
        active_cooldown,
        active_stamina,
        active_damage,
        active_valueIDs,
        active_valueIsEnemies,
        active_valueValues
    );

        createClass(
        &owner,
        4, // classID
        passive_name,
        passive_valueIDs,
        passive_valueIsEnemies,
        passive_valueValues,
        passive_valueTimes,
        active_name,
        active_cooldown,
        active_stamina,
        active_damage,
        active_valueIDs,
        active_valueIsEnemies,
        active_valueValues
    );

        createClass(
        &owner,
        5, // classID
        passive_name,
        passive_valueIDs,
        passive_valueIsEnemies,
        passive_valueValues,
        passive_valueTimes,
        active_name,
        active_cooldown,
        active_stamina,
        active_damage,
        active_valueIDs,
        active_valueIsEnemies,
        active_valueValues
    );

    print(&viewClass(1));
    print(&viewClass(2));
    print(&viewClass(3));
    print(&viewClass(4));
    print(&viewClass(5));
    print(&viewClasses());
}}

