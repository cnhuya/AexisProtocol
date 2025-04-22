
module deployer::oracleHolderv7{

    use std::signer;
    use std::vector;
    use std::account;
    use std::debug::print;
    use std::string::utf8;
    use std::string;
    use std::table;
    use supra_oracle::supra_oracle_storage;
   // use 0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020::hierarchy;
   // use 0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020::errors;
// use 0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020::governancev44;
    use 0x392727cb3021ab76bd867dd7740579bc9e42215d98197408b667897eb8e13a1f::oracle_corev30::TIER;
    use 0x1928893148d317947c302185417e2c1d32640c6ef8521b48e1ae6308ab1a41c3::smart_math;
    use 0x1928893148d317947c302185417e2c1d32640c6ef8521b48e1ae6308ab1a41c3::time;
    //use 0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020::oracle_corev3;

    // MODULE ID
    const MODULE_ID: u16 = 6;

    const DEPLOYER: address = @deployer;
    const MESSAGER: address = @deployer;

    const NAME: vector<u8> = b"ETHEREUM";
    const SYMBOL: vector<u8> = b"ETH";
    const DECIMALS: u16 = 2;
    const INDEX: u32 = 2;
    const TIER: u8 = 1;

    const ERROR_NOT_OWNER: u64 = 1; 
    const ERROR_NUMBER_TOO_BIG: u64 = 2;
    const ERROR_INVALID_RANGE: u64 = 3;
    const ERROR_CLOSE_CANT_BE_HIGHER_THAN_HIGHEST: u64 = 4;
    const ERROR_CLOSE_CANT_BE_LOWER_THAN_LOWEST: u64 = 5;
    const ERROR_COUNTER_DOESNT_EXISTS: u64 = 6;
    const ERROR_CONTRACT_DOESNT_EXISTS: u64 = 7;
    const ERROR_MAXIMUM_SMOOTH_IS_60: u64 = 8;
    const ERROR_HISTORICAL_PRICE_NOT_FOUND: u64 = 9;
    const ERROR_SAME_PRICE: u64 = 10;
    const ERROR_NOT_MESSAGER: u64 = 11;
    const ERROR_ADDRESS_IS_NOT_VALIDATOR: u64 = 12;
    const ERROR_ADDRESS_ALREADY_VALIDATOR: u64 = 13;
    const ERROR_PRICE_IMPACT_TOO_BIG: u64 = 14;
    const ERROR_INVALID_PRICE: u64 = 15;
    const ERROR_NOT_ENOUGH_DATA: u64 = 16;
    const ERROR_DONT_HAVE_PERMISSION: u64 = 17;
    const ERROR_NOT_ENOUGH_POINTS: u64 = 18;
    const ERROR_VECTOR_IS_EMPTY: u64 = 19;
    const ERROR_ADDITIONAL_OHCL_OVER_PUBLISH_TIME: u64 = 20;

    //  CHANGING CODES
    const CODE_CHANGE_OWNER: u8 = 1;
    const CODE_CHANGE_MESSAGER: u8 = 2;


    struct POINTS has key {points: u64}

    struct CONTRACT has key, drop, store,copy {name: vector<u8>, symbol: vector<u8>, decimals: u16, deployer: address, messager: address, index: u32}

    struct CONFIG has key, store, drop {tier: u8 }

    struct PRICE has store, key, copy, drop{ sender: address, timestamp: u64, price: u64, weight: u8  }

    struct ACTUAL_PRICE has store, key, copy, drop{ price: u64 }

    struct OHCL has store, key, copy, drop{ start: u64, o: u64, h: u64, c: u64, l: u64 }

    struct DATABASE has store, drop, key,copy {database: vector<PRICE>}

    struct FAKE_DATABASE has key, store, drop, copy {database: vector<PRICE>}

    struct EMPTY_VEC has key, store {database: vector<PRICE>}


