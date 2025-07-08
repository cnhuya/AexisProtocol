
module deployer::GameTestingV7{

    use std::signer;
    use std::vector;
    use std::account;
    use std::debug::print;
    use std::string::utf8;
    use std::string;
    use std::timestamp;
    use std::table;
    use std::hash;

    const DEPLOYER: address = @deployer;
    struct ItemCounter has store, key {count: u64}

    struct ItemDatabase has store, key, copy, drop {database: vector<Item>}

    struct Item has store, key, copy, drop {id: u64, type:u8, tier: u8, gold: u16, equiped: bool, ms: u16, damage: u32, hp: u32, hpregen: u16, inteligence: u32, agility: u32, power:u64}
   
    fun init_module(address: &signer){
        if (!exists<ItemCounter>(DEPLOYER)) {
            move_to(address, ItemCounter {count: 0});
        };

        if (!exists<ItemDatabase>(DEPLOYER)) {
            move_to(address, ItemDatabase {database: vector::empty()});
        };
    }

    #[view]
    public fun hashData(data: vector<u8>): vector<u8>{
        let hash = hash::sha3_256(data);
        move hash
    }


    public fun privateView(sign: &signer): vector<Item> acquires ItemDatabase{
        let addr = signer::address_of(sign);

        let item_database = borrow_global<ItemDatabase>(DEPLOYER);
        let database = item_database.database;
        move database
    }

    public entry fun registerItem(type: u8, tier: u8, number1: u16, number2: u32) acquires ItemDatabase, ItemCounter{


        let item_database = borrow_global_mut<ItemDatabase>(DEPLOYER);
        let item_counter = borrow_global_mut<ItemCounter>(DEPLOYER);

        let _item = Item{
            id: item_counter.count,
            type: type,
            weight: number1,
            tier: tier,
            gold: number1*2,
            equiped: false,
            ms: number1,
            damage: number2,
            hp: number2*2,
            hpregen: number1,
            inteligence: number2,
            agility: number2,
            strenght: number2,
        };
        vector::push_back(&mut item_database.database, _item);
        item_counter.count = item_counter.count + 1;
    }

    public entry fun counter() acquires ItemCounter{

        let item_counter = borrow_global_mut<ItemCounter>(DEPLOYER);
        item_counter.count = item_counter.count + 1;
       
    }

    #[view]
    public fun viewItemCounter(): u64 acquires ItemCounter {
        let item_counter = borrow_global<ItemCounter>(DEPLOYER);
        let counter = item_counter.count;
        move counter
    }

    #[view]
    public fun viewItem(id: u64): Item acquires ItemDatabase {
        let item_database = borrow_global<ItemDatabase>(DEPLOYER);
        let leng = vector::length(&item_database.database);
        let item: Item;
        while(leng > 1){
            let any_item = *vector::borrow(&item_database.database, leng-1);
            if(any_item.id == id){
                item = any_item;
                return item
            };
            leng = leng-1;
        };
        abort(1)
    }

    #[view]
    public fun viewItemDatabase(): vector<Item> acquires ItemDatabase {
        let item_database = borrow_global<ItemDatabase>(DEPLOYER);
        let database = item_database.database;
        move database
    }

    #[test(account = @0x1, owner = @0xc5e7e76cbce04ac46b408d26fdb0ba3e0fbbbd6b0cd3f4f9bfc62466f6ab72c2)]
     public entry fun test(account: signer, owner: signer) acquires ItemCounter, ItemDatabase{
        timestamp::set_time_has_started_for_testing(&account);  
        init_module(&owner);
        let addr = signer::address_of(&owner);
        counter();
        registerItem(1,1,50,100);
        print(&hashData(b"abc"));
        print(&hashData(b"abc6"));
        print(&hashData(b"abxc4"));
        print(&hashData(b"abc2"));
        print(&hashData(b"abc1"));
        print(&viewItemDatabase());
        print(&viewItemCounter());
  }
}   

    