module deployer::testClass9{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::option::{self, Option};
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;
    use deployer::testCore31::{Self as Core, Stat, Material, Item, DungeonPlayer};
    use deployer::testStats::{Self as Stats};
    use deployer::testItems17::{Self as Items, UserItem,UserItemString};
    use deployer::testPlayerCore::{Self as PlayerCore,DungeonPlayer,Crafting,CraftingString,StatPlayer};
    use deployer::testConstant::{Self as Constant};


// Structs
    struct PlayerDatabase has copy,store,drop,key {database: vector<Player>}

    struct PlayerString has copy, store, drop, key {id: u64, name: String, className: String, raceName: String, level: u8, xp: u32, stats: vector<StatPlayer>, elements: vector<ValueString>, material: vector<MaterialString>, perksID: vector<u16>, inventory: vector<UserItemString>, equip: vector<UserItemString>,crafting: vector<CraftingString>, dungeon: DungeonPlayer, status: String}
    struct Player has copy, store, drop ,key {id: u64, name: String, classID: u8, raceID: u8, hash: u64, stats: vector<Stats>, elements: vector<Value>, materials: vector<Material>, perksID: vector<u16>, inventory: vector<UserItem>, equip: vector<UserItem>, crafting: vector<Crafting>,crafting: vector<Crafting>,dungeon: DungeonPlayer,status: vector<u8>}

    struct PlayerConfig has copy,store,drop,key {starting_stats: vector::<Stat>}



// Const
    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

// Errors
    const ERROR_NAME_TOO_LONG: u64 = 1;
    const ERROR_PLAYER_NAME_ALREADY_EXISTS: u64 = 2;
    const ERROR_PLAYER_DOES_NOT_EXIST: u64 = 3;
    const ERROR_NOT_HAVE_ENOUGH_MATERIALS: u64 = 4;

// On Deploy Event
   fun init_module(address: &signer) {

        let vect = vector[
            Core::make_stat(1, 100),  // HP
            Core::make_stat(2, 0),    // ARMOR
            Core::make_stat(3, 3),    // DMG
            Core::make_stat(4, 100)   // AS
        ];

        if (!exists<PlayerConfig>(deploy_addr)) {
          move_to(address, PlayerConfig { starting_stats: vect});
        };
    }



// Make
    fun make_player(name: String, classID: u8, raceID: u8): Player acquires PlayerConfig {
        assert!(String::length(name) >= 16, ERROR_NAME_TOO_LONG);
        assert!(player_exists(name) == false, ERROR_PLAYER_NAME_ALREADY_EXISTS);
        let stats = borrow_global<PlayerConfig>(OWNER);
        Player { id: Stats::view_stats_total_heroes()+1, name: name, classID: classID, raceID: raceID, hash: 1, stats: stats.starting_stats, materials: vector::empty<>, perksID: vector::empty<>, inventory: vector::empty<>, equip: vector::empty<>, dungeon: Core::make_dungeonPlayer(1,0), status: 0 }
    }

    fun make_playerString(player: &Player, level: u8, xp: u32, stats: vector<StatsPlayer>): PlayerString acquires PlayerConfig {
        PlayerString { id: player.id, name: player.name, className: Core::convert_classID_to_String(player.classID), raceID: Core::convert_raceID_to_String(player.raceID), level: level,xp: xp, hash: 1, stats: stats, materials: Core::build_materials_with_strings(player.materials), perksID: player.perksID, inventory: Items::make_multiple_userItemStrings(player.inventory), equip: Items::make_multiple_userItemStrings(player.equip), dungeon: player.dungeon, status: convert_playerStatus_to_String(player.status)}
    }

// Gets
// Entry Functions
    public entry fun registerPlayer(address: &signer, name: String, classID: u8, raceID: u8) acquires PlayerDatabase {
        init_player_storage(address);
        let player_db = borrow_global_mut<PlayerDatabase>(signer::address_of(address));
        let player = make_player(name, classID, raceID);
        vector::push_back(&mut player_db.database, player);
        Stats::add_total_hero_count();
    }

    // Items
        public entry fun addItemToPlayerInventory(address: &signer, name: String, item: UserItem) acquires PlayerDatabase {
            let player = find_player(singer::address_of(address), name);
            vector::push_back(&mut player.inventory, item);
        }

        public entry fun equipItem(address: &signer, name: String, item: UserItem) acquires PlayerDatabase {
            let player = find_player(singer::address_of(address), name);
            let index = vector::index_of(&player.inventory, item);
            let item_ref = vector::borrow_mut(&player.inventory, index);

            let maybe_equipped = check_user_equip_item(addr, name, Core::get_Item_typeID(item));
            if (option::is_some(&maybe_equipped)) {
                let old_item = option::extract(&mut maybe_equipped);
                vector::push_back(&mut player.inventory, old_item);
            };
            let item_to_equip = vector::remove(&mut player.inventory, index);
            vector::push_back(&mut player.equip, item_to_equip);
        }




// View Functions
    #[view]
    public fun viewHeroes(address: address): vector<PlayerString> acquires PlayerDatabase {
        let player_db = borrow_global<PlayerDatabase>(address);
        let len = vector::length(&player_db.database);
        let vect = vector::empty<PlayerString>()
        while(len>0)    {
            let player = vector::borrow(&player_db.database, len-1);
            let (level, xp) = viewHeroLevel(address, player.name);
            let _player = make_playerString(player, level, xp, viewStats(address, player.name));
            vector::push_back(&mut vect, _player);
            len=len-1;
        };
        move vect
    }



