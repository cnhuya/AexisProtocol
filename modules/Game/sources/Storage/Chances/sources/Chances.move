module deployer::testChancesV4{

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
    use deployer::testItemsV6::{Self as Items};

    //struct TreasureChance has copy,drop,store,key {rounds: u8, types: vector<u8>, items: vector<Item>, materials: vector<Material>}
    //struct TreasureChanceString has copy,drop,store,key {rounds: u8, types: vector<String>, items: vector<ItemString>, materials: vector<MaterialString>}


   // const ERROR_NOT_OWNER: u64 = 1;

    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

   fun init_module(address: &signer) {

    }


 #[view]
    public fun simulate_treasure(chance: u64, _hash: u128, level: u8): vector<MaterialString> {
      let materials = buildTreasureRandom(chance, _hash, level);
      let len = vector::length(&materials);
      let string_mats = Core::build_materials_with_strings(materials);
      string_mats
    }


    #[view]
    public fun buildTreasureRandom(chance: u64, _hash: u128, level: u8): vector<Material> {
        let original_rounds = chanceTreasure_rounds(chance);
        let rounds = original_rounds;
        // Mix initial hash with time and chance, make mutable
        let hash = (((_hash as u64) % 351487) + (timestamp::now_seconds() % 2574)) * chance;
        let vect = vector::empty<Material>();
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

            let treasure_type = chanceTreasure_type(hash);
            if(treasure_type != 0){
                let material = Core::make_material(1, (treasure_type as u32));
                vector::push_back(&mut vect, material);
            };
            rounds = rounds - 1;
        };
        vect
    }

    #[view]
    public fun buildTreasureRandom_items(chance: u64, _hash: u128, level: u8): vector<Item> {
        let original_rounds = chanceTreasure_rounds(chance);
        let rounds = original_rounds;

        let hash = (((_hash as u64) % 351487) + (timestamp::now_seconds() % 2574)) * chance;
        let items = vector::empty<Item>();
        let rounds_u64 = (rounds as u64); 
        while (rounds > 0) {
            let array = Random::generateRangeArray(vector[
                9u32, 21u32, 22u32, 1u32, 7u32, 3u32, 11u32, 15u32, 5u32, 7u32, 
                8u32, 13u32, 4u32, 3u32, 2u32, 1u32, 16u32, 33u32, 6u32, 18u32
            ], 1, 10001, 17);


            let index = (hash ^ rounds_u64) % vector::length(&array);
            let random_value = *vector::borrow(&array, index);

            hash = (((hash ^ (random_value as u64)) << 5) | ((hash ^ (random_value as u64)) >> 27)) % 1_989_247_113;

            hash = (hash + (chance + rounds_u64 + (random_value as u64))) % 90_002;

            let rarity_type = chanceTreasure_itemRarity((hash * (hash as u64)) % 10001);
            let itemMaterial_type = chanceItemMaterials(((hash * ((hash as u64)-(rarity_type as u64))) % 10001));
            let item = Items::viewFinalizedItem(((hash % 17) as u8), itemMaterial_type, rarity_type, level, hash);
            vector::push_back(&mut items, item);
            hash = hash + (itemMaterial_type as u64) + (rarity_type as u64)*2;
            rounds = rounds - 1;
            Items::add_count_item();
        };
        items
    }

   #[view]
    public fun buildTreasureRandom_materials(chance: u64, _hash: u128, level: u8): vector<Material> {
        let original_rounds = chanceTreasure_rounds(chance);
        let rounds = original_rounds+1;
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
            hash = (hash + (chance + rounds_u64 + (random_value as u64))) % 90_002;
            let material = chanceMaterials(((hash-1) * (chance*742)) % 10001, level, hash);
            vector::push_back(&mut materials, material);
            rounds = rounds - 1;
        };
        materials
    }

    #[view]
    public fun buildTreasureRandom_minerals(chance: u64, _hash: u128, level: u8): vector<Material> {
        let original_rounds = chanceTreasure_rounds(chance);
        let rounds = original_rounds+1;
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
            hash = (hash + (chance + rounds_u64 + (random_value as u64))) % 90_002;
            let material = chanceMinerals(((hash-1) * (chance*742)) % 10001, level, hash);
            vector::push_back(&mut materials, material);
            rounds = rounds - 1;
        };
        materials
    }

    fun chanceMaterials(chance: u64, _level: u8, hash: u64): Material {
        let level = (_level as u64);
        if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"xp_chance"))) as u64)) {
            return Core::make_material(0, (((hash % (level * 5)) + level * 10) as u32)) //2500
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"gold_chance"))) as u64)) {
            return Core::make_material(1, (((hash % (level * 5)) + level * 9) as u32)) //4500
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"wood_chance"))) as u64)) {
            return Core::make_material(3, (((hash % (level * 5)) + level * 8) as u32)) //6000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"stone_chance"))) as u64)) {
            return Core::make_material(4, (((hash % (level * 5)) + level * 7) as u32)) //7000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"sand_chance"))) as u64)) {
            return Core::make_material(5, (((hash % (level * 5)) + level * 6) as u32)) //7750
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"organic_chance"))) as u64)) {
            return Core::make_material(6, (((hash % (level * 5)) + level * 5) as u32)) //8500
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Player"), utf8(b"leather_chance"))) as u64)) {
            return Core::make_material(7, (((hash % (level * 5)) + level * 4) as u32)) //9250
        } else {
            return Core::make_material(17, (((hash % (level * 5)) + level * 3) as u32))
        }
    }

    fun chanceMinerals(chance: u64, _level: u8, hash: u64): Material {
        let level = (_level as u64);

        if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"minerals_flint_chance"))) as u64)) {
            return Core::make_material(101, (((hash % (level * 3)) + level * 7) as u32)) // 3000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"minerals_bones_chance"))) as u64)) {
            return Core::make_material(8, (((hash % (level * 3)) + level * 7) as u32)) // 5500
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"minerals_basalt_chance"))) as u64)) {
            return Core::make_material(102, (((hash % (level * 3)) + level * 6) as u32)) // 7500
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"minerals_copper_chance"))) as u64)) {
            return Core::make_material(103, (((hash % (level * 2)) + level * 5) as u32)) // 8750
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"minerals_iron_chance"))) as u64)) {
            return Core::make_material(104, (((hash % (level * 2)) + level * 5) as u32)) // 9400
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"minerals_diamond_chance"))) as u64)) {
            return Core::make_material(105, (((hash % (level * 1)) + level * 4) as u32)) // 9700
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"minerals_obsidian_chance"))) as u64)) {
            return Core::make_material(106, (((hash % (level * 1)) + level * 3) as u32)) // 9900
        } else {
            return Core::make_material(107, (((hash % (level * 1)) + level * 2) as u32)) // 9955+
        }
    }


    fun chanceItemMaterials(chance: u64): u8 {
        if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"item_organic_chance"))) as u64)) {
            return 6 //4000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"item_flint_chance"))) as u64)) {
            return 101 //6500
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"item_bones_chance"))) as u64)) {
            return 8 //7750
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"item_basalt_chance"))) as u64)) {
            return 102 //8500
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"item_copper_chance"))) as u64)) {
            return 103 //9200
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"item_iron_chance"))) as u64)) {
            return 104 //9600
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"item_diamond_chance"))) as u64)) {
            return 105 //9800
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"item_obsidian_chance"))) as u64)) {
            return 106 //9925
        } else {
            return 107 //955
        }
    }

    fun chanceTreasure_itemRarity(chance: u64): u8 {
        if (chance < (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"item_rarity_0_chance"))) as u64)) { 
            return 0 //5000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"item_rarity_1_chance"))) as u64)) {
            return 1 //7000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"item_rarity_2_chance"))) as u64)) {
            return 2 //8500
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"item_rarity_3_chance"))) as u64)) {
            return 3 //9250
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"item_rarity_4_chance"))) as u64)) {
            return 4 //9750
        } else {
            return 5
        }
    }


    fun chanceTreasure_type(chance: u64): u8 {
        if (chance < (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"treasure_typeChance_nothing"))) as u64)) { 
            return 0 //10000
        } else if (chance < (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"treasure_typeChance_items"))) as u64)) { 
            return 202 //12500
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"treasure_typeChance_materials"))) as u64)) {
            return 203 //30000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"treasure_typeChance_minerals"))) as u64)) {
            return 204 //50000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"treasure_typeChance_battlePassXP"))) as u64)) {
            return 205 //60000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"treasure_typeChance_supraToken"))) as u64)) {
            return 206 //70000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"treasure_typeChance_cosmetic"))) as u64)) { 
            return 207 //80000
        } else{
            return 0
        }
    }

    fun chanceTreasure_rounds(chance: u64): u8 {
        if (chance < (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"treasure_roundChance_6"))) as u64)) { 
            return 6 //1000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"treasure_roundChance_7"))) as u64)) {
            return 7 //3000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"treasure_roundChance_8"))) as u64)) {
            return 8 //6000
        } else if (chance <= (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Treasure"), utf8(b"treasure_roundChance_9"))) as u64)) {
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
