module deployer::testItemsV3{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;
    use dev::randomv1;
    use deployer::testCore43::{Self as Core, Material, MaterialString, Stat, StatString, StatRange, StatRangeString, Rarity, RarityString, Item, ItemString };

    struct Simulated_Item has copy, drop{typeID: u8, typeName: String, crafting_multi: u8, materialID: u8, materialName: String, rarityID: u8, rarityName: String, rarity_bonus_stats: vector<StatString>, stats: vector<StatString>}
    struct FullItem has copy, drop {typeID: u8, typeName: String, crafting_multi: u8, materialID: u8, materialName: String, rarityID: u8, rarityName: String,  stats: vector<StatRangeString>, crafting: vector<MaterialString>}

    struct DisplayItem has copy, drop {typeName: String, materialName: String, stats: vector<StatRangeString>, crafting: vector<MaterialString>}

    // 1 = 0,01%
    // 10000 = 100%
    struct Rarity_Config_With_String has copy,store,drop,key {config: vector<RarityString>, number_precision: u8 }
    struct Rarity_Config has copy,store,drop,key {config: vector<Rarity>, number_precision: u8 }

    struct Item_Material_Config has copy, store, drop, key {config: vector<Item_Material>}
    
    // Obsidian Item = crafting costs 100 gold, 10 obsidian, 1 shungite
    struct Item_Material has copy, drop, store, key {materialID: u8, bonus_stats: u16, crafting: vector<Material>}
    struct Item_Material_With_String has copy, drop, store, key {materialID: u8, materialName:String, bonus_stats: u16, crafting: vector<MaterialString>}


    struct Item_Type_Config has copy, store, drop, key {config: vector<Item_Type>}
    // Helmet : health = 20, armor = 1
    struct Item_Type has copy, drop, store, key {typeID: u8, crafting_multi: u8, stats: vector<StatRange>}
    struct Item_Type_With_String has copy, drop, store, key {typeID: u8, typeName: String, crafting_multi: u8, stats: vector<StatRangeString>}




    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_VAR_NOT_INNITIALIZED: u64 = 2;
    const ERROR_TX_DOESNT_EXISTS: u64 = 3;

    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

   fun init_module(address: &signer) acquires Rarity_Config {

        let deploy_addr = signer::address_of(address);
        
        if (!exists<Item_Type_Config>(deploy_addr)) {
          move_to(address, Item_Type_Config { config: vector::empty()});
        };
        if (!exists<Item_Material_Config>(deploy_addr)) {
          move_to(address, Item_Material_Config { config: vector::empty()});
        };
        if (!exists<Rarity_Config>(deploy_addr)) {
          move_to(address, Rarity_Config { config: vector::empty(),number_precision: 5});
        };
    addMultipleRaritiesToConfig(address,(vector[1u8, 2u8, 3u8, 4u8, 5u8]: vector<u8>),(vector[30u8, 25u8, 20u8, 15u8, 10u8]: vector<u8>),(vector[110u16, 120u16, 130u16,140u16,150u16]: vector<u16>) );
    }

public entry fun addItemTypeToConfig(address: &signer, typeIDs: u8, crafting_multies: u8, stat_ids: vector<u8>, stat_mins: vector<u64>, stat_maxs: vector<u64>) acquires Item_Type_Config {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);
    assert!(vector::length(&stat_mins) == vector::length(&stat_maxs),100);
    let item_type_config = borrow_global_mut<Item_Type_Config>(OWNER);
    let vect = vector::empty<Item_Type>();
    let item_type = Item_Type{
        typeID: typeIDs,
        crafting_multi: crafting_multies,
        stats: Core::make_multiple_range_stats(stat_ids,stat_mins,stat_maxs),
    };
    vector::push_back(&mut item_type_config.config, item_type);
}
public entry fun addMultipleItemTypesToConfig(address: &signer, typeIDs: vector<u8>, crafting_multies: vector<u8>, stat_ids: vector<vector<u8>>, stat_mins: vector<vector<u64>>, stat_maxs: vector<vector<u64>>) acquires Item_Type_Config {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);
    assert!(vector::length(&typeIDs) == vector::length(&crafting_multies),100);
    let vect = vector::empty<Item_Type>();
    let len = vector::length(&typeIDs);
    while(len > 0){
        let item_type = Item_Type{
            typeID: *vector::borrow(&typeIDs, len-1),
            crafting_multi: *vector::borrow(&crafting_multies, len-1),
            stats: Core::make_multiple_range_stats(*vector::borrow(&stat_ids,len-1), *vector::borrow(&stat_mins,len-1), *vector::borrow(&stat_maxs,len-1)),
        };
        vector::push_back(&mut vect, item_type);
        len=len-1;
    };
    let item_type_config = borrow_global_mut<Item_Type_Config>(OWNER);
    item_type_config.config = vect;
}