    #[view]
    public fun viewHeroLevel(address: address, name: String): (u8,u32) acquires PlayerDatabase {
        let player = find_player(address, name);
        let len = vector::length(&player.material);
        while(len>0) {
            let material = vector::borrow(&player.material, len-1);
            if(Core::get_material_ID(material) == 0){
                let value = Core::get_material_amount(material);
                let (level, exp) = calculate_level(value);
                break;
            }
            len=len-1;
        };
        (level, exp);
    }
#[view]
    public fun viewStats(address: address, name: String): vector<StatPlayer> acquires PlayerDatabase {
        let player = Player::find_player(address, name);
        let equip = player.equip;
        let vect = vector::empty<StatPlayer>(); // Fixed type

        let HP: u64 = 100;
        let HP_PERCENTAGE: u64 = 0;
        let ARMOR: u64 = 0;
        let ARMOR_PERCENTAGE: u64 = 0;
        let DMG: u64 = 1;
        let DMG_PERCENTAGE: u64 = 0;
        let AS: u64 = 0;
        let AS_PERCENTAGE: u64 = 0;

        let i = vector::length(&equip);
        while (i > 0) {
            let item = vector::borrow(&equip, i - 1);
            let j = vector::length(&item.stats);
            while (j > 0) {
                let stat = vector::borrow(&item.stats, j - 1);
                let id = Core::get_stat_ID(stat);
                let value = Core::get_stat_value(stat);

                if (id == 1) {
                    HP = HP + value + 100;
                } else if (id == 2) {
                    ARMOR = ARMOR + value;
                } else if (id == 3) {
                    DMG = DMG + value;
                } else if (id == 4) {
                    AS = AS - (value / 5);
                }
                j = j - 1;
            };

            if (Core::get_Item_rarityID(item) != 0) {
                let k = vector::length(&item.rarityStats);
                while (k > 0) {
                    let rarityStat = vector::borrow(&item.rarityStats, k - 1);
                    let idRarity = Core::get_stat_ID(rarityStat);
                    let valueRarity = Core::get_stat_value(rarityStat);

                    if (idRarity == 1) {
                        HP_PERCENTAGE = HP_PERCENTAGE + valueRarity;
                    } else if (idRarity == 2) {
                        ARMOR_PERCENTAGE = ARMOR_PERCENTAGE + valueRarity;
                    } else if (idRarity == 3) {
                        DMG_PERCENTAGE = DMG_PERCENTAGE + valueRarity;
                    } else if (idRarity == 4) {
                        AS_PERCENTAGE = AS_PERCENTAGE + valueRarity;
                    }
                    k = k - 1;
                }
            }

            i = i - 1;
        };

        vector::push_back(&mut vect, Player::make_statPlayer(1, (HP*HP_PERCENTAGE)/100, HP_PERCENTAGE));
        vector::push_back(&mut vect, Player::make_statPlayer(2, (ARMOR*ARMOR_PERCENTAGE)/100, ARMOR_PERCENTAGE));
        vector::push_back(&mut vect, Player::make_statPlayer(3, (DMG*DMG_PERCENTAGE)/100, DMG_PERCENTAGE));
        vector::push_back(&mut vect, Player::make_statPlayer(4, (AS*AS_PERCENTAGE)/100, AS_PERCENTAGE));

        vect
    }


// Util Functions

   fun init_player_storage(address: &signer) {

        let deploy_addr = signer::address_of(address);

        if (!exists<PlayerDatabase>(deploy_addr)) {
          move_to(address, PlayerDatabase { database: vector::empty()});
          Stats::add_unique_player_count();
        };

    }


        fun change_player_materials_amount(address: &signer, name: String, mats: vector<Material>, isIncrementing: bool) {
            let player = find_player(signer::address_of(address), name);
            let j = vector::length(&mats);
            while (j > 0) {
                let arg_mat = vector::borrow(&mats, j - 1);
                let target_id = Core::get_material_ID(arg_mat);
                let target_amt = Core::get_material_amount(arg_mat);
                let found = false;

                let i = vector::length(&player.materials);
                while (i > 0) {
                    let material = vector::borrow_mut(&mut player.materials, i - 1);

                    if (Core::get_material_ID(material) == target_id) {
                        let existing_amt = Core::get_material_amount(material);

                        if (isIncrementing) {
                            Core::change_material_amount(material, existing_amt + target_amt);
                        } else {
                            if(target_amt > existing_amt){
                               abort(ERROR_NOT_HAVE_ENOUGH_MATERIALS)
                            } else {
                                Core::change_material_amount(material, existing_amt - target_amt);
                            }
                        }

                        found = true;
                        break;
                    }

                    i = i - 1;
                }

                if (!found && isIncrementing) {
                    vector::push_back(&mut player.materials, *arg_mat);
                }

                j = j - 1;
            }
        }




