module deployer::testEntitiesV1{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;
    use deployer::testCore34::{Self as Core, Entity, Type, Stat, StatString, Location, Material, MaterialString };


    struct FullEntity has copy, drop {entity: Entity, stats: vector<StatString>}
    struct Entity_Database_With_String has copy {stats_config: vector<StatString>, database: vector<StatString>}
    struct Entity_Database has copy,drop,store,key {stats_config: vector<Stat>, database: vector<Entity>}
                           
    // expedition = 1x
    // dungeon = 1,5x
    struct Location_Database has copy,drop,store,key {database: vector<Location>}

    // mob = 1x
    // titan = 3x
    // god = 10x
    struct Type_Database has copy,drop,store,key {database: vector<Type>}


    #[event]
    struct LocationMultiChange has drop, store {address: address, locationName: String, isBuff: bool, from: u16, to: u16}

    #[event]
    struct EntityTypeMultiChange has drop, store {address: address, typeName: String, isBuff: bool, from: u16, to: u16}

    #[event]
    struct EntityStatsConfigChange has drop, store {address: address, isBuff: bool, old_config: vector<StatString>, new_config: vector<StatString>}


    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_ENTITY_TYPE_DOESNT_EXISTS: u64 = 2;
    const ERROR_LOCATION_DOESNT_EXISTS: u64 = 3;
    const ERROR_ENTITY_WITH_NAME_ALREADY_EXISTS: u64 = 4;
    const ERROR_ENTITY_WITH_ID_ALREADY_EXISTS: u64 = 5;

    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

   fun init_module(address: &signer) acquires Entity_Database, Location_Database, Type_Database{

        let deploy_addr = signer::address_of(address);

        if (!exists<Type_Database>(deploy_addr)) {
          move_to(address, Type_Database { database: vector::empty()});
        };

        if (!exists<Location_Database>(deploy_addr)) {
          move_to(address, Location_Database { database: vector::empty()});
        };

        if (!exists<Entity_Database>(deploy_addr)) {
          move_to(address, Entity_Database { stats_config: vector::empty(), database: vector::empty()});
        };

        registerEntityDatabase(address,(vector[1u8, 2u8, 3u8]: vector<u8>),(vector[200u64, 5u64, 1u64]: vector<u64>));
        addType(address, utf8(b"Mob"),1);
        addType(address, utf8(b"Titan"),2);
        addType(address, utf8(b"God"),5);

        addLocation(address, utf8(b"Expedition"),1);
        addLocation(address, utf8(b"Dungeon"),3);

    }

public entry fun changeEntityStatsConfig(address: &signer, isbuff: bool, stat_ids: vector<u8>, stat_values: vector<u64>) acquires Entity_Database {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);
    let entity_db = borrow_global_mut<Entity_Database>(OWNER);
    let old_config = entity_db.stats_config;
    entity_db.stats_config = Core::make_multiple_stats(stat_ids,stat_values);
    event::emit(EntityStatsConfigChange {
        address: signer::address_of(address),
        isBuff: isbuff,
        old_config: Core::build_stats_with_strings(old_config),
        new_config: Core::build_stats_with_strings(entity_db.stats_config),
    });
}
public entry fun changeEntityTypeMulti(address: &signer, typeName: String, new_multi: u16) acquires Type_Database {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);
    let isBuff = false;
    let type_db = borrow_global_mut<Type_Database>(OWNER);
    let len = vector::length(&type_db.database);
    while(len > 0){
        let type = vector::borrow_mut(&mut type_db.database, len-1);
        if(Core::get_type_name(type) == typeName){
            let from = Core::get_type_multi(type);
            Core::change_type_multi(type,new_multi);

            if(new_multi > from){
                isBuff = true
            };

                event::emit(EntityTypeMultiChange {
                    address: signer::address_of(address),
                    typeName: typeName,
                    isBuff: isBuff,
                    from: from,
                    to: new_multi,
                });

            len=len-1;
        };
    };
}
public entry fun changeLocationMulti(address: &signer, locationName: String, new_multi: u16) acquires Location_Database {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);
    let isBuff = false;
    let location_db = borrow_global_mut<Location_Database>(OWNER);
    let len = vector::length(&location_db.database);
    while(len > 0){
        let location = vector::borrow_mut(&mut location_db.database, len-1);
        if(Core::get_location_name(location) == locationName){
            let from = Core::get_location_multi(location);
            Core::changes_location_multi(location,new_multi);

            if(new_multi > from){
                isBuff = true
            };

                event::emit(LocationMultiChange {
                    address: signer::address_of(address),
                    locationName: locationName,
                    isBuff: isBuff,
                    from: from,
                    to: new_multi,
                });

            len=len-1;
        };
    };
}

public entry fun addType(address: &signer, name: String, stat_multi: u16) acquires Type_Database {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);
    assert!(entity_type_exists(name) == false, 1);
    let type_db = borrow_global_mut<Type_Database>(OWNER);

    let type = Core::make_type(name, stat_multi);
    vector::push_back(&mut type_db.database, type);
}

