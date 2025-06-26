module deployer::testCore29 {

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

    const VALUE_ID_FIRE: u8 = 1;
    const VALUE_ID_POISON: u8 = 2;
    const VALUE_ID_ICE: u8 = 3;
    const VALUE_ID_LIGHTNING: u8 = 4;
    const VALUE_ID_DARK_MAGIC: u8 = 5;
    const VALUE_ID_WATER: u8 = 6;
    const VALUE_ID_CURSE: u8 = 7;

    const STAT_ID_HEALTH: u8 = 1;
    const STAT_ID_DAMAGE: u8 = 2;
    const STAT_ID_ARMOR: u8 = 3;
    const STAT_ID_ATTACK_SPEED: u8 = 4;

    const CLASS_ID_WARRIOR: u8 = 1;
    const CLASS_ID_ARCHER: u8 = 2;
    const CLASS_ID_MAGE: u8 = 3;
    const CLASS_ID_ASSASSIN: u8 = 4;
    const CLASS_ID_NECROMANCER: u8 = 5;

    const ABILITY_TYPE_PASSIVE: u8 = 1;
    const ABILITY_TYPE_ACTIVE: u8 = 2;
    const ABILITY_TYPE_TOGGLE: u8 = 3;

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
        valueID: u8, isEnemy: bool, value: u8
    }
    struct ValueString has copy,drop,store {
        valueID: u8, name: String, isEnemy: bool, value: u8
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
        entityID: u8, entityStatsMulti: u16, entityName: String, entityType: String, location: String
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
        id: u8, name: String, bossName: String, entitiesName: vector<String>, rewards: vector<MaterialString>
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
        perkID: u64, name: String, typeID: u8, stamina: u8, damage:u32, values: vector<Value>
    }
    struct PerkString has copy, drop, key, store{
        perkID: u64, name: String, typeID: u8, typeName: String, stamina: u8, damage:u32, values: vector<ValueString>
    }
