module deployer::testCrafting{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;
    use deployer::testCore31::{Self as Core, Stat, Material, Item, DungeonPlayer};
    use deployer::testStats::{Self as Stats};
    use deployer::testItems17::{Self as Items, UserItem};
    use deployer::testPlayerCore::{Self as PlayerCore,DungeonPlayer,Crafting,CraftingString};
    use deployer::testConstant::{Self as Constant};

    friend deployer::testCore31;

    use deployer::testPlayer as Player;

// Structs

// Const
    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

// Errors
    const ERROR_NAME_TOO_LONG: u64 = 1;
    const ERROR_PLAYER_NAME_ALREADY_EXISTS: u64 = 2;

// On Deploy Event
   fun init_module(address: &signer) {

    }


// Make


// Entry Functions

    public entry fun craftItem(address: &signer, name: String, typeID: u8, materialID: u8) acquires Player::PlayerDatabase {
        let player = Player::find_player(singer::address_of(address), name);
        let item = viewItem(typeID, materialID, 0);
        Player::change_player_materials_amount(singer::address_of(address), name, Core::degrade_multiple_materialsString(item.crafting), false);
        let time = timestamp::now_seconds() + 60 + materialID * 5;
        let crafting = PlayerCore::make_crafting(time, typeID, materialID);
        vector::push_back(&mut player.crafting, crafting);
    }


    public entry fun get_craftedItems(address: address, name: String) acquires Player::PlayerDatabase {
        let player = Player::find_player(address, name);
        let len = vector::length(&crafting);
        while(len > 0){
            let craft = vector::borrow(&player.crafting, len-1);
            if(PlayerCore::get_crafting_start(craft) > timestamp::now_seconds()){
                vector::remove(&mut player.crafting, len-1);
                let item = Items::viewFinalizedItem(Player::get_crafting_materialID(craft), player::get_crafting_typeID(craft), 0, Player::viewHeroLevel(address, player.name), player.hash)
                Player::addItemToPlayerInventory(item);
            };
            len=len-1;
        };
    }
// View Functions

#[view]
    public fun viewCrafting(address: address, name: String) vector<CraftingString> acquires Player::PlayerDatabase {
        let player = Player::find_player(address, name);
        let crafting = player.crafting;
        let len = vector::length(&crafting);
        let vect = vector::empty<CraftingString>();
        while(len > 0){
            let craft = vector::borrow(&crafting, len-1);

            if(PlayerCore::get_crafting_start(craft) > timestamp::now_seconds()){
                let crafting_string = PlayerCore::make_crafting_string(craft, true);
            } else{
                 let crafting_string = PlayerCore::make_crafting_string(craft, false);
            };

            vector::push_back(crafting_string);
            len=len-1;
        };
        move vect
    }


// Util Functions

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
}}}

