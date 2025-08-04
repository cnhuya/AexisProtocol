module deployer::testChancesV3{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;
    use deployer::testCore45::{Self as Core, Material, Item, ItemString, MaterialString };
    use deployer::randomv1::{Self as Random};
    use deployer::testConstantV4::{Self as Constant};
    use deployer::testItemsV5::{Self as Items};

    struct TreasureChance has copy,drop,store,key {rounds: u8, types: vector<u8>, items: vector<Item>, materials: vector<Material>}
    struct TreasureChanceString has copy,drop,store,key {rounds: u8, types: vector<String>, items: vector<ItemString>, materials: vector<MaterialString>}


   // const ERROR_NOT_OWNER: u64 = 1;

    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

   fun init_module(address: &signer) {

    }
    public fun make_treasureChance(rounds: u8, types: vector<u8>, items: vector<Item>, materials: vector<Material>): TreasureChance{
        TreasureChance {rounds:rounds, types: types, items: items, materials: materials}
    }

    public fun make_treasureChanceString(treasureChance: &TreasureChance): TreasureChanceString{
        TreasureChanceString {rounds:treasureChance.rounds, types: Core::build_treasureChance_with_strings_from_Ids(treasureChance.types), items: Core::make_multiple_string_items(treasureChance.items), materials: Core::build_materials_with_strings(treasureChance.materials)}
    }

    public fun get_treasureChance_items(treasure: &TreasureChance): vector<Item>{
        treasure.items
    }

    public fun get_treasureChance_materials(treasure: &TreasureChance): vector<Material>{
        treasure.materials
    }

        public fun get_treasureChance_rounds(treasure: &TreasureChance): u8{
        treasure.rounds
    }

        public fun get_treasureChance_types(treasure: &TreasureChance): vector<u8>{
        treasure.types
    }


    public fun build_Treasure_Strings(treasures: vector<TreasureChance>): vector<TreasureChanceString> {
        let vect = vector::empty<TreasureChanceString>();
        let len = vector::length(&treasures);
        while(len>0){
            let treasure = vector::borrow(&treasures, len-1);
            let treasure_string = make_treasureChanceString(treasure);
            vector::push_back(&mut vect, treasure_string);
            len=len-1;
        };

        vect
    }

    #[view]
    public fun simulate_Treasure(chance: u64, _hash: u128, level: u8): TreasureChanceString {
        let treasurechancestring = buildTreasureRandom(chance, _hash, level);
        let str = make_treasureChanceString(&treasurechancestring);
        str
    }

    #[view]
    public fun buildTreasureRandom(chance: u64, _hash: u128, level: u8): TreasureChance {
        let original_rounds = chanceTreasure_rounds(chance);
        let rounds = original_rounds;
        // Mix initial hash with time and chance, make mutable
        let hash = (((_hash as u64) % 351487) + (timestamp::now_seconds() % 2574)) * chance;
        let types = vector::empty<u8>();
        let items = vector::empty<Item>();
        let materials = vector::empty<Material>();
        let rounds_u64 = (rounds as u64); 
        while (rounds > 0) {
            let array = Random::generateRangeArray(vector[
                9u32, 21u32, 22u32, 1u32, 7u32, 3u32, 11u32, 15u32, 5u32, 7u32, 
                8u32, 13u32, 4u32, 3u32, 2u32, 1u32, 16u32, 33u32, 6u32, 18u32
            ], 1, 10001, 17);

            // Use more complex index calculation with hash and rounds
            let index = (hash ^ rounds_u64) % vector::length(&array);
            let random_value = *vector::borrow(&array, index);

            // Update hash with bitwise mixing and larger modulus
            hash = (((hash ^ (random_value as u64)) << 5) | ((hash ^ (random_value as u64)) >> 27)) % 1_989_247_113;

            // Slightly randomize with chance and rounds again
            hash = (hash + (chance + rounds_u64 + (random_value as u64))) % 100_002;
// viewFinalizedItem(typeID: u8, materialID: u8, rarityID: u8, user_level: u8, hash:u64)
            let treasure_type = chanceTreasure_type(hash);
            if(treasure_type == 5 || treasure_type == 6 || treasure_type == 7 || treasure_type == 8 || treasure_type == 9|| treasure_type == 10 || treasure_type == 11 || treasure_type == 12){
                random_value = *vector::borrow(&array, (treasure_type as u64));
                let rarity_type = chanceTreasure_itemRarity((hash * (random_value as u64)) % 10001);
                let itemMaterial_type = chanceItemMaterials(((hash * ((random_value as u64)-(rarity_type as u64))) % 999));
                let item = Items::viewFinalizedItem(treasure_type, itemMaterial_type, rarity_type, level, hash);
                vector::push_back(&mut items, item);
            } else if (treasure_type == 1){
                let material = chanceMaterials(((hash-1) * (chance*742)) % 10001, level, hash);
                vector::push_back(&mut materials, material);
            };

            vector::push_back(&mut types, treasure_type);
            rounds = rounds - 1;
        };

        make_treasureChance(original_rounds, types, items ,materials)
    }
    fun chanceMaterials(chance: u64, _level: u8, hash: u64): Material {
        let level = (_level as u64);
        if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"xp_chance"))) as u64)) {
            return Core::make_material(0, (((hash % (level * 5)) + level * 25) as u32)) //2500
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"gold_chance"))) as u64)) {
            return Core::make_material(1, (((hash % (level * 5)) + level * 20) as u32)) //4500
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"wood_chance"))) as u64)) {
            return Core::make_material(3, (((hash % (level * 5)) + level * 15) as u32)) //6000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"stone_chance"))) as u64)) {
            return Core::make_material(4, (((hash % (level * 5)) + level * 7) as u32)) //7000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"sand_chance"))) as u64)) {
            return Core::make_material(5, (((hash % (level * 5)) + level * 5) as u32)) //7750
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"organic_chance"))) as u64)) {
            return Core::make_material(6, (((hash % (level * 5)) + level * 4) as u32)) //8500
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"leather_chance"))) as u64)) {
            return Core::make_material(7, (((hash % (level * 5)) + level * 3) as u32)) //9250
        } else {
            return Core::make_material(17, (((hash % (level * 2)) + level * 1) as u32))
        }
    }

    fun chanceItemMaterials(chance: u64): u8 {
        if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"), utf8(b"basalt_chance"))) as u64)) {
            return 8 //375
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"), utf8(b"copper_chance"))) as u64)) {
            return 9 //625
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"), utf8(b"iron_chance"))) as u64)) {
            return 11 //775
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"), utf8(b"diamond_chance"))) as u64)) {
            return 12 //875
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"), utf8(b"obsidian_chance"))) as u64)) {
            return 13 //925
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Gems"), utf8(b"shungite_chance"))) as u64)) {
            return 14 //955
        } else {
            return 15
        }
    }

    fun chanceTreasure_itemRarity(chance: u64): u8 {
        if (chance < (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_rarityChance_0"))) as u64)) { 
            return 0 //5000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_rarityChance_1"))) as u64)) {
            return 1 //7000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_rarityChance_2"))) as u64)) {
            return 2 //8500
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_rarityChance_3"))) as u64)) {
            return 3 //9250
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_rarityChance_4"))) as u64)) {
            return 4 //9750
        } else {
            return 5
        }
    }

    fun chanceTreasure_type(chance: u64): u8 {
        if (chance < (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_typeChance_nothing"))) as u64)) { 
            return 0 //5000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_typeChance_material"))) as u64)) {
            return 1 //32500
        // TO DO
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_typeChance_cosmetic"))) as u64)) {
            return 2 //37500
        // TO DO
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_typeChance_supraToken"))) as u64)) {
            return 3 //42500
        // TO DO
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_typeChance_battlePassXP"))) as u64)) {
            return 4 //47500
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_typeChance_itemOrganic"))) as u64)) { 
            return 5 //70000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_typeChance_itemBasalt"))) as u64)) {
            return 6 //85000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_typeChance_itemCopper"))) as u64)) {
            return 7 //92500
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_typeChance_itemIron"))) as u64)) {
            return 8 //96000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_typeChance_itemDiamond"))) as u64)) {
            return 9 //98000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_typeChance_itemObsidian"))) as u64)) {
            return 10 //99000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_typeChance_itemShungite"))) as u64)) {
            return 11 //99500
        } else {
            return 12
        }
    }

    fun chanceTreasure_rounds(chance: u64): u8 {
        if (chance < (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_roundChance_6"))) as u64)) { 
            return 6 //1000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_roundChance_7"))) as u64)) {
            return 7 //3000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_roundChance_8"))) as u64)) {
            return 8 //6000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"treasure_roundChance_9"))) as u64)) {
            return 9 //9000
        } else {
            return 10
        }
    }


 #[test(account = @0x1, owner = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7)]
     public entry fun test(account: signer, owner: signer) acquires Race_Database{
        print(&utf8(b" ACCOUNT ADDRESS "));
        print(&account);


        print(&utf8(b" OWNER ADDRESS "));
        print(&owner);


        let source_addr = signer::address_of(&account);
        
        init_module(&owner);

    }
}   
