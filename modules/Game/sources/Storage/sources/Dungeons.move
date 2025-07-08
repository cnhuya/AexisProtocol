module deployer::testDungeons08{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;
    use deployer::testCore31::{Self as Core, Dungeon,DungeonString, Material, MaterialString };
    use deployer::testEntities13::{Self as Entities};

    struct DungeonString_Config has copy, drop, store,key {period: u64, cost: vector<MaterialString>}
    struct Dungeon_Config has copy, drop, store,key {period: u64, cost: vector<Material>}
    struct DungeonString_Database has copy, drop {database: vector<DungeonString>}
    struct Dungeon_Database has copy, drop, store, key {database: vector<Dungeon>}


    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_DUNGEON_ALREADY_EXISTS: u64 = 2;

    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

    #[event]
    struct DungeonConfigChange has drop, store {address: address,  isBuff: bool, old_Config: Dungeon_Config, new_config: Dungeon_Config}


   fun init_module(address: &signer) {

        let deploy_addr = signer::address_of(address);

        if (!exists<Dungeon_Database>(deploy_addr)) {
          move_to(address, Dungeon_Database { database: vector::empty()});
        };
        if (!exists<Dungeon_Config>(deploy_addr)) {
          move_to(address, Dungeon_Config { period: 0, cost: vector::empty()});
        };

    }

    public entry fun testFun(address: &signer, dungeonID: u8, bossID: u8, numbs: vector<u32>, materialAmount: u32 ) {
    }

    public entry fun registerDungeon(address: &signer, dungeonID: u8, bossID: u8, entitiesID: vector<u8>, materialID: vector<u8>, materialAmount: vector<u32> ) acquires Dungeon_Database {
        let addr = signer::address_of(address);
        assert!(addr == OWNER, ERROR_NOT_OWNER);
        assert!(dungeon_exists(dungeonID) == false, ERROR_DUNGEON_ALREADY_EXISTS);
        let dungeon_db = borrow_global_mut<Dungeon_Database>(OWNER);
        let materials = Core::make_multiple_materials(materialID,materialAmount);
        let dungeon = Core::make_dungeon(dungeonID, bossID, entitiesID,materials);
        vector::push_back(&mut dungeon_db.database, dungeon);
    }

    public entry fun change_dungeon_config(address: &signer, period: u64, materialIDs: vector<u8>, materialAmounts: vector<u32>, isbuff: bool) acquires Dungeon_Config{
        let addr = signer::address_of(address);
        assert!(addr == OWNER, ERROR_NOT_OWNER);
        let config = borrow_global_mut<Dungeon_Config>(OWNER);
        let old_config = *config;
        config.period = period;
        let materials = Core::make_multiple_materials(materialIDs, materialAmounts);
        config.cost = materials;
        event::emit(DungeonConfigChange {
            address: signer::address_of(address),
            isBuff: isbuff,
            old_Config: old_config,
            new_config: *config,
        });
    }



#[view]
public fun viewDungeonsConfig(): DungeonString_Config acquires Dungeon_Config {
    let dungeon_config = borrow_global_mut<Dungeon_Config>(OWNER);
    let dung_confing = DungeonString_Config{
        period: dungeon_config.period,
        cost: Core::build_materials_with_strings(dungeon_config.cost),
    };
    dung_confing
}

#[view]
public fun viewDungeons(): vector<Dungeon> acquires Dungeon_Database {
    let dungeon_db = borrow_global_mut<Dungeon_Database>(OWNER);
    dungeon_db.database
}

//dungeon: Dungeon, bossName: String, entitiesName: vector<String>)
#[view]
public fun viewDungeonsString(): vector<DungeonString> acquires Dungeon_Database {
    let dungeon_db = borrow_global_mut<Dungeon_Database>(OWNER);
    let len = vector::length(&dungeon_db.database);
    let vec = vector::empty<DungeonString>();
    while(len > 0){
        let dung = vector::borrow(&dungeon_db.database,len-1);
        let dungeon = Core::make_string_dungeon(*dung,Entities::getEntityByID(Core::get_dungeon_boss(dung)),Entities::getMultipleEntitiesByIDs(Core::get_dungeon_entities(dung)));
        vector::push_back(&mut vec, dungeon);
        len=len-1;
    };
    vec
}


fun dungeon_exists(id: u8): bool acquires Dungeon_Database{
    let dungeon_db = borrow_global_mut<Dungeon_Database>(OWNER);
    let len = vector::length(&dungeon_db.database);
    let exists:bool = false;
    while (len>1){
        let dungeon = vector::borrow(&dungeon_db.database, len-1);
        if(Core::get_dungeon_ID(dungeon) == id){
            exists = true;
        };
        len=len-1;
    };
    exists
}



 #[test(account = @0x1, owner = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7)]
     public entry fun test(account: signer, owner: signer)  acquires Dungeon_Database {
        print(&utf8(b" ACCOUNT ADDRESS "));
        print(&account);
        print(&utf8(b" OWNER ADDRESS "));
        print(&owner);
                init_module(&owner);  
        //address: &signer, dungeonID: u8, bossID: u8, entitiesID: vector<u8>, materialID: vector<u8>, materialAmount: vector<u32> 
registerDungeon(
    &owner,
    1,
    1,
    (vector[0u8, 1u8, 2u8]: vector<u8>),
    (vector[0u8, 1u8, 2u8]: vector<u8>),
    (vector[0u32, 1u32, 2u32]: vector<u32>)
);

registerDungeon(
    &owner,
    2,
    1,
    (vector[0u8, 1u8, 2u8]: vector<u8>),
    (vector[0u8, 1u8, 2u8]: vector<u8>),
    (vector[0u32, 1u32, 2u32]: vector<u32>)
);

registerDungeon(
    &owner,
    3,
    1,
    (vector[0u8, 1u8, 2u8]: vector<u8>),
    (vector[0u8, 1u8, 2u8]: vector<u8>),
    (vector[0u32, 1u32, 2u32]: vector<u32>)
);
  

    }
}   