// Reward
    struct Reward has copy, drop, key, store{
        materialID: u8, amount: u32, period: u64
    }
    struct RewardString has copy, drop, key, store{
        materialName: String, amount: u32, period: u64
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

// Entity
    //makes
        public fun make_entity(entityID: u8, entityStatsMulti: u16, entityName: String, entityType: String, entityLocation: String,): Entity {
            Entity { entityID: entityID, entityStatsMulti: entityStatsMulti, entityName: entityName, entityType: entityType, location: entityLocation, }
        }
    //gets
        public fun get_entity_name(entity: &Entity): String {
            entity.entityName
        }

        public fun get_entity_statsMulti(entity: &Entity): u16 {
            entity.entityStatsMulti
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
        public fun make_value(id: u8, isEnemy: bool, val: u8): Value {
            Value { valueID: id, isEnemy: isEnemy, value: val }
        }

        public fun make_string_value(value: &Value): ValueString {
            ValueString { valueID: value.valueID, name: convert_valueID_to_String(value.valueID), isEnemy: value.isEnemy, value: value.value}
        }

    //changes
        public fun change_value_amount(value: &mut Value, amount: u8): Value {
            value.value = amount;
            *value
        }
        
        public fun change_value_value(value: &mut Value, val: u8): ValueString {
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

        public fun get_value_value(value: &Value): u8 {
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


    //degrades
        public fun degrade_string_value_to_value(valueString: &ValueString): Value {
            Value { valueID: valueString.valueID, isEnemy: valueString.isEnemy, value: valueString.value }
        }

    //multiples
        public fun make_multiple_values(valueIDs: vector<u8>, isEnemy: vector<bool>, values: vector<u8>): vector<Value> {
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

        public fun get_expedition_rewards(expedition: &mut Expedition): vector<Reward>{
                expedition.rewards
            }


// Dungeon
    //makes
        public fun make_dungeon(id: u8, bossID: u8, entitiesID: vector<u8>, rewards: vector<Material>): Dungeon {
            Dungeon { id: id, bossID: bossID, entitiesID: entitiesID, rewards: rewards}
        }
        
        public fun make_string_dungeon(dungeon: Dungeon, bossName: String, entitiesName: vector<String>): DungeonString {
            DungeonString { id: dungeon.id, name: convert_dungeonID_to_String(dungeon.id), bossName: bossName, entitiesName: entitiesName, rewards: build_materials_with_strings(dungeon.rewards)}
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
        public fun make_perk(perkID: u64, name: String, typeID: u8, stamina: u8, damage: u32, values: vector<Value>): Perk {
            Perk { perkID: perkID, name: name, typeID: typeID, stamina: stamina, damage:damage, values: values }
        }
        public fun make_string_perk(perk: &Perk): PerkString{
            PerkString { perkID: perk.perkID, name: perk.name, typeID: perk.typeID, typeName: convert_perksTypeID_to_String(perk.typeID), stamina: perk.stamina, damage:perk.damage, values: build_values_with_strings(perk.values) }
        }

    //changes
        public fun change_perk_stamina(perk: &mut Perk, new_stamina: u8) {
            perk.stamina = new_stamina
        }
        public fun change_perk_damage(perk: &mut Perk, new_damage: u32) {
            perk.damage = new_damage
        }

    //gets
        public fun get_perk_id(perk: &Perk): u64 {
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
            perk.stamina
        }
        public fun get_perk_damage(perk: &Perk): u32 {
            perk.damage
        }
        public fun get_perk_values(perk: &Perk): vector<Value> {
            perk.values
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

// ===  ===  ===  ===  === 
// ===     CONVERTS    ===
// ===  ===  ===  ===  ===
    public fun convert_valueID_to_String(valueID: u8): String {
        if (valueID == VALUE_ID_FIRE) {
            utf8(b"fire")
        } else if (valueID == VALUE_ID_POISON) {
            utf8(b"poison")
        } else if (valueID == VALUE_ID_ICE) {
            utf8(b"ice")
        } else if (valueID == VALUE_ID_LIGHTNING) {
            utf8(b"lightning")
        } else if (valueID == VALUE_ID_DARK_MAGIC) {
            utf8(b"dark magic")
        } else if (valueID == VALUE_ID_WATER) {
            utf8(b"water")
        } else if (valueID == VALUE_ID_CURSE) {
            utf8(b"curse")
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
            utf8(b"Attack_Speed")
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

    public fun convert_materialID_to_String(materialID: u8): String {
        if (materialID == 1) {
            utf8(b"Gold")
        } else if (materialID == 2) {
            utf8(b"Essence")
        } else if (materialID == 3) {
            utf8(b"Organic")
        } else if (materialID == 4) {
            utf8(b"Leather")
        } else if (materialID == 5) {
            utf8(b"Stone")
        } else if (materialID == 6) {
            utf8(b"Flint")
        } else if (materialID == 7) {
            utf8(b"Basalt")
        } else if (materialID == 8) {
            utf8(b"Bones")
        } else if (materialID == 9) {
            utf8(b"Iron")
        } else if (materialID == 10) {
            utf8(b"Obsidian")
        } else if (materialID == 11) {
            utf8(b"Diamond")
        } else if (materialID == 12) {
            utf8(b"Shungite")
        } 
        else {
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
            utf8(b"Sword")
        } else if (typeID == 6) {
            utf8(b"Shield")
        } else if (typeID == 7) {
            utf8(b"Bow")
        } else if (typeID == 8) {
            utf8(b"Arrow")
        } else if (typeID == 9) {
            utf8(b"Wand")
        } else if (typeID == 10) {
            utf8(b"Book")
        } else if (typeID == 11) {
            utf8(b"Scyth")
        } else if (typeID == 12) {
            utf8(b"Lantern")
        } else if (typeID == 13) {
            utf8(b"Dagger")
        } else if (typeID == 14) {
            utf8(b"Amulet")
        } else if (typeID == 15) {
            utf8(b"Cape")
        } else if (typeID == 16) {
            utf8(b"Ring")
        } 
        else {
            utf8(b"Unknown")
        }

    }

    public fun convert_rarityID_to_String(rarityID: u8): String {
        if (rarityID == 1) {
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
            utf8(b"Celestial")
        } else if (raceID == 5) {
            utf8(b"Undead")
        } else {
            utf8(b"Unknown")
        }
    }

    public fun convert_perksTypeID_to_String(perkTypeID: u8): String {
        if (perkTypeID == 1) {
            utf8(b"Offensive")
        } else if (perkTypeID == 2) {
            utf8(b"Defensive")
        } else if (perkTypeID == 3) {
            utf8(b"Utility")
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