    fun init_module(address: &signer) {


        //    struct TIER has key, store, copy, drop {rounding: u8, max_change: u16, reward_multi: u16, min_price_weight: u8}
        let tier = oracle_corev30::viewTier(1);

        if (!exists<CONTRACT>(DEPLOYER)) {
            move_to(address, CONTRACT { name: NAME, symbol: SYMBOL, decimals: DECIMALS, deployer: DEPLOYER, messager: MESSAGER, index: INDEX });
        };

        if (!exists<PRICE>(DEPLOYER)) {
            move_to(address, PRICE { sender: @0x1, timestamp: 0, price: 0, weight: 1 });
        };

        if (!exists<ACTUAL_PRICE>(DEPLOYER)) {
            move_to(address, ACTUAL_PRICE {price: 10000});
        };

        if (!exists<CONFIG>(DEPLOYER)) {
            move_to(address, CONFIG {tier: 1 });
        };

        if (!exists<POINTS>(DEPLOYER)) {
            move_to(address, POINTS { points: 0});
        };

        if (!exists<DATABASE>(DEPLOYER)) {
            move_to(address, DATABASE { database: vector::empty() });
        };

        if (!exists<FAKE_DATABASE>(DEPLOYER)) {
            move_to(address, FAKE_DATABASE { database: vector::empty() });
        };

    }

    entry fun addPoints(address: &signer, value: u64) acquires POINTS {
        if (!exists<POINTS>(signer::address_of(address))) {
            move_to(address, POINTS { points: 0});
        };
        let balance = borrow_global_mut<POINTS>(signer::address_of(address));
        balance.points = balance.points + value;
    }


    entry fun removePoints(address: &signer, value: u64) acquires POINTS {
        let balance = borrow_global_mut<POINTS>(signer::address_of(address));
        assert!(balance.points > value, ERROR_NOT_ENOUGH_POINTS);
        balance.points = balance.points - value;
    }



    entry fun savePrice(address: &signer, _price: u64, _weight: u8) acquires DATABASE, FAKE_DATABASE, POINTS, ACTUAL_PRICE, CONFIG {
        let time_minutes = 0;

        //if (!exists<FAKE_DATABASE>(DEPLOYER)) {
         //   move_to(address, DATABASE { database: vector::empty() });
        //};

        let config = borrow_global<CONFIG>(DEPLOYER);
        let database = borrow_global_mut<FAKE_DATABASE>(DEPLOYER);
        let actual_price = borrow_global_mut<ACTUAL_PRICE>(DEPLOYER);

        let new_price = PRICE {
            sender: signer::address_of(address),
            timestamp: time_minutes,
            price: _price,
            weight: _weight,
        };


        vector::push_back(&mut database.database, new_price);  

        if(vector::length(&database.database) > 100){
            let real_database = borrow_global_mut<DATABASE>(DEPLOYER);
            while(vector::length(&database.database) > 0){
                let old_price = vector::pop_back(&mut database.database);
                vector::push_back(&mut real_database.database, old_price);
                addPoints(address, 2000);
            };


            print(&utf8(b"REAL DATABASE"));
            print(&real_database.database);

            print(&utf8(b"FAKE DATABASE"));
            print(&database.database);

          //  vector::destroy_empty(database.database);
          //  move_from<FAKE_DATABASE>(DEPLOYER);

        };
        

        //10000 + (10080 * 2) / 3
        actual_price.price = ((actual_price.price + (_price * (_weight as u64))) / ((_weight as u64)+1));
        addPoints(address, 1000);
    }

    public entry fun fetchPrice(address: &signer, _price: u64) acquires DATABASE, FAKE_DATABASE, ACTUAL_PRICE, POINTS, CONFIG
      {
        let addr = signer::address_of(address);

       // let validator = borrow_global_mut<VALIDATOR>(addr);
      //  assert!(validator.isValidator == true || addr == MESSAGER, ERROR_DONT_HAVE_PERMISSION);
       // let weightened_price = _price * (validator.weight as u64);


        let price_change = antiManipulation(_price);
        

        let pow = smart_math::pow(10, (DECIMALS as u256));
        if(price_change > 5 * (pow as u64)) {
           // validator.strikes = validator.strikes + 1;
            abort(ERROR_PRICE_IMPACT_TOO_BIG)
        }
        else{
            savePrice(address, _price, 2);
            //validator.count = validator.count + 1;
        }

    }

