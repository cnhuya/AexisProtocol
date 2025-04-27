
module deployer::oracle_corev15{

    use std::signer;
    use std::vector;
    use std::account;
    use std::debug::print;
    use std::string::utf8;
    use std::string;
    use std::timestamp;
    use std::table;
    use supra_oracle::supra_oracle_storage;
    use 0x392727cb3021ab76bd867dd7740579bc9e42215d98197408b667897eb8e13a1f::governance;

    // MODULE ID
    const MODULE_ID: u32 = 5;

    // A wallet thats designed to hold the contract struct permanently.
    const DEPLOYER: address = @deployer;
    // A wallet which purpose is to the prices.
    const OWNER: address = @deployer;


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
    const ERROR_ROUNDING_CANT_BE_HIGHER_THAN_DECIMALS: u64 =9;
    const ERROR_ADDRESS_IS_ALREADY_VALIDATOR: u64 = 10;
    const ERROR_ADDRESS_IS_NOT_VALIDATOR: u64 = 11;
    const ERROR_PROPOSAL_NOT_STARTED: u64 = 12;
    const ERROR_PROPOSAL_NOT_PASSED: u64 = 13;
    const WRONG_HIERARCH: u64 = 14;

    //  CHANGING CODES
    const CODE_CHANGE_TIER: u16 = 1;
    const CODE_CHANGE_REWARDS: u16 = 2;
    const CODE_CHANGE_MAX_VALUES_STORED: u16 = 3;




    struct PRICE has key, drop {price: u128, decimals: u16, time: u64, time_secure: u64}

    struct TIER has key, store, copy, drop {rounding: u8, max_change: u16, reward_multi: u16, min_price_weight: u8}

    /*

    =[= TABLE OF TIER SETTINGS AT GENESIS =]= 
    *subject to change
    
    TIER - A NUMBER (1 TO 5)
    MAX CHANGE - MAXIMUM PRICE IMPACT THAT VALIDATOR INPUTED PRICE CAN BE FROM CURRENT PRICE ORACLE
    REWARD_MULTIPLIER - A REWARD MULTIPLIER FOR SUCCESSFULL VALIDATED PRICE INPUT
    MIN_PRICE_WEIGHT - MINIMAL PRICE AGGREGATION FROM NATIVE SUPRA ORACLE, IF ITS PROVIDED BY SUPRA NATIVE ORACLES

    TIER | MAX_CHANGE | REWARD_MULTIPLIER | MIN_PRICE_WEIGHT
    1          0,01%            1x                  1x
    2          0,025%           2x                  3x
    3          0,05%            3x                  5x
    4          0,1%             4x                  10x
    5          0,2%             5x                  15x

    */

    struct CONTRACT has key, drop, store,copy {deployer: address, owner: address}

    struct TIER_TABLE has key, store {tiers: table::Table<u8, TIER>}

    struct CONFIG has key, store, drop {base_reward: u64, max_values: u64}

    struct VALIDATOR has key, drop, copy, store { isValidator: bool, count: u64, strikes: u8, weight: u8}

    struct VALIDATOR_TABLE has key, store { database: table::Table<u16, table::Table<address, VALIDATOR>>}

    fun init_module(address: &signer){

        if (!exists<CONTRACT>(DEPLOYER)) {
            move_to(address, CONTRACT { deployer: DEPLOYER, owner: OWNER });
        };

        if (!exists<VALIDATOR_TABLE>(DEPLOYER)) {
            let validator_table = table::new<u16, table::Table<address, VALIDATOR>>();
            move_to(address, VALIDATOR_TABLE {database: validator_table});
        };

        if (!exists<TIER>(DEPLOYER)) {
            move_to(address, TIER { rounding: ROUNDING, max_change: 0, reward_multi: 0, min_price_weight:0 });
        };

        if (!exists<CONFIG>(DEPLOYER)) {
            move_to(address, CONFIG { base_reward: 100, max_values: 1000});
        };

        if (!exists<TIER_TABLE>(DEPLOYER)) {
            let price_table = table::new<u8, TIER>();
            let _tier1 = TIER{
                rounding: ROUNDING,
                max_change: 1000,
                reward_multi: 1000,
                min_price_weight: 1,
            };

            let _tier2 = TIER{
                rounding: ROUNDING,
                max_change: 2500,
                reward_multi: 2000,
                min_price_weight: 3,
            };

            let _tier3 = TIER{
                rounding: ROUNDING,
                max_change: 5000,
                reward_multi: 3000,
                min_price_weight: 5,
            };

            let _tier4 = TIER{
                rounding: ROUNDING,
                max_change: 10000,
                reward_multi: 4000,
                min_price_weight: 10,
            };

          let _tier5 = TIER{
                rounding: ROUNDING,
                max_change: 20000,
                reward_multi: 5000,
                min_price_weight: 15,
            };
            table::upsert(&mut price_table, 1, _tier1);
            table::upsert(&mut price_table, 2, _tier2);
            table::upsert(&mut price_table, 3, _tier3);
            table::upsert(&mut price_table, 4, _tier4);
            table::upsert(&mut price_table, 5, _tier5);
            
            move_to(address, TIER_TABLE { tiers: price_table });

        };

    }


