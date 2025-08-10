module new_dev::testCraftingV21{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;

    //core
    use deployer::testCore45::{Self as Core, Stat, Material, Item, ItemString, Value, ValueString, MaterialString, Expedition };
    use deployer::testPlayerCore11::{Self as PlayerCore,DungeonPlayer,Crafting,CraftingString,StatPlayer, ExamineString, Examine, Oponent, ExpeditionPlayer, ExpeditionPlayerString};


     use new_dev::testItemsV7::{Self as Items};
    use deployer::testConstantV4::{Self as Constant};

    use deployer::randomv1::{Self as Random};

    use new_dev::testPlayerV30::{Self as Player};

// Structs

// Const
    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

// Errors
    const ERROR_NAME_TOO_LONG: u64 = 1;
    const ERROR_PLAYER_NAME_ALREADY_EXISTS: u64 = 2;
    const ERROR_RARITY_UPGRADE_TOO_HUGE: u64 = 3;
    const ERROR_NO_CRAFTING: u64 = 4;
    const ERROR_UPRAGE_ITEM_RARITY_CUSTOM_COST_OVERFLOW_COST: u64 = 5;
    const ERROR_CANT_DOWNGRADE_RARITY: u64 = 6;

// On Deploy Event
   fun init_module(address: &signer) {

    }


// Make


// Entry Functions

    public entry fun craftItem(address: &signer, name: String, typeID: u8, materialID: u8) {
        let addr = signer::address_of(address);
        let player = Player::find_player(addr, name);

        let item = Items::viewItem(typeID, materialID, 0);
        player = Player::change_player_materials_amount(addr, player, Core::degrade_multiple_materialsString(Items::get_item_crafting(&item)), false);

        let time = timestamp::now_seconds() + 60 + (materialID as u64) * 5;
        let crafting = PlayerCore::make_crafting(time, typeID, materialID);
        player = Player::add_player_crafting(player, crafting);

        Player::update_player(addr, name, player);
    }


public entry fun get_craftedItems(address: &signer, name: String) {
    let addr = signer::address_of(address);
    let player = Player::find_player(addr, name);

    let len = vector::length(&Player::get_player_crafting(&player));
    while (len > 0) {
        let index = len - 1;
        let craft = *vector::borrow(&Player::get_player_crafting(&player), index);

        if (PlayerCore::get_crafting_end(&craft) < timestamp::now_seconds()) {
            // Remove the crafting first

            // Now add the crafted item
            player = Player::addItem(
                address,
                name,
                PlayerCore::get_crafting_typeID(&craft),
                PlayerCore::get_crafting_materialID(&craft),
                0
            );
        };

        len = len - 1;
    };
    player = Player::remove_player_crafting(&mut player);
    Player::update_player(addr, name, player);
}


public entry fun upgrade_item_rarity(address: &signer, name: String, itemID: u64, rarity: u8, custom_cost: u64) {
    let addr = signer::address_of(address);
    let player = Player::find_player(addr, name);

    let item = Player::find_item(&player, itemID); // get mutable item if possible

    let current_rarity = Core::get_Item_rarityID(&item);
    assert!(current_rarity + rarity <= 6, ERROR_RARITY_UPGRADE_TOO_HUGE);
    assert!(current_rarity + rarity > current_rarity, ERROR_CANT_DOWNGRADE_RARITY);

    let cost = calculate_cost(Core::get_Item_materialID(&item), rarity, current_rarity);
    assert!(custom_cost <= (cost as u64), ERROR_UPRAGE_ITEM_RARITY_CUSTOM_COST_OVERFLOW_COST);

    let (level, _) = Player::viewHeroLevel(player);

    player = Player::change_player_materials_amount(
        addr,
        player,
        vector[Core::make_material(1, (cost as u32))],
        false
    );

    let rarity_stats = Core::get_Item_rarityStats(&item);
    if (chanceRarityUpgrade((custom_cost * 1000 / (cost as u64)))) {
        let new_rarity_stats = Items::rarity_simulation_test(2, level, Player::get_player_hash(&player));
        let i = vector::length(&new_rarity_stats);

        while (i > 0) {
            i = i - 1;
            let stat = *vector::borrow(&new_rarity_stats, i);
            vector::push_back(&mut rarity_stats, stat);
        };

        Core::change_Item_rarityStats(&mut item, rarity_stats);
        Core::change_Item_rarity(&mut item, current_rarity + rarity);

        //  Remove old item & add updated one
        player = Player::remove_player_item(player, item);
        player = Player::add_player_item(player, item);
    };

    Player::update_player(addr, name, player);
}


// View Functions


#[view]
    public fun calculate_cost(materialID: u8, rarity:u8, now_rarity: u8): u64{
        let cost = (materialID  + rarity + now_rarity) * 2;
        return (cost as u64)
    }

#[view]
    public fun predict_rarity_upgrade_chance(cost: u64, custom_cost: u64): u64 {
        let chance = ((custom_cost as u256) * 1000) / (cost as u256);
       // let success = chanceRarityUpgrade((chance as u64));
        return (chance as u64)
    }


#[view]
    public fun viewCrafting(address: address, name: String): vector<CraftingString> {
        let player = Player::find_player(address, name);
        let crafting = Player::get_player_crafting(&player);
        let len = vector::length(&crafting);
        let vect = vector::empty<CraftingString>();
        let crafting_string: CraftingString;
        while(len > 0){
            let craft = vector::borrow(&crafting, len-1);

            if(PlayerCore::get_crafting_end(craft) <= timestamp::now_seconds()){
                crafting_string = PlayerCore::make_crafting_string(craft, true);
            } else{
                crafting_string = PlayerCore::make_crafting_string(craft, false);
            };

            vector::push_back(&mut vect, crafting_string);
            len=len-1;
        };
        move vect
    }

// Util Functions
    fun chanceRarityUpgrade(chance: u64): bool {
        let value_array = Random::generateRangeArray((vector[1u32, 2u32, 3u32, 4u32, 5u32,6u32,7u32,8u32,9u32,10u32,11u32,12u32,13u32,14u32,15u32]: vector<u32>), 1, 1001,11);
        let value = vector::borrow(&value_array, chance % 7);
        // 974(value example) - 975(chance example)
        if (((*value) as u64) <= chance) {
            return true
        };
        return false
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

}}

