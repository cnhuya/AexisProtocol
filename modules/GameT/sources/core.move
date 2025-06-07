module deployer::testCore2 {

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

    // === Structs ===
    struct Stat has copy, drop, store{
        statID: u8, value: u64
    }

    struct StatList has copy, drop, store, key{
        list: vector<Stat>
    }


    struct StatString has copy {
        name: String, value: u64
    }

    struct StatRange has copy,drop,store {
        statID: u8, min: u64, max: u64
    }

    struct StatRangeString has copy {
        name: String, min: u64, max: u64
    }

    struct Value has copy, drop,store {
        valueID: u8, isEnemy: bool, value: u8
    }

    struct ValueList has copy, drop, store, key{
        list: vector<Value>
    }
    struct ValueString has copy, drop {
        name: String, isEnemy: bool, value: u8
    }

    struct Type has copy, drop,store {
        name: String, stat_multi: u16
    }

    struct Location has copy, drop,store {
        name: String, stat_multi: u16
    }

    struct Entity has copy,drop,store {
        entityID: u8, entityName: String, entityType: String, location: String
    }
    // === Factory Functions ===
    // Entity
    public fun make_entity(entityID: u8, entityName: String, entityType: String, entityLocation: String): Entity {
        Entity { entityID: entityID, entityName: entityName, entityType: entityType, location: entityLocation }
    }

    // Value
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

    public fun make_string_value(value: Value): ValueString {
        ValueString { name: convert_valueID_to_String(value.valueID), isEnemy: value.isEnemy, value: value.value}
    }

    // Stat
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

    public fun make_string_stat(stat: Stat): StatString {
        StatString { name: convert_statID_to_String(stat.statID), value: stat.value}
    }

    public fun make_range_stat(id: u8, min: u64, max: u64): StatRange {
        StatRange { statID: id, min: min, max: max }
    }

    public fun make_string_stat_range(stat: StatRange): StatRangeString {
        StatRangeString { name: convert_statID_to_String(stat.statID),  min: stat.min, max: stat.max}
    }

    // Type
    public fun make_type(name: String, stat_multi: u16): Type {
        Type { name: name, stat_multi: stat_multi }
    }

    // Location
    public fun make_location(name: String, stat_multi: u16): Location {
        Location { name: name, stat_multi: stat_multi }
    }

    // === Converters ===
    fun convert_valueID_to_String(valueID: u8): String {
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

    fun convert_statID_to_String(statID: u8): String {
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

    fun convert_ability_typeID_to_String(typeID: u8): String {
        if (typeID == ABILITY_TYPE_PASSIVE) {
            utf8(b"Passive")
        } else if (typeID == ABILITY_TYPE_ACTIVE) {
            utf8(b"Active")
        } else {
            abort(UNKNOWN_ABILITY_TYPE)
        }
    }

    fun convert_classID_to_String(classID: u8): String {
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

    // === Batch Conversion ===
    public fun build_values_with_strings(values: vector<Value>): vector<ValueString> {
        let len = vector::length(&values);
        let output = vector::empty<ValueString>();
        let i = 0;
        while (i < len) {
            let value = *vector::borrow(&values, i);
            vector::push_back(&mut output, make_string_value(value));
            i = i + 1;
        };
        output
    }
}
