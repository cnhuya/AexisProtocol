module new_dev::testPlayerV28{

    use std::debug::print;
    use std::string::{Self as Str,String,utf8};
    use std::timestamp; 
    use std::option::{Self, Option};
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;

    //core
    use deployer::testCore45::{Self as Core, Stat, Material, Item, ItemString, Value, ValueString, MaterialString, Expedition };
    use deployer::testPlayerCore11::{Self as PlayerCore,DungeonPlayer,Crafting,CraftingString,StatPlayer, ExamineString, Examine, Oponent, ExpeditionPlayer, ExpeditionPlayerString, PerksUsage};

    //storage
    use new_dev::testItemsV7::{Self as Items};
    use deployer::testPerksV13::{Self as Perks};
    use deployer::testConstantV4::{Self as Constant};
    use new_dev::testChancesV4::{Self as Chances};
    use deployer::testExpeditionsV9::{Self as Expedition};

    use deployer::randomv1::{Self as Random};
    //in package

    use new_dev::testStats11::{Self as Stats};
    use new_dev::testPoints11::{Self as Points};
    use deployer::testAccountsV5::{Self as Accounts};


// Structs

    struct CapHolder_stats has key {
        cap: Stats::AccessCap,
    }

    struct CapHolder_points has key {
        cap: Points::AccessCap,
    }

    struct PlayerDatabase has copy,store,drop,key {database: vector<Player>}

    struct PlayerString has copy, store, drop, key {id: u64, name: String, className: String, raceName: String, hash: u64, level: u8, xp: u32, required_xp: u32, stats: vector<StatPlayer>, elements: vector<ValueString>, materials: vector<MaterialString>, minerals: vector<MaterialString>,bags: vector<MaterialString>, perksID: vector<u16>, perk_usage:PerksUsage, inventory: vector<ItemString>, equip: vector<ItemString>,crafting: vector<CraftingString>, examinations: vector<ExamineString>, dungeon: DungeonPlayer, expedition: ExpeditionPlayerString, power: u32, oponent: Oponent, status: String}
    struct Player has copy, store, drop ,key {id: u64, name: String, classID: u8, raceID: u8, hash: u64, stats: vector<Stat>, elements: vector<Value>, materials: vector<Material>, perksID: vector<u16>, inventory: vector<Item>, equip: vector<Item>, crafting: vector<Crafting>, examinations: vector<Examine>, dungeon: DungeonPlayer, expedition: ExpeditionPlayer, oponent: Oponent, status: u8}
// Const
    const OWNER: address = @new_dev;

// Errors
    const ERROR_NAME_TOO_LONG: u64 = 1;
    const ERROR_PLAYER_NAME_ALREADY_EXISTS: u64 = 2;
    const ERROR_PLAYER_DOES_NOT_EXIST: u64 = 3;
    const ERROR_NOT_HAVE_ENOUGH_MATERIALS: u64 = 4;
    const ERROR_EXPEDITION_REQUIRES_HIGHER_LEVEL: u64 = 5;
    const ERROR_NOT_INACTIVE: u64 = 6;
    const ERROR_PLAYER_EXPEDITION_IS_EMPTY: u64 = 7;
    const ERROR_NOT_ON_EXPEDITION: u64 = 8;
    const ERROR_PLAYER_DOES_NOT_HAVE_ENOUGH_UNUSED_LEVELS: u64 = 9;
    const ERROR_YOU_CAN_OPEN_ONLY_FULL_CHEST: u64 = 10;
    const ERROR_MINIMUM_CHEST_OPEN_VALUE_IS_10: u64 = 11;
    const ERROR_PLAYER_DOES_NOT_HAVE_THIS_ITEM: u64 = 12;

// On Deploy Event
    fun init_module(address: &signer) {
        assert!(signer::address_of(address) == OWNER, 1000);

        let cap = Stats::grant_cap(address);
        move_to(address, CapHolder_stats { cap });

        let cap = Points::grant_cap(address);
        move_to(address, CapHolder_points { cap });

    }



// Make
    fun make_player(name: String, classID: u8, raceID: u8): Player  {
        assert!(Str::length(&name) <= 16, ERROR_NAME_TOO_LONG);
        //assert!(player_exists(name) == false, ERROR_PLAYER_NAME_ALREADY_EXISTS);
        Player { id:0, name: name, classID: classID, raceID: raceID, hash: 1, stats: vector::empty<Stat>(), elements: vector::empty<Value>(), materials: vector::empty<Material>(), perksID: vector::empty<u16>(), inventory: vector::empty<Item>(), equip: vector::empty<Item>(),crafting: vector::empty<Crafting>(), examinations: vector::empty<Examine>(), dungeon: PlayerCore::make_dungeonPlayer(19,0), expedition: PlayerCore::make_empty_expeditionPlayer(), oponent: PlayerCore::make_empty_oponent(), status: 0}
    }

    fun make_playerString(player: &Player, level: u8, xp: u32, required_xp: u32, stats: vector<StatPlayer>, crafting: vector<CraftingString>, power: u32, exams: vector<ExamineString>): PlayerString  {
        PlayerString { id: player.id, name: player.name, className: Core::convert_classID_to_String(player.classID), raceName: Core::convert_raceID_to_String(player.raceID), level: level,xp: xp, required_xp: required_xp, hash: 1, stats: stats, elements: Core::build_values_with_strings(player.elements),materials: Core::extract_materials_from_materials(player.materials), minerals: Core::extract_minerals_from_materials(player.materials), bags: Core::extract_bags_from_materials(player.materials), perksID: player.perksID, perk_usage: Perks::calculate_perk_usage(player.perksID,level), inventory: Core::make_multiple_string_items(player.inventory), crafting: crafting, examinations: exams, equip:  Core::make_multiple_string_items(player.equip), dungeon: player.dungeon, expedition: PlayerCore::make_expeditionPlayerString(&player.expedition), power: power, oponent: player.oponent, status: convert_playerStatus_to_String(player.status)}
    }

// Gets
    public fun get_player_ID(player: &Player): u64{
        player.id
    }
    public fun get_player_name(player: &Player): String{
        player.name
    }
    public fun get_player_classID(player: &Player): u8{
        player.classID
    }
    public fun get_player_raceID(player: &Player): u8{
        player.raceID
    }
    public fun get_player_hash(player: &Player): u64{
        player.hash
    }
    public fun get_player_stats(player: &Player): vector<Stat>{
        player.stats
    }
    public fun get_player_elements(player: &Player): vector<Value>{
        player.elements
    }
    public fun get_player_materials(player: &Player): vector<Material>{
        player.materials
    }
    public fun get_player_perksID(player: &Player): vector<u16>{
        player.perksID
    }
    public fun get_player_inventory(player: &Player): vector<Item>{
        player.inventory
    }
    public fun get_player_equip(player: &Player): vector<Item>{
        player.equip
    }
    public fun get_player_crafting(player: &Player): vector<Crafting>{
        player.crafting
    }
    public fun get_player_examinations(player: &Player): vector<Examine>{
        player.examinations
    }
    public fun get_player_dungeon(player: &Player): DungeonPlayer{
        player.dungeon
    }
    public fun get_player_oponent(player: &Player): Oponent{
        player.oponent
    }
    public fun get_player_status(player: &Player): u8{
        player.status
    }


    public fun update_player(address: address, name: String, updated_player: Player) acquires PlayerDatabase {
        let db = borrow_global_mut<PlayerDatabase>(address);
        let index = internal_find_player_index(&db.database, &name);
        *vector::borrow_mut(&mut db.database, index) = updated_player;
    }

    public fun add_player_crafting(player: Player, crafting: Crafting): Player{
        vector::push_back(&mut player.crafting, crafting);
        player
    }

    public fun remove_player_crafting(player: &mut Player): Player {
        let len = vector::length(&player.crafting);
        while (len > 0) {
            let index = len - 1;
            let craft_ref = vector::borrow(&player.crafting, index);

            if (PlayerCore::get_crafting_end(craft_ref) < timestamp::now_seconds()){
                vector::remove(&mut player.crafting, index);
            };

            len = len - 1;
        };
        *player
    }



    public fun add_player_item(player: Player, item: Item): Player{
        vector::push_back(&mut player.inventory, item);
        player
    }

    public fun remove_player_item(player: Player, item: Item): Player{
        let (isb, index) = vector::index_of(&player.inventory, &item);
        vector::remove(&mut player.inventory, index);
        player
    }

    public fun add_player_exam(player: Player, examine: Examine): Player{
        vector::push_back(&mut player.examinations, examine);
        player
    }

    public fun remove_player_exam(player: Player, examine: Examine): Player{
        let (isb, index) = vector::index_of(&player.examinations, &examine);
        vector::remove(&mut player.examinations, index);
        player
    }


    public fun set_player_dungeon(player: &mut Player, entityID: u8, health: u64){
        player.dungeon = PlayerCore::make_dungeonPlayer(entityID, health)
    }

    public fun set_player_expedition(player: &mut Player, expeditionID: u8){
        player.expedition = PlayerCore::make_expeditionPlayer(expeditionID, timestamp::now_seconds())
    }


    fun pay_fees_get_points(signer: &signer, amount: u64, fee:u64) acquires CapHolder_points{
        let acc_type = Accounts::view_acc_type(signer::address_of(signer));

        let holder = borrow_global<CapHolder_points>(OWNER); // Always use the fixed address

        // use point 3 digs -> 1 000

        let offchain_deduction = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Points"),utf8(b"offchain_deduction"))) as u64);
        let third_party_chain_deduction = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Points"),utf8(b"third_party_chain_deductin"))) as u64);

        if(acc_type == utf8(b"Onchain")){
            Points::give_points(signer, &holder.cap, amount, fee);
        } else if (acc_type == utf8(b"Offchain")){
            Points::give_points_free(signer, &holder.cap, amount);
        } else if (acc_type == utf8(b"Third-Party Chain")){
            Points::give_points_free(signer, &holder.cap, amount);
        }
    }



// Entry Functions
    public entry fun registerPlayer(address: &signer, name: String, classID: u8, raceID: u8) acquires PlayerDatabase, CapHolder_stats, CapHolder_points {
        init_player_storage(address);

        let player_db = borrow_global_mut<PlayerDatabase>(signer::address_of(address));
        let player = make_player(name, classID, raceID);
        vector::push_back(&mut player_db.database, player);

        let holder = borrow_global<CapHolder_stats>(OWNER); // Always use the fixed address
        let register_fee = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Points"),utf8(b"fee_create_hero"))) as u64);
        pay_fees_get_points(address, 0, register_fee);
        Stats::add_total_hero_count(&holder.cap);
    }


    public entry fun open_bag(address: &signer, name: String, bag_id: u8) acquires PlayerDatabase, CapHolder_stats, CapHolder_points{
        let addr = signer::address_of(address);
        let player = find_player(signer::address_of(address), name);


        let array = Random::generateRangeArray(vector[7u32, 21u32, 1u32, 1u32, 7u32, 3u32, 11u32, 2u32, 5u32, 7u32, 8u32, 13u32, 4u32, 3u32], 1, 10001, 11);
        let hash = get_player_hash(&player);

        let index = ((hash * timestamp::now_seconds())) % vector::length(&array);
        let random_value = *vector::borrow(&array, index);

        let (level, xp) = viewHeroLevel(player);


        player = change_player_materials_amount(addr, player, vector[Core::make_material(bag_id,1)], false);

        if(bag_id == 202){
            let items = Chances::buildTreasureRandom_items(((random_value as u64) % 10001), (hash as u128)+121, level);

            let len_items = vector::length(&items);
            while(len_items>0){
                let item = vector::borrow(&items, len_items-1);
                vector::push_back(&mut player.inventory, *item);
                len_items = len_items-1;
            };
        };

        if(bag_id == 203){
            let materials = Chances::buildTreasureRandom_materials(((random_value as u64) % 10001), (hash as u128)+857845, level); 
            player = change_player_materials_amount(addr, player, materials, true);
        };

        if(bag_id == 204){
            let minerals = Chances::buildTreasureRandom_minerals(((random_value as u64) % 10001), (hash as u128)+15445, level); 
            player = change_player_materials_amount(addr, player, minerals, true);
        };
        let open_bag_fee = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Points"),utf8(b"fee_open_chest"))) as u64);
        let open_bag_points = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Points"),utf8(b"points_open_chest"))) as u64);
        pay_fees_get_points(address, open_bag_points, open_bag_fee);
        let holder = borrow_global<CapHolder_stats>(OWNER); // Always use the fixed address
        Stats::add_chest_opened_count(&holder.cap);

        update_player(addr, name, player);
    }

    public entry fun open_chest(address: &signer, name: String, amount: u32) acquires PlayerDatabase, CapHolder_stats, CapHolder_points{
        let addr = signer::address_of(address);
        let player = find_player(signer::address_of(address), name);
        assert!(amount == 10, ERROR_MINIMUM_CHEST_OPEN_VALUE_IS_10);
       // assert!((amount % 10), ERROR_YOU_CAN_OPEN_ONLY_FULL_CHEST);

        let array = Random::generateRangeArray(vector[9u32, 21u32, 7u32, 3u32, 11u32, 15u32, 5u32, 7u32, 8u32, 13u32, 4u32, 16u32], 1, 10001, 9);
        let hash = get_player_hash(&player);

        let index = (hash * timestamp::now_seconds()) % vector::length(&array);
        let random_value = *vector::borrow(&array, index);

        let (level, xp) = viewHeroLevel(player);
        let materials = Chances::buildTreasureRandom(((random_value % 10001) as u64), ((get_player_hash(&player) * 2)as u128), level);
 
        player = change_player_materials_amount(addr, player, vector[Core::make_material(201, amount)], false);
        player = change_player_materials_amount(addr, player, materials, true);

        let holder = borrow_global<CapHolder_stats>(OWNER); // Always use the fixed address
        Stats::add_chest_opened_count(&holder.cap);
        let open_chest_fee = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Points"),utf8(b"fee_open_chest"))) as u64);
        let open_chest_points = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Points"),utf8(b"points_open_chest"))) as u64);
        pay_fees_get_points(address, open_chest_points, open_chest_fee);
        update_player(addr, name, player);
    }

    // Perks
        public entry fun getPerk(address: &signer, name: String, perkID: u8) acquires PlayerDatabase {
            let addr = signer::address_of(address);
            let player = find_player(signer::address_of(address), name);
                        
            // Step 2: Modify the copy
            let perk = Perks::viewPerkByID(perkID);

            let (level, _xp) = viewHeroLevel(player);
            let free = PlayerCore::get_perkUsage_free_to_use(&Perks::calculate_perk_usage(player.perksID, level));
            assert!(free >= Core::get_perkString_required(&perk), ERROR_PLAYER_DOES_NOT_HAVE_ENOUGH_UNUSED_LEVELS);

            vector::push_back(&mut player.perksID, (perkID as u16));

            // Step 3: Save it back
            update_player(addr, name, player);
        }

        public entry fun resetPerks(address: &signer, name: String) acquires PlayerDatabase {
            let addr = signer::address_of(address);

            // Step 1: Fetch a copy of the player
            let player = find_player(signer::address_of(address), name);

            // Step 2: Use the player info
            let (level, _xp) = viewHeroLevel(player);
            let cost = vector[
                Core::make_material(1, ((level * 100) as u32))
            ];
            change_player_materials_amount(addr, player, cost, true);

            // Step 3: Modify the player
            player.perksID = vector::empty<u16>();

            // Step 4: Write back
            update_player(addr, name, player);
        }

    // Items
        public fun addItem(address: &signer, name: String, itemID: u8, materialID: u8, rarityID: u8): Player acquires PlayerDatabase, CapHolder_stats, CapHolder_points {

            let addr = signer::address_of(address);
            let item = Items::viewItem(itemID, materialID, rarityID);
            let player = find_player(signer::address_of(address), name);
            let (level, _) = viewHeroLevel(player);
            Items::add_count_item();
            let item = Items::viewFinalizedItem(itemID, materialID, rarityID, level, get_player_hash(&player));
            vector::push_back(&mut player.inventory, item);

            let fee = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Points"),utf8(b"fee_items"))) as u64);
            let points = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Points"),utf8(b"points_items"))) as u64);
            pay_fees_get_points(address, points, fee);

            let holder = borrow_global<CapHolder_stats>(OWNER); // Always use the fixed address
            Stats::add_items_count(&holder.cap);
            return player
        }

        public entry fun equipItem(address: &signer, name: String, itemID: u64) acquires PlayerDatabase {
            let addr = signer::address_of(address);

            let player = find_player(addr, name);
            let item = find_item(&player, itemID);
            let (ishere, index) = vector::index_of(&player.inventory, &item);
            assert!(index >= 0, 0); // just to be safe

            let type_id = Core::get_Item_typeID(&item);

            let maybe_equipped = check_user_equip_item(addr, name, type_id);
            if (option::is_some(&maybe_equipped)) {
                let old_item = option::extract(&mut maybe_equipped);
                vector::push_back(&mut player.inventory, old_item);
            };

            let item_to_equip = vector::remove(&mut player.inventory, index);
            vector::push_back(&mut player.equip, item_to_equip);

            update_player(addr, name, player);
        }


        // Expeditions
        public entry fun entryExpedition(address: &signer, name: String, expeditionID: u8) acquires PlayerDatabase, CapHolder_points {
            let addr = signer::address_of(address);
            let player = find_player(addr, name);

            let expedition = Expedition::viewExpeditionByID_raw(expeditionID);
            let (level, xp) = viewHeroLevel(player);

            assert!(level >= Core::get_expedition_required_level(&expedition), ERROR_EXPEDITION_REQUIRES_HIGHER_LEVEL);
            assert!(player.status == 0, ERROR_NOT_INACTIVE);
            if(player.status == 1){
                leaveExpedition(address, name);
            };
            let fee = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Points"),utf8(b"fee_expedition"))) as u64);
            let points = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Points"),utf8(b"points_expedition"))) as u64);
            pay_fees_get_points(address, points, fee);

            change_player_status(&mut player, 1);
            set_player_expedition(&mut player, expeditionID);

            update_player(addr, name, player);
        }


        public entry fun leaveExpedition(address: &signer, name: String) acquires PlayerDatabase, CapHolder_points {
            let addr = signer::address_of(address);
            let player = find_player(addr, name);

            let (level, xp) = viewHeroLevel(player);
            assert!(PlayerCore::get_expeditionPlayer_entry_time(&player.expedition) != 0, ERROR_PLAYER_EXPEDITION_IS_EMPTY);
            assert!(player.status == 1, ERROR_NOT_ON_EXPEDITION);

            let expedition = Expedition::viewExpeditionByID_raw(PlayerCore::get_expeditionPlayer_id(&player.expedition));
            let timeOnExped = timestamp::now_seconds() - PlayerCore::get_expeditionPlayer_entry_time(&player.expedition);

            player = change_player_materials_amount(addr, player, Expedition::distribute_exped_rewards(Core::get_expedition_ID(&expedition), timeOnExped), true);
            //change_player_materials_amount(address, name, Expedition::distribute_exped_costs(Core::get_expedition_ID(&expedition), timeOnExped), false);


            let fee = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Points"),utf8(b"fee_expedition"))) as u64);
            let points = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"Points"),utf8(b"points_expedition"))) as u64);
            pay_fees_get_points(address, points, fee);

            player.expedition = PlayerCore::make_empty_expeditionPlayer();
            change_player_status(&mut player, 0);

            update_player(addr, name, player);
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


        #[view]
        public fun viewStats_view (address: address, name: String): vector<Stat> acquires PlayerDatabase {
            let player = find_player(address, name);
            let stats = viewStats(player);
            return stats
         }

        public fun viewStats(player: Player): vector<Stat> {
            let len = vector::length(&viewPlayerStats(player));
            let vect = vector::empty<Stat>();
            while(len>0){
                let playerstat = vector::borrow(&viewPlayerStats(player), len-1);
                let stat_value = (PlayerCore::get_statPlayer_value(playerstat) * PlayerCore::get_statPlayer_bonus(playerstat))/100;

                let id: u8 = 0;
                if(PlayerCore::get_statPlayer_statName(playerstat) == utf8(b"Health")){
                    id = 1;
                } else if (PlayerCore::get_statPlayer_statName(playerstat) == utf8(b"Armor")){
                    id = 2;
                } else if (PlayerCore::get_statPlayer_statName(playerstat) == utf8(b"Damage")){
                    id = 3;
                } else if (PlayerCore::get_statPlayer_statName(playerstat) == utf8(b"Chakra Absorbtion")){
                    id = 4;
                } else if (PlayerCore::get_statPlayer_statName(playerstat) == utf8(b"Stamina")){
                    id = 5;
                };
                len=len-1;
                let stat = Core::make_stat(id, stat_value);
                vector::push_back(&mut vect, stat);
            };
    
            vect
        }
        #[view]
        public fun viewPlayerStats_view (address: address, name: String): vector<StatPlayer> acquires PlayerDatabase {
            let player = find_player(address, name);
            let stats = viewPlayerStats(player);
            return stats
         }
        public fun viewPlayerStats(player: Player): vector<StatPlayer> {
            let equip = player.equip;
            let vect = vector::empty<StatPlayer>(); // Fixed type

          //  let hp: u64 = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"PlayerBaseStats"),utf8(b"Health"))) as u64);
          let hp: u64 = 100;
            let hp_percentage: u64 = 100;
            let armor: u64 = 0;
            let armor_percentage: u64 = 100;
         //   let dmg: u64 = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"PlayerBaseStats"),utf8(b"Damage"))) as u64);
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




// Util Functions
    // Init player
        fun init_player_storage(address: &signer) acquires CapHolder_stats{

                let deploy_addr = signer::address_of(address);

                if (!exists<PlayerDatabase>(deploy_addr)) {
                move_to(address, PlayerDatabase { database: vector::empty()});

                let holder = borrow_global<CapHolder_stats>(OWNER);
                Stats::add_unique_player_count(&holder.cap);
                };

            }


        fun internal_find_player_index(database: &vector<Player>, name: &String): u64 {
            let i = vector::length(database);
            while (i > 0) {
                let player = vector::borrow(database, i - 1);
                if (player.name == *name) {
                    return i - 1
                };
                i = i - 1;
            };
            abort(ERROR_PLAYER_DOES_NOT_EXIST)
        }

        public fun find_player(address: address, name: String): Player acquires PlayerDatabase{
            let index = internal_find_player_index(&borrow_global<PlayerDatabase>(address).database, &name);
            *vector::borrow(&borrow_global<PlayerDatabase>(address).database, index)
        }

        public fun find_item(player: &Player, itemID: u64): Item {
            let inventory = get_player_inventory(player);
            let len = vector::length(&inventory);

            while(len>0){
                let item = vector::borrow(&inventory,len-1);
                if(Core::get_Item_itemID(item) == itemID){
                    return *item
                };
                len=len-1;
            };
            abort (ERROR_PLAYER_DOES_NOT_HAVE_THIS_ITEM)
        }

       /* public fun find_mutable_player(address: address, name: String): &mut Player acquires PlayerDatabase {
            let index = internal_find_player_index(&borrow_global_mut<PlayerDatabase>(address).database, &name);
            vector::borrow_mut(&mut borrow_global_mut<PlayerDatabase>(address).database, index)
        }
*/



    // Reset player perks
        fun reset_player_perks(address: &signer, name: String) acquires PlayerDatabase {
            let addr = signer::address_of(address);
            let player = find_player(addr, name);

            player.perksID = vector::empty<u16>();

            update_player(addr, name, player);
        }

    // Change  (materials, values...)
public fun change_player_materials_amount(address: address, player: Player, mats: vector<Material>, isIncrementing: bool): Player {
    let j_index = vector::length(&mats);
    while (j_index > 0) {
        j_index = j_index - 1;
        let arg_mat = vector::borrow(&mats, j_index);
        let target_id = Core::get_material_ID(arg_mat);
        let target_amt = Core::get_material_amount(arg_mat);
        let found = false;

        let i = vector::length(&player.materials);
        let i_index = i;
        while (i_index > 0) {
            i_index = i_index - 1;
            let material = vector::borrow_mut(&mut player.materials, i_index);

            if (Core::get_material_ID(material) == target_id) {
                let existing_amt = Core::get_material_amount(material);

                if (isIncrementing) {
                    Core::change_material_amount(material, existing_amt + target_amt);
                } else {
                    assert!(target_amt <= existing_amt, ERROR_NOT_HAVE_ENOUGH_MATERIALS);
                    Core::change_material_amount(material, existing_amt - target_amt);
                };

                found = true;
                break;
            };
        };

        if (!found && !isIncrementing) {
           abort(ERROR_NOT_HAVE_ENOUGH_MATERIALS)
        };

        if (!found && isIncrementing) {
            vector::push_back(&mut player.materials, *arg_mat);
        };
    };

    return player
}


public fun change_player_values_amount(address: &signer, name: String, values: vector<Value>, enemy: &mut Player, isIncrementing: bool) acquires PlayerDatabase {
    let addr = signer::address_of(address);
    let player = find_player(addr, name);

    let j = vector::length(&values);
    let j_index = j;

    while (j_index > 0) {
        j_index = j_index - 1;
        let target_value = vector::borrow(&values, j_index);
        let is_enemy = Core::get_value_isEnemy(target_value);
        let found = false;

        if (!is_enemy) {
            let i = vector::length(&player.elements);
            let i_index = i;
            while (i_index > 0) {
                i_index = i_index - 1;
                let value = vector::borrow_mut(&mut player.elements, i_index);
                if (Core::get_value_ID(value) == Core::get_value_ID(target_value)) {
                    let current_amount = Core::get_value_value(value);
                    let added_amount = Core::get_value_value(target_value);
                    if (isIncrementing) {
                        Core::change_value_amount(value, current_amount + added_amount);
                    } else {
                        Core::change_value_amount(value, current_amount - added_amount);
                    };
                    found = true;
                    break;
                };
            };

            if (!found && isIncrementing) {
                vector::push_back(&mut player.elements, *target_value);
            };

        } else {
            let i = vector::length(&enemy.elements);
            let i_index = i;
            while (i_index > 0) {
                i_index = i_index - 1;
                let value = vector::borrow_mut(&mut enemy.elements, i_index);
                if (Core::get_value_ID(value) == Core::get_value_ID(target_value)) {
                    let target_amt = Core::get_value_value(target_value);
                    let existing_amt = Core::get_value_value(value);
                    if (isIncrementing) {
                        Core::change_value_amount(value, existing_amt + target_amt);
                    } else {
                        Core::change_value_amount(value, existing_amt - target_amt);
                    };
                    found = true;
                    break;
                };
            };

            if (!found && isIncrementing) {
                vector::push_back(&mut enemy.elements, *target_value);
            };
        }
    };

    update_player(addr, name, player);
}

        public fun change_player_status(player: &mut Player, new_status: u8){
            player.status = new_status
        }
        public fun change_player_oponent(player: &mut Player, oponent_address: address, oponent_name: String){
            player.oponent = PlayerCore::make_oponent(oponent_address, oponent_name);
        }
        public fun change_player_hash(player: &mut Player, new_hash: u64){
            player.hash = new_hash
        }
    // Combat oriented (damage, heal)
public fun damage_player(address: &signer, name: String, damage: u64) acquires PlayerDatabase {
    let addr = signer::address_of(address);
    let player = find_player(addr, name);

    let j = vector::length(&player.stats);
    let j_index = j;

    while (j_index > 0) {
        j_index = j_index - 1;
        let stat = vector::borrow_mut(&mut player.stats, j_index);
        if (Core::get_stat_ID(stat) == 1) {
            let current = Core::get_stat_value(stat);
            if (current < damage) {
                Core::change_stat_amount(stat, 0);
            } else {
                Core::change_stat_amount(stat, current - damage);
            };
        };
    };

    update_player(addr, name, player);
}

public fun heal_player(address: &signer, name: String, heal: u64) acquires PlayerDatabase {
    let addr = signer::address_of(address);
    let player = find_player(addr, name);

    let j = vector::length(&player.stats);
    let j_index = j;

    while (j_index > 0) {
        j_index = j_index - 1;
        let stat = vector::borrow_mut(&mut player.stats, j_index);
        if (Core::get_stat_ID(stat) == 1) {
            let current = Core::get_stat_value(stat);
            Core::change_stat_amount(stat, current + heal);
        };
    };

    update_player(addr, name, player);
}


    // Checks (user equip item...)
        public fun check_user_equip_item(address: address, name: String, itemID: u8): Option<Item> acquires PlayerDatabase{
            let player = find_player(address, name);
            let len = vector::length(&player.equip);

            while (len > 0) {
                len = len - 1;
                let item_ref = vector::borrow(&player.equip, len);
                if (Core::get_Item_typeID(item_ref) == itemID) {
                    return option::some(*item_ref); // Return the item wrapped in Some
                };
            };

            option::none<Item>() // If not found, return None
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


    // Convertions
       public fun convert_playerStatus_to_String(status: u8): String {
            if (status == 0) {
                utf8(b"Inactive")
            } else if (status == 1) {
                utf8(b"Travelling")
            } else if (status == 2) {
                utf8(b"Fighting")
            } else if (status == 3) {
                utf8(b"Training")
            } else if (status == 4) {
                utf8(b"In Que")
            } else {
                abort(000)
            }
        }



#[test(account = @0x1, owner = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7)]
public entry fun test(account: signer, owner: signer) acquires PlayerDatabase {
    print(&utf8(b" ACCOUNT ADDRESS "));
    print(&account);

    print(&utf8(b" OWNER ADDRESS "));
    print(&owner);

    let source_addr = signer::address_of(&owner);
    init_module(&owner);
    print(&utf8(b" USER STATS "));
    registerPlayer(&owner, utf8(b"test"), 1,1);
    let player = find_player(source_addr, utf8(b"test"));
      //public fun viewPlayerStats(player: Player): vector<StatPlayer> {
    print(&viewPlayerStats(player));
    print(&viewCrafting(player));
    print(&viewExamine(player));
    //            let _player = make_playerString(player, level, xp, viewPlayerStats(*player), viewCrafting(*player),calculate_power(player), viewExamine(*player));
    let (level, xp) = viewHeroLevel(player);
    print(&level);
    print(&xp);
    print(&viewHeroes(source_addr));
    entryExpedition(&owner, player.name, 1);
}}



