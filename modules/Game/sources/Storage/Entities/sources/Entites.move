module deployer::testEntitiesV6{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;
    use deployer::testCore45::{Self as Core, Entity, Type, Stat, StatString, Location, Material, MaterialString };
    use deployer::testConstantV4::{Self as Constant};

    struct FullEntity has copy, drop {entity: Entity, stats: vector<StatString>}
    struct Entity_Database has copy,drop,store,key {database: vector<Entity>}
                           

    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_ENTITY_TYPE_DOESNT_EXISTS: u64 = 2;
    const ERROR_LOCATION_DOESNT_EXISTS: u64 = 3;
    const ERROR_ENTITY_WITH_NAME_ALREADY_EXISTS: u64 = 4;
    const ERROR_ENTITY_WITH_ID_ALREADY_EXISTS: u64 = 5;

    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

   fun init_module(address: &signer) {

        let deploy_addr = signer::address_of(address);


        if (!exists<Entity_Database>(deploy_addr)) {
          move_to(address, Entity_Database {database: vector::empty()});
        };

    }

public entry fun addEntity(address: &signer, entityID: u8, entityName: String, type: String, location: String) acquires Entity_Database {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);

    assert!(entity_exists_by_ID(entityID) == false, ERROR_ENTITY_WITH_ID_ALREADY_EXISTS);
    assert!(entity_exists_by_name(entityName) == false, ERROR_ENTITY_WITH_NAME_ALREADY_EXISTS);
    let entity_db = borrow_global_mut<Entity_Database>(OWNER);

    let entity = Core::make_entity(entityID,  entityName, type, location);
    vector::push_back(&mut entity_db.database, entity);
}



#[view]
public fun viewEntityBaseStats(): vector<Stat>  {

    let hp = Constant::get_constant_value(&Constant::viewConstant(utf8(b"Entities"),utf8(b"base_hp")));
    let damage = Constant::get_constant_value(&Constant::viewConstant(utf8(b"Entities"),utf8(b"base_dmg")));
    let armor = Constant::get_constant_value(&Constant::viewConstant(utf8(b"Entities"),utf8(b"base_armor")));

    let vect = vector[Core::make_stat(1, (hp as u64)),Core::make_stat(3, (damage as u64)),Core::make_stat(2, (armor as u64))];
    vect
}

#[view]
public fun viewEntityTypeMulti(type: String): u64  {

    let multi = 0;
    if(type == utf8(b"Mob")){
        multi = Constant::get_constant_value(&Constant::viewConstant(utf8(b"Entities"),utf8(b"mob_multi")));
    } else if(type == utf8(b"Titan")){
        multi = Constant::get_constant_value(&Constant::viewConstant(utf8(b"Entities"),utf8(b"titan_multi")));
    }  else if(type == utf8(b"God")){
        multi = Constant::get_constant_value(&Constant::viewConstant(utf8(b"Entities"),utf8(b"god_multi")));
    } ;

    (multi as u64)
}

#[view]
public fun viewEntities(): vector<Entity> acquires Entity_Database {
    let type_db = borrow_global<Entity_Database>(OWNER);
    type_db.database
}

#[view]
public fun getEntityByID(id: u8): String acquires Entity_Database {
    let entity_db = borrow_global<Entity_Database>(OWNER);
    let entities = &entity_db.database;  // <-- borrow from database vector, which holds Entities
    let len = vector::length(entities);

    let i = len;
    while (i > 0) {
        i = i - 1;
        let entity_ref = vector::borrow(entities, i);
        if (Core::get_entity_ID(entity_ref) == id) {
            return Core::get_entity_name(entity_ref)
        };
    };
    abort(1)
}

