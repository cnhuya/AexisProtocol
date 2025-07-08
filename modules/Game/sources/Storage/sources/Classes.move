module deployer::testClass10{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;
    use deployer::testCore31::{Self as Core, Ability, AbilityString, PassiveAbility,PassiveAbilityString};

    struct Class_Database has copy, store, drop ,key {database: vector<Class>}
    struct Class has copy,drop,store,key {classID: u8,  passives: vector<PassiveAbility>, actives: vector<Ability>}
    struct ClassString has copy,drop,store,key {className: String,  passives: vector<PassiveAbilityString>, actives: vector<AbilityString>}

    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_VAR_NOT_INNITIALIZED: u64 = 2;
    const ERROR_TX_DOESNT_EXISTS: u64 = 3;

    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

   fun init_module(address: &signer) {

        let deploy_addr = signer::address_of(address);

        if (!exists<Class_Database>(deploy_addr)) {
          move_to(address, Class_Database { database: vector::empty()});
        };

    }
public entry fun createClass(address: &signer, classID: u8, 
    passive_Name: vector<String>, passive_valueIDs: vector<vector<u8>>, passive_valueIsEnemies: vector<vector<bool>>, passive_valueValues: vector<vector<u8>>,passive_valueTimes: vector<vector<u64>>,
    active_Name: vector<String>,  active_Cooldown: vector<u8>, active_Stamina: vector<u8>, active_Damage: vector<u16>,active_valueIDs: vector<vector<u8>>, active_valueIsEnemies: vector<vector<bool>>, active_valueValues: vector<vector<u8>>) acquires Class_Database {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);
    let class_db = borrow_global_mut<Class_Database>(OWNER);
    let vect = vector::empty<Ability>();
        let passives = Core::make_multiple_PassiveAbilities(
             passive_Name, passive_valueIDs, passive_valueIsEnemies, passive_valueValues, passive_valueTimes
        );

        let actives = Core::make_multiple_Abilities(
             active_Name, active_Cooldown, active_Stamina, active_Damage, active_valueIDs, active_valueIsEnemies, active_valueValues
        );

        let _class = Class{
            classID: classID,
            passives: passives,
            actives: actives
        };
        vector::push_back(&mut class_db.database, _class);
}

public fun returnMe(address: &signer): vector<ClassString> acquires Class_Database {
    viewClasses()
}

//{classID: u8, className: String, abilities: vector<Ability_With_Strings>}
#[view]
public fun viewClass(classID: u8): ClassString acquires Class_Database {
    let class_db = borrow_global<Class_Database>(OWNER);
    let len = vector::length(&class_db.database);
    while(len>0){
        let class = vector::borrow(&class_db.database, len-1);
        if(class.classID == classID){
            let _class = ClassString {
                className: Core::convert_classID_to_String(classID),
                passives: Core::make_multiple_string_passiveAbilities(class.passives),
                actives: Core::make_multiple_string_bilities(class.actives),
            };
            return _class
        };
        print(&len);
        len=len-1;
    };
    abort(99)
}
#[view]
public fun viewClasses(): vector<ClassString> acquires Class_Database {
    let class_db = borrow_global<Class_Database>(OWNER);
    let len = vector::length(&class_db.database);
    let vect = vector::empty<ClassString>();
    while(len>0){
        let class = vector::borrow(&class_db.database, len-1);
        let _class = ClassString {
            className: Core::convert_classID_to_String(class.classID),
            passives: Core::make_multiple_string_passiveAbilities(class.passives),
            actives: Core::make_multiple_string_bilities(class.actives),
        };
        vector::push_back(&mut vect, _class);
        len=len-1;
    };
    move vect
}


#[view]
public fun viewClassesDB(): vector<Class> acquires Class_Database {
    let class_db = borrow_global<Class_Database>(OWNER);
    class_db.database
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
}

}   