
module testing::oraclev5{

    use std::signer;
    use std::vector;
    use std::account;
    use std::debug::print;
    use std::string::utf8;
    use std::string;
    use std::timestamp;
    use 0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020::utilizationv4;


    // A wallet thats designed to hold the contract struct permanently.
    const DEPLOYER: address = @testing;
    // A wallet thats designed to update values such as ratio, or change who the messager/oracle/vault is.
    const OWNER: address = @owner;
    // A wallet which purpose is to store the user data, and the user database.
    const MESSANGER: address = @messager;

    const NAME: vector<u8> = b"ETHEREUM";
    const SYMBOL: vector<u8> = b"ETH";
    const DECIMALS: u8 = 18;

    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_NUMBER_TOO_BIG: u64 = 2;
    const ERROR_INVALID_RANGE: u64 = 3;
    const ERROR_CLOSE_CANT_BE_HIGHER_THAN_HIGHEST: u64 = 4;
    const ERROR_CLOSE_CANT_BE_LOWER_THAN_LOWEST: u64 = 5;

    struct COUNTER has key { count: u64 }

    struct CONTRACT has key, drop, store,copy {name: vector<u8>, symbol: vector<u8>, decimals: u8, deployer: address, owner: address, messager: address}

    struct PRICE has store, key, copy, drop{ timespan: u64, price: u32 }

    struct PRICE_DATABASE has key{ database: vector<PRICE>, }


    fun init_module(address: &signer) {

        if (!exists<CONTRACT>(DEPLOYER)) {
            move_to(address, CONTRACT { name: NAME, symbol: SYMBOL, decimals: DECIMALS, deployer: DEPLOYER, owner: OWNER, messager: MESSANGER });
        };

        if (!exists<PRICE>(DEPLOYER)) {
            move_to(address, PRICE { timespan: 0, price: 0 });
        };

        if (!exists<PRICE_DATABASE>(DEPLOYER)) {
            move_to(address, PRICE_DATABASE { database: vector::empty() });
        };

        if (!exists<COUNTER>(DEPLOYER)) {
            move_to(address, COUNTER { count: 0 });
        };

    }

    public entry fun fetchPrice(address: &signer, _price: u32) acquires PRICE_DATABASE, COUNTER, PRICE
      {
        let addr = signer::address_of(address);

        assert!(addr == OWNER, ERROR_NOT_OWNER);

        let price = borrow_global_mut<PRICE>(DEPLOYER);
        let time = timestamp::now_seconds();


        let counter = borrow_global_mut<COUNTER>(DEPLOYER);
        counter.count = counter.count + 1;

        let new_price = PRICE {
            timespan: time,
            price: _price,
        };
        let database = borrow_global_mut<PRICE_DATABASE>(DEPLOYER);
        vector::push_back(&mut database.database, new_price);
    }



    #[view]
    public fun viewPastPrice(count: u64): PRICE acquires PRICE_DATABASE, COUNTER
    {
        let counter = borrow_global_mut<COUNTER>(DEPLOYER);
        assert!(count <= counter.count, count);
        let database = borrow_global<PRICE_DATABASE>(DEPLOYER);    
        let oracle = vector::borrow(&database.database, count);

        let new_ohcl = PRICE {
            timespan: oracle.timespan,
            price: oracle.price,
        };
        move new_ohcl
    }

#[view]
    public fun viewCurrentPrice(): u32 acquires COUNTER, PRICE_DATABASE
    {
        let counter = borrow_global_mut<COUNTER>(DEPLOYER);
        let database = borrow_global_mut<PRICE_DATABASE>(DEPLOYER);
        let oracle = vector::borrow(&database.database, counter.count-1); 
        let _test = oracle.price;
        move _test
    }
    

#[view]
    public fun viewHistoricalRangePrice(count1: u64, count2: u64): vector<PRICE> acquires PRICE_DATABASE, COUNTER
    {
        let counter = borrow_global_mut<COUNTER>(DEPLOYER);

        // Assert that count1 and count2 are within valid bounds (assuming 0-based indexing)
        assert!(count1 < counter.count, ERROR_NUMBER_TOO_BIG); // count1 must be a valid index
        assert!(count2 < counter.count, ERROR_NUMBER_TOO_BIG); // count2 must be a valid index
        assert!(count1 <= count2, ERROR_INVALID_RANGE); // count1 must be less than or equal to count2

        let database = borrow_global<PRICE_DATABASE>(DEPLOYER);

        let result_vector = vector::empty<PRICE>();
        while (count1 <= count2) {
            let oracle = vector::borrow(&database.database, count1); // Borrow OHCL at current index

            let new_ohcl = PRICE {
                timespan: oracle.timespan,
                price: oracle.price,
            };
            vector::push_back(&mut result_vector, new_ohcl); // Add the OHCL to the result vector
            count1 = count1 + 1; // Increment the index
        };

        move result_vector // Return the vector of OHCL structs
    }


    #[view]
    public fun view_COUNTER(addr: address): u64 acquires COUNTER
    {

        assert!(exists<COUNTER>(addr), 1024);
        let count = borrow_global_mut<COUNTER>(addr);
        let display = count.count;
        print(&count.count);

        move display
    }

    

 
    #[test(account = @0x1, owner = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020)]
     public entry fun test(account: signer, owner: signer) acquires COUNTER, PRICE, PRICE_DATABASE {
        timestamp::set_time_has_started_for_testing(&account);  
        init_module(&owner);
        let addr = signer::address_of(&owner);
        fetchPrice(&owner, 11);
        fetchPrice(&owner,  11);
        fetchPrice(&owner,  5);
        fetchPrice(&owner,  7);
        fetchPrice(&owner,  6);
        fetchPrice(&owner,  9);
        view_COUNTER(addr);
        let pastprice = viewPastPrice(0);
        print(&pastprice);
        let currentprice = viewCurrentPrice();
        print(&currentprice);
        let index = viewHistoricalRangePrice(0, 5);
        print(&index);

  }
}   

    