    #[view] // view function, which returns price from all saved prices as argument.
    public fun viewAllPrices(): vector<PRICE> acquires DATABASE, FAKE_DATABASE
    {
        let database = borrow_global<FAKE_DATABASE>(DEPLOYER);
        let real_database = borrow_global<DATABASE>(DEPLOYER);
        let prices_vector = real_database.database;
        vector::append(&mut prices_vector, database.database);

        move prices_vector
    }


    #[view] // view function, which returns price from all saved prices as argument.
    public fun viewPastPricesInMinute(validator: address): vector<PRICE> acquires DATABASE, FAKE_DATABASE
    {
        let vect = vector::empty();
        let prices_vector = viewAllPrices();
        let leng = vector::length(&prices_vector);
        while(leng > 0){
            let oracle = vector::borrow(&prices_vector, leng-1); 

            let price = PRICE {
                sender: oracle.sender,
                timestamp: oracle.timestamp,
                price: oracle.price,
                weight: oracle.weight,
            };

            if(oracle.sender == validator){
              vector::push_back(&mut vect, price);
            };

            leng = leng - 1;
        };
        move vect
    }


  /*  #[view] // view function, which returns current price
    public fun viewCurrentPriceWithNativeOracle(): u128 acquires  CONFIG, ACTUAL_PRICE
    {

        let current_price = viewCurrentPrice();
        let config = borrow_global<CONFIG>(DEPLOYER);
       // let native_oracle = oracle_corev3::returnAggregatedPrice(config.index, config.weight, config.decimals);
        //let return_price = (current_price*(100-(config.weight as u128)) + native_oracle) / ((1+config.weight) as u128);
        let return_price = (current_price*(100-(config.weight as u128))) / ((1+config.weight) as u128);
        move return_price
    }*/

   #[view] // view function, which returns current price
    public fun viewCurrentPrice(): u128 acquires ACTUAL_PRICE
    {
        let actual_price = borrow_global<ACTUAL_PRICE>(DEPLOYER);
        let price = (actual_price.price as u128);

        move price
    }
   

  /*  #[view] // view function, which returns ohcl between interval -> arg-1 | arg-2
    public fun viewOHCL(count: u64): OHCL acquires DATABASE, FAKE_DATABASE 
    {

        let _ohcl: OHCL;
        let database = borrow_global_mut<PRICE_DATABASE>(DEPLOYER);
        let prices_vector = table::borrow(&database.database, count);
        let len = vector::length(prices_vector);
        assert!(len > 0, ERROR_VECTOR_IS_EMPTY);
        let open = 0;
        let high = 0;
        let close = 0;
        let end = 0;
        let low = 1000000000u64;

        while (len > 0) {
            let price = vector::borrow(prices_vector, len-1);
            let pastPrice = price.price / (price.weight as u64);
            if(pastPrice > close)

            if(len == 1){
                open = pastPrice
            };
            if(low > pastPrice){
                low = pastPrice
            };
            if(high < pastPrice){
                high = pastPrice
            };
            if(close == 0){
                close = pastPrice
            };
            len = len - 1; // Increment the index
        };

            _ohcl = OHCL {
                start: count,
                o: open,
                h: high,
                c: close,
                l: low,
            };

        move _ohcl // Return the vector of OHCL structs
    }
*/
    #[view] // view function, which returns the reward points of validators
    public fun viewPoints(addr: address): u64 acquires POINTS
    {
        //assert!(exists<VALIDATOR>(addr), ERROR_ADDRESS_IS_NOT_VALIDATOR);
        let balance = borrow_global_mut<POINTS>(addr);
        let display = balance.points;
        move display
    }