public entry fun addMultipleRaritiesToConfig(address: &signer, rarityIDs: vector<u8>,chances:vector<u8>, multies: vector<u16>) acquires Rarity_Config {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);
    let rarity_config = borrow_global_mut<Rarity_Config>(OWNER);
    let rarities = Core::make_multiple_rarities(rarityIDs, chances, multies);
    rarity_config.config = rarities;
}

public entry fun addItemMaterialTypeToConfig(address: &signer, materialID: u8, stats_multi: u16, material_ids: vector<u8>, material_amounts: vector<u32>) acquires Item_Material_Config {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);
    let item_material_config = borrow_global_mut<Item_Material_Config>(OWNER);
    let item_material = Item_Material{
        materialID: materialID,
        bonus_stats: stats_multi,
        crafting: Core::make_multiple_materials(material_ids, material_amounts),
    };
    vector::push_back(&mut item_material_config.config, item_material);
}

//  struct Item_Material has copy, drop, store, key {materialID: u8, bonus_stats: u16, crafting: vector<Material>}
public entry fun addMultipleItemMaterialTypesToConfig(address: &signer, materialID: vector<u8>, bonus_stats: vector<u16>, material_ids: vector<vector<u8>>, material_amounts: vector<vector<u32>>) acquires Item_Material_Config {
    let addr = signer::address_of(address);
    assert!(addr == OWNER, ERROR_NOT_OWNER);
    assert!(vector::length(&materialID) == vector::length(&bonus_stats),100);
    let vect = vector::empty<Item_Material>();
    let len = vector::length(&materialID);
    while(len > 0){
        let item_material = Item_Material{
            materialID: *vector::borrow(&materialID, len-1),
            bonus_stats: *vector::borrow(&bonus_stats, len-1),
            crafting: Core::make_multiple_materials(*vector::borrow(&material_ids,len-1), *vector::borrow(&material_amounts,len-1)),
        };
        vector::push_back(&mut vect, item_material);
        len=len-1;
    };
    let item_material_config = borrow_global_mut<Item_Material_Config>(OWNER);
    item_material_config.config = vect;
}

