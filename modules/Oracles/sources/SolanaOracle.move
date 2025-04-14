module deployer::SolanaOracleTest0{
  
    use std::signer;
    use std::vector;
    use std::account;
    use std::string;
    use std::timestamp;
    use std::table;
    use std::debug::print;

    const OWNER: address = @deployer;

    const NAME: vector<u8> = b"SOLANA";
    const SYMBOL: vector<u8> = b"SOL";
    const DECIMALS: u8 = 3;


    // ERROR CODES
    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_NOT_VALIDATOR: u64 = 2;

    struct CONFIG has copy, key, store, drop {name: vector<u8>, symbol: vector<u8>, decimals: u8}

    struct DATA has copy, key, store, drop {id: u64,price: u64, timestamp: u64, }

    struct HISTORICAL_DATA has key, store, drop, copy {database: vector<DATA>}

    struct COUNTER has copy, key, store, drop {count: u64}

    struct VALIDATOR has key,store,copy,drop {address: address}


 fun init_module(address: &signer) {



        if (!exists<CONFIG>(OWNER)) {
            move_to(address, CONFIG {name: NAME, symbol: SYMBOL, decimals: DECIMALS, });
        };

        if (!exists<VALIDATOR>(OWNER)) {
            move_to(address, VALIDATOR {address: @0x02});
        };

        if (!exists<DATA>(OWNER)) {
            move_to(address, DATA {id: 0, price: 0, timestamp: 0, });
        };

        if (!exists<HISTORICAL_DATA>(OWNER)) {
            move_to(address, HISTORICAL_DATA { database: vector::empty() });
        };

        if (!exists<COUNTER>(OWNER)) {
            move_to(address, COUNTER { count: 0 });
        };
    }

    public entry fun storeDATA(address: &signer, _price: u64,) acquires DATA, HISTORICAL_DATA, COUNTER
    {

        let addr = signer::address_of(address);
        let data = borrow_global_mut<DATA>(OWNER);
        let counter = borrow_global_mut<COUNTER>(OWNER);
        let timestamp = timestamp::now_seconds();
        let id_count = counter.count + 1;

        let _data = DATA{
            id: id_count,
            price: _price,
            timestamp: timestamp,
                    };
        print(&_data);
        let database = borrow_global_mut<HISTORICAL_DATA>(OWNER);
        vector::push_back(&mut database.database, _data);
        counter.count = counter.count + 1;
    }
 
    #[view]
    public fun viewDATA(count: u64): DATA acquires HISTORICAL_DATA
    {
        //"pujceni" ulozenych dat na adresse <OWNER>
        assert!(exists<HISTORICAL_DATA>(OWNER), count);
        let database = borrow_global<HISTORICAL_DATA>(OWNER);    
        let _data = vector::borrow(&database.database, count);

        //nacteni ulozenych dat do datoveho structu, ke kteremu patri
        let data = DATA{
            id: _data.id,
            price: _data.price,
            timestamp: _data.timestamp,
                    
        };

        //debug
        print(&data);
        //return
        move data
    }
 


     #[view]
    public fun viewALLDATA(): HISTORICAL_DATA acquires HISTORICAL_DATA
    {
        //"pujceni" ulozenych dat na adresse <OWNER>
        let historical_data = *borrow_global<HISTORICAL_DATA>(OWNER);    
        //let open_view = vector::borrow(&ohcl_Database.database, count);
        //nacteni ulozenych dat do datoveho structu, ke kteremu patri
        let _historical_data = HISTORICAL_DATA{
            database: historical_data.database,
        };

        //debug
        print(&_historical_data);
        //return
        move _historical_data
    }

    #[view]
    public fun viewCONFIG(): CONFIG acquires CONFIG
    {
        //"pujceni" ulozenych dat na adresse <OWNER>
        let config = *borrow_global<CONFIG>(OWNER);    
        //let open_view = vector::borrow(&ohcl_Database.database, count);
        //debug
        print(&config);
        //return
        move config
    }

 
    // Test function
    #[test(account = @0x1, owner = @0x8480994b8cdeb0b3c6136dcc65edaafd6cd4ad18eb0d515676f3efd4dbd7d5e5)]
    public entry fun test(account: signer, owner: signer) acquires DATA, HISTORICAL_DATA, COUNTER, CONFIG, VALIDATOR{
        init_module(&owner);
        storeDATA(&owner, 5);
        viewDATA(0);
        storeDATA(&owner, 50);
        viewALLDATA();
        viewCONFIG();
    }
}