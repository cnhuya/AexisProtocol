module deployer::testCore20 {

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
    struct StatList has copy, drop, store, key{
        list: vector<Stat>
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

    struct ValueList has copy, drop, store, key{
        list: vector<Value>
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
        entityID: u8, entityName: String, entityType: String, location: String
    }
// Material
    struct Material has copy, key, store, drop {
        materialID: u8, amount: u16
    }

    struct MaterialList has copy, drop, store, key{
        list: vector<Material>
    }


    struct MaterialString has copy, key, store, drop {
        materialID: u8, materialName: String, amount: u16
    }

// Expedition 
    struct Expedition has copy, drop, store, key {
        id: u8, required_level: u8, costs: vector<Material>, rewards: vector<Material>
    }    
    struct ExpeditionString has copy, drop, store, key {
        id: u8, name: String, required_level: u8, costs: vector<MaterialString>, rewards: vector<MaterialString>
    }    
// Dungeon
    struct Dungeon has copy, drop, store, key {
        id: u8, entityID: u8, floors: vector<Floor>, rewards: vector<Material>
    }    
    struct DungeonString has copy, drop, store, key {
        id: u8, entityName: String, name: String, floors: vector<Floor>, rewards: vector<MaterialString>
    }   
    // floors arent needed? cuz the entities already have type (eg. titan)? so i can create a function that fetches all titans in certain dung
    struct FloorList has copy, drop, store, key{
        list: vector<Floor>
    }
    struct Floor has copy, drop, store, key {
        id: u8, entityName: String,
    }   
// Rarity    
    struct Rarity has copy, store, drop, key {
        rarityID: u8, chance: u8, multi: u16, number_of_values:u8
    }

    struct RarityString has copy, store, drop, key {
        rarityID: u8, rarityName: String, chance:u8, multi: u16, number_of_values: u8
    }
// ===  ===  ===  ===  === ===
// ===  Factory Functions  ===
// ===  ===  ===  ===  === ===
// Material

    public fun get_material_list(address: &signer): vector<Material> acquires MaterialList{
        let material_list = borrow_global_mut<MaterialList>(signer::address_of(address));
        material_list.list
    }

    public fun extract_material_list(address: &signer): vector<Material> acquires MaterialList {
        let material_list = borrow_global_mut<MaterialList>(signer::address_of(address));
        let extracted_list = material_list.list;
        material_list.list = vector::empty<Material>();
        extracted_list
    }

    public entry fun register_material(address: &signer, id: u8, val: u16) acquires MaterialList{
        let material = make_material(id, val);

        if (!exists<MaterialList>(signer::address_of(address))) {
          move_to(address, MaterialList { list: vector::empty()});
        };

        let material_list = borrow_global_mut<MaterialList>(signer::address_of(address));
        vector::push_back(&mut material_list.list, material);
    }

    public fun make_material(materialID: u8, amount: u16): Material {
        Material { materialID: materialID, amount: amount}
    }



    public fun change_material_amount(material: &mut Material, amount: u16): Material {
        material.amount = amount;
        *material
    }


    public fun get_material_ID(material: &Material): u8{
        material.materialID
    }

    public fun get_material_amount(material: &Material): u16{
        material.amount
    }

    public fun make_material_string(material: &Material): MaterialString {
        MaterialString { materialID: material.materialID, materialName: convert_materialID_to_String(material.materialID), amount: material.amount}
    }

    public fun degrade_string_materialString_to_material(materialString: &MaterialString): Material {
        Material { materialID: materialString.materialID, amount: materialString.amount}
    }

// Entity
    public fun make_entity(entityID: u8, entityName: String, entityType: String, entityLocation: String): Entity {
        Entity { entityID: entityID, entityName: entityName, entityType: entityType, location: entityLocation }
    }

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

    public fun get_value_list(address: &signer): vector<Value> acquires ValueList{
        let value_list = borrow_global_mut<ValueList>(signer::address_of(address));
        value_list.list
    }

    public fun extract_value_list(address: &signer): vector<Value> acquires ValueList {
        let value_list = borrow_global_mut<ValueList>(signer::address_of(address));
        let extracted_list = value_list.list;
        value_list.list = vector::empty<Value>();
        extracted_list
    }


    public entry fun register_value(address: &signer, id: u8, isEnemy: bool, val: u8) acquires ValueList{
        let value = make_value(id,isEnemy,val);

        if (!exists<ValueList>(signer::address_of(address))) {
          move_to(address, ValueList { list: vector::empty()});
        };

        let value_list = borrow_global_mut<ValueList>(signer::address_of(address));
        vector::push_back(&mut value_list.list, value);
    }

    public fun make_value(id: u8, isEnemy: bool, val: u8): Value {
        Value { valueID: id, isEnemy: isEnemy, value: val }
    }

    public fun change_value_amount(value: &mut Value, amount: u8): Value {
        value.value = amount;
        *value
    }

    public fun get_value_ID(value: &Value): u8 {
        value.valueID
    }

    public fun get_value_isEnemy(value: &Value): bool {
        value.isEnemy
    }

    public fun get_value_value(value: &Value): u8 {
        value.value
    }

    public fun change_value_value(value: &mut Value, val: u8): ValueString {
        value.value = val;
        make_string_value(&*value)
    }

    public fun make_string_value(value: &Value): ValueString {
        ValueString { valueID: value.valueID, name: convert_valueID_to_String(value.valueID), isEnemy: value.isEnemy, value: value.value}
    }

    public fun degrade_string_value_to_value(valueString: &ValueString): Value {
        Value { valueID: valueString.valueID, isEnemy: valueString.isEnemy, value: valueString.value }
    }

// Stat

    public fun get_stat_list(address: &signer): vector<Stat> acquires StatList {
        let stat_list = borrow_global_mut<StatList>(signer::address_of(address));
        stat_list.list
    }

    public fun extract_stat_list(address: &signer): vector<Stat> acquires StatList {
        let stat_list = borrow_global_mut<StatList>(signer::address_of(address));
        let extracted_list = stat_list.list;
        stat_list.list = vector::empty<Stat>();
        extracted_list
    }

    public entry fun register_stat(address: &signer, id: u8, val: u64) acquires StatList{
        let stat = make_stat(id, val);

        if (!exists<StatList>(signer::address_of(address))) {
          move_to(address, StatList { list: vector::empty()});
        };

        let stat_list = borrow_global_mut<StatList>(signer::address_of(address));
        vector::push_back(&mut stat_list.list, stat);
    }

    public fun make_stat(id: u8, val: u64): Stat {
        Stat { statID: id, value: val }
    }
    
    public fun change_stat_amount(stat: &mut Stat, value: u64): Stat {
        stat.value = value;
        *stat
    }

    public fun get_stat_ID(stat: &Stat): u8 {
        stat.statID
    }

    public fun get_stat_value(stat: &Stat): u64 {
        stat.value
    }

    public fun change_stat_value(stat: &mut Stat, val: u64): StatString {
        stat.value = val;
        make_string_stat(&*stat)
    }

    public fun make_string_stat(stat: &Stat): StatString {
        StatString { statID: stat.statID, name: convert_statID_to_String(stat.statID), value: stat.value}
    }
    public fun degrade_string_stat_to_stat(statRange: &StatString): Stat {
        Stat { statID: statRange.statID,  value: statRange.value}
    }

    public fun make_range_stat(id: u8, min: u64, max: u64): StatRange {
        StatRange { statID: id, min: min, max: max }
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

    public fun change_statRange_min(statRange: &mut StatRange, min: u64)  {
        statRange.min = min
    }

    public fun change_statRange_max(statRange: &mut StatRange, max: u64) {
        statRange.max = max
    }

    public fun make_string_stat_range(stat: &StatRange): StatRangeString {
        StatRangeString { statID: stat.statID, name: convert_statID_to_String(stat.statID),  min: stat.min, max: stat.max}
    }

    public fun degrade_string_statRange_to_statRange(statRangeString: &StatRangeString): StatRange {
        StatRange { statID: statRangeString.statID,  min: statRangeString.min, max: statRangeString.max}
    }

// Type
    public fun make_type(name: String, stat_multi: u16): Type {
        Type { name: name, stat_multi: stat_multi }
    }

    public fun get_type_name(type: &Type): String {
        type.name
    }

    public fun get_type_multi(type: &Type): u16 {
        type.stat_multi
    }

    public fun set_type_multi(type: &mut Type, value: u16) {
        type.stat_multi = value;
    }

// Location
    public fun make_location(name: String, stat_multi: u16): Location {
        Location { name: name, stat_multi: stat_multi }
    }

    public fun get_location_name(type: &Location): String {
        type.name
    }

    public fun get_location_multi(type: &Location): u16 {
        type.stat_multi
    }

    public fun set_location_multi(type: &mut Location, value: u16) {
        type.stat_multi = value;
    }
// Expedition
    public fun make_expedition(id: u8, required_level: u8, costs: vector<Material>, rewards: vector<Material>): Expedition {
        Expedition { id: id, required_level: required_level, costs: costs, rewards:rewards}
    }

    public fun make_string_expedition(expedition: &Expedition): ExpeditionString {
        ExpeditionString { id: expedition.id, name: convert_expeditionID_to_String(expedition.id), required_level: expedition.required_level, costs: build_materials_with_strings(expedition.costs), rewards:build_materials_with_strings(expedition.rewards) }
    }

    public fun get_expedition_ID(expedition: &Expedition): u8 {
        expedition.id
    }

    public fun get_expedition_required_level(expedition: &Expedition): u8 {
        expedition.required_level
    }

    public fun get_expedition_costs(expedition: &Expedition): vector<Material> {
        expedition.costs
    }


    public fun change_expedition_costs(address: &signer, expedition: &mut Expedition): Expedition acquires MaterialList{
        expedition.costs = extract_material_list(address);
        *expedition
    }

    public fun get_expedition_rewards(expedition: &mut Expedition): vector<Material>{
        expedition.rewards
    }

    public fun change_expedition_rewards(address: &signer, expedition: &mut Expedition): Expedition acquires MaterialList{
        expedition.rewards = extract_material_list(address);
        *expedition
    }

    public fun change_expedition_required_level(expedition: &mut Expedition, required_level: u8 ): Expedition {
        expedition.required_level = required_level;
        *expedition
    }
// Dungeon
    public fun make_dungeon(id: u8, entityID:u8, floor: vector<Floor>, rewards: vector<Material>): Dungeon {
        Dungeon { id: id, entityID: entityID, floors: floor, rewards:rewards}
    }

    public fun make_string_dungeon(dungeon: Dungeon, entityName:String): DungeonString {
        DungeonString { id: dungeon.id, entityName: entityName, name: convert_dungeonID_to_String(dungeon.id), floors: dungeon.floors, rewards: build_materials_with_strings(dungeon.rewards)}
    }

    public fun get_dungeon_ID(dungeon: &Dungeon): u8 {
        dungeon.id
    }

    public fun change_dungeon_floors(address: &signer, dungeon: &mut Dungeon): Dungeon acquires FloorList{
        dungeon.floors = extract_floor_list(address);
        *dungeon
    }

    public fun get_dungeon_floors(dungeon: &Dungeon): vector<Floor> {
        dungeon.floors
    }

    public fun change_dungeon_rewards(address: &signer, dungeon: &mut Dungeon): Dungeon acquires MaterialList{
        dungeon.rewards = extract_material_list(address);
        *dungeon
    }

    public fun get_dungeon_rewards(dungeon: &mut Dungeon): vector<Material>{
        dungeon.rewards
    }

// Floor

    public fun make_floor(id: u8, entityName: String): Floor {
        Floor { id: id, entityName: entityName}
    }


    public fun get_floor_list(address: &signer): vector<Floor> acquires FloorList{
        let floor_list = borrow_global_mut<FloorList>(signer::address_of(address));
        floor_list.list
    }

    public fun extract_floor_list(address: &signer): vector<Floor> acquires FloorList {
        let floor_list = borrow_global_mut<FloorList>(signer::address_of(address));
        let extracted_list = floor_list.list;
        floor_list.list = vector::empty<Floor>();
        extracted_list
    }

    public entry fun register_floor(address: &signer, id: u8, entityName: String) acquires FloorList{
        if (!exists<FloorList>(signer::address_of(address))) {
          move_to(address, FloorList { list: vector::empty()});
        };
        let floor = make_floor(id, entityName);

        let floor_list = borrow_global_mut<FloorList>(signer::address_of(address));
        vector::push_back(&mut floor_list.list, floor);
    }
// Rarity


    public fun make_rarity(id: u8, chance: u8, multi: u16, number_of_values: u8): Rarity {
        Rarity { rarityID: id, chance: chance, multi: multi, number_of_values: number_of_values}
    }

    public fun get_rarity_id(rarity: Rarity): u8 {
        rarity.rarityID
    }

    public fun get_rarity_chance(rarity: Rarity): u8 {
        rarity.chance
    }
    public fun change_rarity_chance(rarity: &mut Rarity, new_chance: u8): Rarity {
        rarity.chance = new_chance;
        *rarity

    }

    public fun get_rarity_multi(rarity: Rarity): u16 {
        rarity.multi
    }
    
    public fun change_rarity_multi(rarity: &mut Rarity, new_multi: u16): Rarity {
        rarity.multi = new_multi;
        *rarity

    }


    public fun get_rarity_number_of_values(rarity: Rarity): u8 {
        rarity.number_of_values
    }
    

    public fun make_string_rarity(rarity: Rarity): RarityString{
        RarityString {rarityID: rarity.rarityID, rarityName: convert_rarityID_to_String(rarity.rarityID), chance: rarity.chance, multi: rarity.multi, number_of_values: rarity.number_of_values}
    }

    public fun degrade_stringRarity_to_rarity(rarityString: RarityString): Rarity{
        Rarity { rarityID: rarityString.rarityID, chance: rarityString.chance, multi: rarityString.multi, number_of_values: rarityString.number_of_values}
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

  /*  public fun change_material_amount(materials: v    ector<Material>, id:u8, amount: u16): Material {
        let len = vector::length(&materials);
        let i = 0;
        while (i < len) {
            let material = vector::borrow_mut(&mut materials, i);
            if(get_material_ID(material) == id){
                material.amount = amount;
                return *material
            }
        };
        abort(1)
    }*/
}
