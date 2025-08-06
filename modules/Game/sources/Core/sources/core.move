module deployer::testCore45 {

    use std::debug::print;
    use std::string::{String, utf8};
    use std::timestamp;
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;

    // === Constants ===

    const UNKNOWN_VALUE: u64 = 1;
    const UNKNOWN_STAT: u64 = 1;
    const UNKNOWN_ABILITY_TYPE: u64 = 1;
    const UNKNOWN_CLASS: u64 = 1;

    //buffs
    const VALUE_ID_RAGE: u8 = 1;
    const VALUE_ID_ENDURANCE: u8 = 2;
    const VALUE_ID_DOPAMINE: u8 = 3;
    const VALUE_ID_VITALS: u8 = 4;
    const VALUE_ID_VAMP: u8 = 5;
    const VALUE_ID_WISDOM: u8 = 6;
    const VALUE_ID_BARRIER: u8 = 7;
    const VALUE_ID_IMMUNE: u8 = 8;
    //debuffs
    const VALUE_ID_FIRE: u8 = 101;
    const VALUE_ID_POISON: u8 = 102;
    const VALUE_ID_ICE: u8 = 103;
    const VALUE_ID_LIGHTNING: u8 = 104;
    const VALUE_ID_DARK_MAGIC: u8 = 105;
    const VALUE_ID_WATER: u8 = 106;
    const VALUE_ID_CURSE: u8 = 107;

    const VALUE_ID_DMG: u8 = 201;
    const VALUE_ID_HEAL: u8 = 202;
    const VALUE_ID_STAMINA: u8 = 203;

    const STAT_ID_HEALTH: u8 = 1;
    const STAT_ID_ARMOR: u8 = 2;
    const STAT_ID_DAMAGE: u8 = 3;
    const STAT_ID_ATTACK_SPEED: u8 = 4;
    const STAT_ID_STAMINA: u8 = 5;

    const CLASS_ID_WARRIOR: u8 = 1;
    const CLASS_ID_ARCHER: u8 = 2;
    const CLASS_ID_MAGE: u8 = 3;
    const CLASS_ID_ASSASSIN: u8 = 4;
    const CLASS_ID_NECROMANCER: u8 = 5;

    const ABILITY_TYPE_PASSIVE: u8 = 1;
    const ABILITY_TYPE_ACTIVE: u8 = 2;
    const ABILITY_TYPE_TOGGLE: u8 = 3;

    const MATERIAL_ID_EXP: u8 = 0;
    const MATERIAL_ID_GOLD: u8 = 1;
    const MATERIAL_ID_ESSENCE: u8 = 2;
    const MATERIAL_ID_WOOD: u8 = 3;
    const MATERIAL_ID_STONE: u8 = 4;
    const MATERIAL_ID_SAND: u8 = 5;
    const MATERIAL_ID_ORGANIC: u8 = 6;
    const MATERIAL_ID_LEATHER: u8 = 7;
    const MATERIAL_ID_BONES: u8 = 8;

    const MATERIAL_ID_FLINT: u8 = 101;
    const MATERIAL_ID_BASALT: u8 = 102;
    const MATERIAL_ID_COPPER: u8 = 103;
    const MATERIAL_ID_IRON: u8 = 104;
    const MATERIAL_ID_OBSIDIAN: u8 = 105;
    const MATERIAL_ID_DIAMOND: u8 = 106;
    const MATERIAL_ID_SHUNGITE: u8 = 107;
    const MATERIAL_ID_GEMDUST: u8 = 108;

    const MATERIAL_ID_TREASURE: u8 = 201;
    const MATERIAL_ID_BAG_ITEMS: u8 = 202;
    const MATERIAL_ID_BAG_MATERIALS: u8 = 203;
    const MATERIAL_ID_BAG_MINERALS: u8 = 204;
    const MATERIAL_ID_BAG_AEXIS_BATTLE_PASS: u8 = 205;
    const MATERIAL_ID_BAG_SUPRA_TOKENS: u8 = 206;
    const MATERIAL_ID_BAG_COSMETICS: u8 = 207;



// ===  ===  ===  ===  ===
// ===     STRUCTS     ===
// ===  ===  ===  ===  ===
// Stat
    struct Stat has copy, drop, store{
        statID: u8, value: u64
  
    }
    struct StatString has copy,drop,store {
         statID: u8, name: String, value: u64
    }

    struct StatRange has copy,drop,store {
        statID: u8, min: u64, max: u64
    }
    struct StatRangeString has copy,drop,store {
         statID: u8, name: String, min: u64, max: u64
    }
    
// Value
    struct Value has copy, drop,store {
        valueID: u8, isEnemy: bool, value: u16
    }
    struct ValueString has copy,drop,store {
        valueID: u8, name: String, isEnemy: bool, value: u16
    }
// ValueTime
    struct ValueTime has copy, drop,store {
        value: Value, time: u64
    }
    struct ValueTimeString has copy,drop,store {
        value: ValueString, time: u64
    }   
// Type
    struct Type has copy, drop,store {
        name: String, stat_multi: u16
    }
// Location
    struct Location has copy, drop,store {
        name: String, stat_multi: u16
    }
// Entity
    struct Entity has copy,drop,store {
        entityID: u8, entityName: String, entityType: String, location: String
    }
// Material
    struct Material has copy, key, store, drop {
        materialID: u8, amount: u32
    }
    struct MaterialString has copy, key, store, drop {
        materialID: u8, materialName: String, amount: u32
    }
// Expedition 
    struct Expedition has copy, drop, store, key {
        id: u8, required_level: u8, costs: vector<Reward>, rewards: vector<Reward>
    }    
    struct ExpeditionString has copy, drop, store, key {
        id: u8, name: String, required_level: u8, costs: vector<RewardString>, rewards: vector<RewardString>
    }    
// Dungeon
    struct Dungeon has copy, drop, store, key {
        id: u8, bossID: u8, entitiesID: vector<u8>, rewards: vector<Material>
    }    
    struct DungeonString has copy, drop, store, key {
        name: String, bossName: String, entitiesName: vector<String>, rewards: vector<MaterialString>
    }   

// Rarity    
    struct Rarity has copy, store, drop, key {
        rarityID: u8, chance: u8, multi: u16, number_of_values:u8
    }

    struct RarityString has copy, store, drop, key {
        rarityID: u8, rarityName: String, chance:u8, multi: u16, number_of_values: u8
    }
// Race
    struct Race has copy,drop,store,key {
        raceID: u8, values: vector<Value>
    }
    struct RaceString has copy,drop,store,key {
        raceID: u8, raceName: String, values: vector<ValueString>
    }    
// Perk
    struct Perk has copy, drop, key, store{
        perkID: u8, name: String, typeID: u8, cost: u8, cooldown:u8, values: vector<Value>
    }
    struct PerkString has copy, drop, key, store{
        perkID: u8, name: String, typeID: u8, typeName: String, required: u8, cost: u8, cooldown:u8, values: vector<ValueString>
    }
// Reward
    struct Reward has copy, drop, key, store{
        materialID: u8, amount: u32, period: u64
    }
    struct RewardString has copy, drop, key, store{
        materialName: String, amount: u32, period: u64
    }  
// Ability 
    struct Ability has copy, drop, store, key {
        abilityID: u8, classID: u8, abilityName: String, required_chakra: u32, values: vector<Value>
    }   
    struct AbilityString has copy, drop, store, key {
        abilityID: u8, className: String, abilityName: String, required_chakra: u32, values: vector<ValueString>
    }     
// Item
    struct Item has copy, drop,store {
        itemID: u64, typeID: u8, materialID: u8, rarityID: u8, rarityStats: vector<Stat>,stats: vector<Stat>
    }
  
    struct ItemString has copy, drop, store {
        itemID: u64, typeName: String, materialName: String, rarityName: String, rarityStats: vector<StatString>, stats: vector<StatString>
    }
// Cosmetic
    struct Cosmetic has copy, drop,store {
        cosmeticID: u64, thematic: String, name: String
    }
// ===  ===  ===  ===  === ===
// ===  Factory Functions  ===
// ===  ===  ===  ===  === ===
// Material
    //makes
        public fun make_material(materialID: u8, amount: u32): Material {
            Material { materialID: materialID, amount: amount}
        }
        public fun make_material_string(material: &Material): MaterialString {
            MaterialString { materialID: material.materialID, materialName: convert_materialID_to_String(material.materialID), amount: material.amount}
        }

    //convert
        public fun convert_material(material: &mut Material): Material {
            let amt = get_material_amount(material);
            if (amt > 0) {
                change_material_amount(material, amt / 10);
            };
            *material
        }


    //changes
        public fun change_material_amount(material: &mut Material, amount: u32): Material {
            material.amount = amount;
            *material
        }

    //gets
        public fun get_material_ID(material: &Material): u8{
            material.materialID
        }

        public fun get_material_amount(material: &Material): u32{
            material.amount
        }


    //multiples
        public fun make_multiple_string_materials(materials: vector<Material>, amounts: vector<u32>): vector<MaterialString> {
            let len = vector::length(&materials);
            let vect = vector::empty<MaterialString>();
            while(len>0){
                let material = make_material_string(vector::borrow(&materials, len-1));
                vector::push_back(&mut vect, material);
                len=len-1;
            };
            move vect
        }
        public fun make_multiple_materials(materialIDs: vector<u8>, amounts: vector<u32>): vector<Material> {
            assert!(vector::length(&materialIDs) == vector::length(&amounts),5);
            let len = vector::length(&materialIDs);
            let vect = vector::empty<Material>();
            while(len>0){
                let material = make_material(*vector::borrow(&materialIDs, len-1), *vector::borrow(&amounts, len-1));
                vector::push_back(&mut vect, material);
                len=len-1;
            };
            move vect
        }

    //degrades
        public fun degrade_string_materialString_to_material(materialString: &MaterialString): Material {
            Material { materialID: materialString.materialID, amount: materialString.amount}
        }
        public fun degrade_multiple_materialsString(materialStrings: vector<MaterialString>): vector<Material> {
            let len = vector::length(&materialStrings);
            let vect = vector::empty<Material>();
            while(len>0){
                let material = degrade_string_materialString_to_material(vector::borrow(&materialStrings, len-1));
                vector::push_back(&mut vect, material);
                len=len-1;
            };
            move vect
        } 
// Entity
    //makes
        public fun make_entity(entityID: u8, entityName: String, entityType: String, entityLocation: String,): Entity {
            Entity { entityID: entityID, entityName: entityName, entityType: entityType, location: entityLocation, }
        }
    //gets
        public fun get_entity_name(entity: &Entity): String {
            entity.entityName
        }

        public fun get_entity_ID(entity: &Entity): u8 {
            entity.entityID
        }

        public fun get_entity_type(entity: &Entity): String {
            entity.entityType
        }

        public fun get_entity_location(entity: &Entity): String {
            entity.location
        }


// Value
    //makes
        public fun make_value(id: u8, isEnemy: bool, val: u16): Value {
            Value { valueID: id, isEnemy: isEnemy, value: val }
        }

        public fun make_string_value(value: &Value): ValueString {
            ValueString { valueID: value.valueID, name: convert_valueID_to_String(value.valueID), isEnemy: value.isEnemy, value: value.value}
        }

    //changes
        public fun change_value_amount(value: &mut Value, amount: u16): Value {
            value.value = amount;
            *value
        }
        
        public fun change_value_value(value: &mut Value, val: u16): ValueString {
            value.value = val;
            make_string_value(&*value)
        }

    //gets
        public fun get_value_ID(value: &Value): u8 {
            value.valueID
        }

        public fun get_value_isEnemy(value: &Value): bool {
            value.isEnemy
        }

        public fun get_value_value(value: &Value): u16 {
            value.value
        }

        public fun get_value_from_vector_value(vect: vector<Value>, valueID: u8): Value {
            let len = vector::length(&vect);
            while(len > 0){
                let value = vector::borrow(&mut vect, len-1);
                if(value.valueID == valueID){
                    return *value
                };
            };
            abort(1)
        }

        public fun get_value_by_name(vect: vector<ValueString>, valueName: String): ValueString {
            let len = vector::length(&vect);
            while(len > 0){
                let value = vector::borrow(&mut vect, len-1);
                if(value.name == valueName){
                    return *value
                };
            };
            abort(1)
        }


    //degrades
        public fun degrade_string_value_to_value(valueString: &ValueString): Value {
            Value { valueID: valueString.valueID, isEnemy: valueString.isEnemy, value: valueString.value }
        }

    //multiples
        public fun make_multiple_values(valueIDs: vector<u8>, isEnemy: vector<bool>, values: vector<u16>): vector<Value> {
            assert!(vector::length(&valueIDs) == vector::length(&values),5);
            let len = vector::length(&valueIDs);
            let vect = vector::empty<Value>();
            while(len>0){
                let value = make_value(*vector::borrow(&valueIDs, len-1), *vector::borrow(&isEnemy, len-1),*vector::borrow(&values, len-1));
                vector::push_back(&mut vect, value);
                len=len-1;
            };
            move vect
        }

        public fun make_multiple_string_values(values: vector<Value>): vector<ValueString> {
            let len = vector::length(&values);
            let vect = vector::empty<ValueString>();
            while(len>0){
                let value_string = make_string_value(vector::borrow(&values, len-1));
                vector::push_back(&mut vect, value_string);
                len=len-1;
            };
            move vect
        }
// ValueTime
    //makes
        public fun make_valueTime(value: Value, time: u64): ValueTime {
            ValueTime { value: value, time: time }
        }

        public fun make_string_valueTime(value: &ValueTime): ValueTimeString {
            ValueTimeString { value: make_string_value(&value.value), time: value.time}
        }

    //changes

        public fun change_valueTime_time(value: &mut ValueTime, time: u64): ValueTime {
            value.time = time;
            *value
        }

    //gets

        public fun get_valueTime_time(value: &ValueTime): u64 {
            value.time
        }

    //degrades
        public fun degrade_string_valueTime_to_valueTime(valueString: &ValueTimeString): ValueTime {
            ValueTime { value: degrade_string_value_to_value(&valueString.value), time: valueString.time }
        }
    //multiples
        public fun make_multiple_valuesTimes(values: vector<Value>,times: vector<u64>): vector<ValueTime> {
            assert!(vector::length(&values) == vector::length(&times),5);
            let len = vector::length(&values);
            let vect = vector::empty<ValueTime>();
            while(len>0){
                let value = make_valueTime(*vector::borrow(&values, len-1), *vector::borrow(&times, len-1));
                vector::push_back(&mut vect, value);
                len=len-1;
            };
            move vect
        }

        public fun make_multiple_string_valuesTimes(values: vector<ValueTime>): vector<ValueTimeString> {
            let len = vector::length(&values);
            let vect = vector::empty<ValueTimeString>();
            while(len>0){
                let value_string = make_string_valueTime(vector::borrow(&values, len-1));
                vector::push_back(&mut vect, value_string);
                len=len-1;
            };
            move vect
        }     

// Stat
    //makes
        public fun make_stat(id: u8, val: u64): Stat {
            Stat { statID: id, value: val }
        }

        public fun make_string_stat(stat: &Stat): StatString {
            StatString { statID: stat.statID, name: convert_statID_to_String(stat.statID), value: stat.value}
        }
        public fun make_range_stat(id: u8, min: u64, max: u64): StatRange {
            StatRange { statID: id, min: min, max: max }
        }

        public fun make_string_stat_range(stat: &StatRange): StatRangeString {
            StatRangeString { statID: stat.statID, name: convert_statID_to_String(stat.statID),  min: stat.min, max: stat.max}
        }


    //changes
        public fun change_stat_amount(stat: &mut Stat, value: u64): Stat {
            stat.value = value;
            *stat
        }
        public fun change_stat_value(stat: &mut Stat, val: u64): StatString {
            stat.value = val;
            make_string_stat(&*stat)
        }
        public fun change_statRange_min(statRange: &mut StatRange, min: u64)  {
            statRange.min = min
        }
        public fun change_statRange_max(statRange: &mut StatRange, max: u64) {
            statRange.max = max
        }

    //gets
        public fun get_stat_ID(stat: &Stat): u8 {
            stat.statID
        }
        public fun get_stat_value(stat: &Stat): u64 {
            stat.value
        }
        public fun get_statRange_ID(statRange: &StatRange): u8 {
            statRange.statID
        }

        public fun get_statRange_min(statRange: &StatRange): u64 {
            statRange.min
        }

        public fun get_statRange_max(statRange: &StatRange): u64 {
            statRange.max
        }


        public fun get_stat_by_name(vect: vector<StatString>, statName: String): StatString {
            let len = vector::length(&vect);
            while(len > 0){
                let stat = vector::borrow(&mut vect, len-1);
                if(stat.name == statName){
                    return *stat
                };
                len = len-1;
            };
            abort(1)
        }

    //degrades
        public fun degrade_string_stat_to_stat(statRange: &StatString): Stat {
            Stat { statID: statRange.statID,  value: statRange.value}
        }
        public fun degrade_string_statRange_to_statRange(statRangeString: &StatRangeString): StatRange {
            StatRange { statID: statRangeString.statID,  min: statRangeString.min, max: statRangeString.max}
        }
    //multiples
        public fun make_multiple_stats(statIDs: vector<u8>, values: vector<u64>): vector<Stat> {
            assert!(vector::length(&statIDs) == vector::length(&values),5);
            let len = vector::length(&statIDs);
            let vect = vector::empty<Stat>();
            while(len>0){
                let stat = make_stat(*vector::borrow(&statIDs, len-1), *vector::borrow(&values, len-1),);
                vector::push_back(&mut vect, stat);
                len=len-1;
            };
            move vect
        }
        public fun make_multiple_string_stats(stats: vector<Stat>): vector<StatString> {
            let len = vector::length(&stats);
            let vect = vector::empty<StatString>();
            while(len>0){
                let stat_string = make_string_stat(vector::borrow(&stats, len-1), );
                vector::push_back(&mut vect, stat_string);
                len=len-1;
            };
            move vect
        }

        public fun make_multiple_range_stats(statIDs: vector<u8>, mins: vector<u64>, maxs: vector<u64>): vector<StatRange> {
            assert!(vector::length(&statIDs) == vector::length(&mins) || vector::length(&mins) == vector::length(&maxs),5);
            let len = vector::length(&statIDs);
            let vect = vector::empty<StatRange>();
            while(len>0){
                let stat_range = make_range_stat(*vector::borrow(&statIDs, len-1), *vector::borrow(&mins, len-1), *vector::borrow(&maxs, len-1));
                vector::push_back(&mut vect, stat_range);
                len=len-1;
            };
            move vect
        }
        public fun make_multiple_string_range_stats(stats: vector<StatRange>): vector<StatRangeString> {
            let len = vector::length(&stats);
            let vect = vector::empty<StatRangeString>();
            while(len>0){
                let stat_string_range = make_string_stat_range(vector::borrow(&stats, len-1), );
                vector::push_back(&mut vect, stat_string_range);
                len=len-1;
            };
            move vect
        }




// Type
    //makes
        public fun make_type(name: String, stat_multi: u16): Type {
            Type { name: name, stat_multi: stat_multi }
        }
    //changes
        public fun change_type_multi(type: &mut Type, value: u16) {
            type.stat_multi = value;
        }
    //gets
        public fun get_type_name(type: &Type): String {
            type.name
        }

        public fun get_type_multi(type: &Type): u16 {
            type.stat_multi
        }


// Location
    //makes
        public fun make_location(name: String, stat_multi: u16): Location {
            Location { name: name, stat_multi: stat_multi }
        }
    //changes
        public fun changes_location_multi(type: &mut Location, value: u16) {
            type.stat_multi = value;
        }
    //gets
        public fun get_location_name(type: &Location): String {
            type.name
        }

        public fun get_location_multi(type: &Location): u16 {
            type.stat_multi
        }


// Expedition
    //makes
        public fun make_expedition(id: u8, required_level: u8, costs: vector<Reward>, rewards: vector<Reward>): Expedition {
            Expedition { id: id, required_level: required_level, costs: costs, rewards:rewards}
        }

        public fun make_string_expedition(expedition: &Expedition): ExpeditionString {
            ExpeditionString { id: expedition.id, name: convert_expeditionID_to_String(expedition.id), required_level: expedition.required_level, costs: build_rewards_with_strings(expedition.costs), rewards:build_rewards_with_strings(expedition.rewards) }
        }

    //changes
        public fun change_expedition_required_level(expedition: &mut Expedition, required_level: u8 ): Expedition {
            expedition.required_level = required_level;
            *expedition
        }

    //gets
        public fun get_expedition_ID(expedition: &Expedition): u8 {
            expedition.id
        }

        public fun get_expedition_required_level(expedition: &Expedition): u8 {
            expedition.required_level
        }

        public fun get_expedition_costs(expedition: &Expedition): vector<Reward> {
            expedition.costs
        }

        public fun get_expedition_rewards(expedition: &Expedition): vector<Reward>{
                expedition.rewards
            }


// Dungeon
    //makes
        public fun make_dungeon(id: u8, bossID: u8, entitiesID: vector<u8>, rewards: vector<Material>): Dungeon {
            Dungeon { id: id, bossID: bossID, entitiesID: entitiesID, rewards: rewards}
        }

        
        public fun make_string_dungeon(dungeon: Dungeon, bossName: String, entitiesName: vector<String>): DungeonString {
            DungeonString { name: convert_dungeonID_to_String(dungeon.id), bossName: bossName, entitiesName: entitiesName, rewards: build_materials_with_strings(dungeon.rewards)}
        }

    //gets
        public fun get_dungeon_ID(dungeon: &Dungeon): u8 {
            dungeon.id
        }
        public fun get_dungeon_boss(dungeon: &Dungeon): u8 {
            dungeon.bossID
        }
        public fun get_dungeon_entities(dungeon: &Dungeon): vector<u8> {
            dungeon.entitiesID
        }
        public fun get_dungeon_rewards(dungeon: &mut Dungeon): vector<Material>{
            dungeon.rewards
        }


// Rarity
    //makes
        public fun make_rarity(id: u8, chance: u8, multi: u16, number_of_values: u8): Rarity {
            Rarity { rarityID: id, chance: chance, multi: multi, number_of_values: number_of_values}
        }
            public fun make_string_rarity(rarity: Rarity): RarityString{
            RarityString {rarityID: rarity.rarityID, rarityName: convert_rarityID_to_String(rarity.rarityID), chance: rarity.chance, multi: rarity.multi, number_of_values: rarity.number_of_values}
        }
    //gets
        public fun get_rarity_id(rarity: Rarity): u8 {
            rarity.rarityID
        }
        public fun get_rarity_chance(rarity: Rarity): u8 {
            rarity.chance
        }
        public fun get_rarity_number_of_values(rarity: Rarity): u8 {
            rarity.number_of_values
        }
        public fun get_rarity_multi(rarity: Rarity): u16 {
            rarity.multi
        }
    //changes
        public fun change_rarity_multi(rarity: &mut Rarity, new_multi: u16): Rarity {
            rarity.multi = new_multi;
            *rarity
        }
            public fun change_rarity_chance(rarity: &mut Rarity, new_chance: u8): Rarity {
            rarity.chance = new_chance;
            *rarity
        }
    //degrades
        public fun degrade_stringRarity_to_rarity(rarityString: RarityString): Rarity{
            Rarity { rarityID: rarityString.rarityID, chance: rarityString.chance, multi: rarityString.multi, number_of_values: rarityString.number_of_values}
        }
    //multiples
        public fun make_multiple_rarities(ids: vector<u8>, chances: vector<u8>, multies: vector<u16>): vector<Rarity> {
            assert!(vector::length(&ids) == vector::length(&chances) || vector::length(&ids) == vector::length(&multies),101);
            let len = vector::length(&ids);
            let vect = vector::empty<Rarity>();
            while(len>0){
                let rarity = make_rarity(*vector::borrow(&ids, len-1),*vector::borrow(&chances, len-1),*vector::borrow(&multies, len-1),*vector::borrow(&ids, len-1));
                vector::push_back(&mut vect, rarity);
                len=len-1;
            };
            move vect
        }
// Race
    //makes
        public fun make_race(raceID: u8, values: vector<Value>): Race {
            Race { raceID: raceID, values: values }
        }
        public fun make_string_race(race: &Race): RaceString{
            RaceString { raceID: race.raceID, raceName: get_race_name(race), values: build_values_with_strings(race.values) }
        }

    //gets
        public fun get_race_id(race: &Race): u8 {
            race.raceID
        }

        public fun get_race_name(race: &Race): String {
            convert_raceID_to_String(race.raceID)
        }

        public fun get_race_values(race: &Race): vector<Value> {
            race.values
        }


// Perk
    //makes
        public fun make_perk(perkID: u8, name: String, typeID: u8, cost: u8, cooldown: u8, values: vector<Value>): Perk {
            Perk { perkID: perkID, name: name, typeID: typeID, cost: cost, cooldown:cooldown, values: values }
        }
        public fun make_string_perk(perk: &Perk, required: u8): PerkString{
            PerkString { perkID: perk.perkID, name: perk.name, typeID: perk.typeID, typeName: convert_perksTypeID_to_String(perk.typeID), required: required, cost: perk.cost, cooldown:perk.cooldown, values: build_values_with_strings(perk.values) }
        }

    //changes
        public fun change_perk_cost(perk: &mut Perk, new_cost: u8) {
            perk.cost = new_cost
        }
        public fun change_perk_cooldowm(perk: &mut Perk, new_cdr: u8) {
            perk.cooldown = new_cdr
        }

    //gets
        public fun get_perk_id(perk: &Perk): u8 {
            perk.perkID
        }
        public fun get_perk_name(perk: &Perk): String {
            perk.name
        }
        public fun get_perk_typeID(perk: &Perk): u8 {
            perk.typeID
        }
        public fun get_perk_typeName(perk: &Perk): String {
            convert_perksTypeID_to_String(perk.typeID)
        }
        public fun get_perk_stamina(perk: &Perk): u8 {
            perk.cost
        }
        public fun get_perk_cooldown(perk: &Perk): u8 {
            perk.cooldown
        }
        public fun get_perk_values(perk: &Perk): vector<Value> {
            perk.values
        }

        public fun get_perkString_required(perk: &PerkString): u8 {
            perk.required
        }
// Reward
     //makes
        public fun make_reward(materialID: u8, amount: u32, period: u64): Reward {
            Reward { materialID: materialID, amount: amount, period: period}
        }
        public fun make_string_reward(reward: &Reward): RewardString{
            RewardString { materialName: convert_materialID_to_String(reward.materialID), amount: reward.amount, period: reward.period}
        }

    //gets
        public fun get_reward_id(reward: &Reward): u8{
            reward.materialID
        }
        public fun get_reward_amount(reward: &Reward): u32 {
            reward.amount
        }
        public fun get_reward_period(reward: &Reward): u64 {
            reward.period
        }
  //multiples
        public fun make_multiple_string_rewards(rewards: vector<Reward>): vector<RewardString> {
            let len = vector::length(&rewards);
            let vect = vector::empty<RewardString>();
            while(len>0){
                let reward = make_string_reward(vector::borrow(&rewards, len-1));
                vector::push_back(&mut vect, reward);
                len=len-1;
            };
            move vect
        }
        public fun make_multiple_rewards(materialIDs: vector<u8>, amounts: vector<u32>,periods: vector<u64>): vector<Reward> {
            assert!(vector::length(&materialIDs) == vector::length(&amounts),5);
            let len = vector::length(&materialIDs);
            let vect = vector::empty<Reward>();
            while(len>0){
                let reward = make_reward(*vector::borrow(&materialIDs, len-1), *vector::borrow(&amounts, len-1),*vector::borrow(&periods, len-1));
                vector::push_back(&mut vect, reward);
                len=len-1;
            };
            move vect
        }



// Ability
     //makes
        public fun make_Ability(abilityID: u8, classID: u8, abilityName: String, required_chakra: u32, values: vector<Value>): Ability {
            Ability {abilityID: abilityID, classID: classID, abilityName: abilityName, required_chakra: required_chakra, values: values}
        }
        public fun make_string_Ability(ability: &Ability): AbilityString{
            AbilityString { abilityID: ability.abilityID, className: convert_classID_to_String(ability.classID), abilityName: ability.abilityName, required_chakra: ability.required_chakra, values: build_values_with_strings(ability.values)}
        }

    //gets
        public fun get_Ability_abilityID(ability: &Ability): u8{
            ability.abilityID
        }
        public fun get_Ability_classID(ability: &Ability): u8{
            ability.classID
        }
        public fun get_Ability_name(ability: &Ability): String{
            ability.abilityName
        }
        public fun get_Ability_required_chakra(ability: &Ability): u32 {
            ability.required_chakra
        }
        public fun get_Ability_values(ability: &Ability): vector<Value> {
            ability.values
        }
    //change
        public fun change_Ability_required_chakra(ability: &mut Ability,new_chakra: u32) {
            ability.required_chakra = new_chakra
        }
    //multiples
        public fun make_multiple_string_Abilities(abilities: vector<Ability>): vector<AbilityString> {
            let len = vector::length(&abilities);
            let vect = vector::empty<AbilityString>();
            while(len>0){
                let reward = make_string_Ability(vector::borrow(&abilities, len-1));
                vector::push_back(&mut vect, reward);
                len=len-1;
            };
            move vect
        }
        public fun make_multiple_Abilities(idss: vector<u8>, classID: u8, names: vector<String>, required_chakra: vector<u32>,ids: vector<vector<u8>>, isEnemies: vector<vector<bool>>, vals: vector<vector<u16>>): vector<Ability> {
            assert!(vector::length(&names) == vector::length(&required_chakra),5);
            let len = vector::length(&names);
            let vect = vector::empty<Ability>();
            while(len>0){
                let reward = make_Ability(*vector::borrow(&idss, len-1),classID,*vector::borrow(&names, len-1),*vector::borrow(&required_chakra, len-1),make_multiple_values(*vector::borrow(&ids, len-1), *vector::borrow(&isEnemies, len-1), *vector::borrow(&vals, len-1)));
                vector::push_back(&mut vect, reward);
                len=len-1;
            };
            move vect
        }
// Item
     //makes
        public fun make_Item(itemID: u64, typeID: u8, materialID: u8, rarityID: u8, rarityStats: vector<Stat>,stats: vector<Stat>): Item {
            Item {itemID: itemID, typeID: typeID, materialID: materialID, rarityID: rarityID, rarityStats: rarityStats, stats: stats}
        }
        public fun make_string_item(item: &Item): ItemString {
            ItemString { itemID: item.itemID, typeName: convert_typeID_to_String(item.typeID), materialName: convert_materialID_to_String(item.materialID), rarityName: convert_rarityID_to_String(item.rarityID), rarityStats: build_stats_with_strings(item.rarityStats), stats: build_stats_with_strings(item.stats)}
        }

    //gets
        public fun get_Item_itemID(item: &Item): u64{
            item.itemID
        }
        public fun get_Item_typeID(item: &Item): u8{
            item.typeID
        }
        public fun get_Item_materialID(item: &Item): u8{
            item.materialID
        }
        public fun get_Item_rarityID(item: &Item): u8{
            item.rarityID
        }
        public fun get_Item_rarityStats(item: &Item): vector<Stat>{
            item.rarityStats
        }
        public fun get_Item_stats(item: &Item): vector<Stat>{
            item.stats
        }
    //change
        public fun change_Item_rarity(item: &mut Item, new_rarity: u8) {
            item.rarityID = new_rarity
        }
        public fun change_Item_rarityStats(item: &mut Item, new_rarityStats: vector<Stat>) {
            item.rarityStats = new_rarityStats
        }
    //multiples
        public fun make_multiple_string_items(items: vector<Item>): vector<ItemString> {
            let len = vector::length(&items);
            let vect = vector::empty<ItemString>();
            while(len>0){
                let item = make_string_item(vector::borrow(&items, len-1));
                vector::push_back(&mut vect, item);
                len=len-1;
            };
            move vect
        }
        public fun make_multiple_items(itemID: vector<u64>, typeID: vector<u8>, materialID: vector<u8>, rarityID: vector<u8>, rarityStats: vector<vector<Stat>>,stats: vector<vector<Stat>>): vector<Item> {
            assert!(vector::length(&typeID) == vector::length(&materialID),5);
            let len = vector::length(&typeID);
            let vect = vector::empty<Item>();
            while(len>0){
                let item = make_Item(*vector::borrow(&itemID, len-1),*vector::borrow(&typeID, len-1),*vector::borrow(&materialID, len-1), *vector::borrow(&rarityID, len-1),*vector::borrow(&rarityStats, len-1),(*vector::borrow(&stats, len-1)));
                vector::push_back(&mut vect, item);
                len=len-1;
            };
            move vect
        }
// Cosmetic
     //makes
        public fun make_Cosmetic(cosmeticID: u64, thematic: String, name: String): Cosmetic {
            Cosmetic {cosmeticID: cosmeticID, thematic: thematic, name: name}
        }

    //gets
        public fun get_Cosmetic_ID(cosmetic: &Cosmetic): u64{
            cosmetic.cosmeticID
        }
        public fun get_Cosmetic_thematic(cosmetic: &Cosmetic): String{
            cosmetic.thematic
        }
        public fun get_Cosmetic_name(cosmetic: &Cosmetic): String{
            cosmetic.name
        }

    //multiples
        public fun make_multiple_Cosmetic(cosmeticIDs: vector<u64>, thematic: String, names: vector<String>): vector<Cosmetic> {
            assert!(vector::length(&cosmeticIDs) == vector::length(&names),5);
            let len = vector::length(&cosmeticIDs);
            let vect = vector::empty<Cosmetic>();
            while(len>0){
                let cosmetic = make_Cosmetic(*vector::borrow(&cosmeticIDs, len-1),thematic,*vector::borrow(&names, len-1));
                vector::push_back(&mut vect, cosmetic);
                len=len-1;
            };
            move vect
        }

// ===  ===  ===  ===  === 
// ===     CONVERTS    ===
// ===  ===  ===  ===  ===
public fun convert_valueID_to_String(valueID: u8): String {
    if (valueID == VALUE_ID_RAGE) {
        utf8(b"rage")
    } else if (valueID == VALUE_ID_ENDURANCE) {
        utf8(b"Endurance")
    } else if (valueID == VALUE_ID_DOPAMINE) {
        utf8(b"Dopamine")
    } else if (valueID == VALUE_ID_VITALS) {
        utf8(b"Vitals")
    } else if (valueID == VALUE_ID_VAMP) {
        utf8(b"Vamp")
    } else if (valueID == VALUE_ID_WISDOM) {
        utf8(b"Wisdom")
    } else if (valueID == VALUE_ID_BARRIER) {
        utf8(b"Barrier")
    } else if (valueID == VALUE_ID_IMMUNE) {
        utf8(b"Immune")
    } else if (valueID == VALUE_ID_FIRE) {
        utf8(b"Fire")
    } else if (valueID == VALUE_ID_POISON) {
        utf8(b"Poison")
    } else if (valueID == VALUE_ID_ICE) {
        utf8(b"Ice")
    } else if (valueID == VALUE_ID_LIGHTNING) {
        utf8(b"Lightning")
    } else if (valueID == VALUE_ID_DARK_MAGIC) {
        utf8(b"Dark Magic")
    } else if (valueID == VALUE_ID_WATER) {
        utf8(b"Water")
    } else if (valueID == VALUE_ID_CURSE) {
        utf8(b"Curse")
    } else if (valueID == VALUE_ID_HEAL) {
        utf8(b"Heal")
    } else if (valueID == VALUE_ID_DMG) {
        utf8(b"Damage")
    } else if (valueID == VALUE_ID_STAMINA) {
        utf8(b"Stamina")
    } else {
        abort(UNKNOWN_VALUE)
    }
}

    public fun convert_statID_to_String(statID: u8): String {
        if (statID == STAT_ID_HEALTH) {
            utf8(b"Health")
        } else if (statID == STAT_ID_DAMAGE) {
            utf8(b"Damage")
        } else if (statID == STAT_ID_ARMOR) {
            utf8(b"Armor")
        } else if (statID == STAT_ID_ATTACK_SPEED) {
            utf8(b"Chakra Absorbtion")
        }  else if (statID == STAT_ID_STAMINA) {
            utf8(b"Stamina")
        } else {
            abort(UNKNOWN_STAT)
        }
    }

    public fun convert_ability_typeID_to_String(typeID: u8): String {
        if (typeID == ABILITY_TYPE_PASSIVE) {
            utf8(b"Passive")
        } else if (typeID == ABILITY_TYPE_ACTIVE) {
            utf8(b"Active")
        } else {
            abort(UNKNOWN_ABILITY_TYPE)
        }
    }

    public fun convert_classID_to_String(classID: u8): String {
        if (classID == CLASS_ID_WARRIOR) {
            utf8(b"Warrior")
        } else if (classID == CLASS_ID_ARCHER) {
            utf8(b"Archer")
        } else if (classID == CLASS_ID_MAGE) {
            utf8(b"Mage")
        } else if (classID == CLASS_ID_ASSASSIN) {
            utf8(b"Assassin")
        } else if (classID == CLASS_ID_NECROMANCER) {
            utf8(b"Necromancer")
        } else {
            abort(UNKNOWN_CLASS)
        }
    }

#[deprecated]
    public fun convert_materialMineralID_to_String(materialID: u8): String {
        if (materialID == MATERIAL_ID_FLINT) {
            utf8(b"Flint")
        } else if (materialID == MATERIAL_ID_BASALT) {
            utf8(b"Basalt")
        } else if (materialID == MATERIAL_ID_COPPER) {
            utf8(b"Copper")
        } else if (materialID == MATERIAL_ID_IRON) {
            utf8(b"Iron")
        } else if (materialID == MATERIAL_ID_OBSIDIAN) {
            utf8(b"Obsidian")
        } else if (materialID == MATERIAL_ID_DIAMOND) {
            utf8(b"Diamond")
        } else if (materialID == MATERIAL_ID_SHUNGITE) {
            utf8(b"Shungite")
        } else {
            utf8(b"Unknown")
        }
    }
#[deprecated]
    public fun convert_materialBagsID_to_String(materialID: u8): String {
        if (materialID == MATERIAL_ID_BAG_ITEMS) {
            utf8(b"Items Bag")
        } else if (materialID == MATERIAL_ID_BAG_MATERIALS) {
            utf8(b"Materials Bag")
        } else if (materialID == MATERIAL_ID_BAG_MINERALS) {
            utf8(b"Minerals Bag")
        } else if (materialID == MATERIAL_ID_BAG_AEXIS_BATTLE_PASS) {
            utf8(b"Aexis Pass XP Bag")
        } else if (materialID == MATERIAL_ID_BAG_SUPRA_TOKENS) {
            utf8(b"Supra Tokens Bag")
        } else if (materialID == MATERIAL_ID_BAG_COSMETICS) {
            utf8(b"Cosmetics Bag")
        } else {
            utf8(b"Unknown")
        }
    }

public fun convert_materialID_to_String(materialID: u8): String {
    if (materialID == MATERIAL_ID_FLINT) {
        utf8(b"Flint")
    } else if (materialID == MATERIAL_ID_BASALT) {
        utf8(b"Basalt")
    } else if (materialID == MATERIAL_ID_COPPER) {
        utf8(b"Copper")
    } else if (materialID == MATERIAL_ID_IRON) {
        utf8(b"Iron")
    } else if (materialID == MATERIAL_ID_OBSIDIAN) {
        utf8(b"Obsidian")
    } else if (materialID == MATERIAL_ID_DIAMOND) {
        utf8(b"Diamond")
    } else if (materialID == MATERIAL_ID_SHUNGITE) {
        utf8(b"Shungite")
    } else if (materialID == MATERIAL_ID_TREASURE) {
        utf8(b"Treasure")
    } else if (materialID == MATERIAL_ID_BAG_ITEMS) {
        utf8(b"Items Bag")
    } else if (materialID == MATERIAL_ID_BAG_MATERIALS) {
        utf8(b"Materials Bag")
    } else if (materialID == MATERIAL_ID_BAG_MINERALS) {
        utf8(b"Minerals Bag")
    } else if (materialID == MATERIAL_ID_BAG_AEXIS_BATTLE_PASS) {
        utf8(b"Aexis Pass XP Bag")
    } else if (materialID == MATERIAL_ID_BAG_SUPRA_TOKENS) {
        utf8(b"Supra Tokens Bag")
    } else if (materialID == MATERIAL_ID_BAG_COSMETICS) {
        utf8(b"Cosmetics Bag")
    } else if (materialID == MATERIAL_ID_EXP) {
        utf8(b"Exp")
    } else if (materialID == MATERIAL_ID_GOLD) {
        utf8(b"Gold")
    } else if (materialID == MATERIAL_ID_ESSENCE) {
        utf8(b"Essence")
    } else if (materialID == MATERIAL_ID_WOOD) {
        utf8(b"Wood")
    } else if (materialID == MATERIAL_ID_STONE) {
        utf8(b"Stone")
    } else if (materialID == MATERIAL_ID_SAND) {
        utf8(b"Sand")
    } else if (materialID == MATERIAL_ID_ORGANIC) {
        utf8(b"Organic")
    } else if (materialID == MATERIAL_ID_LEATHER) {
        utf8(b"Leather")
    } else if (materialID == MATERIAL_ID_BONES) {
        utf8(b"Bones")
    } else if (materialID == MATERIAL_ID_GEMDUST) {
        utf8(b"Gemdust")
    } else {
        utf8(b"Unknown")
    }
}


    public fun convert_typeID_to_String(typeID: u8): String {
        if (typeID == 1) {
            utf8(b"Helmet")
        } else if (typeID == 2) {
            utf8(b"Chestplate")
        } else if (typeID == 3) {
            utf8(b"Leggings")
        } else if (typeID == 4) {
            utf8(b"Boots")
        } else if (typeID == 5) {
            utf8(b"Dagger")
        } else if (typeID == 6) {
            utf8(b"Sword")
        } else if (typeID == 7) {
            utf8(b"Shield")
        } else if (typeID == 8) {
            utf8(b"Bow")
        } else if (typeID == 9) {
            utf8(b"Arrow")
        } else if (typeID == 10) {
            utf8(b"Wand")
        } else if (typeID == 11) {
            utf8(b"Book")
        } else if (typeID == 12) {
            utf8(b"Scyth")
        } else if (typeID == 13) {
            utf8(b"Lantern")
        } else if (typeID == 14) {
            utf8(b"Cloak")
        } else if (typeID == 15) {
            utf8(b"Amulet")
        } else if (typeID == 16) {
            utf8(b"Ring")
        } else if (typeID == 17) {
            utf8(b"Bandage")
        } 
        else {
            utf8(b"Unknown")
        }

    }

    public fun convert_rarityID_to_String(rarityID: u8): String {
        if (rarityID == 0) {
            utf8(b"None")
        } else if (rarityID == 1) {
            utf8(b"Common")
        } else if (rarityID == 2) {
            utf8(b"Uncommon")
        } else if (rarityID == 3) {
            utf8(b"Rare")
        } else if (rarityID == 4) {
            utf8(b"Epic")
        } else if (rarityID == 5) {
            utf8(b"Legendary")
        } 
        else {
            utf8(b"Unknown")
        }
    }


    public fun convert_treasureType_to_String(rarityID: u8): String {
        if (rarityID == 0) {
            utf8(b"Nothing")
        } else if (rarityID == 1) {
            utf8(b"Materials")
        } else if (rarityID == 2) {
            utf8(b"Cosmetics")
        } else if (rarityID == 3) {
            utf8(b"Supra Token")
        } else if (rarityID == 4) {
            utf8(b"Aexis Battle Pass XP")
        } else if (rarityID == 5) {
            utf8(b"Item (organic)")
        } else if (rarityID == 6) {
            utf8(b"Item (basalt)")
        } else if (rarityID == 7) {
            utf8(b"Item (copper)")
        } else if (rarityID == 8) {
           utf8(b"Item (iron)")
        } else if (rarityID == 9) {
            utf8(b"Item (diamond)")
        } else if (rarityID == 10) {
            utf8(b"Item (obsidian)")
        } else if (rarityID == 11) {
            utf8(b"Item (shungite)")
        } 
        else {
            utf8(b"Unknown")
        }
    }

    public fun convert_expeditionID_to_String(expeditionID: u8): String {
        if (expeditionID == 1) {
            utf8(b"Valley")
        } else if (expeditionID == 2) {
            utf8(b"Desert")
        } else if (expeditionID == 3) {
            utf8(b"Frostland")
        } else if (expeditionID == 4) {
            utf8(b"Graveyard")
        } else if (expeditionID == 5) {
            utf8(b"Sea")
        } else if (expeditionID == 6) {
            utf8(b"Underground")
        } 
        else {
            utf8(b"Unknown")
        }
    }

    public fun convert_dungeonID_to_String(dungeonID: u8): String {
        if (dungeonID == 1) {
            utf8(b"The Depths of Hell")
        } else if (dungeonID == 2) {
            utf8(b"Realm of Silent Passing")
        } else if (dungeonID == 3) {
            utf8(b"Crossroads of the Underworld")
        } else if (dungeonID == 4) {
            utf8(b"Void of Eternal Night")
        } else if (dungeonID == 5) {
            utf8(b"Abyssal Shadow Realm")
        } else if (dungeonID == 6) {
            utf8(b"The Blooming Descent")
        } else if (dungeonID == 7) {
            utf8(b"Fields of Eternal Harvest")
        } else if (dungeonID == 8) {
            utf8(b"Vine-Laced Wildlands")
        } else if (dungeonID == 9) {
            utf8(b"Sacred Moonlit Forests")
        } else if (dungeonID == 10) {
            utf8(b"Crossroads of Realms")
        } else if (dungeonID == 11) {
            utf8(b"Battlefield of Eternal Conflict")
        } else if (dungeonID == 12) {
            utf8(b"Citadel of Divine Knowledge")
        } else if (dungeonID == 13) {
            utf8(b"Divine Forge in Volcanic Core")
        } else if (dungeonID == 14) {
            utf8(b"Palace beneath the Ocean")
        } else if (dungeonID == 15) {
            utf8(b"Temple of Solar Harmony")
        } else if (dungeonID == 16) {
            utf8(b"Island of Divine Desire")
        } else if (dungeonID == 17) {
            utf8(b"Nexus of Creation")
        } else if (dungeonID == 18) {
            utf8(b"Mount Olympus")
        } else {
            utf8(b"Unknown")
        }
    }

    public fun convert_raceID_to_String(raceID: u8): String {
        if (raceID == 1) {
            utf8(b"Human")
        } else if (raceID == 2) {
            utf8(b"Orc")
        } else if (raceID == 3) {
            utf8(b"Elf")
        } else if (raceID == 4) {
            utf8(b"Undead")
        } else if (raceID == 5) {
            utf8(b"Celestial")
        } else {
            utf8(b"Unknown")
        }
    }

    public fun convert_perksTypeID_to_String(perkTypeID: u8): String {
        if (perkTypeID == 1) {
            utf8(b"Nature")
        } else if (perkTypeID == 2) {
            utf8(b"Aura")
        } else if (perkTypeID == 3) {
            utf8(b"Arcane")
        } else {
            utf8(b"Unknown")
        }
    }


// ===  ===  ===  ===  ===  ===
// ===   BATCH CONVERTIONS  ===
// ===  ===  ===  ===  ===  ===
    public fun build_values_with_strings(values: vector<Value>): vector<ValueString> {
        let len = vector::length(&values);
        let output = vector::empty<ValueString>();
        let i = 0;
        while (i < len) {
            let value = vector::borrow(&values, i);
            vector::push_back(&mut output, make_string_value(value));
            i = i + 1;
        };
        output
    }

    public fun build_valuesTimes_with_strings(values: vector<ValueTime>): vector<ValueTimeString> {
        let len = vector::length(&values);
        let output = vector::empty<ValueTimeString>();
        let i = 0;
        while (i < len) {
            let value = vector::borrow(&values, i);
            vector::push_back(&mut output, make_string_valueTime(value));
            i = i + 1;
        };
        output
    }


    public fun build_stats_with_strings(stats: vector<Stat>): vector<StatString> {
        let len = vector::length(&stats);
        let output = vector::empty<StatString>();
        let i = 0;
        while (i < len) {
            let stat = vector::borrow(&stats, i);
            vector::push_back(&mut output, make_string_stat(stat));
            i = i + 1;
        };
        output
    }

        public fun build_statsRange_with_strings(statsRange: vector<StatRange>): vector<StatRangeString> {
        let len = vector::length(&statsRange);
        let output = vector::empty<StatRangeString>();
        let i = 0;
        while (i < len) {
            let statRange = vector::borrow(&statsRange, i);
            vector::push_back(&mut output, make_string_stat_range(statRange));
            i = i + 1;
        };
        output
    }


    public fun extract_materials_from_materials(materials: vector<Material>): vector<MaterialString> {
        let len = vector::length(&materials);
        let output = vector::empty<MaterialString>();
        let i = 0;
        while (i < len) {
            let material = vector::borrow(&materials, i);
            if(get_material_ID(material) == 0 || get_material_ID(material) == 1 || get_material_ID(material) == 2 || get_material_ID(material) == 3 || get_material_ID(material) == 4 || get_material_ID(material) == 5 || get_material_ID(material) == 6 || get_material_ID(material) == 7 || get_material_ID(material) == 8) {
                vector::push_back(&mut output, make_material_string(material));
            };
            i = i + 1;
        };
        output
    }

    public fun extract_minerals_from_materials(materials: vector<Material>): vector<MaterialString> {
        let len = vector::length(&materials);
        let output = vector::empty<MaterialString>();
        let i = 0;
        while (i < len) {
            let material = vector::borrow(&materials, i);
            if(get_material_ID(material) == 101 || get_material_ID(material) == 102 || get_material_ID(material) == 103 || get_material_ID(material) == 104 || get_material_ID(material) == 105 || get_material_ID(material) == 106 || get_material_ID(material) == 107 || get_material_ID(material) == 108) {
                vector::push_back(&mut output, make_material_string(material));
            };
            i = i + 1;
        };
        output
    }

    public fun extract_bags_from_materials(materials: vector<Material>): vector<MaterialString> {
        let len = vector::length(&materials);
        let output = vector::empty<MaterialString>();
        let i = 0;
        while (i < len) {
            let material = vector::borrow(&materials, i);
            if(get_material_ID(material) == 201 || get_material_ID(material) == 202 || get_material_ID(material) == 203 || get_material_ID(material) == 204 || get_material_ID(material) == 205 || get_material_ID(material) == 206 || get_material_ID(material) == 207) {
                vector::push_back(&mut output, make_material_string(material));
            };
            i = i + 1;
        };
        output
    }

    public fun build_materials_with_strings(materials: vector<Material>): vector<MaterialString> {
        let len = vector::length(&materials);
        let output = vector::empty<MaterialString>();
        let i = 0;
        while (i < len) {
            let material = vector::borrow(&materials, i);
            vector::push_back(&mut output, make_material_string(material));
            i = i + 1;
        };
        output
    }

    public fun build_materials_with_strings_from_IDs(materialIDs: vector<u8>): vector<String> {
        let len = vector::length(&materialIDs);
        let output = vector::empty<String>();
        let i = 0;
        while (i < len) {
            let material = vector::borrow(&materialIDs, i);
            vector::push_back(&mut output, convert_materialID_to_String(*material));
            i = i + 1;
        };
        output
    }

    public fun build_treasureChance_with_strings_from_Ids(materialIDs: vector<u8>): vector<String> {
        let len = vector::length(&materialIDs);
        let output = vector::empty<String>();
        let i = 0;
        while (i < len) {
            let material = vector::borrow(&materialIDs, i);
            vector::push_back(&mut output, convert_treasureType_to_String(*material));
            i = i + 1;
        };
        output
    }

    public fun build_rewards_with_strings(rewards: vector<Reward>): vector<RewardString> {
        let len = vector::length(&rewards);
        let output = vector::empty<RewardString>();
        let i = 0;
        while (i < len) {
            let reward = vector::borrow(&rewards, i);
            vector::push_back(&mut output, make_string_reward(reward));
            i = i + 1;
        };
        output
    }

    public fun build_rarity_with_strings(rarity: vector<Rarity>): vector<RarityString> {
        let len = vector::length(&rarity);
        let vec = vector::empty<RarityString>();

        while (len > 0){
            let rarity = vector::borrow(&rarity, len-1);
            let _rarity = make_string_rarity(*rarity);
            vector::push_back(&mut vec, _rarity);
            len = len-1 

        };
        move vec
    }
}