    #[view]
    fun antiManipulation(price: u64): u64 acquires ACTUAL_PRICE {
        let percentage_change = 0;
        let current_price = (viewCurrentPrice() as u64);

        let diff;

        if (current_price >= price) {
            diff = current_price - price;
         } else {
            diff = price - current_price;
        };
        // 0.64% = 68
        if(current_price != 0 ){
            percentage_change = (((diff as u64) * 100)  * (smart_math::pow(10, (DECIMALS as u256)) as u64) / (current_price as u64));   
            print(&percentage_change);
            print(&diff);
            print(&current_price);
        }
        else{
            //abort(99999);
        };

        move percentage_change
    }

    #[view]
    public fun viewContract(): CONTRACT acquires CONTRACT
    {
        
        let contract = CONTRACT{
            name: NAME,
            symbol: SYMBOL,
            decimals: DECIMALS,
            deployer: viewDeployer(),
            messager: viewMessager(),
            index: INDEX,
        };

        move contract
    }

        #[view]
    public fun viewConfig(): CONFIG acquires CONFIG
    {
        let config = borrow_global<CONFIG>(DEPLOYER);   
        let _config = CONFIG{
            tier: config.tier,
        };

        move _config
    }


    #[view]
    public fun viewDeployer(): address acquires CONTRACT
    {
        let _contract = borrow_global_mut<CONTRACT>(DEPLOYER);
        let deployer = _contract.deployer;
        move deployer
    }

    #[view]
    public fun viewDecimals(): u16 acquires CONTRACT
    {
        let _contract = borrow_global_mut<CONTRACT>(DEPLOYER);
        let decimals = _contract.decimals;
        move decimals
    }


    #[view]
    public fun viewMessager(): address acquires CONTRACT
    {
        let _contract = borrow_global_mut<CONTRACT>(DEPLOYER);
        let messager = _contract.messager;
        move messager
    }


 
    #[test(account = @0x1, owner = @0x392727cb3021ab76bd867dd7740579bc9e42215d98197408b667897eb8e13a1f)]
     public entry fun test(account: signer, owner: signer) acquires DATABASE, FAKE_DATABASE, POINTS, ACTUAL_PRICE, CONFIG {
        //timestamp::set_time_has_started_for_testing(&account);  
        init_module(&owner);
        let addr = signer::address_of(&owner);
        let addr2 = signer::address_of(&account);
        addPoints(&owner, 400000000);
        fetchPrice(&owner, 10080);
        fetchPrice(&owner,  10096);
        fetchPrice(&owner,  10080);
        fetchPrice(&owner,  10000);
        fetchPrice(&owner,  10020);
        fetchPrice(&owner,  9990);
        fetchPrice(&owner,  9990);
       // allowValidator(&owner, addr2);
        //let pastprice = viewPastPrice(0);
        //print(&pastprice);
        //print(&utf8(b"OHCL"));
       // print(&viewOHCL(1));
      //  print(&viewContract());
        print(&utf8(b"ALL PRICES"));
        print(&viewAllPrices());
        print(&utf8(b"SMOOTH PRICE"));
       // print(&viewSmoothPrice(viewCounter()));
      //  print(&utf8(b"PAST PRICE"));
    //    print(&viewPastPrice(1, 3));
        print(&utf8(b"POINTS"));
        print(&viewPoints(addr));
        print(&utf8(b"CURRENT PRICE"));
        print(&viewCurrentPrice());
        print(&utf8(b"viewPastPricesInMinute PRICE"));
        print(&viewPastPricesInMinute(@0x392727cb3021ab76bd867dd7740579bc9e42215d98197408b667897eb8e13a1f));
        //print(&viewPrice(1));
        //let (price, decimals, timestamp, round_id) = supra_oracle_storage::get_price(1);
        //print(&price);       // Print the u128 value
  }
}   

    
