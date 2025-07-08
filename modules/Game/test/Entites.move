module deployer::testEntities{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;
    use deployer::testCore9::{Self as Core, Entity, Type, Stat, StatString, Location, };


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
    struct FullEntity has copy, drop {entity: Entity, stats: vector<StatString>}
    struct Entity_Database_With_String has copy {config: vector<StatString>, database: vector<StatString>}
    struct Entity_Database has copy,drop,store,key {config: vector<Stat>, database: vector<Entity>}
                           
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
    const ERROR_VAR_NOT_INNITIALIZED: u64 = 2;
    const ERROR_TX_DOESNT_EXISTS: u64 = 3;

    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

   fun init_module(address: &signer) acquires Entity_Database{

        let deploy_addr = signer::address_of(address);

        if (!exists<Type_Database>(deploy_addr)) {
          move_to(address, Type_Database { database: vector::empty()});
        };

        if (!exists<Location_Database>(deploy_addr)) {
          move_to(address, Location_Database { database: vector::empty()});
        };

        if (!exists<Entity_Database>(deploy_addr)) {
          move_to(address, Entity_Database { config: vector::empty(), database: vector::empty()});
        };


        addStat(address, 1, 125);
        addStat(address, 2, 5);
        addStat(address, 3, 2);
        addStat(address, 4, 1);
        registerEntityDatabase(address);
    }


public entry fun changeEntityStatsConfig(address: &signer, isBuff: bool) acquires Entity_Database {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);
    let entity_db = borrow_global_mut<Entity_Database>(OWNER);
    let stat_list = Core::extract_stat_list(address);
    let old_config = entity_db.config;
    assert!(vector::length(&stat_list) == 4, 2);
    entity_db.config = stat_list;
    event::emit(EntityStatsConfigChange {
        address: signer::address_of(address),
        isBuff: isBuff,
        old_config: Core::build_stats_with_strings(old_config),
        new_config: Core::build_stats_with_strings(entity_db.config),
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
            Core::set_type_multi(type,new_multi);

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
            Core::set_location_multi(location,new_multi);

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
public entry fun addStat(address: &signer, statID: u8, value: u64){
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);
    Core::register_stat(address, statID, value);
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
    assert!(entity_type_exists(type) == true, 1);
    assert!(location_exists(location) == true, 1);

    assert!(entity_exists_by_ID(entityID) == false, 2);
    assert!(entity_exists_by_name(entityName) == false, 2);
    let entity_db = borrow_global_mut<Entity_Database>(OWNER);

    let entity = Core::make_entity(entityID, entityName, type, location);
    vector::push_back(&mut entity_db.database, entity);
}

public entry fun registerEntityDatabase(address: &signer) acquires Entity_Database {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);
    let entity_db = borrow_global_mut<Entity_Database>(OWNER);

    let len = vector::length(&entity_db.config);

    assert!(len == 0, 999);

    entity_db.config = Core::extract_stat_list(address);
    }

#[view]
public fun viewEntityTypes(): vector<Type> acquires Type_Database {
    let type_db = borrow_global<Type_Database>(OWNER);
    type_db.database
}


#[view]
public fun viewEntityTypeMulti(typeName: String): u16 acquires Type_Database {
    let type_db = viewEntityTypes();
    let len = vector::length(&type_db);
    assert!(entity_type_exists(typeName) == true,2);
    while(len > 0){
        let type = vector::borrow(&type_db,len-1);

        if(Core::get_type_name(type) == typeName){
            return Core::get_type_multi(type)
        };

        len=len-1;
    };
    abort(1)
}

#[view]
public fun viewLocations(): vector<Location> acquires Location_Database {
    let type_db = borrow_global<Location_Database>(OWNER);
    type_db.database
}

#[view]
public fun viewLocationMulti(locationName: String): u16 acquires Location_Database {
    let location_db = viewLocations();
    let len = vector::length(&location_db);
    assert!(location_exists(locationName) == true,2);
    while(len >0){
        let location = vector::borrow(&location_db,len-1);

        if(Core::get_location_name(location) == locationName){
            return Core::get_location_multi(location)
        };

         len=len-1;
    };
    abort(1)
}

#[view]
public fun viewEntities(): vector<Entity> acquires Entity_Database {
    let type_db = borrow_global<Entity_Database>(OWNER);
    type_db.database
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
    let len = vector::length(&entity_db.config);
    let vec = vector::empty<StatString>();
    while(len > 0){
        let stat = vector::borrow(&entity_db.config, len-1);

        vector::push_back(&mut vec, Core::make_string_stat(stat));

        len=len-1;
    };
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


fun simulate_entity_stat(entityName: u8): vector<StatString> acquires Entity_Database, Type_Database, Location_Database {
    let entity = viewEntityByID(entityName);
    let location_multi = viewLocationMulti(Core::get_entity_location(&entity));
    let entity_type_multi = viewEntityTypeMulti(Core::get_entity_type(&entity));

    let config = borrow_global_mut<Entity_Database>(OWNER); 
    let len = vector::length(&config.config);
    let vec = vector::empty<StatString>();
    let  i = 0;

    while (i < len) {
        let stat = vector::borrow_mut(&mut config.config, i);
        let _stat: StatString;

        if (convert_statID_to_String(Core::get_stat_ID(stat)) == utf8(b"Attack_Speed")) {
            _stat = Core::change_stat_value(stat, 1);
        } else {
            let stat_val = Core::get_stat_value(stat);
            _stat = Core::change_stat_value(
                stat,
                stat_val * ((location_multi as u64) * (entity_type_multi as u64)) / 100,
            );
        };

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


fun convert_valueID_to_String(valueID: u8): String {

        let valueName;

        if (valueID == 1) {
            valueName = utf8(b"fire");
        } else if (valueID == 2) {
            valueName = utf8(b"poison");
        } else if (valueID == 3) {
            valueName = utf8(b"ice");
        } else if (valueID == 4) {
            valueName = utf8(b"lightning");
        } else if (valueID == 5) {
            valueName = utf8(b"dark magic");
        } else if (valueID == 6) {
            valueName = utf8(b"water");
        } else if (valueID == 7) {
            valueName = utf8(b"curse");
        } else {
            valueName = utf8(b"unknown");
        };

        move valueName
    }

fun convert_statID_to_String(statID: u8): String {
    if (statID == 1) {
        utf8(b"Health")
    } else if (statID == 2) {
        utf8(b"Damage")
    } else if (statID == 3) {
        utf8(b"Armor")
    } else if (statID == 4) {
        utf8(b"Attack_Speed")
    } 
    else {
        utf8(b"Unknown")
    }
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

        addType(&owner, utf8(b"Mob"),100);
        addType(&owner, utf8(b"Titan"),300);
        addType(&owner, utf8(b"God"),1000);

        addLocation(&owner, utf8(b"Expedition"),100);
        addLocation(&owner, utf8(b"Dungeon"),150);
        
        //ntityID: u8, entityName: String, type: String, location: String
        addEntity(&owner, 1, utf8(b"Zombie"),utf8(b"Mob"), utf8(b"Expedition"));
        addEntity(&owner, 2, utf8(b"Skeleton"),utf8(b"Titan"), utf8(b"Dungeon"));
        addEntity(&owner, 3, utf8(b"Hades"),utf8(b"Titan"), utf8(b"Dungeon"));
        addEntity(&owner, 4, utf8(b"Zeus"),utf8(b"God"), utf8(b"Dungeon"));
        print(&viewEntityTypes());
        print(&viewLocations());
        print(&viewEntities());
        print(&viewEntityByID(1));
        print(&viewEntityByName(utf8(b"Hades")));
        print(&viewEntityConfig());
        print(&viewLocationMulti(utf8(b"Dungeon")));
        print(&viewEntityTypeMulti(utf8(b"Titan")));
        print(&viewEntityStatsByName(1));
        addStat(&owner, 1, 150);
        addStat(&owner, 2, 5);
        addStat(&owner, 3, 2);
        addStat(&owner, 4, 1);
        changeEntityStatsConfig(&owner, true);
        print(&viewEntityConfig());

    }
}   