public entry fun addLocation(address: &signer, name: String, stat_multi: u16) acquires Location_Database, {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);
    assert!(location_exists(name) == false, 1);
    let location_db = borrow_global_mut<Location_Database>(OWNER);

    let type = Core::make_location(name, stat_multi);
    vector::push_back(&mut location_db.database, type);
}
public entry fun addEntity(address: &signer, entityID: u8, entityName: String, type: String, location: String) acquires Entity_Database, Type_Database, Location_Database {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);
    assert!(entity_type_exists(type) == true, ERROR_ENTITY_TYPE_DOESNT_EXISTS);
    assert!(location_exists(location) == true, ERROR_LOCATION_DOESNT_EXISTS);

    assert!(entity_exists_by_ID(entityID) == false, ERROR_ENTITY_WITH_ID_ALREADY_EXISTS);
    assert!(entity_exists_by_name(entityName) == false, ERROR_ENTITY_WITH_NAME_ALREADY_EXISTS);
    let entity_db = borrow_global_mut<Entity_Database>(OWNER);

    let entity = Core::make_entity(entityID,  entityName, type, location);
    vector::push_back(&mut entity_db.database, entity);
}

public entry fun registerEntityDatabase(address: &signer, stat_ids: vector<u8>, stat_values: vector<u64>) acquires Entity_Database {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);
    let entity_db = borrow_global_mut<Entity_Database>(OWNER);

    let len = vector::length(&entity_db.stats_config);

    assert!(len == 0, 999);

    entity_db.stats_config = Core::make_multiple_stats(stat_ids,stat_values);
    }


#[view]
public fun viewEntityTypes(): vector<Type> acquires Type_Database {
    let type_db = borrow_global<Type_Database>(OWNER);
    type_db.database
}


#[view]
public fun viewLocations(): vector<Location> acquires Location_Database {
    let type_db = borrow_global<Location_Database>(OWNER);
    type_db.database
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
public fun viewEntityConfig(): vector<StatString> acquires Entity_Database {
    let entity_db = borrow_global<Entity_Database>(OWNER);
    let vec = Core::build_stats_with_strings(entity_db.stats_config);
    move vec
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


//    struct Simulated_Stat_With_String has copy, key, store, drop {statID: u8, statName: String, value: u32}
#[view]
public fun viewEntityStatsByName(name: u8): FullEntity acquires Entity_Database,Location_Database,Type_Database {
    let entity_db = viewEntities();

    let len = vector::length(&entity_db);

    while(len > 0){
        let entity = vector::borrow(&entity_db, len-1);

        if(Core::get_entity_ID(entity) == name){

            let _entity = FullEntity {
                entity: *entity,
                stats: simulate_entity_stat(name),
            };
            return _entity
        };
        len=len-1;
    };
    abort(1)
}

#[view]
public fun viewEntitiesStats(): vector<FullEntity> acquires Entity_Database,Location_Database,Type_Database {
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

fun get_entityloc(entity: Entity): Location acquires Location_Database{
    let location_db = borrow_global<Location_Database>(OWNER);
    let len = vector::length(&location_db.database);
    while(len>0){
        let location = vector::borrow(&location_db.database, len-1);
        if(Core::get_location_name(location) == Core::get_entity_location(&entity)){
            return *location
        };
        len = len-1;
    };
    abort(1)
}

fun get_entitytype(entity: Entity): Type acquires Type_Database{
    let type_db = borrow_global<Type_Database>(OWNER);
    let len = vector::length(&type_db.database);
    while(len>0){
        let type = vector::borrow(&type_db.database, len-1);
        if(Core::get_type_name(type) == Core::get_entity_type(&entity)){
            return *type
        };
        len = len-1;
    };
    abort(1)
}



fun simulate_entity_stat(entityName: u8): vector<StatString> acquires Entity_Database, Type_Database, Location_Database {
    let entity = viewEntityByID(entityName);
    let location_multi = Core::get_location_multi(&get_entityloc(entity));
    let entity_type_multi = Core::get_type_multi(&get_entitytype(entity));
    let entityID = Core::get_entity_ID(&entity);
    let config = borrow_global<Entity_Database>(OWNER); // Immutable borrow now
    let len = vector::length(&config.stats_config);
    let vec = vector::empty<StatString>();
    let i = 0;
    while (i < len) {
        let stat = vector::borrow(&config.stats_config, i); // Immutable reference
        let stat_id = Core::get_stat_ID(stat);
        let stat_name = Core::convert_statID_to_String(stat_id); // Assuming this function exists
        let stat_val = Core::get_stat_value(stat);
        let new_val: u64;
    
        if (Core::convert_statID_to_String(stat_id) == utf8(b"Attack_Speed")) {
            new_val = 1;
        } else {
            let entityID_val = (entityID as u64);
            let growth_factor = ((entityID_val * entityID_val)) * 65 + 1000;
            new_val = stat_val * ((location_multi as u64) * (entity_type_multi as u64) * growth_factor) / 1500;
        };

        let _stat = Core::make_stat(stat_id, new_val); // Custom constructor
        let _stat_ = Core::make_string_stat(&_stat);
        vector::push_back(&mut vec, _stat_);
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

fun location_exists(locationName: String): bool acquires Location_Database {
    let type_db = viewLocations();
    let len = vector::length(&type_db);
    let exists = false;
    while(len > 0){
        let location = vector::borrow(&type_db, len-1);

        if(Core::get_location_name(location) == locationName){
            exists = true;
        };

        len=len-1;
    };

    move exists
}

fun entity_type_exists(entityName: String): bool acquires Type_Database {
    let type_db = viewEntityTypes();
    let len = vector::length(&type_db);
    let exists = false;
    while(len > 0){
        let type = vector::borrow(&type_db, len-1);

        if(Core::get_type_name(type) == entityName){
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
     public entry fun test(account: signer, owner: signer) acquires Type_Database,Location_Database,Entity_Database{
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