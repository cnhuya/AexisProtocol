
module deployer::oracle_core{

    use std::signer;
    use std::vector;
    use std::account;
    use std::debug::print;
    use std::string::utf8;
    use std::string;
    use std::timestamp;
    use std::table;
    use supra_oracle::supra_oracle_storage;
   // use 0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020::hierarchy;
   // use 0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020::errors;
   // use 0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020::governance;
   // use 0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020::timev3;
   // use 0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020::oracle_core;

    // MODULE ID
    const MODULE_ID: u16 = 5;

    // A wallet thats designed to hold the contract struct permanently.
    const DEPLOYER: address = @deployer;
    // A wallet which purpose is to the prices.
    const OWNER: address = @owner;


    //CONFIG 
    const ROUNDING: u8 = 5;

    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_NUMBER_TOO_BIG: u64 = 2;
    const ERROR_INVALID_RANGE: u64 = 3;
    const ERROR_CLOSE_CANT_BE_HIGHER_THAN_HIGHEST: u64 = 4;
    const ERROR_CLOSE_CANT_BE_LOWER_THAN_LOWEST: u64 = 5;
    const ERROR_COUNTER_DOESNT_EXISTS: u64 = 6;
    const ERROR_INVALID_TIER: u64 =7;
    const ERROR_MAX_TIERS_REACHED: u64 =8;


    //  CHANGING CODES
    const CODE_CHANGE_TIER: u8 = 1;



    struct PRICE has key, drop {price: u128, decimals: u16, time: u64, time_secure: u64}

    struct TIER has key, store, copy, drop {rounding: u8, max_change: u16, reward_multi: u16, min_price_aggregation: u8}

    /*

    =[= TABLE OF TIER SETTINGS AT GENESIS =]= 
    *subject to change
    
    TIER - A NUMBER (1 TO 5)
    MAX CHANGE - MAXIMUM PRICE IMPACT THAT VALIDATOR INPUTED PRICE CAN BE FROM CURRENT PRICE ORACLE
    REWARD_MULTIPLIER - A REWARD MULTIPLIER FOR SUCCESSFULL VALIDATED PRICE INPUT
    MIN_PRICE_AGGREGATION - MINIMAL PRICE AGGREGATION FROM NATIVE SUPRA ORACLE, IF ITS PROVIDED BY SUPRA NATIVE ORACLES

    TIER | MAX_CHANGE | REWARD_MULTIPLIER | MIN_PRICE_AGGREGATION
    1          0,01%            1x                  1x
    2          0,025%           2x                  3x
    3          0,05%            3x                  5x
    4          0,1%             4x                  10x
    5          0,2%             5x                  15x

    */

    struct CONTRACT has key, drop, store,copy {base_reward: u8, deployer: address, owner: address}

    struct TIER_TABLE has key, store {tiers: table::Table<u8, TIER>}


    fun init_module(address: &signer) acquires TIER_TABLE{

        if (!exists<CONTRACT>(DEPLOYER)) {
            move_to(address, CONTRACT { base_reward: 1, deployer: DEPLOYER, owner: OWNER });
        };

        if (!exists<TIER>(DEPLOYER)) {
            move_to(address, TIER { rounding: ROUNDING, max_change: 0, reward_multi: 0, min_price_aggregation:0 });
        };

        if (!exists<TIER_TABLE>(DEPLOYER)) {
            let price_table = table::new<u8, TIER>();
            move_to(address, TIER_TABLE { tiers: price_table });
        };

        changeTier(1, 1000, 1000, 1);
        changeTier(2, 2500, 2000, 3);
        changeTier(3, 5000, 3000, 5);
        changeTier(4, 10000, 4000, 10);
        changeTier(5, 20000, 5000, 15);
    }


    entry fun changeTier(tier: u8, _max_change: u16, _reward_multi: u16, _min_price_aggregation: u8) acquires TIER_TABLE{
        assert!(tier <= 5, ERROR_MAX_TIERS_REACHED);
        let tier_table = borrow_global_mut<TIER_TABLE>(DEPLOYER);
        let _tier = TIER{
            rounding: ROUNDING,
            max_change: _max_change,
            reward_multi: _reward_multi,
            min_price_aggregation: _min_price_aggregation,
        };

        if (table::contains(&tier_table.tiers, tier)) {
            table::upsert(&mut tier_table.tiers, tier, _tier);
        }
        else{
             table::add(&mut tier_table.tiers, tier, _tier);
        };
    }

    #[view]
    public fun viewStructPrice(index: u32): PRICE
    {
        let (price, decimals, timestamp, round_id) = supra_oracle_storage::get_price(index);
        let _price = PRICE{
            price: price,
            decimals: decimals,
            time: timestamp,
            time_secure: round_id,
        };
        move _price
    }


    #[view]
    public fun viewTier(tier: u8): TIER acquires TIER_TABLE
    {
        let tier_table = borrow_global<TIER_TABLE>(DEPLOYER);
        
        if (!table::contains(&tier_table.tiers, tier)) {
            abort(ERROR_INVALID_TIER)
        };

        let  tier = *table::borrow(&tier_table.tiers, tier);

        move tier
    }

    #[view]
    public fun viewALLTiers(): vector<TIER> acquires TIER_TABLE
    {
        let tier_table = borrow_global<TIER_TABLE>(DEPLOYER);
        let tier_count = 5;
        let tier_vector = vector::empty();
        while(tier_count >0){
            let tier = viewTier(tier_count);
            vector::push_back(&mut tier_vector, tier);
            tier_count = tier_count-1;
        };

        move tier_vector
    }

    #[view]
    public fun viewPrice(index: u32): u64
    {
        let (price, decimals, timestamp, round_id) = supra_oracle_storage::get_price(index);
        move price
    }

    #[view]
    public fun viewContract(): CONTRACT acquires CONTRACT
    {
        let deployer = viewDeployer();
        let owner = viewOwner();

        let contract = borrow_global<CONTRACT>(DEPLOYER);
        let _contract = CONTRACT{
            base_reward: contract.base_reward,
            deployer: deployer,
            owner: owner,
        };

        move _contract
    }

    #[view]
    public fun returnAggregatedPrice(index: u32, weight: u8): u64
    {
        let (price, decimals, timestamp, round_id) = supra_oracle_storage::get_price(index);
        let weightened_price = price * (weight as u128);
        move weightened_price
    }


    #[view]
    public fun pow(base: u128, exponent: u128): u128
    {
        let result = 1;
        let i = 0;
        while (i < exponent) {
            result = result * base;
            i = i + 1;
        };
        move result
    }


    #[view]
    public fun viewDeployer(): address acquires CONTRACT
    {
        let _contract = borrow_global_mut<CONTRACT>(DEPLOYER);
        let deployer = _contract.deployer;
        move deployer
    }


    #[view]
    public fun viewOwner(): address acquires CONTRACT
    {
        let _contract = borrow_global_mut<CONTRACT>(DEPLOYER);
        let owner = _contract.owner;
        move owner
    }


    #[test(account = @0x1, owner = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020)]
     public entry fun test(account: signer, owner: signer) acquires CONTRACT, TIER_TABLE {
        timestamp::set_time_has_started_for_testing(&account);  
        init_module(&owner);
        let addr = signer::address_of(&owner);
        //print(&viewPrice(1));
        //print(&viewStructPrice(1));
        print(&viewContract());
        print(&viewALLTiers());
  }
}   

    