    public entry fun removeValidator(address: &signer, moduleID: u16, validator: address) acquires VALIDATOR_TABLE {

        let addr = signer::address_of(address);

        assert!(addr == DEPLOYER, ERROR_NOT_OWNER);

        let validator_db = borrow_global_mut<VALIDATOR_TABLE>(DEPLOYER);
        let validator_module = table::borrow_mut(&mut validator_db.database, moduleID);

        if(!table::contains(validator_module, validator)) {
            abort(ERROR_ADDRESS_IS_NOT_VALIDATOR)
        } 
        else {
            table::remove(validator_module, validator); 
        }
    }




    public entry fun allowValidator(address: &signer, moduleID: u16, validator: address) acquires VALIDATOR_TABLE{

        let addr = signer::address_of(address);
        let (id, address, hierarch, code) = governance::viewHierarch(addr);
        
        assert!(hierarch == b"oracle_core", ERROR_NOT_OWNER);
        assert!(code == 1, WRONG_HIERARCH);
    
        let validator_db = borrow_global_mut<VALIDATOR_TABLE>(DEPLOYER);

        if (!table::contains(&validator_db.database, moduleID)) {
            let validator_table = table::new<address, VALIDATOR>();
            table::add(&mut validator_db.database, moduleID, validator_table); 
        };
        let validator_module = table::borrow_mut(&mut validator_db.database, moduleID);
        if(!table::contains(validator_module, validator)) {
            let _validator = VALIDATOR {
                isValidator: true,
                 count: 0,
                 strikes: 0,
                 weight: 2,
            };
            table::add(validator_module, validator, _validator); 
        } 
          else {
              abort(ERROR_ADDRESS_IS_ALREADY_VALIDATOR)
        };
    }


     entry fun mock_change(code: u16, to: u64 ) acquires CONFIG{
        let config = borrow_global_mut<CONFIG>(DEPLOYER);
        
        if(code == CODE_CHANGE_REWARDS){
            config.base_reward = to;
        } else if (code == CODE_CHANGE_MAX_VALUES_STORED){
            config.max_values = to;
        }
    }


/*    //id: u32, hash: vector<u8>, proposer: address, modul: u32, code: u16, name: vector<u8>, desc: vector<u8>, start: u64, end: u64, stats: PROPOSAL_STATS, status: PROPOSAL_STATUS, from: vector<u8>, to: vector<u8>
    #[view]
    public fun viewProposalByModule_tuple(_module: u32, _code: u16): (u32,address,u16,bool,bool,vector<u8>,vector<u8>) acquires MODULE_TABLE
    {
        let data = viewProposalByModule(_module, _code);
        (data.id, data.proposer, data.code data.status.pending, data.status.passed, data.from, data.to)
    }
*/
    public entry fun change(address: &signer, _code: u16) acquires CONFIG{
        let (id, proposer, code, pending, passed, from, to, type) = governance::viewProposalByModule_tuple(MODULE_ID, _code);
        assert!(passed == true, ERROR_PROPOSAL_NOT_PASSED);
        assert!(signer::address_of(address) == DEPLOYER, ERROR_NOT_OWNER);
        mock_change(code, (to as u64));
    }

    entry fun mock_changeTier(tier: u8, _max_change: u16, _reward_multi: u16, min_price_weight: u8) acquires TIER_TABLE{
        assert!(tier <= 5, ERROR_MAX_TIERS_REACHED);
        let tier_table = borrow_global_mut<TIER_TABLE>(DEPLOYER);
        let _tier = TIER{
            rounding: ROUNDING,
            max_change: _max_change,
            reward_multi: _reward_multi,
            min_price_weight: min_price_weight,
        };

        if (table::contains(&tier_table.tiers, tier)) {
            table::upsert(&mut tier_table.tiers, tier, _tier);
        }
        else{
             table::add(&mut tier_table.tiers, tier, _tier);
        };
    }

