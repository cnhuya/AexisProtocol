module deployer::testClassV10{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;
    use deployer::testCore45::{Self as Core, Ability, AbilityString, Value};

    struct Ability_Database has copy, store, drop ,key {database: vector<Ability>}

    struct Class has copy,drop,store,key {classID: u8, spells: vector<Ability>}
    struct ClassString has copy,drop,store,key {className: String,  spells: vector<AbilityString>}

    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_VAR_NOT_INNITIALIZED: u64 = 2;
    const ERROR_TX_DOESNT_EXISTS: u64 = 3;

    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

   fun init_module(address: &signer) {

        let deploy_addr = signer::address_of(address);

        if (!exists<Ability_Database>(deploy_addr)) {
          move_to(address, Ability_Database { database: vector::empty()});
        };

    }
    public entry fun createAbilitiesForClass(address: &signer, abilityids: vector<u8> ,classID: u8, passive_Name: vector<String>, required_chakra: vector<u32>, passive_valueIDs: vector<vector<u8>>, passive_valueIsEnemies: vector<vector<bool>>, passive_valueValues: vector<vector<u16>>) acquires Ability_Database {
        let spell_db = borrow_global_mut<Ability_Database>(OWNER);
       
        let addr = signer::address_of(address);
        assert!(addr == OWNER, ERROR_NOT_OWNER);
        let len = vector::length(&passive_valueIDs);

        let abilities = Core::make_multiple_Abilities(abilityids,classID, passive_Name, required_chakra, passive_valueIDs, passive_valueIsEnemies, passive_valueValues);
        let len = vector::length(&abilities);

        while(len>0){
            let ability = vector::borrow(&abilities, len-1);
            vector::push_back(&mut spell_db.database, *ability);
            len=len-1;
        };
    }



    //{classID: u8, className: String, abilities: vector<Ability_With_Strings>}
    #[view]
    public fun viewClass(classID: u8): ClassString acquires Ability_Database {
        let ability_db = borrow_global<Ability_Database>(OWNER);
        let len = vector::length(&ability_db.database);
        let vect = vector::empty<Ability>();
        while(len>0){
            let ability = vector::borrow(&ability_db.database, len-1);
            if(Core::get_Ability_classID(ability) == classID){
                vector::push_back(&mut vect, *ability);
            };
            len=len-1;
        };

        let _class = ClassString {
            className: Core::convert_classID_to_String(classID),
            spells: Core::make_multiple_string_Abilities(vect),
        };
        return _class

    }

    #[view]
    public fun viewClassSpell(id: u8,): AbilityString acquires Ability_Database {
        let ability_db = borrow_global<Ability_Database>(OWNER);
        let len = vector::length(&ability_db.database);
        while(len>0){
            let ability = vector::borrow(&ability_db.database, len-1);
            if(Core::get_Ability_classID(ability) == id){
                return Core::make_string_Ability(ability)
            };
            len=len-1;
        };
        abort(99)
    }

    #[view]
    public fun viewClassSpell_raw(id: u8): Ability acquires Ability_Database {
        let ability_db = borrow_global<Ability_Database>(OWNER);
        let len = vector::length(&ability_db.database);
        while(len>0){
            let ability = vector::borrow(&ability_db.database, len-1);
            if(Core::get_Ability_abilityID(ability) == id){
                return *ability
            };
            len=len-1;
        };
        abort(99)
    }

    #[view]
    public fun viewClasses(): vector<ClassString> acquires Ability_Database {
        let vect = vector::empty<ClassString>();
        let max_classes = get_safe_class_count();
        while (max_classes > 0){
           let class = viewClass(max_classes);
           vector::push_back(&mut vect, class); 
           max_classes = max_classes - 1;
        };
        move vect
    }


    #[view]
    public fun viewAbilities(): vector<Ability> acquires Ability_Database {
        let ability_db = borrow_global<Ability_Database>(OWNER);
        ability_db.database
    }

    #[view]
    public fun get_safe_class_count(): u8 acquires Ability_Database {
        let abilities = viewAbilities();
        let len = vector::length(&abilities);

        let vect = vector::empty<u8>();
        while(len>0){
            let ability = vector::borrow(&abilities, len-1);
            let classID = Core::get_Ability_classID(ability);
            if(!vector::contains(&vect, &classID)){
                vector::push_back(&mut vect, classID);
            };
            len=len-1;
        };
        return (vector::length(&vect) as u8)
    }



#[test(account = @0x1, owner = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7)]
public entry fun test(account: signer, owner: signer) acquires Ability_Database {
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
    let passive_valueIDs = vector[1u32,5u32];
    let passive_valueIDs = vector[vector[1u8], vector[2u8]];
    let passive_valueIsEnemies = vector[vector[true], vector[false]];
    let passive_valueValues = vector[vector[10u8], vector[20u8]];


    createClass(
        &owner,
        1, // classID
        passive_name,
        passive_valueIDs,
        passive_valueIsEnemies,
        passive_valueValues,
    );

        createClass(
        &owner,
        2, // classID
        passive_name,
        passive_valueIDs,
        passive_valueIsEnemies,
        passive_valueValues,
    );
    print(&viewClass(1));
    print(&viewClass(2));
    print(&viewClasses());
}
}   
