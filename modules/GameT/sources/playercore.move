module deployer::testPlayerCore {

    use std::debug::print;
    use std::string::{String, utf8};
    use std::timestamp;
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;
    use supra_framework::event;

    friend deployer::testCore31;

    use deployer::testCore31 as Core;

// ===  ===  ===  ===  ===
// ===     STRUCTS     ===
// ===  ===  ===  ===  ===

    struct Expedition has copy, drop, store, key {
        id: u8, required_level: u8, costs: vector<Reward>, rewards: vector<Reward>
    }    
    struct ExpeditionString has copy, drop, store, key {
        id: u8, name: String, required_level: u8, costs: vector<RewardString>, rewards: vector<RewardString>
    }    
// DungeonPlayer
    struct DungeonPlayer has copy, drop, store, key {
        entityiD: u8, hpleft: u64;
    }   
// CraftingPlayer
    struct Crafting has copy,store,drop,key {
        end: u64, typeID: u8, materialID: u8,
    }

    struct CraftingString has copy,store,drop,key {
        end: u64, typeID: String, materialID: String, isFinished: bool
    }

// ===  ===  ===  ===  === ===
// ===  Factory Functions  ===
// ===  ===  ===  ===  === ===
// DungeonPlayer
    //makes
        public fun make_dungeonPlayer(id: u8, hp: u64): DungeonPlayer {
            Dungeon { id: id, hpleft: u64}
        }
    //changes
        public fun change_dungeonPlayer_hpleft(dungeon: &DungeonPlayer, u64: new_hpleft) {
            dungeon.hpleft = new_hpleft;
        }
    //gets
        public fun get_dungeonPlayer_id(dungeon: &DungeonPlayer): u8 {
            dungeon.id
        }
        public fun get_dungeonPlayer_hpleft(dungeon: &DungeonPlayer): u64{
            dungeon.hpleft
        }
// CraftingPlayer
    //makes
        public fun make_crafting(start: u64, typeID: u8, materialID: u8): Crafting {
            Crafting { start: start, typeID: typeID,materialID: materialID}
        }
        public fun make_crafting_string(crafting: &Crafting, status: bool): CraftingString {
            CraftingString { start: crafting.start, typeID: Core::convert_typeID_to_String(crafting.typeID), materialName: convert_materialID_to_String(crafting.materialID), isFinished: status}
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
// ===  ===  ===  ===  ===  ===
// ===   BATCH CONVERTIONS  ===
// ===  ===  ===  ===  ===  ===

}