    fun check_user_equip_item(address: address, name: String, itemID: u8): Option<Item> {
        let player = find_player(address, name);
        let mut len = vector::length(&player.equip);

        while (len > 0) {
            len = len - 1;
            let item_ref = vector::borrow(&player.equip, len);
            if (Core::get_Item_typeID(item_ref) == itemID) {
                return option::some(*item_ref); // Return the item wrapped in Some
            };
        };

        option::none<Item>() // If not found, return None
    }



    fun calculate_level(xp: u32): (u8, u32) {
        let level = 1;
        let required_xp = 100;
        let current_xp = xp;

        while (current_xp >= required_xp) {
            current_xp = current_xp - required_xp;
            required_xp = required_xp * 3 / 2; // Increase cost by 1.5x
            level = level + 1;
        }

        (level, current_xp)
    }



    fun find_player(address: address, name: String): Player acquires Class_Database {
        let player_db = borrow_global_mut<PlayerDatabase>(address);
        let len = vector::length(&player_db.database);
        while(len>0){
            let player = vector::borrow(&player_db.database, len-1);
            if(player.name == name){
                return *player
            };
            len=len;
        };
        abort(ERROR_PLAYER_DOES_NOT_EXIST)
    }

    fun convert_playerStatus_to_String(status: u8): String {
        if (status == 0) {
            utf8(b"Inactive")
        } else if (status == 1) {
            utf8(b"Travelling")
        } else if (status == 2) {
            utf8(b"Fighting")
        } else if (statID == 3) {
            utf8(b"Training")
        } else {
            abort(000)
        }
// External Functions


#[test(account = @0x1, owner = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7)]
public entry fun test(account: signer, owner: signer) acquires Class_Database {
    print(&utf8(b" ACCOUNT ADDRESS "));
    print(&account);

    print(&utf8(b" OWNER ADDRESS "));
    print(&owner);

    let source_addr = signer::address_of(&account);
    init_module(&owner);
    account::create_account_for_test(source_addr);

    print(&utf8(b" USER STATS "));

    // Sample passive data
    let passive_name = vector[utf8(b"passive1"), utf8(b"passive2")];
    let passive_valueIDs = vector[vector[1u8], vector[2u8]];
    let passive_valueIsEnemies = vector[vector[true], vector[false]];
    let passive_valueValues = vector[vector[10u8], vector[20u8]];
    let passive_valueTimes = vector[vector[100u64], vector[200u64]];

    // Sample active data
    let active_name = vector[utf8(b"active1"), utf8(b"active2")];
    let active_cooldown = vector[5u8, 6u8];
    let active_stamina = vector[10u8, 20u8];
    let active_damage = vector[50u16, 100u16];
    let active_valueIDs = vector[vector[3u8], vector[4u8]];
    let active_valueIsEnemies = vector[vector[true], vector[false]];
    let active_valueValues = vector[vector[7u8], vector[8u8]];

    createClass(
        &owner,
        1, // classID
        passive_name,
        passive_valueIDs,
        passive_valueIsEnemies,
        passive_valueValues,
        passive_valueTimes,
        active_name,
        active_cooldown,
        active_stamina,
        active_damage,
        active_valueIDs,
        active_valueIsEnemies,
        active_valueValues
    );

        createClass(
        &owner,
        2, // classID
        passive_name,
        passive_valueIDs,
        passive_valueIsEnemies,
        passive_valueValues,
        passive_valueTimes,
        active_name,
        active_cooldown,
        active_stamina,
        active_damage,
        active_valueIDs,
        active_valueIsEnemies,
        active_valueValues
    );

        createClass(
        &owner,
        3, // classID
        passive_name,
        passive_valueIDs,
        passive_valueIsEnemies,
        passive_valueValues,
        passive_valueTimes,
        active_name,
        active_cooldown,
        active_stamina,
        active_damage,
        active_valueIDs,
        active_valueIsEnemies,
        active_valueValues
    );

        createClass(
        &owner,
        4, // classID
        passive_name,
        passive_valueIDs,
        passive_valueIsEnemies,
        passive_valueValues,
        passive_valueTimes,
        active_name,
        active_cooldown,
        active_stamina,
        active_damage,
        active_valueIDs,
        active_valueIsEnemies,
        active_valueValues
    );

        createClass(
        &owner,
        5, // classID
        passive_name,
        passive_valueIDs,
        passive_valueIsEnemies,
        passive_valueValues,
        passive_valueTimes,
        active_name,
        active_cooldown,
        active_stamina,
        active_damage,
        active_valueIDs,
        active_valueIsEnemies,
        active_valueValues
    );

    print(&viewClass(1));
    print(&viewClass(2));
    print(&viewClass(3));
    print(&viewClass(4));
    print(&viewClass(5));
    print(&viewClasses());
}}}

