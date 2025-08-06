module deployer::testMarketV20{

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

    use deployer::testConstantV4::{Self as Constant};
    use deployer::testPlayerV27::{Self as Player};

// Structs

// Const
    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

// Errors
    const ERROR_EXAMINE_AMOUNT_TOO_LOW: u64 = 1;

// On Deploy Event
   fun init_module(address: &signer) {

    }


// Make


// Entry Functions

    public entry fun Buy(address: &signer, name: String, materialID: u8, amount:u32) {
        assert!(amount > 5,ERROR_EXAMINE_AMOUNT_TOO_LOW);
        let player = Player::find_player(signer::address_of(address), name);
        let vect_cost = (vector[Core::make_material(1, amount*2)]: vector<Material>);
        let vect_receive = (vector[Core::make_material(materialID, amount)]: vector<Material>);

        player = Player::change_player_materials_amount(signer::address_of(address), player,vect_receive, true);
        player = Player::change_player_materials_amount(signer::address_of(address), player,vect_cost, false);

        Player::update_player(signer::address_of(address), name, player);

    }

    public entry fun Sell(address: &signer, name: String, materialID: u8, amount:u32) {
        assert!(amount > 5,ERROR_EXAMINE_AMOUNT_TOO_LOW);
        let player = Player::find_player(signer::address_of(address), name);

        let vect_receive = (vector[Core::make_material(1, amount*2)]: vector<Material>);
        let vect_cost = (vector[Core::make_material(materialID, amount)]: vector<Material>);

        player = Player::change_player_materials_amount(signer::address_of(address), player,vect_receive, true);
        player = Player::change_player_materials_amount(signer::address_of(address), player,vect_cost, false);

        Player::update_player(signer::address_of(address), name, player);
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

