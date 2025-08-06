module deployer::testPVPV20{

    use std::debug::print;
    use std::string::{String,utf8};
    use std::timestamp; 
    use std::account;
    use std::signer;
    use std::vector;
    use supra_framework::event;
    //core
    use deployer::testCore45::{Self as Core, Stat, StatString,Material, Item, ItemString, Value, ValueString, MaterialString, Expedition };
    use deployer::testPlayerCore11::{Self as PlayerCore,DungeonPlayer,Crafting,CraftingString,StatPlayer, ExamineString, Examine, Oponent};

    //storage
    use deployer::testPerksV13::{Self as Perks};
    use deployer::testClassV11::{Self as Classes};

    use deployer::testPlayerV27::{Self as Player};
    use deployer::testConstantV4::{Self as Constant};

// Structs
    struct QueDatabase has copy,store,drop,key {database: vector<QuedPlayer>}
    struct QuedPlayer has copy,store,drop,key {address: address, name: String}

    struct OnGoingFightDatabase has copy,store,drop,key {database: vector<Fight>}

    struct Fight has copy, store, drop, key {player1: Fighter, player2: Fighter, combat: vector<Cast>, start: u64}

    struct Cast has copy, store, drop, key {caster: String, isPerk: bool, id: u8, calltime: u64}

    struct Fighter has copy, store, drop, key {address: address, name: String, stats: vector<Stat>, elements: vector<Value>, stamina: u32, chakra: u32, chakra_debt: u32, frozen: vector<u64>, isFrozen: bool, accepted: bool}

    struct FighterString has copy, store, drop, key {address: address, name: String, stats: vector<StatString>, elements: vector<ValueString>, stamina: u32, chakra: u32, chakra_debt: u32, frozen: vector<u64>, isFrozen: bool, accepted: bool}

// Const
    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

// Errors
    const ERROR_PLAYER_DOESNT_NOT_HAVE_THIS_PERK: u64 = 1;
    const ERROR_PLAYER_IS_NOT_CORRECT_CLASS: u64 = 2;
    const ERROR_PERK_IS_ON_COOLDOWN: u64 = 3;
    const ERROR_PLAYER_DOES_NOT_HAVE_ENOUGH_STAMINA: u64 = 4;
    const ERROR_PLAYER_DOES_NOT_HAVE_ENOUGH_CHAKRA: u64 = 5;
    const ERROR_GAME_NOT_STARTED: u64 = 6;

// On Deploy Event
   fun init_module(address: &signer) {
        if (!exists<OnGoingFightDatabase>(signer::address_of(address))) {
          move_to(address, OnGoingFightDatabase { database: vector::empty()});
        };
        if (!exists<QueDatabase>(signer::address_of(address))) {
          move_to(address, QueDatabase { database: vector::empty()});
        };
    }

// Make
    public fun make_fighter(address: address, name: String, accepted: bool, starting_stats: vector<Stat>): Fighter{
        Fighter {address: address, name: name,  stats: starting_stats, elements: vector::empty<Value>(), stamina: 100, chakra:0, chakra_debt: 0, frozen: vector::empty<u64>(), isFrozen: false, accepted: accepted}
    }

    public fun make_string_fighter(fighter: &Fighter): FighterString{
        FighterString {address: fighter.address, name: fighter.name, stats: Core::build_stats_with_strings(fighter.stats), elements: Core::build_values_with_strings(fighter.elements), stamina: fighter.stamina, chakra: fighter.chakra, chakra_debt: fighter.chakra_debt, frozen:fighter.frozen, isFrozen: fighter.isFrozen, accepted: fighter.accepted}
    }

    public fun make_fight(player1: Fighter, player2: Fighter): Fight{
        Fight {player1: player1, player2: player2, start: timestamp::now_seconds() + 60, combat: vector::empty<Cast>()}
    }


entry fun delete_fight(name: String) acquires OnGoingFightDatabase {
    let fight_db = borrow_global_mut<OnGoingFightDatabase>(OWNER);

    let i = vector::length(&fight_db.database);

    while (i > 0) {
        i = i - 1;
        let fight_ref = vector::borrow(&fight_db.database, i);
        if (fight_ref.player1.name == name || fight_ref.player2.name == name) {
            vector::remove(&mut fight_db.database, i);
        };
    };

    abort 0;
}


    public entry fun castPerk(address: &signer, name: String, id: u8) acquires OnGoingFightDatabase{
        let player = Player::find_player(signer::address_of(address), name);
        let fight = viewOnGoingFight(name);
        assert!(fight.start <= timestamp::now_seconds(), ERROR_GAME_NOT_STARTED);
        assert!(vector::contains(&Player::get_player_perksID(&player), &(id as u16)),ERROR_PLAYER_DOESNT_NOT_HAVE_THIS_PERK);

        let perk = Perks::viewPerkByID_raw(id);
        let fighter = viewFighter(name);

        let cooldown: u64 = (Core::get_perk_cooldown(&perk) as u64);
        let stamina: u64 = (Core::get_perk_stamina(&perk) as u64);

        let wisdom = Core::get_stat_value(&Core::degrade_string_stat_to_stat((&Core::get_stat_by_name(viewUpdatedStats(signer::address_of(address), name), utf8(b"Wisdom")))));
        let dark_magic = Core::get_stat_value(&Core::degrade_string_stat_to_stat((&Core::get_stat_by_name(viewUpdatedStats(signer::address_of(address), name), utf8(b"Dark Magic")))));

        if (wisdom >= 10) {
            let wisdom_multi = (wisdom / 10) * 5;
            cooldown = cooldown - (cooldown * wisdom_multi) / 100;
        };

        if (dark_magic >= 10) {
            let darkmagic_multi = (dark_magic / 10) * 3;
            cooldown = cooldown - (cooldown * dark_magic) / 100;
            stamina = stamina + (stamina * dark_magic) / 100;
        };
        assert!((fighter.stamina as u64) >= stamina, ERROR_PLAYER_DOES_NOT_HAVE_ENOUGH_STAMINA);
        let last_call_time = get_perk_last_called_time(name, id);
        let now = timestamp::now_seconds();
        if (last_call_time != 999_999_999) {
            assert!(now - last_call_time >= cooldown, ERROR_PERK_IS_ON_COOLDOWN);
        };

        addCast(&mut fight, name, true, id);
    }

        fun addCast(fight: &mut Fight, player: String, isperk: bool, id: u8) {
            let cast = Cast {
                caster: player,
                isPerk: isperk,
                id: id,
                calltime: timestamp::now_seconds(),
            };
            vector::push_back(&mut fight.combat, cast);
        }


    public fun get_perk_last_called_time(name: String, id: u8): u64 acquires OnGoingFightDatabase{
        let fight = viewOnGoingFight(name);
        let calls = fight.combat;
        let len = vector::length(&calls);
        let perk = Perks::viewPerkByID(id);

        let i = len;
        while (i > 0) {
            let call = vector::borrow(&calls, i - 1);
            if (call.isPerk && call.id == id && call.caster == name) {
                return call.calltime
            };
            i = i - 1;
        };
        return 999_999_999
    }


    public entry fun castAbility(address: &signer,name: String, id: u8) acquires OnGoingFightDatabase{
        let player = Player::find_player(signer::address_of(address), name);
        let fight = viewOnGoingFight(name);
        assert!(fight.start <= timestamp::now_seconds(), ERROR_GAME_NOT_STARTED);
        let ability = Classes::viewClassSpell_raw(id);
        let fighter = viewFighter(name);

       // assert!(Player::get_player_classID(player) == Core::get_Ability_classID(&ability), ERROR_PLAYER_IS_NOT_CORRECT_CLASS);
        assert!(fighter.chakra >= Core::get_Ability_required_chakra(&ability), ERROR_PLAYER_DOES_NOT_HAVE_ENOUGH_CHAKRA);

        addCast(&mut fight, name, false, id);
    }

    public entry fun enterQue(address: &signer, name: String) acquires QueDatabase, OnGoingFightDatabase{
        let addr = signer::address_of(address);
        let player = Player::find_player(signer::address_of(address), name);
        let que_db = borrow_global_mut<QueDatabase>(OWNER);
        let quedPlayer = QuedPlayer {address: signer::address_of(address), name: name};
        vector::push_back(&mut que_db.database, quedPlayer);
        Player::change_player_status(&mut player,4);
        validateQue(address, name);
        Player::update_player(addr, name, player);
    }

    public entry fun exitQue(address: &signer, name: String) acquires QueDatabase{
        removePlayerFromQue(signer::address_of(address),name);
    }

    public entry fun forceFight(address: &signer, name: String, oponent_address: address, oponent_name: String) acquires QueDatabase, OnGoingFightDatabase{
        let addr = signer::address_of(address);
        let player = Player::find_player(signer::address_of(address), name);
        let fight_db = borrow_global_mut<OnGoingFightDatabase>(OWNER);
        let fight = make_fight(make_fighter(signer::address_of(address),name, true, Player::viewStats(player)), make_fighter(oponent_address,oponent_name, false, Player::viewStats(player)));
        removePlayerFromQue(signer::address_of(address),name);
        let player = Player::find_player(signer::address_of(address), name);
        Player::change_player_oponent(&mut player, oponent_address, oponent_name);
        vector::push_back(&mut fight_db.database, fight);
        Player::update_player(addr, name, player);
    }

    public entry fun validateQue(address: &signer, name: String) acquires QueDatabase, OnGoingFightDatabase {
        let addr = signer::address_of(address);

        // Clone player1 locally
        let player1 = Player::find_player(addr, name);

        let que_db = borrow_global_mut<QueDatabase>(OWNER);
        let fight_db = borrow_global_mut<OnGoingFightDatabase>(OWNER);

        let len = vector::length(&que_db.database);
        while (len > 0) {
            let quedPlayer = vector::borrow(&que_db.database, len - 1);
            let addr2 = quedPlayer.address;
            let name2 = quedPlayer.name;

            let player2 = Player::find_player(addr2, name2);

            if (Player::get_player_status(&player1) == 4 || Player::get_player_status(&player2) == 4) {
                let p1 = Player::calculate_power(&player1);
                let p2 = Player::calculate_power(&player2);

                if (p1 > p2 - 100 && p1 < p2 + 100) {
                    Player::change_player_status(&mut player1, 3);
                    Player::change_player_status(&mut player2, 3);
                    Player::change_player_oponent(&mut player1, addr2, name2);
                    Player::change_player_oponent(&mut player2, addr, name);

                    let fighter1 = make_fighter(addr, Player::get_player_name(&player1), true, Player::viewStats(player1));
                    let fighter2 = make_fighter(addr2, Player::get_player_name(&player2), true, Player::viewStats(player2));
                    let fight = make_fight(fighter1, fighter2);

                    Player::update_player(addr, name, player1);
                    Player::update_player(addr2, name2, player2);
                    vector::push_back(&mut fight_db.database, fight);
                    return;
                };
            };
            len = len - 1;
        };
    }

// Views
    #[view]
    public fun viewQuedPlayers(): vector<QuedPlayer> acquires QueDatabase{
        let que_db = borrow_global<QueDatabase>(OWNER);
        que_db.database
    }
    
    #[view]
    public fun viewOnGoingFights(): vector<Fight> acquires OnGoingFightDatabase{
        let fight_db = borrow_global<OnGoingFightDatabase>(OWNER);
        fight_db.database
    }

    #[view]
    public fun viewOnGoingFight(player: String): Fight acquires OnGoingFightDatabase {
        let fight_db = borrow_global<OnGoingFightDatabase>(OWNER); // not mut
        let fights = &fight_db.database;

        let len = vector::length(fights);
        let i = len;
        while (i > 0) {
            let fight_ref = vector::borrow(fights, i - 1);
            if (fight_ref.player1.name == player || fight_ref.player2.name == player) {
                return simulate_fight(*fight_ref)
            };
            i = i - 1;
        };
        abort 0
    }



    #[view]
    public fun viewFighter(player: String): FighterString acquires OnGoingFightDatabase{
        let fight_db = borrow_global<OnGoingFightDatabase>(OWNER);
        let len = vector::length(&fight_db.database);
        while(len > 0){
            let fight = vector::borrow(&fight_db.database, len-1);
            let simulated_fight = simulate_fight(*fight);
            if(fight.player1.name == player){
                let fighter1 = simulated_fight.player1;
                return make_string_fighter(&fighter1)
            } else if (fight.player2.name == player) {
                let fighter2 = simulated_fight.player1;
                return make_string_fighter(&fighter2)
            };
            len=len-1;
        };
        abort (000)
    }

    #[view]
    public fun viewUpdatedStats(address: address, player: String): vector<StatString> acquires OnGoingFightDatabase{
        let fighter = viewFighter(player);
        let len = vector::length(&fighter.stats);
        while(len > 0){
            let now = timestamp::now_seconds();
            let stat = vector::borrow(&fighter.stats, len-1);
            let _stat = Core::make_string_stat(&Core::degrade_string_stat_to_stat(stat));
            len=len-1;
        };
        abort (000)
    }


// Utils
    fun removePlayerFromQue(address: address, name: String) acquires QueDatabase {
        let que_db = borrow_global_mut<QueDatabase>(OWNER);
        let quedPlayer = QuedPlayer { address: address, name: name };
        let (isb, index) = vector::index_of(&que_db.database, &quedPlayer);
        vector::remove(&mut que_db.database, index);

        let player = Player::find_player(address, name);
        Player::change_player_status(&mut player, 1);

        Player::update_player(address, name, player);
    }



    fun simulate_fight(fight: Fight): Fight {
        let now = timestamp::now_seconds();
        let fighter = fight.player1;
        let enemy = fight.player2;

        // Set base element values
        fighter.elements = safe_write_elements();
        enemy.elements = safe_write_elements();

        let all_casts = &fight.combat;
        let len = vector::length(all_casts);
        let last_time = fight.start;
        let i = 0;

        while (i < len) {
            let cast = vector::borrow(all_casts, i);
            let current_time = cast.calltime;
            let time_elapsed = current_time - last_time;

            fighter.stats = overwrite_stats(&mut fighter, &enemy, time_elapsed);
            enemy.stats = overwrite_stats(&mut enemy, &fighter, time_elapsed);

            if (cast.isPerk) {
                let real_perk = Perks::viewPerkByID_raw(cast.id);
                apply_values(&mut fighter, &mut enemy, Core::get_perk_values(&real_perk), (Core::get_perk_stamina(&real_perk) as u32), true);
            } else {
                let real_ability = Classes::viewClassSpell_raw(cast.id);
                apply_values(&mut fighter, &mut enemy, Core::get_Ability_values(&real_ability), (Core::get_Ability_required_chakra(&real_ability) as u32), false);
            };

            last_time = current_time;
            i = i + 1;
        };

        let remaining_time = now - last_time;
        fighter.stats = overwrite_stats(&mut fighter, &enemy, remaining_time);
        enemy.stats = overwrite_stats(&mut enemy, &fighter, remaining_time);

        // Update and return new fight
        fight.player1 = fighter;
        fight.player2 = enemy;
        fight
    }


    fun apply_values(fighter: &mut Fighter, enemy: &mut Fighter, values: vector<Value>, cost: u32, isPerk: bool) {
        let len = vector::length(&values);
        let i = 0;
        if(isPerk == true){
            fighter.stamina = fighter.stamina - cost;
        } else {
            fighter.chakra = fighter.chakra - cost;
        };
        while (i < len) {
            let value = vector::borrow(&values, i);
            if (Core::get_value_isEnemy(value)) {
                is_value_initialized(enemy, value);
            } else {
                is_value_initialized(fighter, value);
            };
            i = i + 1;
        };
    }

    fun min(a: u64, b: u64): u64 {
        if (a < b) {
            a
        } else {
            b
        }
    }

    fun max(a: u64, b: u64): u64 {
        if (a > b) {
            a
        } else {
            b
        }
    }


    fun overwrite_stats(fighter: &mut Fighter, enemy: &Fighter, time_elapsed: u64): vector<Stat> {

        let stats = fighter.stats;
        let _stats = Core::build_stats_with_strings(stats);


        let hp = Core::get_stat_value(&Core::degrade_string_stat_to_stat(&Core::get_stat_by_name(_stats, utf8(b"Health"))));
        let dmg = Core::get_stat_value(&Core::degrade_string_stat_to_stat(&Core::get_stat_by_name(_stats, utf8(b"Damage"))));
        let armor = Core::get_stat_value(&Core::degrade_string_stat_to_stat(&Core::get_stat_by_name(_stats, utf8(b"Armor"))));
        let chakra = Core::get_stat_value(&Core::degrade_string_stat_to_stat(&Core::get_stat_by_name(_stats, utf8(b"Chakra Absorbtion"))));
        let stamina = Core::get_stat_value(&Core::degrade_string_stat_to_stat(&Core::get_stat_by_name(_stats, utf8(b"Stamina"))));
      //  let stamina = &mut fighter.stamina;

        let _enemy_stats = Core::build_stats_with_strings(enemy.stats);    
        let enemy_dmg = Core::get_stat_value(&Core::degrade_string_stat_to_stat(&Core::get_stat_by_name(_enemy_stats, utf8(b"Damage"))));
        let now = timestamp::now_seconds() + time_elapsed;
        let frozen_len = vector::length(&fighter.frozen);
        let  frozen_recent = false;
        if (frozen_len > 0) {
            let last_frozen = *vector::borrow(&fighter.frozen, frozen_len - 1);
            if (last_frozen + 5 > now) {
                frozen_recent = true;
            };
        };


        let frozen_seconds = 0;
        let freeze_len = vector::length(&fighter.frozen);
        let start_time = now - time_elapsed;

        let i = 0;
        while (i < freeze_len) {
            let freeze_start = *vector::borrow(&fighter.frozen, i);
            let freeze_end = freeze_start + 5;

            // calculate overlap
            if (freeze_end > start_time && freeze_start < now) {
                let overlap_start = max(freeze_start, start_time);
                let overlap_end = min(freeze_end, now);
                frozen_seconds = frozen_seconds + (overlap_end - overlap_start);
            };
            i = i + 1;
        };

        // to automatically deduct the frozen time, so it doesnt count in things such as stamina regeneration, dmg dealt...
        let deducted_time = time_elapsed - frozen_seconds;

        if (stamina < 99){
            stamina = stamina + deducted_time;
        } else if (stamina + deducted_time >= 100){
            stamina = 100;
        };

        let chakra_debt = fighter.chakra_debt;
        let curse_dmg_reduction = 0;
        now = timestamp::now_seconds() + time_elapsed;

        let elements = Core::build_values_with_strings(fighter.elements);
        // Needs to be at top, because setting value at curse dmg reduction
        // Curse Element
        let curse_value = Core::get_value_value(&Core::degrade_string_value_to_value(&Core::get_value_by_name(elements, utf8(b"Lightning"))));
        curse_dmg_reduction = ((curse_value / 10)*3 as u64);

        // Rage Element
        let rage_value = Core::get_value_value(&Core::degrade_string_value_to_value(&Core::get_value_by_name(elements, utf8(b"Rage"))));
        let rage_multiplier = (rage_value / 10) * 75;
        let bonus_dmg = (dmg*(rage_multiplier as u64))/10;
        dmg = dmg + bonus_dmg;

        // Endurance Element
        let endurance_value = Core::get_value_value(&Core::degrade_string_value_to_value(&Core::get_value_by_name(elements, utf8(b"Endurance"))));
        let endurance_multiplier = (endurance_value / 10) * 25;
        let bonus_armor = (armor*(endurance_multiplier as u64))/10;
        armor = armor + bonus_armor;

        // Dopamine Element
        let dopamine_value = Core::get_value_value(&Core::degrade_string_value_to_value(&Core::get_value_by_name(elements, utf8(b"Dopamine"))));
        let dopamine_multiplier = (dopamine_value / 10) + 1;
        let bonus_chakra = (deducted_time*(dopamine_multiplier as u64))+100;
        chakra = chakra + bonus_chakra;

        // Vitals Element
        let vitals_value = Core::get_value_value(&Core::degrade_string_value_to_value(&Core::get_value_by_name(elements, utf8(b"Vitals"))));
        let vitals_multiplier = (vitals_value / 10);
        let healted_amount = (hp*(vitals_multiplier as u64))/10;
        hp = hp + healted_amount;

        // Vamp Element
        let vamp_value = Core::get_value_value(&Core::degrade_string_value_to_value(&Core::get_value_by_name(elements, utf8(b"Vamp"))));
        let vamp_multiplier = (vamp_value / 10)*25;
        let dmg_dealt = dmg * deducted_time;
        let vamp_amount = (dmg_dealt*(vamp_multiplier as u64))/100;
        hp = hp + vamp_amount;

        // Poison Element
        let poison_value = Core::get_value_value(&Core::degrade_string_value_to_value(&Core::get_value_by_name(elements, utf8(b"Poison"))));
        let poison_multiplier = (poison_value / 10);
        let poison_dmg = (enemy_dmg*(poison_multiplier as u64))/100;
        hp = hp - poison_dmg;

        // Ice Element
        let ice_value = Core::get_value_value(&Core::degrade_string_value_to_value(&Core::get_value_by_name(elements, utf8(b"Ice"))));
        let ice_multiplier = (ice_value / 10);
        if (!frozen_recent && ice_value > 0) {
        vector::push_back(&mut fighter.frozen, now);
       };

        // Lightning Element
        let lightning_value = Core::get_value_value(&Core::degrade_string_value_to_value(&Core::get_value_by_name(elements, utf8(b"Lightning"))));
        let lightning_multiplier = (lightning_value / 10);
        let lightning_dmg = dmg*(lightning_multiplier as u64);
        if(lightning_dmg >= 100){
            chakra = chakra + lightning_dmg/100; 
        };
        hp = hp - lightning_dmg;

        // Water Element
        let water_value = Core::get_value_value(&Core::degrade_string_value_to_value(&Core::get_value_by_name(elements, utf8(b"Water"))));
        let water_multiplier = (water_value / 10);
        let chakra_down = (dmg*(water_multiplier as u64))/100;
        chakra_debt = chakra_debt + (chakra_down as u32);



        // Damage taken over time
        let dmg_taken = deducted_time * enemy_dmg;
        if (dmg_taken >= hp) {
            hp = 0;
        } else {
            let calculated_damage_taken = calculate_damage_taken(dmg_taken, 0, armor);
            hp = hp - calculated_damage_taken;
            if(calculated_damage_taken >= 100){
               chakra = chakra + (calculated_damage_taken/100); 
            };
        };

        // Fire Element DOT
        let fire_value = Core::get_value_value(&Core::degrade_string_value_to_value(&Core::get_value_by_name(elements, utf8(b"Fire"))));
        let fire_multiplier = (fire_value / 10) * 5;
        if (fire_multiplier > 0) {
            let fire_damage = ((fire_multiplier as u64) * hp) / 100;
            hp = hp - calculate_damage_taken(fire_damage, curse_dmg_reduction, armor) ;
            if(calculate_damage_taken(dmg_taken, curse_dmg_reduction,  armor) >= 100){
               chakra = chakra + (calculate_damage_taken(fire_damage, curse_dmg_reduction,  armor)/100); 
            };
        };

        fighter.isFrozen = frozen_recent;
        // Construct updated stats
        vector[
            Core::make_stat(1, hp),
            Core::make_stat(2, dmg),
            Core::make_stat(3, armor),
            Core::make_stat(4, chakra),
            Core::make_stat(5, stamina),
        ]
    }

    fun calculate_damage_taken(damage: u64, dmg_reduction: u64, armor: u64): u64 {
        let k: u64 = 500; 
        if(armor >= 2){
           k = k + (armor/2); 
        };

        let reduced_dmg = damage-((damage*dmg_reduction)/100);
        let reduction_ratio = armor / (armor + k);
        let damage_after_reduction = reduced_dmg * (1 - reduction_ratio);

        return damage_after_reduction
    }


    fun safe_write_elements(): vector<Value> {
        let rage_value = Core::make_value(1, false, 0);
        let endurance_value = Core::make_value(2, false, 0);
        let dopamine_value = Core::make_value(3, false, 0);
        let vitals_value = Core::make_value(4, false, 0);
        let vamp_value = Core::make_value(5, false, 0);
        let wisdom_value = Core::make_value(6, false, 0);
        let fire_value = Core::make_value(101, false, 0);
        let poison_value = Core::make_value(102, false, 0);
        let ice_value = Core::make_value(103, false, 0);
        let lightning_value = Core::make_value(104, false, 0);
        let darkmagic_value = Core::make_value(105, false, 0);
        let water_value = Core::make_value(106, false, 0);
        let curse_value = Core::make_value(107, false, 0);

        vector[
            rage_value, endurance_value, dopamine_value, vitals_value, vamp_value, wisdom_value, fire_value, poison_value, ice_value, lightning_value, darkmagic_value, water_value, curse_value
        ]
    }

        fun is_value_initialized(fighter: &mut Fighter, value: &Value) {
            let len = vector::length(&fighter.elements);
            let  i = 0;
            while (i < len) {
                let existing = vector::borrow_mut(&mut fighter.elements, i);
                if (Core::get_value_ID(value) == Core::get_value_ID(existing)) {
                    let current_amount = Core::get_value_value(existing);
                    let added_amount = Core::get_value_value(value);
                    Core::change_value_amount(existing, current_amount + added_amount);
                    return
                };
                i = i + 1;
            };
        }



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


}}

