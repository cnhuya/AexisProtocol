module new_dev::testGemsV21{

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

    use deployer::randomv1::{Self as Random};

    use new_dev::testPlayerV30::{Self as Player};

// Structs

// Const
    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

// Errors
    const ERROR_EXAMINE_AMOUNT_TOO_LOW: u64 = 1;
    const ERROR_SPEED_TYPE_TOO_HIGH: u64 = 2;
    const ERROR_INVALID_EXAMINATION_TYPE: u64 = 3;
    const ERROR_AMOUNT_MUST_BE_MODULABLE_BY_10: u64 = 4;
    const ERROR_EXAMINE_AMOUNT_TOO_HIGH_PLEASE_CUT_CHUNKS_IN_SMALLER_AMOUNTS: u64 = 5;

// On Deploy Event
   fun init_module(address: &signer) {

    }


// Make


// Entry Functions

    public entry fun Gems(address: &signer, name: String, _amount: u32, type: u8, speed_type: u8){
        let addr = signer::address_of(address);
        assert!(_amount >= 50, ERROR_EXAMINE_AMOUNT_TOO_LOW);
        assert!(speed_type <= 3, ERROR_SPEED_TYPE_TOO_HIGH);
        assert!(type <= 3, ERROR_INVALID_EXAMINATION_TYPE);
        assert!((_amount % 10) == 0, ERROR_AMOUNT_MUST_BE_MODULABLE_BY_10);
        let time_reduction = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"),utf8(b"speed_type_time_reduction"))) as u64); // 5
        let cost_increase =  (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"),utf8(b"speed_type_cost_increase"))) as u32); // 4
        let cost =  (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"),utf8(b"base_cost"))) as u32); // 1
        let time_per_amount =  (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"),utf8(b"base_time"))) as u64); // 1
        let player = Player::find_player(signer::address_of(address), name);

        let amount = _amount / 10;
        assert!(amount <= 1000, ERROR_EXAMINE_AMOUNT_TOO_HIGH_PLEASE_CUT_CHUNKS_IN_SMALLER_AMOUNTS);
        let  vect = vector::empty<Material>();
        if (type == 1) {
            vect = vector[
                Core::make_material(1, ((_amount * cost) * (100+((speed_type as u32)*cost_increase)))/100),
                Core::make_material(4, _amount)
            ];
        } else if (type == 2) {
            vect = getGemDustCraftingMaterials(_amount);
        };

        player = Player::change_player_materials_amount(addr, player, vect, false);

        let time = (timestamp::now_seconds() + ((time_per_amount*(amount as u64)) * (100-((speed_type as u64)*time_reduction)))/100);
        let examine = PlayerCore::make_examine(time, (amount as u64), type, speed_type);
        player = Player::add_player_exam(player, examine);

        Player::update_player(addr, name, player);
    }

    public entry fun claimExaminations(address: &signer, name: String) {
        let addr = signer::address_of(address);

        // Step 1: Clone player
        let player = Player::find_player(signer::address_of(address), name);

        // Step 2: Iterate through player.examinations
        let i = vector::length(&Player::get_player_examinations(&player));
        let reward = vector::empty<Material>();
        while (i > 0) {
            let examine_ref = vector::borrow(&Player::get_player_examinations(&player), i - 1);
            if (PlayerCore::get_examine_start(examine_ref) < timestamp::now_seconds()) {
                let examine = *examine_ref;
                player = Player::remove_player_exam(player, examine);
                if(PlayerCore::get_examine_type(examine_ref) == 1){
                    reward = randomizeExaminationMaterials(
                        PlayerCore::get_examine_value(&examine),
                        Player::get_player_hash(&player)
                    );
                } else if(PlayerCore::get_examine_type(examine_ref) == 2){
                    let material = Core::make_material(14, (PlayerCore::get_examine_value(examine_ref)*75 as u32));
                    vector::push_back(&mut reward, material);
                };

                player = Player::change_player_materials_amount(addr, player, reward, true);
            };
            i = i - 1;
        };

        // Step 3: Write updated player back
        Player::update_player(addr, name, player);
    }
// View Functions

#[view]
    public fun viewExamine(address: address, name: String): vector<ExamineString> {
        let player = Player::find_player(address, name);
        let examinations = Player::get_player_examinations(&player);
        let len = vector::length(&examinations);
        let vect = vector::empty<ExamineString>();
        let crafting_string: ExamineString;
        while(len > 0){
            let examine = vector::borrow(&examinations, len-1);

            if(PlayerCore::get_examine_start(examine) > timestamp::now_seconds()){
                crafting_string = PlayerCore::make_examineString(examine, true);
            } else{
                crafting_string = PlayerCore::make_examineString(examine, false);
            };

            vector::push_back(&mut vect, crafting_string);
            len=len-1;
        };
        move vect
    }


// Util Functions
public fun randomizeExaminationMaterials(len: u64, hash: u64): vector<Material> {
    let vect = vector::empty<Material>();
    let materialID_array = Random::generateRangeArray(
        vector[1u32, 2u32, 3u32, 4u32, 5u32, 6u32, 7u32, 8u32, 9u32, 10u32, 11u32, 12u32, 13u32, 14u32, 15u32],
        1,
        1001,
        12
    );
    let pack:u32 = 1;
    if(len > 500){
        pack = 2;
    } else if (len > 1000){
        pack = 5;
    };
    let count = len;
    let array_len = vector::length(&materialID_array);

    let current_hash = hash;

    while (count > 0) {
        let index = (current_hash + count) % array_len; // 
        let value = *vector::borrow(&materialID_array, index);
        let hashed_value = (((value as u64) + current_hash) % 999) + 1;

        let stat = Core::make_material(chanceMaterials(hashed_value), 1*pack);
        current_hash = (current_hash + hashed_value) % 1_000_000; // 

        vector::push_back(&mut vect, stat);
        if(pack > (count as u32)){
            count = 0;
        } else{
            count = count - (pack as u64);
        };
    };

    vect
}


fun chanceMaterials(chance: u64): u8 {
    if (chance < (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"), utf8(b"stone_chance"))) as u64)) { 
        return 4 //100
    } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"), utf8(b"flint_chance"))) as u64)) {
        return 101 //375
    } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"), utf8(b"basalt_chance"))) as u64)) {
        return 102 //375
    } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"), utf8(b"copper_chance"))) as u64)) {
        return 103 //625
    } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"), utf8(b"iron_chance"))) as u64)) {
        return 104 //775
    } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"), utf8(b"diamond_chance"))) as u64)) {
        return 105 //875
    } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"), utf8(b"obsidian_chance"))) as u64)) {
        return 106 //925
    } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"), utf8(b"shungite_chance"))) as u64)) {
        return 107 //955
    } else {
        return 108
    }
}


    fun getGemDustCraftingMaterials(amount: u32): vector<Material> {

        let sand_increase =  (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"),utf8(b"gemdust_sand_increase"))) as u32);
        let gold_increase =  (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"),utf8(b"gemdust_gold_increase"))) as u32);
        let stone_increase =  (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"),utf8(b"gemdust_stone_increase"))) as u32);

        let sand = Core::make_material(5, (amount*sand_increase)/100);
        let gold = Core::make_material(1, (amount*gold_increase)/100);
        let stone  = Core::make_material(4, (amount*stone_increase)/100);

        vector[sand, gold, stone]
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
}}