#[view]
public fun getMultipleEntitiesByIDs(ids: vector<u8>): vector<String> acquires Entity_Database {
    let entity_db = borrow_global<Entity_Database>(OWNER);
    let entities = &entity_db.database;  // <-- borrow from database vector, which holds Entities
    let len = vector::length(&ids);
    let vect = vector::empty<String>();
    while (len > 0) {
        let entityID = vector::borrow(&ids, len-1);
        let entityName = getEntityByID(*entityID);
        vector::push_back(&mut vect, entityName);
        len=len-1;
    };
    move vect
}

#[view]
public fun viewEntityByName(name: String): Entity acquires Entity_Database {
    let entity_db = borrow_global<Entity_Database>(OWNER);
    let entities = &entity_db.database;  // <-- borrow from database vector, which holds Entities
    let len = vector::length(entities);

    let i = len;
    while (i > 0) {
        i = i - 1;
        let entity_ref = vector::borrow(entities, i);
        if (Core::get_entity_name(entity_ref) == name) {
            return *entity_ref
        };
    };
    abort(1)
}

#[view]
public fun viewEntityByID(id: u8): Entity acquires Entity_Database {
    let type_db = viewEntities();
    let len = vector::length(&type_db);

    while(len > 0){
        let entity = vector::borrow(&type_db, len-1);

        if(Core::get_entity_ID(entity) == id){
            return *entity
        };

        len=len-1;
    };
    abort(1)
}

public fun get_entity_stats(id: u8): vector<StatString> acquires Entity_Database{
    let entity = viewEntityStatsByName(id);
    return entity.stats
}

public fun get_entity_stats_raw(id: u8): vector<Stat> acquires Entity_Database{
    simulate_entity_stat(id)
}

#[view]
public fun viewEntityStatsByName(name: u8): FullEntity acquires Entity_Database {
    let entity_db = viewEntities();

    let len = vector::length(&entity_db);

    while(len > 0){
        let entity = vector::borrow(&entity_db, len-1);

        if(Core::get_entity_ID(entity) == name){

            let _entity = FullEntity {
                entity: *entity,
                stats: Core::build_stats_with_strings(simulate_entity_stat(name)),
            };
            return _entity
        };
        len=len-1;
    };
    abort(1)
}

#[view]
public fun viewEntitiesStats(): vector<FullEntity> acquires Entity_Database{
    let entity_db = viewEntities();

    let len = vector::length(&entity_db);
    let vect = vector::empty<FullEntity>();
    while(len > 1){
        let entity = viewEntityStatsByName((len as u8));
        vector::push_back(&mut vect, entity);
        len=len-1;
    };
    move vect
}

fun simulate_entity_stat(entityName: u8): vector<Stat> acquires Entity_Database{
    let entity = viewEntityByID(entityName);
    let entity_type_multi = viewEntityTypeMulti(Core::get_entity_type(&entity));
    let entityID = Core::get_entity_ID(&entity);
    let stats = viewEntityBaseStats(); // Immutable borrow now
    let len = vector::length(&stats);
    let vec = vector::empty<Stat>();
    let i = 0;
    while (i < len) {
        let stat = vector::borrow(&stats, i); // Immutable reference
        let stat_id = Core::get_stat_ID(stat);
        let stat_name = Core::convert_statID_to_String(stat_id); // Assuming this function exists
        let stat_val = Core::get_stat_value(stat);
        let new_val: u64;
    
        if (Core::convert_statID_to_String(stat_id) == utf8(b"Attack_Speed")) {
            new_val = 1;
        } else {
            let entityID_val = (entityID as u64);
            let grow_multi = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Entities"),utf8(b"id_grow_multi"))) as u64);
            let growth_factor = ((entityID_val * entityID_val)) * grow_multi;
            new_val = (stat_val * ((entity_type_multi as u64) * growth_factor)) / 10001;
        };

        let _stat = Core::make_stat(stat_id, new_val); // Custom constructor
        vector::push_back(&mut vec, _stat);
        i = i + 1;
    };

    move vec
}