// View Functions
    #[view]
    public fun viewRarityStatIncrease(rarityID: u8): u16 acquires Rarity_Config {
        let rarity_config = borrow_global<Rarity_Config>(OWNER);
        let len = vector::length(&rarity_config.config);

        while(len > 0){
            let rarity = vector::borrow(&rarity_config.config, len-1);

            if(Core::get_rarity_id(*rarity)== rarityID){
                return Core::get_rarity_multi(*rarity)
            };
            len = len-1;
        };
        abort(1)
    }
    // config: vector<Rarity_With_String>, stats_range: vector<Stat_With_String>, number_precision: u8
    #[view]
    public fun viewRarityConfig(): Rarity_Config_With_String acquires Rarity_Config {
        let rarity_config = borrow_global<Rarity_Config>(OWNER);
        let _rarity_config_with_string = Rarity_Config_With_String{
            config: Core::build_rarity_with_strings(rarity_config.config),
            number_precision: rarity_config.number_precision,
        };
        move _rarity_config_with_string  
    }

    #[view]
    public fun viewItemsConfig(): vector<Item_Type_With_String> acquires Item_Type_Config {
        let item_list = borrow_global<Item_Type_Config>(OWNER);
        let len = vector::length(&item_list.config);

        let vect =  vector::empty<Item_Type_With_String>();
        while (len > 0){
            let item_material = vector::borrow(&item_list.config, len-1);

            let _item_material = Item_Type_With_String{
                typeID: item_material.typeID, 
                typeName: Core::convert_typeID_to_String(item_material.typeID),
                crafting_multi: item_material.crafting_multi,
                stats: Core::build_statsRange_with_strings(item_material.stats),
            };
            vector::push_back(&mut vect, _item_material);
            len = len -1;
        };
        move vect
    }

    //materialID: u8, materialName:String, bonus_stats: u16, crafting: vector<Material>}
    #[view]
    public fun viewItemsMaterialConfig(): vector<Item_Material_With_String> acquires Item_Material_Config {
        let item_list = borrow_global<Item_Material_Config>(OWNER);
        let len = vector::length(&item_list.config);

        let vect =  vector::empty<Item_Material_With_String>();
        while (len > 0){
            let item_material = vector::borrow(&item_list.config, len-1);

            let _item_material = Item_Material_With_String{
                materialID: item_material.materialID, 
                materialName: Core::convert_materialID_to_String(item_material.materialID),
                bonus_stats: item_material.bonus_stats,
                crafting: Core::build_materials_with_strings(item_material.crafting),
            };
            vector::push_back(&mut vect, _item_material);
            len = len -1;
        };
        move vect
    }

    #[view]
    public fun viewItemMaterialConfigById(materialID: u8): Item_Material_With_String acquires Item_Material_Config {
        let item_list = borrow_global<Item_Material_Config>(OWNER);
        let len = vector::length(&item_list.config);

        while (len > 0){
            let item_material = vector::borrow(&item_list.config, len-1);
            if(item_material.materialID == materialID){

                let _item_material = Item_Material_With_String{
                    materialID: item_material.materialID,
                    materialName: Core::convert_materialID_to_String(item_material.materialID),
                    bonus_stats: item_material.bonus_stats,
                    crafting: Core::build_materials_with_strings(item_material.crafting),
                };
                return _item_material
            };
            len = len -1;
        };
         abort(1)
    }

    #[view]
    public fun viewItemTypeConfigById(typeID: u8): Item_Type_With_String acquires Item_Type_Config {
        let item_list = borrow_global<Item_Type_Config>(OWNER);
        let len = vector::length(&item_list.config);

        while (len > 0){
            let item_material = vector::borrow(&item_list.config, len-1);
            if(item_material.typeID == typeID){

                let _item_material = Item_Type_With_String{
                    typeID: item_material.typeID,
                    typeName: Core::convert_materialID_to_String(item_material.typeID),
                    crafting_multi: item_material.crafting_multi,
                    stats: Core::build_statsRange_with_strings(item_material.stats),
                };
                return _item_material
            };
            len = len -1;
        };
         abort(1)
    }
    #[view]
    public fun viewItem(typeID: u8, materialID: u8, rarityID: u8): FullItem acquires Item_Type_Config, Item_Material_Config {
        let item_list = borrow_global<Item_Type_Config>(OWNER);
        
        let stats = viewItemTypeConfigById(typeID);
        let crafting = viewItemMaterialConfigById(materialID);

        let _item = FullItem{
            typeID: typeID,
            typeName: Core::convert_typeID_to_String(typeID),
            crafting_multi: stats.crafting_multi,
            materialID: materialID,
            materialName: Core::convert_materialID_to_String(materialID),
            rarityID: rarityID,
            rarityName: Core::convert_rarityID_to_String(rarityID),
            stats: multiply_stats(crafting.bonus_stats, stats.stats),
            crafting: multiply_crafting_costs(stats.crafting_multi,crafting.crafting),
        };

        move _item
    }



    #[view]
    public fun viewFinalizedItem(typeID: u8, materialID: u8, rarityID: u8, user_level: u8, hash:u64): Item acquires Item_Type_Config, Item_Material_Config, Rarity_Config {
        let fake_item = viewItem(typeID, materialID, rarityID);
        
         Core::make_Item(typeID,materialID,rarityID,rarity_simulation_test(rarityID, user_level, hash),item_simulation_test(fake_item.stats, user_level, hash))
         }

    #[view]
    public fun viewItemSet(materialID: u8, rarityID: u8): vector<DisplayItem> acquires Item_Type_Config, Item_Material_Config {
        
        let item_count = 16;
        let vect = vector::empty<DisplayItem>();
        while(item_count>0){
            let fake_item = viewItem(item_count, materialID, rarityID);
            let item = DisplayItem{
                typeName: Core::convert_typeID_to_String(item_count),
                materialName: Core::convert_materialID_to_String(materialID),
                stats: fake_item.stats,
                crafting: fake_item.crafting,
            };
            vector::push_back(&mut vect, item);
            item_count=item_count-1;
        };
        move vect
    }