    public entry fun changeTier(address: &signer, tier: u8, _max_change: u16, _reward_multi: u16, min_price_weight: u8) acquires TIER_TABLE{
        let (id, proposer, code, pending, passed, from, to, type) = governance::viewProposalByModule_tuple(MODULE_ID, CODE_CHANGE_TIER);
        assert!(passed == true, ERROR_PROPOSAL_NOT_PASSED);
        assert!(signer::address_of(address) == DEPLOYER, ERROR_NOT_OWNER);
        mock_changeTier(tier, _max_change, _reward_multi, min_price_weight);
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
    public fun viewConfig(): (u64, u64) acquires CONFIG {
        let config = borrow_global<CONFIG>(DEPLOYER);
        (config.base_reward, config.max_values) // Returns a tuple of two u64 values
    }


    #[view]
    public fun viewValidator(moduleID: u16, validator: address): VALIDATOR acquires VALIDATOR_TABLE
    {
        let validator_db = borrow_global<VALIDATOR_TABLE>(DEPLOYER);
        let validator_module = table::borrow(&validator_db.database, moduleID);

        if (!table::contains(validator_module, validator)) {
            abort(ERROR_ADDRESS_IS_NOT_VALIDATOR)
        };
        let _validator = *table::borrow(validator_module, validator);

        move _validator
    }


#[view]
public fun viewTier(tier: u8): (u8, u16, u16, u8) acquires TIER_TABLE {
    let tier_table = borrow_global<TIER_TABLE>(DEPLOYER);
    
    if (!table::contains(&tier_table.tiers, tier)) {
        abort(ERROR_INVALID_TIER)
    };

    let tier_data = table::borrow(&tier_table.tiers, tier);
    
    // Destructure the TIER struct and return as a tuple
    (
        tier_data.rounding,      // u8
        tier_data.max_change,    // u16
        tier_data.reward_multi,  // u16
        tier_data.min_price_weight // u8
    )
}

    #[view]
    public fun viewALLTiers(): vector<TIER> acquires TIER_TABLE
    {
        let tier_table = borrow_global<TIER_TABLE>(DEPLOYER);
        let tier_count = 5;
        let tier_vector = vector::empty();
        while(tier_count >0){
            let (rounding, max_change, reward_multi, min_price_weight) = viewTier(tier_count);
            let _tier = TIER{
                rounding: rounding,
                max_change: max_change,
                reward_multi: reward_multi,
                min_price_weight: min_price_weight,
            };
            vector::push_back(&mut tier_vector, _tier);
            tier_count = tier_count-1;
        };

        move tier_vector
    }

    #[view]
    public fun viewPrice(index: u32): u128
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
            deployer: deployer,
            owner: owner,
        };

        move _contract
    }

    #[view]
    public fun returnAggregatedPrice(index: u32, weight: u8, rounding: u16): u128
    {
        let (price, decimals, timestamp, round_id) = supra_oracle_storage::get_price(index);
        assert!(decimals>=rounding, ERROR_ROUNDING_CANT_BE_HIGHER_THAN_DECIMALS);
        let weightened_price = price * (weight as u128);
        let number = decimals-rounding;
        let _decimals = pow(10,(decimals-rounding as u128));
        let price = weightened_price / _decimals;
        move price
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


    #[test(account = @0x1, owner = @0x392727cb3021ab76bd867dd7740579bc9e42215d98197408b667897eb8e13a1f)]
     public entry fun test(account: signer, owner: signer) acquires CONTRACT, TIER_TABLE, CONFIG, VALIDATOR_TABLE {
        timestamp::set_time_has_started_for_testing(&account);  
        init_module(&owner);
        let addr = signer::address_of(&owner);
        //print(&viewPrice(1));
        //print(&viewStructPrice(1));
        print(&viewContract());
        print(&viewALLTiers());
        //print(&viewConfig());
        change(&owner,2);
        //print(&viewConfig());
        allowValidator(&owner, 1, @0x123);
        print(&viewValidator(1, @0x123));
        removeValidator(&owner, 1, @0x123);
        changeTier(&owner, 5, 20000, 5000, 20);
        print(&viewALLTiers());
  }
}   

    
