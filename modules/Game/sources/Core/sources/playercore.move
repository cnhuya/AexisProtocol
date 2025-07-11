module deployer::testPlayerCore5 {

    use std::debug::print;
    use std::string::{String, utf8};
    use std::timestamp;
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;

    use deployer::testCore39 as Core;

// ===  ===  ===  ===  ===
// ===     STRUCTS     ===
// ===  ===  ===  ===  === 
// DungeonPlayer
    struct DungeonPlayer has copy, drop, store, key {
        entityID: u8, hpleft: u64
    }   
// CraftingPlayer
    struct Crafting has copy,store,drop,key {
        end: u64, typeID: u8, materialID: u8,
    }

    struct CraftingString has copy,store,drop,key {
        end: u64, typeName: String, materialName: String, isFinished: bool
    }

// StatsPlayer
    struct StatPlayer has copy, drop, store{
        statName: String, value: u64, bonus: u64
    } 

// Examine
    struct Examine has copy, drop, store{
        start: u64, value: u64, type: u8, speed_type: u8
    }     

    struct ExamineString has copy, drop, store{
        start: u64, value: u64, type: String, speed_type: String, isFinished: bool
    }     

// ===  ===  ===  ===  === ===
// ===  Factory Functions  ===
// ===  ===  ===  ===  === ===
// DungeonPlayer
    //makes
        public fun make_dungeonPlayer(id: u8, hp: u64): DungeonPlayer {
            DungeonPlayer { entityID: id, hpleft: hp}
        }
    //changes
        public fun change_dungeonPlayer_hpleft(dungeon: &mut DungeonPlayer, new_hpleft: u64) {
            dungeon.hpleft = new_hpleft;
        }
    //gets
        public fun get_dungeonPlayer_entityID(dungeon: &DungeonPlayer): u8 {
            dungeon.entityID
        }
        public fun get_dungeonPlayer_hpleft(dungeon: &DungeonPlayer): u64{
            dungeon.hpleft
        }
// CraftingPlayer
    //makes
        public fun make_crafting(end: u64, typeID: u8, materialID: u8): Crafting {
            Crafting { end: end, typeID: typeID,materialID: materialID}
        }
        public fun make_crafting_string(crafting: &Crafting, status: bool): CraftingString {
            CraftingString { end: crafting.end, typeName: Core::convert_typeID_to_String(crafting.typeID), materialName: Core::convert_materialID_to_String(crafting.materialID), isFinished: status}
        }
    //gets
        public fun get_crafting_end(crafting: &Crafting): u64 {
            crafting.end
        }
        public fun get_crafting_typeID(crafting: &Crafting): u8 {
            crafting.typeID
        }
        public fun get_crafting_materialID(crafting: &Crafting): u8 {
            crafting.materialID
        }
        public fun get_craftingString_Status(crafting: &CraftingString): bool {
            crafting.isFinished
        }
// StatsPlayer
    //makes
        public fun make_statPlayer(statName: String, value: u64, bonus: u64): StatPlayer {
            StatPlayer { statName: statName, value: value, bonus: bonus}
        }
    //gets
        public fun get_statPlayer_statName(statPlayer: &StatPlayer): String {
            statPlayer.statName
        }
        public fun get_statPlayer_value(statPlayer: &StatPlayer): u64 {
            statPlayer.value
        }
        public fun get_statPlayer_bonus(statPlayer: &StatPlayer): u64 {
            statPlayer.bonus
        }   
// Examine
    //makes
        public fun make_examine(start: u64, value: u64, type: u8, speed_type: u8): Examine {
            Examine { start: start, value: value, type: type, speed_type: speed_type}
        }
        public fun make_examineString(examine: &Examine,status: bool): ExamineString {
            ExamineString { start: examine.start, value: examine.value, type: convert_examineType_to_String(examine.type), speed_type: convert_examineSpeedType_to_String(examine.speed_type), isFinished: status}
        }
    //gets
        public fun get_examine_start(examine: &Examine): u64 {
            examine.start
        }
        public fun get_examine_value(examine: &Examine): u64 {
            examine.value
        }
        public fun get_examine_type(examine: &Examine): u8 {
            examine.type
        } 
        public fun get_examine_speed_type(examine: &Examine): u8 {
            examine.speed_type
        } 
    //change
        public fun change_examine_value(examine: &mut Examine, new_value: u64){
            examine.value = new_value;
        }      
// ===  ===  ===  ===  ===  ===
// ===   BATCH CONVERTIONS  ===
// ===  ===  ===  ===  ===  ===

// ===  ===  ===  ===  === 
// ===     CONVERTS    ===
// ===  ===  ===  ===  ===
    public fun convert_examineSpeedType_to_String(examineType: u8): String {
        if (examineType == 1) {
            utf8(b"Slow")
        } else if (examineType == 2) {
            utf8(b"Medium")
        } else if (examineType == 3) {
            utf8(b"Fast")
        } else {
            abort(000)
        }
    }

    public fun convert_examineType_to_String(examineType: u8): String {
        if (examineType == 1) {
            utf8(b"Stone Examination")
        } else if (examineType == 2) {
            utf8(b"Gem Dust Making")
        } else {
            abort(000)
        }
    }
}