// Utils
    public fun item_simulation_test(stats: vector<StatRangeString>, user_level: u8, hash: u64): vector<Stat> {
        let vect = vector::empty<Stat>();
        let adjusted_user_level = user_level + 1;

        let stat_count = vector::length(&stats);
        let value_array = randomv1::generateRangeArray(
            (vector[1u32, 2u32, 3u32, 4u32, 5u32, 6u32, 7u32, 8u32, 9u32, 10u32, 11u32, 12u32, 13u32, 14u32, 15u32]: vector<u32>),
            1, 1000, // broad min/max
            15
        );

        let  i = 0;
        while (i < stat_count) {
            let stat_str = vector::borrow(&stats, i);
            let degraded_stat = Core::degrade_string_statRange_to_statRange(stat_str);

            let min = Core::get_statRange_min(&degraded_stat);
            let max = Core::get_statRange_max(&degraded_stat);

            let range = if (max > min) { max - min } else { 1 };
            let rand_index = i % vector::length(&value_array);
            let value = *(vector::borrow(&value_array, rand_index));

            let hashed_value = (((value as u64) + hash) % range) + min;

            //let final_value = hashed_value / 6; // This is arbitrary scaling; adjust as needed
            let stat = Core::make_stat(Core::get_statRange_ID(&degraded_stat), hashed_value);

            vector::push_back(&mut vect, stat);

            hash = (hash + hashed_value) * (adjusted_user_level as u64);
            i = i + 1;
        };

        move vect
    }

    public fun rarity_simulation_test(rarityID: u8, user_level: u8, hash: u64): vector<Stat> acquires Rarity_Config {
        let vect = vector::empty<Stat>();
        let increase = viewRarityStatIncrease(rarityID);
        // needs to be here otherwise it returns vector error if its 1??;
        user_level = user_level+1;
        print(&utf8(b" OWNER ADDRESS "));
        let statID_array = randomv1::generateRangeArray((vector[1u32, 2u32, 3u32, 4u32, 5u32,6u32,7u32,8u32,9u32,10u32,11u32,12u32,13u32,14u32,15u32]: vector<u32>), 101, 499, 11);
        while (rarityID > 0){
            let statID = *(vector::borrow(&statID_array,(rarityID as u64)))/100;
            let min = 25+((user_level as u64)*3)+((increase as u64)*5);
            let max = 35+(((user_level as u64))*4)+((increase as u64)*6);
            let value_array = randomv1::generateRangeArray((vector[1u32, 2u32, 3u32, 4u32, 5u32,6u32,7u32,8u32,9u32,10u32,11u32,12u32,13u32,14u32,15u32]: vector<u32>), min, max,11);
            let value = *(vector::borrow(&value_array,(rarityID as u64)));
            let hashed_stat_id = ((statID as u64) + hash) % 4;
            let range = max - min;
            let hashed_value = (((value as u64)+ hash) % range) + min;
            let stat = Core::make_stat((hashed_stat_id as u8)+1,(hashed_value as u64)/6);
            hash = (hash + hashed_value) * ((user_level as u64) + ((rarityID as u64)));
            vector::push_back(&mut vect, stat);
            rarityID = rarityID-1;
        };
        move vect
    }

    public fun get_rarity_chance(id: u8): u8 acquires Rarity_Config{
        let rarity_config = borrow_global<Rarity_Config>(OWNER);
        let len = vector::length(&rarity_config.config);
        while(len > 0){
            let rarity = vector::borrow(&rarity_config.config, len-1);
            if(Core::get_rarity_id(*rarity) == id){
                return Core::get_rarity_chance(*rarity)
            };
        };
        abort(999)
    }

    public fun generateRandomRarity(hash: u64): u8 acquires Rarity_Config {
        let rarity_config = borrow_global<Rarity_Config>(OWNER);
        let rarityID: u8 = 0;
        



        // Assumes increasing rarity levels: 1 (most common) to 5 (rarest)
        let c1 = get_rarity_chance(1); // e.g. 40
        let c2 = get_rarity_chance(2); // e.g. 30
        let c3 = get_rarity_chance(3); // e.g. 20
        let c4 = get_rarity_chance(4); // e.g. 8
        let c5 = get_rarity_chance(5); // e.g. 2

        // Build cumulative probability ranges
        let r1_max = c1;
        let r2_max = r1_max + c2;
        let r3_max = r2_max + c3;
        let r4_max = r3_max + c4;
        let r5_max = r4_max + c5+1; // should be 100 ideally

        let rand: u8 = (randomv1::extremeRandomNumber((vector[1u32, 2u32, 3u32, 4u32, 5u32,6u32,7u32,8u32,9u32,10u32,11u32,12u32,13u32,14u32,15u32]: vector<u32>), (r5_max as u64)) as u8);
        hash = hash + (rand as u64);
        let x = (((rand as u64)*12) + hash) % (r5_max as u64);
        rand = (rand + (x as u8))/2;
        if (rand < r1_max) {
            rarityID = 1;
        } else if (rand < r2_max) {
            rarityID = 2;
        } else if (rand < r3_max) {
            rarityID = 3;
        } else if (rand < r4_max) {
            rarityID = 4;
        } else {
            rarityID = 5;
        };

        move rarityID
    }

    fun multiply_crafting_costs(multi: u8, crafting: vector<MaterialString>): vector<MaterialString> {
        let len = vector::length(&crafting);
        let vec = vector::empty<MaterialString>();

        let i = 0;
        while (i < len) {
            let material = vector::borrow(&crafting, i);
            let degraded_material = Core::degrade_string_materialString_to_material(material);
            let amount = Core::get_material_amount(&degraded_material);
            Core::change_material_amount(&mut degraded_material, amount * (multi as u32));
            let new_material = Core::make_material_string(&degraded_material);
            vector::push_back(&mut vec, new_material);
            i = i + 1;
        };

        vec
    }

    fun multiply_stats(multi: u16, stats: vector<StatRangeString>): vector<StatRangeString> {
        let len = vector::length(&stats);
        let vec = vector::empty<StatRangeString>();

        while (len > 0){
            let stat = vector::borrow_mut(&mut stats, len-1);
            let degraded_stat = Core::degrade_string_statRange_to_statRange(stat);
            let min = Core::get_statRange_min(&degraded_stat);
            let max = Core::get_statRange_max(&degraded_stat);
            Core::change_statRange_min(&mut degraded_stat, min*(multi as u64)/100);
            Core::change_statRange_max(&mut degraded_stat, max*(multi as u64)/100);
            let _stat = Core::make_string_stat_range(&degraded_stat);
            vector::push_back(&mut vec, _stat);
            len = len-1 

        };
        move vec
    }