fun entity_exists_by_name(entityName: String): bool acquires Entity_Database {
    let entity_db = viewEntities();
    let len = vector::length(&entity_db);
    let exists = false;
    while(len > 0){
        let entity = vector::borrow(&entity_db, len-1);

        if(Core::get_entity_name(entity) == entityName){
            exists = true;
        };

        len=len-1;
    };

    move exists
}

fun entity_exists_by_ID(entityID: u8): bool acquires Entity_Database {
    let entity_db = viewEntities();
    let len = vector::length(&entity_db);
    let exists = false;
    while(len > 0){
        let entity = vector::borrow(&entity_db, len-1);

        if(Core::get_entity_ID(entity) == entityID){
            exists = true;
        };

        len=len-1;
    };

    move exists
}



fun convert_entityID_to_string(id: u8): String acquires Entity_Database{
    let entity_db_db = borrow_global_mut<Entity_Database>(OWNER);
    let len = vector::length(&entity_db_db.database);
    while (len>1){
        let entity = vector::borrow(&entity_db_db.database, len-1);
        if(Core::get_entity_ID(entity)== id){
            return Core::get_entity_name(entity)
        };
    };
    abort(1)
}



 #[test(account = @0x1, owner = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7)]
     public entry fun test(account: signer, owner: signer) acquires Entity_Database{
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

        //addType(&owner, utf8(b"Mob"),100);
        //addType(&owner, utf8(b"Titan"),300);
        //ddType(&owner, utf8(b"God"),1000);

        //addLocation(&owner, utf8(b"Expedition"),100);
        //addLocation(&owner, utf8(b"Dungeon"),150);
        
        //ntityID: u8, entityName: String, type: String, location: String
        addEntity(&owner, 1, utf8(b"Zombie"),utf8(b"Mob"), utf8(b"Expedition"));
        addEntity(&owner, 2, utf8(b"Bat"),utf8(b"Mob"), utf8(b"Expedition"));
        addEntity(&owner, 3, utf8(b"Fish"),utf8(b"Mob"), utf8(b"Dungeon"));
        addEntity(&owner, 4, utf8(b"Shark"),utf8(b"Titan"), utf8(b"Dungeon"));
        addEntity(&owner, 5, utf8(b"Wolf"),utf8(b"Titan"), utf8(b"Dungeon"));
        addEntity(&owner, 6, utf8(b"Snake"),utf8(b"Titan"), utf8(b"Dungeon"));
        addEntity(&owner, 7, utf8(b"Bee"),utf8(b"God"), utf8(b"Dungeon"));
        addEntity(&owner, 8, utf8(b"ga"),utf8(b"God"), utf8(b"Dungeon"));
        addEntity(&owner, 9, utf8(b"Girrafe"),utf8(b"God"), utf8(b"Dungeon"));
        addEntity(&owner, 10, utf8(b"Lion"),utf8(b"God"), utf8(b"Dungeon"));
        addEntity(&owner, 11, utf8(b"Bug"),utf8(b"God"), utf8(b"Dungeon"));
        addEntity(&owner, 12, utf8(b"Vampire"),utf8(b"God"), utf8(b"Dungeon"));
        print(&viewEntityTypes());
        print(&viewLocations());
        print(&viewEntities());
        print(&viewEntityByID(1));
        print(&viewEntityByName(utf8(b"Zombie")));
        print(&viewEntityConfig());
        print(&viewEntityStatsByName(1));
        print(&viewEntityStatsByName(5));
        print(&viewEntityStatsByName(6));
        print(&viewEntityStatsByName(7));
        //changeEntityStatsConfig(&owner, true,(vector[3u8, 1u8, 2u8]: vector<u8>),(vector[0u64, 1u64, 20u64]: vector<u64>));
        print(&viewEntityConfig());
        print(&viewEntitiesStats());
        print(&getMultipleEntitiesByIDs((vector[3u8, 5u8, 7u8]: vector<u8>)));
    }
}   
