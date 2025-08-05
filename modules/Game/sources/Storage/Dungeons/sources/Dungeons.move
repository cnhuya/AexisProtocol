module deployer::testDungeonsV5{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;
    use deployer::testCore45::{Self as Core, Dungeon,DungeonString, Material, MaterialString };
    use deployer::testEntitiesV6::{Self as Entities};
    use deployer::testConstantV4::{Self as Constant};

    struct DungeonString_Database has copy, drop {database: vector<DungeonString>}
    struct Dungeon_Database has copy, drop, store, key {database: vector<Dungeon>}

    #[event]
    struct DungeonChange has drop, store {address: address, old_dungeon: DungeonString, new_dungeon: DungeonString}


    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_DUNGEON_ALREADY_EXISTS: u64 = 2;

    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;



   fun init_module(address: &signer) {

        let deploy_addr = signer::address_of(address);

        if (!exists<Dungeon_Database>(deploy_addr)) {
          move_to(address, Dungeon_Database { database: vector::empty()});
        };

    }

    public entry fun registerDungeon(address: &signer, dungeonID: u8, bossID: u8, entitiesID: vector<u8>, materialID: vector<u8>, materialAmount: vector<u32> ) acquires Dungeon_Database {
        let addr = signer::address_of(address);
        assert!(addr == OWNER, ERROR_NOT_OWNER);
        let dungeon_db = borrow_global_mut<Dungeon_Database>(OWNER);
        let len = vector::length(&dungeon_db.database);

        let materials = Core::make_multiple_materials(materialID, materialAmount);
        let new_dungeon = Core::make_dungeon(dungeonID, bossID, entitiesID, materials);

        let updated = false;

        while (len > 0) {
            let dungeon = vector::borrow_mut(&mut dungeon_db.database, len - 1);
            if (Core::get_dungeon_ID(dungeon) == dungeonID) {
                let old_dungeon = *dungeon;
                *dungeon = new_dungeon;

                event::emit(DungeonChange {
                    address: signer::address_of(address),
                    old_dungeon: Core::make_string_dungeon(old_dungeon,Entities::getEntityByID(Core::get_dungeon_boss(&old_dungeon)),Entities::getMultipleEntitiesByIDs(Core::get_dungeon_entities(&old_dungeon))),
                    new_dungeon: Core::make_string_dungeon(new_dungeon,Entities::getEntityByID(Core::get_dungeon_boss(&new_dungeon)),Entities::getMultipleEntitiesByIDs(Core::get_dungeon_entities(&new_dungeon))),
                });

                updated = true;
                break;
            };
            len = len - 1;
        };

        if (!updated) {
            vector::push_back(&mut dungeon_db.database, new_dungeon);
        };
    }



#[view]
public fun viewDungeonsConfig(): (u64, MaterialString) {
    let free_entry_period = Constant::get_constant_value(&Constant::viewConstant(utf8(b"Entities"),utf8(b"base_hp")));
    let cost_material = Constant::get_constant_value(&Constant::viewConstant(utf8(b"Entities"),utf8(b"base_hp")));
    let mat = Core::make_material(2, (cost_material as u32));
    let string_mat = Core::make_material_string(&mat);
    ((free_entry_period as u64),string_mat)
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
