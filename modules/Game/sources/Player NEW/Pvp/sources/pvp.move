module new_dev::testPVPV21{

    use std::debug::print;
    use std::string::{Self as String, String,utf8};
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
    use deployer::testRacesV5::{Self as Races};

    use new_dev::testPlayerV28::{Self as Player};
    use deployer::testConstantV4::{Self as Constant};

// Structs
    struct QueDatabase has copy,store,drop,key {database: vector<QuedPlayer>}
    struct QuedPlayer has copy,store,drop,key {address: address, name: String}

    struct OnGoingFightDatabase has copy,store,drop,key {database: vector<Fight>}

    struct Fight has copy, store, drop, key {player1: Fighter, player2: Fighter, combat: vector<Cast>, start: u64}

    struct Cast has copy, store, drop, key {caster: String, isPerk: bool, id: u8, calltime: u64}

    struct Fighter has copy, store, drop, key {address: address, name: String, classID: u8, raceID: u8, stats: vector<Stat>, elements: vector<Value>, stamina: u32, chakra_debt: u32, frozen: vector<u64>, isFrozen: bool, accepted: bool}

    struct FighterString has copy, store, drop, key {address: address, name: String, class: String, race: String, stats: vector<StatString>, elements: vector<ValueString>, stamina: u32, chakra_debt: u32, frozen: vector<u64>, isFrozen: bool, accepted: bool}

// Const
    const OWNER: address = @new_dev;

// Errors
    const ERROR_PLAYER_DOESNT_NOT_HAVE_THIS_PERK: u64 = 1;
    const ERROR_PLAYER_IS_NOT_CORRECT_CLASS: u64 = 2;
    const ERROR_PERK_IS_ON_COOLDOWN: u64 = 3;
    const ERROR_PLAYER_DOES_NOT_HAVE_ENOUGH_STAMINA: u64 = 4;
    const ERROR_PLAYER_DOES_NOT_HAVE_ENOUGH_CHAKRA: u64 = 5;
    const ERROR_GAME_NOT_STARTED: u64 = 6;
    const ERROR_FIGHT_DOES_NOT_EXISTS: u64 = 7;
    const ERROR_YOUR_CLASS_DOES_NOT_POSSES_THIS_ABILITY: u64 = 8;

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
    public fun make_fighter(address: address, name: String, accepted: bool, starting_stats: vector<Stat>, classID: u8, raceID: u8): Fighter{
        Fighter {address: address, name: name,  classID: classID, raceID: raceID, stats: starting_stats, elements: vector::empty<Value>(), stamina: 100, chakra_debt: 0, frozen: vector::empty<u64>(), isFrozen: false, accepted: accepted}
    }

    public fun make_string_fighter(fighter: &Fighter): FighterString{
        FighterString {address: fighter.address, name: fighter.name, class: Core::convert_classID_to_String(fighter.classID), race: Core::convert_raceID_to_String(fighter.raceID), stats: Core::build_stats_with_strings(fighter.stats), elements: Core::build_values_with_strings(fighter.elements), stamina: fighter.stamina, chakra_debt: fighter.chakra_debt, frozen:fighter.frozen, isFrozen: fighter.isFrozen, accepted: fighter.accepted}
    }

    public fun make_fight(player1: Fighter, player2: Fighter): Fight{
        Fight {player1: player1, player2: player2, start: timestamp::now_seconds() + 60, combat: vector::empty<Cast>()}
    }


public entry fun delete_fight(name: String) acquires OnGoingFightDatabase {
    let fight_db = borrow_global_mut<OnGoingFightDatabase>(OWNER);

    let i = vector::length(&fight_db.database);

    while (i > 0) {
        i = i - 1;
        let fight_ref = vector::borrow(&fight_db.database, i);
        if (fight_ref.player1.name == name || fight_ref.player2.name == name) {
            vector::remove(&mut fight_db.database, i);
            return  // exit function after deletion
        };
    };

    abort 0;  // abort if no fight found with that name
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
        let cast = Cast {caster: name ,isPerk: true ,id: id,calltime: timestamp::now_seconds()};
        addCast(cast);
    }

        fun addCast(cast: Cast) acquires OnGoingFightDatabase{
            let fight_db = borrow_global_mut<OnGoingFightDatabase>(OWNER);
            let len = vector::length(&fight_db.database);
            let i = 0;
            while (i < len) {
                let f = vector::borrow_mut(&mut fight_db.database, i);
                if (f.player1.name == cast.caster || f.player2.name == cast.caster) {
                    vector::push_back(&mut f.combat, cast);
                    return;
                };
                i = i + 1;
            };

            abort(ERROR_FIGHT_DOES_NOT_EXISTS)
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


    public entry fun castAbility(address: &signer, name: String, id: u8) acquires OnGoingFightDatabase {
        let player = Player::find_player(signer::address_of(address), name);
        
        let fighter = viewFighter(name);

        let chakra = Core::get_stat_value(&Core::degrade_string_stat_to_stat(&Core::get_stat_by_name(fighter.stats, utf8(b"Chakra Absorbtion"))));
        let ability = Classes::viewClassSpell_raw(id);
        assert!(Player::get_player_classID(&player) == Core::get_Ability_classID(&ability), ERROR_YOUR_CLASS_DOES_NOT_POSSES_THIS_ABILITY);
        assert!((chakra as u32) >= Core::get_Ability_required_chakra(&ability), ERROR_PLAYER_DOES_NOT_HAVE_ENOUGH_CHAKRA);
        let cast = Cast {caster: name,isPerk: false ,id: id,calltime: timestamp::now_seconds()};
        addCast(cast);
    }

public entry fun enterQue(address: &signer, name: String) acquires QueDatabase, OnGoingFightDatabase {
    let addr = signer::address_of(address);

    // Ensure player exists
    //assert!(Player::exists(addr, name), 1001); // Error 1001: Player not found
    let player = Player::find_player(addr, name);

    // Ensure queue database exists
    assert!(exists<QueDatabase>(OWNER), 1002); // Error 1002: Queue database missing
    let que_db = borrow_global_mut<QueDatabase>(OWNER);

    // Add player to queue
    let qued_player = QuedPlayer { address: addr, name: name };
    vector::push_back(&mut que_db.database, qued_player);

    // Update player status
    Player::change_player_status(&mut player, 4);

    // Validate queue state
    validateQue(address, name);

    // Update player
    Player::update_player(addr, name, player);
}


    public entry fun exitQue(address: &signer, name: String) acquires QueDatabase{
        removePlayerFromQue(signer::address_of(address),name);
    }

    public entry fun forceFight(address: &signer, name: String, oponent_address: address, oponent_name: String) acquires QueDatabase, OnGoingFightDatabase{
        let addr = signer::address_of(address);
        let player = Player::find_player(signer::address_of(address), name);
        let player2 = Player::find_player(oponent_address, oponent_name);
        let fight_db = borrow_global_mut<OnGoingFightDatabase>(OWNER);
        let fight = make_fight(make_fighter(signer::address_of(address),name, true, Player::viewStats(player), Player::get_player_classID(&player), Player::get_player_raceID(&player)), make_fighter(oponent_address,oponent_name, false, Player::viewStats(player2),Player::get_player_classID(&player2), Player::get_player_raceID(&player2)));
        removePlayerFromQue(signer::address_of(address),name);
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

                    let fighter1 = make_fighter(addr, Player::get_player_name(&player1), true, Player::viewStats(player1),Player::get_player_classID(&player1), Player::get_player_raceID(&player1));
                    let fighter2 = make_fighter(addr2, Player::get_player_name(&player2), true, Player::viewStats(player2),Player::get_player_classID(&player2), Player::get_player_raceID(&player2));
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
                let fighter2 = simulated_fight.player2;
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
        let vect = vector::empty<StatString>();
        while(len > 0){
            let now = timestamp::now_seconds();
            let stat = vector::borrow(&fighter.stats, len-1);
            let _stat = Core::make_string_stat(&Core::degrade_string_stat_to_stat(stat));
            vector::push_back(&mut vect, _stat);
            len=len-1;
        };
        vect
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

    // Immutable borrow first
    let all_casts = &fight.combat;
    let len = vector::length(all_casts);
    let last_time = fight.start;

    // Mutable borrows

    fight.player1.elements = safe_write_elements(Races::extract_race_elements(fight.player1.raceID));
    fight.player2.elements = safe_write_elements(Races::extract_race_elements(fight.player2.raceID));


    let chakra1 = calculate_chakra_total_costs(fight.player1.name, *all_casts);
    let chakra2 = calculate_chakra_total_costs(fight.player2.name, *all_casts);
    //let enemy_name = &fight.player1.name;
    //let fighter_name = &fight.player2.name;

    let i = 0;
    while (i < len) {
        let cast = vector::borrow(all_casts, i);
        let current_time = cast.calltime;
        let time_elapsed = if (current_time >= last_time) { current_time - last_time } else { 0 };

        // Explicit mutable references
        let fighter = &mut fight.player1;
        let enemy = &mut fight.player2;

        fighter.stats = overwrite_stats(fighter, enemy, time_elapsed, *all_casts, chakra1);
        enemy.stats = overwrite_stats(enemy, fighter, time_elapsed, *all_casts, chakra2);

        if (cast.isPerk) {
            let real_perk = Perks::viewPerkByID_raw(cast.id);
            apply_values(fighter, enemy, Core::get_perk_values(&real_perk), (Core::get_perk_stamina(&real_perk) as u32), true);
        } else {
            let real_ability = Classes::viewClassSpell_raw(cast.id);
            apply_values(fighter, enemy, Core::get_Ability_values(&real_ability), (Core::get_Ability_required_chakra(&real_ability) as u32), false);
        };

        last_time = current_time;
        i = i + 1;
    };

    let remaining_time = now - last_time;

    // Re-borrow after loop
    let fighter = &mut fight.player1;
    let enemy = &mut fight.player2;

    fighter.stats = overwrite_stats(fighter, enemy, remaining_time, *all_casts, chakra1);
    enemy.stats = overwrite_stats(enemy, fighter, remaining_time, *all_casts,chakra2);

    fight
}



#[view]
    public fun getcost(id: u8): u32{
        let real_ability = Classes::viewClassSpell_raw(id);
        (Core::get_Ability_required_chakra(&real_ability) as u32)
}

    fun apply_values(fighter: &mut Fighter, enemy: &mut Fighter, values: vector<Value>, cost: u32, isPerk: bool) {
        if (isPerk) {
            fighter.stamina = (safe_sub((fighter.stamina as u64), (cost as u64)) as u32);
        };

        let len = vector::length(&values);
        let i = 0;
        while (i < len) {
            let value = vector::borrow(&values, i);
            let is_enemy = Core::get_value_isEnemy(value);
            if (is_enemy) {
                is_value_initialized(fighter, value);
            } else {
                is_value_initialized(enemy, value);
            };
            i = i + 1;
        };
    }


    fun safe_sub(a: u64, b: u64): u64 {
        if (b >= a) {
            0
        } else {
            a - b
        }
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

fun calculate_chakra_total_costs(name: String, casts: vector<Cast>): u64 {
    let total_chakra_cost = 0;
    let i = vector::length(&casts);

    while (i > 0) {
        let cast = vector::borrow(&casts, i - 1);

        if (cast.caster == name && !cast.isPerk) {
            let ability = Classes::viewClassSpell_raw(cast.id);
            //abort(1000); // Add this to confirm name matches
            total_chakra_cost = total_chakra_cost + (Core::get_Ability_required_chakra(&ability) as u64);
        };
        i = i - 1;
    };
    total_chakra_cost
}


    fun overwrite_stats(fighter: &mut Fighter, enemy: &Fighter, time_elapsed: u64, casts: vector<Cast>, _chakra: u64): vector<Stat>{

        let stats = fighter.stats;
        let _stats = Core::build_stats_with_strings(stats);
        let dmg = Core::get_stat_value(&Core::degrade_string_stat_to_stat(&Core::get_stat_by_name(_stats, utf8(b"Damage"))));
        let hp = Core::get_stat_value(&Core::degrade_string_stat_to_stat(&Core::get_stat_by_name(_stats, utf8(b"Health"))));
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

        let curse_value = Core::get_value_value(&Core::degrade_string_value_to_value(&Core::get_value_by_name(elements, utf8(b"Curse"))));
        curse_dmg_reduction = ((curse_value / 10)*3 as u64);
        // Rage Element
        let rage_value = Core::get_value_value(&Core::degrade_string_value_to_value(&Core::get_value_by_name(elements, utf8(b"rage"))));
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
        hp = safe_sub(hp, poison_dmg);

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
        hp = safe_sub(hp, lightning_dmg);

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
            hp = safe_sub(hp, calculate_damage_taken(fire_damage, curse_dmg_reduction, armor));
            if(calculate_damage_taken(dmg_taken, curse_dmg_reduction,  armor) >= 100){
               chakra = chakra + (calculate_damage_taken(fire_damage, curse_dmg_reduction,  armor)/100); 
            };
        };
        //let chakra_cost = calculate_chakra_total_costs(name, casts);
        //abort(chakra_cost);
        //chakra = chakra - calculate_chakra_total_costs(name, casts);
        fighter.chakra_debt = (_chakra as u32);
        fighter.isFrozen = frozen_recent;
        // Construct updated stats
        vector[
            Core::make_stat(1, hp),
            Core::make_stat(2, armor),
            Core::make_stat(3, dmg),
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


    fun safe_write_elements(values: vector<Value>): vector<Value> {
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

        let vect = vector[
            rage_value, endurance_value, dopamine_value, vitals_value, vamp_value, wisdom_value,
            fire_value, poison_value, ice_value, lightning_value, darkmagic_value, water_value, curse_value
        ];

        let i = vector::length(&vect);
        while (i > 0) {
            let value = vector::borrow_mut(&mut vect, i - 1);
            let k = vector::length(&values);
            while (k > 0) {
                let class_value = vector::borrow(&values, k - 1);
                if (Core::get_value_ID(class_value) == Core::get_value_ID(value)) {
                    let _value = Core::get_value_value(value);
                    Core::change_value_amount(
                        value,
                        _value + Core::get_value_value(class_value)
                    );
                };
                k = k - 1;
            };
            i = i - 1;
        };

        vect
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

#[view]
public fun rewardDeduction(winnerPower: u64, loserPower: u64): u16 {
    let maxDeduction = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"PVP"), utf8(b"reward_deduction_Cap"))) as u64); // e.g., 98
    let c = (Constant::get_constant_value(&Constant::viewConstant(utf8(b"PVP"), utf8(b"reward_deduction_slowDown"))) as u64); // e.g., 98

    let higherPower: u64;
    let lowerPower: u64;
    if (winnerPower > loserPower) {
        higherPower = winnerPower;
        lowerPower = loserPower;
    } else {
        higherPower = loserPower;
        lowerPower = winnerPower;
    };

    if (lowerPower == 0) {
        return (maxDeduction as u16)
    };

    let gap = (higherPower * 100) / lowerPower;  // e.g., 120 for 1.2

    let gapDiff = gap - 100;

    // fraction = gapDiff / (gapDiff + C)
    let fraction = (gapDiff * 1000) / (gapDiff + c); // scaled by 1000 for precision

    let deduction = (maxDeduction * fraction) / 1000;

    if (deduction > maxDeduction) {
        return (maxDeduction as u16)
    };

    return (deduction as u16)
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