// Test
 #[test(account = @0x1, owner = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7)]
     public entry fun test(account: signer, owner: signer) acquires Item_Material_Config, Item_Type_Config, Rarity_Config{
        print(&utf8(b" ACCOUNT ADDRESS "));
        print(&account);


        print(&utf8(b" OWNER ADDRESS "));
        print(&owner);


        let source_addr = signer::address_of(&account);
        
        init_module(&owner);
        print(&viewItemsMaterialConfig());
    //addMultipleItemTypesToConfig(address: &signer, typeIDs: vector<u8>, crafting_multies: vector<u8>, stat_ids: vector<u8>, stat_mins: vector<u64>, stat_maxs: vector<u64>) 
        let stats1 = (vector[3u8, 1u8, 2u8]: vector<u8>);
        let stats2 = (vector[1u8, 2u8]: vector<u8>);
        let stats3 = (vector[3u8, 1u8, 2u8]: vector<u8>);
        let mins1 = (vector[3u64, 1u64, 2u64]: vector<u64>);
        let mins2 = (vector[1u64, 2u64]: vector<u64>);
        let mins3 = (vector[3u64, 1u64, 2u64]: vector<u64>);
        let maxs1 = (vector[3u64, 1u64, 2u64]: vector<u64>);
        let maxs2 = (vector[1u64, 2u64]: vector<u64>);
        let maxs3 = (vector[3u64, 1u64, 2u64]: vector<u64>);

        //addItemTypeToConfig(address: &signer, typeIDs: u8, crafting_multies: u8, stat_ids: vector<u8>, stat_mins: vector<u64>, stat_maxs: vector<u64>) 
        addItemTypeToConfig(&owner, 1,2,(vector[1u8, 3u8,]: vector<u8>),(vector[20u64, 2u64,10u64]: vector<u64>),(vector[0u64, 1u64, 2u64]: vector<u64>));
        addItemTypeToConfig(&owner, 1,2,(vector[1u8, 1u8, 2u8]: vector<u8>),(vector[1u64, 1u64, 2u64]: vector<u64>),(vector[0u64, 1u64, 2u64]: vector<u64>));
        addItemTypeToConfig(&owner, 1,2,(vector[1u8, 1u8, 2u8]: vector<u8>),(vector[0u64, 1u64, 2u64]: vector<u64>),(vector[0u64, 1u64, 2u64]: vector<u64>));
    //addMultipleItemTypesToConfig(&owner,(vector[0u8, 1u8, 2u8]: vector<u8>),(vector[0u8, 1u8, 2u8]: vector<u8>),(vector[stats1,stats2,stats3]: vector<vector<u8>>),(vector[mins1,mins2,mins3]: vector<vector<u64>>),(vector[maxs1, maxs2, maxs3]: vector<vector<u64>>));
      
      // addMultipleRaritiesToConfig(address: &signer, rarityIDs: vector<u8>,chances:vector<u8>, multies: vector<u16>) 
       addMultipleRaritiesToConfig(&owner,(vector[1u8, 2u8, 3u8, 4u8, 5u8]: vector<u8>),(vector[55u8, 20u8, 15u8, 4u8, 1u8]: vector<u8>),(vector[1u16, 3u16, 5u16,10u16,15u16]: vector<u16>) );
       //material_ids: vector<vector<u8>>, material_amounts: vector<vector<u32>>
let materialIDS1 = vector[0u8, 1u8, 2u8];
let materialIDS2 = vector[0u8, 1u8, 2u8];
let materialIDS3 = vector[0u8, 1u8, 2u8];

let materialAmounts1 = vector[0u32, 1u32, 2u32];
let materialAmounts2 = vector[0u32, 1u32, 2u32];
let materialAmounts3 = vector[0u32, 1u32, 2u32];

// Now create the outer vectors (vector of vector<u8> and vector of vector<u32>)
let materialIDs = vector[materialIDS1, materialIDS2, materialIDS3];       // vector<vector<u8>>
let materialAmounts = vector[materialAmounts1, materialAmounts2, materialAmounts3]; // vector<vector<u32>>

addMultipleItemMaterialTypesToConfig(
    &owner,
    vector[0u8, 1u8, 2u8],      // materialID: vector<u8>
    vector[30u16, 10u16, 2000u16],   // bonus_stats: vector<u16>
    materialIDs,                // material_ids: vector<vector<u8>>
    materialAmounts             // material_amounts: vector<vector<u32>>
);
  //addItemToConfig(&owner, 1, 50);
        print(&viewItemsConfig());
            //typeID: u8, elementID: u8,name: vector<u8>, stamina: u8, damage: u32, desc: String)
        print(&viewItemMaterialConfigById(1));
        print(&viewItemTypeConfigById(1));
        print(&viewItem(1,2,2));
       // createRarityConfig(&owner);
        print(&viewRarityConfig());
        //changeRarityMulti(&owner, 3, 100);
        print(&viewRarityConfig());
       // print(&generateRandomRarity());
        print(&get_rarity_chance(1));
        print(&get_rarity_chance(2));
        //changeRarityStats(&owner, 1,500,1000);
        print(&viewRarityConfig());
        print(&viewItemsMaterialConfig());
        let item = &viewItem(1,2,2);
        print(&viewFinalizedItem(1,6,1,1,1));
        //print(&generateRandomRarity());
         //print(&viewSimulatedRarityBonusStats(1,5));
  }
}   
