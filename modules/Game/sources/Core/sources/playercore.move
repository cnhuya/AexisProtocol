module deployer::testPlayerCore1 {

    use std::debug::print;
    use std::string::{String, utf8};
    use std::timestamp;
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;

    use deployer::testCore33 as Core;

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
// ===  ===  ===  ===  ===  ===
// ===   BATCH CONVERTIONS  ===
// ===  ===  ===  ===  ===  ===

}
