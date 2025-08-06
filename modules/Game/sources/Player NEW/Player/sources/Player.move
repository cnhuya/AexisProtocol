module new_dev::test1234{

    use std::debug::print;
    use std::string::{Self as Str,String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;

    //core
    use deployer::testCore45::{Self as Core, Stat, Material, Item, ItemString, Value, ValueString, MaterialString, Expedition };
    use deployer::testPlayerCore11::{Self as PlayerCore,DungeonPlayer,Crafting,CraftingString,StatPlayer, ExamineString, Examine, Oponent, ExpeditionPlayer, ExpeditionPlayerString, PerksUsage};



// Structs

    struct PlayerDatabase has copy,store,drop,key {database: vector<Player>}
    struct PlayerString has copy, store, drop, key {id: u64, name: String, className: String, raceName: String, hash: u64, level: u8, xp: u32, required_xp: u32, stats: vector<StatPlayer>, elements: vector<ValueString>, materials: vector<MaterialString>, minerals: vector<MaterialString>,bags: vector<MaterialString>, perksID: vector<u16>, inventory: vector<ItemString>, equip: vector<ItemString>,crafting: vector<CraftingString>, examinations: vector<ExamineString>, dungeon: DungeonPlayer, expedition: ExpeditionPlayerString, power: u32, oponent: Oponent, status: String}
    struct Player has copy, store, drop ,key {id: u64, name: String, classID: u8, raceID: u8, hash: u64, stats: vector<Stat>, elements: vector<Value>, materials: vector<Material>, perksID: vector<u16>, inventory: vector<Item>, equip: vector<Item>, crafting: vector<Crafting>, examinations: vector<Examine>, dungeon: DungeonPlayer, expedition: ExpeditionPlayer, oponent: Oponent, status: u8}




// Make
    fun make_player(name: String, classID: u8, raceID: u8): Player  {
        Player { id:0, name: name, classID: classID, raceID: raceID, hash: 1, stats: vector::empty<Stat>(), elements: vector::empty<Value>(), materials: vector::empty<Material>(), perksID: vector::empty<u16>(), inventory: vector::empty<Item>(), equip: vector::empty<Item>(),crafting: vector::empty<Crafting>(), examinations: vector::empty<Examine>(), dungeon: PlayerCore::make_dungeonPlayer(1,0), expedition: PlayerCore::make_empty_expeditionPlayer(), oponent: PlayerCore::make_empty_oponent(), status: 0}
    }

    fun make_playerString(player: &Player, level: u8, xp: u32, required_xp: u32, stats: vector<StatPlayer>, crafting: vector<CraftingString>, power: u32, exams: vector<ExamineString>): PlayerString  {
        PlayerString { id: player.id, name: player.name, className: Core::convert_classID_to_String(player.classID), raceName: Core::convert_raceID_to_String(player.raceID), level: level,xp: xp, required_xp: required_xp, hash: 1, stats: stats, elements: Core::build_values_with_strings(player.elements),materials: Core::extract_materials_from_materials(player.materials), minerals: Core::extract_minerals_from_materials(player.materials), bags: Core::extract_bags_from_materials(player.materials), perksID: player.perksID, inventory: Core::make_multiple_string_items(player.inventory), crafting: crafting, examinations: exams, equip:  Core::make_multiple_string_items(player.equip), dungeon: player.dungeon, expedition: PlayerCore::make_expeditionPlayerString(&player.expedition), power: power, oponent: player.oponent, status: utf8(b"test")}
    }


// View Functions
        public fun viewCrafting(player: Player): vector<CraftingString> {
            let crafting = player.crafting;
            let len = vector::length(&crafting);
            let vect = vector::empty<CraftingString>();
            let crafting_string: CraftingString;
            while(len > 0){
                let craft = vector::borrow(&crafting, len-1);

                if(PlayerCore::get_crafting_end(craft) > timestamp::now_seconds()){
                    crafting_string = PlayerCore::make_crafting_string(craft, true);
                } else{
                    crafting_string = PlayerCore::make_crafting_string(craft, false);
                };

                vector::push_back(&mut vect, crafting_string);
                len=len-1;
            };
            move vect
        }
    
        public fun viewExamine(player: Player): vector<ExamineString>  {
            let examinations = player.examinations;
            let len = vector::length(&examinations);
            let vect = vector::empty<ExamineString>();
            let crafting_string: ExamineString;
            while(len > 0){
                let examine = vector::borrow(&examinations, len-1);

                if(PlayerCore::get_examine_start(examine) > timestamp::now_seconds()){
                    crafting_string = PlayerCore::make_examineString(examine, true);
                } else{
                    crafting_string = PlayerCore::make_examineString(examine, false);
                };

                vector::push_back(&mut vect, crafting_string);
                len=len-1;
            };
            move vect
        }

        #[view]
        public fun viewHeroes(address: address): vector<PlayerString> acquires PlayerDatabase {
            let player_db = borrow_global<PlayerDatabase>(address);
            let len = vector::length(&player_db.database);
            let vect = vector::empty<PlayerString>();
            while(len>0)    {
                let player = vector::borrow(&player_db.database, len-1);
                let (level, xp) = viewHeroLevel(*player);
                let _player = make_playerString(player, level, xp, required_xp(level+1), viewPlayerStats(*player), viewCrafting(*player),calculate_power(player), viewExamine(*player));
                vector::push_back(&mut vect, _player);
                len=len-1;
            };
            move vect
        }

        #[view]
        public fun viewHero(address: address, name: String): PlayerString acquires PlayerDatabase {
            let heroes = viewHeroes(address);
            let len = vector::length(&heroes);
            while(len>0) {
                let player = vector::borrow(&heroes, len-1);
                if(player.name == name){
                    return *player
                };
                len=len-1;
            };
            abort(0101)
        }

        public fun viewHeroLevel(player: Player): (u8,u32)  {
            let len = vector::length(&player.materials);
            while(len>0) {
                let material = vector::borrow(&player.materials, len-1);
                if(Core::get_material_ID(material) == 0){
                    let value = Core::get_material_amount(material);
                    return calculate_level(value)
                };
                len=len-1;
            };
            (1u8, 0u32)
        }

        public fun viewStats(player: Player): vector<Stat> {
            let len = vector::length(&viewPlayerStats(player));
            let vect = vector::empty<Stat>();
            while(len>0){
                let playerstat = vector::borrow(&viewPlayerStats(player), len-1);
                let stat_value = (PlayerCore::get_statPlayer_value(playerstat) * PlayerCore::get_statPlayer_bonus(playerstat))/100;

                let id: u8 = 0;
                if(PlayerCore::get_statPlayer_statName(playerstat) == utf8(b"Health")){
                    id == 1;
                } else if (PlayerCore::get_statPlayer_statName(playerstat) == utf8(b"Damage")){
                    id == 2;
                } else if (PlayerCore::get_statPlayer_statName(playerstat) == utf8(b"Armor")){
                    id == 3;
                };
                len=len-1;
                let stat = Core::make_stat(id, stat_value);
                vector::push_back(&mut vect, stat);
            };
    
            vect
        }

        public fun viewPlayerStats(player: Player): vector<StatPlayer> {
            let equip = player.equip;
            let vect = vector::empty<StatPlayer>();

          let hp: u64 = 100;
            let hp_percentage: u64 = 100;
            let armor: u64 = 0;
            let armor_percentage: u64 = 100;
         let dmg: u64 = 1;
            let dmg_percentage: u64 = 100;

            let chakra: u64 = 0;
            let stamina: u64 = 100;

            let i = vector::length(&equip);
            while (i > 0) {
                let item = vector::borrow(&equip, i - 1);
                let j = vector::length(&Core::get_Item_stats(item));
                while (j > 0) {
                    let stat = vector::borrow(&Core::get_Item_stats(item), j - 1);
                    let id = Core::get_stat_ID(stat);
                    let value = Core::get_stat_value(stat);

                    if (id == 1) {
                        hp = hp + value + 100;
                    } else if (id == 2) {
                        armor = armor + value;
                    } else if (id == 3) {
                        dmg = dmg + value;
                    };
                    j = j - 1;
                };

                if (Core::get_Item_rarityID(item) != 0) {
                    let k = vector::length(&Core::get_Item_rarityStats(item));
                    while (k > 0) {
                        let rarityStat = vector::borrow(&Core::get_Item_rarityStats(item), k - 1);
                        let idRarity = Core::get_stat_ID(rarityStat);
                        let valueRarity = Core::get_stat_value(rarityStat);

                        if (idRarity == 1) {
                            hp_percentage = hp_percentage + valueRarity;
                        } else if (idRarity == 2) {
                            armor_percentage = armor_percentage + valueRarity;
                        } else if (idRarity == 3) {
                            dmg_percentage = dmg_percentage + valueRarity;
                        };
                        k = k - 1;
                    };
                };

                i = i - 1;
            };

            vector::push_back(&mut vect, PlayerCore::make_statPlayer(Core::convert_statID_to_String(1), (hp*hp_percentage)/100, hp_percentage));
            vector::push_back(&mut vect, PlayerCore::make_statPlayer(Core::convert_statID_to_String(2), (armor*armor_percentage)/100, armor_percentage));
            vector::push_back(&mut vect, PlayerCore::make_statPlayer(Core::convert_statID_to_String(3), (dmg*dmg_percentage)/100, dmg_percentage));
            vector::push_back(&mut vect, PlayerCore::make_statPlayer(Core::convert_statID_to_String(4), chakra, 0));
            vector::push_back(&mut vect, PlayerCore::make_statPlayer(Core::convert_statID_to_String(5), stamina, 0));

            vect
        }


    // Calculations (level, power...)
        public fun calculate_level(xp: u32): (u8, u32) {
            let level = 1;
            let required_xp = 10;
            let current_xp = xp;

            while (current_xp >= required_xp) {
                current_xp = current_xp - required_xp;
                required_xp = required_xp * 5 / 4; // 1.25x increase using integer math
                level = level + 1;
            };

            (level, current_xp)
        }

        public fun required_xp(level: u8): u32 {
            let  required_xp = 10; // XP required for level 1 - 2
            let i = 1;

            while (i < level) {
                required_xp = required_xp * 5 / 4; // increase by 1.25x each level
                i = i + 1;
            };

            required_xp
        }

        public fun calculate_power(player: &Player): u32 {
            let (level, remaining_xp) = viewHeroLevel(*player);
            let stats = viewPlayerStats(*player);
            let len = vector::length(&stats);


            let health = 0;
            let damage = 0;
            let armor = 0;
            let attack_speed = 0;
            while(len > 0){
                let stat = vector::borrow(&stats, len-1);
                if(PlayerCore::get_statPlayer_statName(stat) == utf8(b"Health")){
                    health = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                } else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Damage")){
                    damage = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }  else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Armor")){
                    armor = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }; 
                len=len-1;
            };
            (((health/2) + damage + (armor * 2)) * (level as u64) as u32)

        }
        
                public fun calculate_level1(xp: u32): (u8, u32) {
                            let level = 1;
                            let required_xp = 10;
                            let current_xp = xp;

                            while (current_xp >= required_xp) {
                                current_xp = current_xp - required_xp;
                                required_xp = required_xp * 5 / 4; // 1.25x increase using integer math
                                level = level + 1;
                            };

                            (level, current_xp)
                        }

                public fun required_xp2(level: u8): u32 {
                    let  required_xp = 10; // XP required for level 1 - 2
                    let i = 1;

                    while (i < level) {
                        required_xp = required_xp * 5 / 4; // increase by 1.25x each level
                        i = i + 1;
                    };

                    required_xp
                }

                public fun calculate_power3(player: &Player): u32 {
                    let (level, remaining_xp) = viewHeroLevel(*player);
                    let stats = viewPlayerStats(*player);
                    let len = vector::length(&stats);


                    let health = 0;
                    let damage = 0;
                    let armor = 0;
                    let attack_speed = 0;
                    while(len > 0){
                        let stat = vector::borrow(&stats, len-1);
                        if(PlayerCore::get_statPlayer_statName(stat) == utf8(b"Health")){
                            health = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                        } else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Damage")){
                            damage = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                        }  else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Armor")){
                            armor = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                        }; 
                        len=len-1;
                    };
                    (((health/2) + damage + (armor * 2)) * (level as u64) as u32)

                }
        public fun calculate_level2(xp: u32): (u8, u32) {
            let level = 1;
            let required_xp = 10;
            let current_xp = xp;

            while (current_xp >= required_xp) {
                current_xp = current_xp - required_xp;
                required_xp = required_xp * 5 / 4; // 1.25x increase using integer math
                level = level + 1;
            };

            (level, current_xp)
        }

        public fun requiredfgd_xp3(level: u8): u32 {
            let  required_xp = 10; // XP required for level 1 - 2
            let i = 1;

            while (i < level) {
                required_xp = required_xp * 5 / 4; // increase by 1.25x each level
                i = i + 1;
            };

            required_xp
        }

        public fun calculadfte_power4(player: &Player): u32 {
            let (level, remaining_xp) = viewHeroLevel(*player);
            let stats = viewPlayerStats(*player);
            let len = vector::length(&stats);


            let health = 0;
            let damage = 0;
            let armor = 0;
            let attack_speed = 0;
            while(len > 0){
                let stat = vector::borrow(&stats, len-1);
                if(PlayerCore::get_statPlayer_statName(stat) == utf8(b"Health")){
                    health = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                } else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Damage")){
                    damage = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }  else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Armor")){
                    armor = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }; 
                len=len-1;
            };
            (((health/2) + damage + (armor * 2)) * (level as u64) as u32)

        }

        public fun calculatrte_level5(xp: u32): (u8, u32) {
            let level = 1;
            let required_xp = 10;
            let current_xp = xp;

            while (current_xp >= required_xp) {
                current_xp = current_xp - required_xp;
                required_xp = required_xp * 5 / 4; // 1.25x increase using integer math
                level = level + 1;
            };

            (level, current_xp)
        }

        public fun requiredwer_xp6(level: u8): u32 {
            let  required_xp = 10; // XP required for level 1 - 2
            let i = 1;

            while (i < level) {
                required_xp = required_xp * 5 / 4; // increase by 1.25x each level
                i = i + 1;
            };

            required_xp
        }

        public fun calculacvte_power7(player: &Player): u32 {
            let (level, remaining_xp) = viewHeroLevel(*player);
            let stats = viewPlayerStats(*player);
            let len = vector::length(&stats);


            let health = 0;
            let damage = 0;
            let armor = 0;
            let attack_speed = 0;
            while(len > 0){
                let stat = vector::borrow(&stats, len-1);
                if(PlayerCore::get_statPlayer_statName(stat) == utf8(b"Health")){
                    health = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                } else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Damage")){
                    damage = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }  else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Armor")){
                    armor = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }; 
                len=len-1;
            };
            (((health/2) + damage + (armor * 2)) * (level as u64) as u32)

        }
        public fun required_asdxp30(level: u8): u32 {
            let  required_xp = 10; // XP required for level 1 - 2
            let i = 1;

            while (i < level) {
                required_xp = required_xp * 5 / 4; // increase by 1.25x each level
                i = i + 1;
            };

            required_xp
        }

        public fun calculatert_power40(player: &Player): u32 {
            let (level, remaining_xp) = viewHeroLevel(*player);
            let stats = viewPlayerStats(*player);
            let len = vector::length(&stats);


            let health = 0;
            let damage = 0;
            let armor = 0;
            let attack_speed = 0;
            while(len > 0){
                let stat = vector::borrow(&stats, len-1);
                if(PlayerCore::get_statPlayer_statName(stat) == utf8(b"Health")){
                    health = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                } else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Damage")){
                    damage = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }  else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Armor")){
                    armor = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }; 
                len=len-1;
            };
            (((health/2) + damage + (armor * 2)) * (level as u64) as u32)

        }

        public fun calculateqwe_level50(xp: u32): (u8, u32) {
            let level = 1;
            let required_xp = 10;
            let current_xp = xp;

            while (current_xp >= required_xp) {
                current_xp = current_xp - required_xp;
                required_xp = required_xp * 5 / 4; // 1.25x increase using integer math
                level = level + 1;
            };

            (level, current_xp)
        }

        public fun required_xp6va0999(level: u8): u32 {
            let  required_xp = 10; // XP required for level 1 - 2
            let i = 1;

            while (i < level) {
                required_xp = required_xp * 5 / 4; // increase by 1.25x each level
                i = i + 1;
            };

            required_xp
        }

        public fun calculate_poweqwer170(player: &Player): u32 {
            let (level, remaining_xp) = viewHeroLevel(*player);
            let stats = viewPlayerStats(*player);
            let len = vector::length(&stats);


            let health = 0;
            let damage = 0;
            let armor = 0;
            let attack_speed = 0;
            while(len > 0){
                let stat = vector::borrow(&stats, len-1);
                if(PlayerCore::get_statPlayer_statName(stat) == utf8(b"Health")){
                    health = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                } else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Damage")){
                    damage = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }  else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Armor")){
                    armor = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }; 
                len=len-1;
            };
            (((health/2) + damage + (armor * 2)) * (level as u64) as u32)

        }

        public fun calculate_levqqel2(xp: u32): (u8, u32) {
            let level = 1;
            let required_xp = 10;
            let current_xp = xp;

            while (current_xp >= required_xp) {
                current_xp = current_xp - required_xp;
                required_xp = required_xp * 5 / 4; // 1.25x increase using integer math
                level = level + 1;
            };

            (level, current_xp)
        }

        public fun required_xcxp3(level: u8): u32 {
            let  required_xp = 10; // XP required for level 1 - 2
            let i = 1;

            while (i < level) {
                required_xp = required_xp * 5 / 4; // increase by 1.25x each level
                i = i + 1;
            };

            required_xp
        }

        public fun calculatebn_power4(player: &Player): u32 {
            let (level, remaining_xp) = viewHeroLevel(*player);
            let stats = viewPlayerStats(*player);
            let len = vector::length(&stats);


            let health = 0;
            let damage = 0;
            let armor = 0;
            let attack_speed = 0;
            while(len > 0){
                let stat = vector::borrow(&stats, len-1);
                if(PlayerCore::get_statPlayer_statName(stat) == utf8(b"Health")){
                    health = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                } else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Damage")){
                    damage = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }  else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Armor")){
                    armor = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }; 
                len=len-1;
            };
            (((health/2) + damage + (armor * 2)) * (level as u64) as u32)

        }

        public fun calculatedfg_level5(xp: u32): (u8, u32) {
            let level = 1;
            let required_xp = 10;
            let current_xp = xp;

            while (current_xp >= required_xp) {
                current_xp = current_xp - required_xp;
                required_xp = required_xp * 5 / 4; // 1.25x increase using integer math
                level = level + 1;
            };

            (level, current_xp)
        }

        public fun required_qqxp6(level: u8): u32 {
            let  required_xp = 10; // XP required for level 1 - 2
            let i = 1;

            while (i < level) {
                required_xp = required_xp * 5 / 4; // increase by 1.25x each level
                i = i + 1;
            };

            required_xp
        }

        public fun calculate_power7(player: &Player): u32 {
            let (level, remaining_xp) = viewHeroLevel(*player);
            let stats = viewPlayerStats(*player);
            let len = vector::length(&stats);


            let health = 0;
            let damage = 0;
            let armor = 0;
            let attack_speed = 0;
            while(len > 0){
                let stat = vector::borrow(&stats, len-1);
                if(PlayerCore::get_statPlayer_statName(stat) == utf8(b"Health")){
                    health = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                } else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Damage")){
                    damage = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }  else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Armor")){
                    armor = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }; 
                len=len-1;
            };
            (((health/2) + damage + (armor * 2)) * (level as u64) as u32)

        }
        public fun required_xp30(level: u8): u32 {
            let  required_xp = 10; // XP required for level 1 - 2
            let i = 1;

            while (i < level) {
                required_xp = required_xp * 5 / 4; // increase by 1.25x each level
                i = i + 1;
            };

            required_xp
        }

        public fun calculate_power40(player: &Player): u32 {
            let (level, remaining_xp) = viewHeroLevel(*player);
            let stats = viewPlayerStats(*player);
            let len = vector::length(&stats);


            let health = 0;
            let damage = 0;
            let armor = 0;
            let attack_speed = 0;
            while(len > 0){
                let stat = vector::borrow(&stats, len-1);
                if(PlayerCore::get_statPlayer_statName(stat) == utf8(b"Health")){
                    health = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                } else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Damage")){
                    damage = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }  else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Armor")){
                    armor = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }; 
                len=len-1;
            };
            (((health/2) + damage + (armor * 2)) * (level as u64) as u32)

        }

        public fun calculate_level5680(xp: u32): (u8, u32) {
            let level = 1;
            let required_xp = 10;
            let current_xp = xp;

            while (current_xp >= required_xp) {
                current_xp = current_xp - required_xp;
                required_xp = required_xp * 5 / 4; // 1.25x increase using integer math
                level = level + 1;
            };

            (level, current_xp)
        }

        public fun required_xp6047(level: u8): u32 {
            let  required_xp = 10; // XP required for level 1 - 2
            let i = 1;

            while (i < level) {
                required_xp = required_xp * 5 / 4; // increase by 1.25x each level
                i = i + 1;
            };

            required_xp
        }

        public fun calculate_power701(player: &Player): u32 {
            let (level, remaining_xp) = viewHeroLevel(*player);
            let stats = viewPlayerStats(*player);
            let len = vector::length(&stats);


            let health = 0;
            let damage = 0;
            let armor = 0;
            let attack_speed = 0;
            while(len > 0){
                let stat = vector::borrow(&stats, len-1);
                if(PlayerCore::get_statPlayer_statName(stat) == utf8(b"Health")){
                    health = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                } else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Damage")){
                    damage = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }  else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Armor")){
                    armor = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }; 
                len=len-1;
            };
            (((health/2) + damage + (armor * 2)) * (level as u64) as u32)

        }

        public fun calculate_level257(xp: u32): (u8, u32) {
            let level = 1;
            let required_xp = 10;
            let current_xp = xp;

            while (current_xp >= required_xp) {
                current_xp = current_xp - required_xp;
                required_xp = required_xp * 5 / 4; // 1.25x increase using integer math
                level = level + 1;
            };

            (level, current_xp)
        }

        public fun required_xp3474(level: u8): u32 {
            let  required_xp = 10; // XP required for level 1 - 2
            let i = 1;

            while (i < level) {
                required_xp = required_xp * 5 / 4; // increase by 1.25x each level
                i = i + 1;
            };

            required_xp
        }

        public fun calculate_power414(player: &Player): u32 {
            let (level, remaining_xp) = viewHeroLevel(*player);
            let stats = viewPlayerStats(*player);
            let len = vector::length(&stats);


            let health = 0;
            let damage = 0;
            let armor = 0;
            let attack_speed = 0;
            while(len > 0){
                let stat = vector::borrow(&stats, len-1);
                if(PlayerCore::get_statPlayer_statName(stat) == utf8(b"Health")){
                    health = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                } else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Damage")){
                    damage = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }  else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Armor")){
                    armor = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }; 
                len=len-1;
            };
            (((health/2) + damage + (armor * 2)) * (level as u64) as u32)

        }

        public fun calculate_level500(xp: u32): (u8, u32) {
            let level = 1;
            let required_xp = 10;
            let current_xp = xp;

            while (current_xp >= required_xp) {
                current_xp = current_xp - required_xp;
                required_xp = required_xp * 5 / 4; // 1.25x increase using integer math
                level = level + 1;
            };

            (level, current_xp)
        }

        public fun required_xp60(level: u8): u32 {
            let  required_xp = 10; // XP required for level 1 - 2
            let i = 1;

            while (i < level) {
                required_xp = required_xp * 5 / 4; // increase by 1.25x each level
                i = i + 1;
            };

            required_xp
        }

        public fun calculate_power70(player: &Player): u32 {
            let (level, remaining_xp) = viewHeroLevel(*player);
            let stats = viewPlayerStats(*player);
            let len = vector::length(&stats);


            let health = 0;
            let damage = 0;
            let armor = 0;
            let attack_speed = 0;
            while(len > 0){
                let stat = vector::borrow(&stats, len-1);
                if(PlayerCore::get_statPlayer_statName(stat) == utf8(b"Health")){
                    health = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                } else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Damage")){
                    damage = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }  else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Armor")){
                    armor = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }; 
                len=len-1;
            };
            (((health/2) + damage + (armor * 2)) * (level as u64) as u32)

        }
        public fun required_xp3000(level: u8): u32 {
            let  required_xp = 10; // XP required for level 1 - 2
            let i = 1;

            while (i < level) {
                required_xp = required_xp * 5 / 4; // increase by 1.25x each level
                i = i + 1;
            };

            required_xp
        }

        public fun calculate_power4000(player: &Player): u32 {
            let (level, remaining_xp) = viewHeroLevel(*player);
            let stats = viewPlayerStats(*player);
            let len = vector::length(&stats);


            let health = 0;
            let damage = 0;
            let armor = 0;
            let attack_speed = 0;
            while(len > 0){
                let stat = vector::borrow(&stats, len-1);
                if(PlayerCore::get_statPlayer_statName(stat) == utf8(b"Health")){
                    health = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                } else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Damage")){
                    damage = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }  else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Armor")){
                    armor = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }; 
                len=len-1;
            };
            (((health/2) + damage + (armor * 2)) * (level as u64) as u32)

        }

        public fun calculate_level5000(xp: u32): (u8, u32) {
            let level = 1;
            let required_xp = 10;
            let current_xp = xp;

            while (current_xp >= required_xp) {
                current_xp = current_xp - required_xp;
                required_xp = required_xp * 5 / 4; // 1.25x increase using integer math
                level = level + 1;
            };

            (level, current_xp)
        }

        public fun required_xp6000(level: u8): u32 {
            let  required_xp = 10; // XP required for level 1 - 2
            let i = 1;

            while (i < level) {
                required_xp = required_xp * 5 / 4; // increase by 1.25x each level
                i = i + 1;
            };

            required_xp
        }

        public fun calculate_power7000(player: &Player): u32 {
            let (level, remaining_xp) = viewHeroLevel(*player);
            let stats = viewPlayerStats(*player);
            let len = vector::length(&stats);


            let health = 0;
            let damage = 0;
            let armor = 0;
            let attack_speed = 0;
            while(len > 0){
                let stat = vector::borrow(&stats, len-1);
                if(PlayerCore::get_statPlayer_statName(stat) == utf8(b"Health")){
                    health = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                } else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Damage")){
                    damage = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }  else if (PlayerCore::get_statPlayer_statName(stat) == utf8(b"Armor")){
                    armor = (PlayerCore::get_statPlayer_value(stat) * (PlayerCore::get_statPlayer_bonus(stat)))/100;
                }; 
                len=len-1;
            };
            (((health/2) + damage + (armor * 2)) * (level as u64) as u32)

        }
        }

