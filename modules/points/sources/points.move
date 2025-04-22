module deployer::pointsv1 {
    use std::signer;
    use std::vector;
    use std::account;
    use std::debug::print;
    use std::string::utf8;
    use std::string;
    use supra_framework::table;
    use supra_framework::timestamp;

    struct CONTRACT has key, drop, store, copy { deployer: address, messager: address }
    struct STATS has copy, drop, key { total_points: u128, total_holders: u64 }
    struct BAG has store, key { holders: table::Table<address, u128> }
    struct HOLDERS has store, key, copy, drop { holders: vector<address> }
    struct HOLDER has key, copy, store, drop { address: address, balance: u128 }

    const ROUNDING: u8 = 2;
    const MESSAGER: address = @deployer;
    const DEPLOYER: address = @deployer;

    const ERROR_NOT_MESSAGER: u64 = 1;
    const ERROR_BAG_DOES_NOT_EXISTS: u64 = 2;
    const ERROR_BALANCE_TOO_LOW: u64 = 3;

    fun init_module(address: &signer) {
        if (!exists<STATS>(DEPLOYER)) {
            move_to(address, STATS { total_points: 0, total_holders: 0 });
        };
        if (!exists<BAG>(DEPLOYER)) {
            let table = table::new<address, u128>();
            move_to(address, BAG { holders: table });
        };
        if (!exists<CONTRACT>(DEPLOYER)) {
            move_to(address, CONTRACT { deployer: DEPLOYER, messager: MESSAGER });
        };
        if (!exists<HOLDERS>(DEPLOYER)) {
            move_to(address, HOLDERS { holders: vector::empty() });
        };
    }

    entry fun mock_addPoints(address: &signer, user: address, amount: u128) acquires BAG, STATS, HOLDERS {
        assert!(signer::address_of(address) == MESSAGER, ERROR_NOT_MESSAGER);
        let bag = borrow_global_mut<BAG>(DEPLOYER);
        let holders = borrow_global_mut<HOLDERS>(DEPLOYER);
        let stats = borrow_global_mut<STATS>(DEPLOYER);

        if (!table::contains(&bag.holders, user)) {
            table::add(&mut bag.holders, user, 0);
            stats.total_holders = stats.total_holders + 1;
            vector::push_back(&mut holders.holders, user);
        } else { // if the user was already initialized but "sold" his governing points and buy them again.
            let _balance = *table::borrow_mut(&mut bag.holders, user);
            if (_balance == 0) {
                stats.total_holders = stats.total_holders + 1;
            }
        };

        let balance = *table::borrow_mut(&mut bag.holders, user);
        let _balance = balance + amount;
        table::upsert(&mut bag.holders, user, _balance);
        stats.total_points = stats.total_points + amount;
    }

    entry fun mock_deductPoints(address: &signer, user: address, amount: u128) acquires BAG, STATS, HOLDERS {
        assert!(signer::address_of(address) == MESSAGER, ERROR_NOT_MESSAGER);
        assert!(exists<BAG>(DEPLOYER), ERROR_BAG_DOES_NOT_EXISTS);
        let bag = borrow_global_mut<BAG>(DEPLOYER);
        let stats = borrow_global_mut<STATS>(DEPLOYER);
        let holder = borrow_global_mut<HOLDERS>(DEPLOYER);
        let balance = *table::borrow_mut(&mut bag.holders, user);
        assert!(balance >= amount, ERROR_BALANCE_TOO_LOW);
        let _balance = balance - amount;
        stats.total_points = stats.total_points - amount;

        if (amount == balance) {
            stats.total_holders = stats.total_holders - 1;

            // Find the index of the user in the holders vector
            let (found, index) = vector::index_of(&holder.holders, &user);
            assert!(found, ERROR_BAG_DOES_NOT_EXISTS); // Ensure the user is found

            // Remove the user from the holders vector
            vector::remove(&mut holder.holders, index);
            table::remove(&mut bag.holders, user);
        } else {
            table::upsert(&mut bag.holders, user, _balance); // Update the balance in the table
        }

}

    public entry fun addPoints(address: &signer, user: address, amount: u128) acquires BAG, STATS, HOLDERS {
        mock_addPoints(address, user, amount);
    }

    public entry fun deductPoints(address: &signer, user: address, amount: u128) acquires BAG, STATS, HOLDERS {
        mock_deductPoints(address, user, amount);
    }

    #[view]
    public fun viewBalance(addr: address): u128 acquires BAG {
        assert!(exists<BAG>(DEPLOYER), ERROR_BAG_DOES_NOT_EXISTS); // Fix: Check if BAG exists
        let bag = borrow_global<BAG>(DEPLOYER);
        let balance = *table::borrow(&bag.holders, addr);
        move balance
    }

    #[view]
    public fun viewHoldersWithBalances(): vector<HOLDER> acquires HOLDERS, BAG {
        let holders = *borrow_global<HOLDERS>(DEPLOYER);
        let addresses = holders.holders;
        let result = vector::empty();

        // Iterate over the addresses and get their balances
        let i = 0;
        while (i < vector::length(&addresses)) {
            let addr = *vector::borrow(&addresses, i);
            let balance = viewBalance(addr); // Call viewBalance for each address
            if(balance != 0){
                let holder = HOLDER {
                    address: addr,
                    balance: balance,
                };
                vector::push_back(&mut result, holder);
            };
            i = i + 1;
        };
        move result
    }

    #[view]
    public fun viewHolders(): vector<address> acquires HOLDERS {
        let holders = *borrow_global<HOLDERS>(DEPLOYER);
        let _holders = holders.holders;
        move _holders // Clone the data (requires BAG to have 'copy')
    }

    #[view]
    public fun viewStats(): STATS acquires STATS {
        let stats = borrow_global<STATS>(DEPLOYER);
        let _stats = STATS {
            total_points: stats.total_points,
            total_holders: stats.total_holders,
        };
        move _stats
    }

    #[view]
    public fun viewContract(): CONTRACT acquires CONTRACT {
        let deployer = viewDeployer();
        let messager = viewMessager();

        let contract = CONTRACT {
            deployer: deployer,
            messager: messager,
        };
        move contract
    }

    #[view]
    public fun viewMessager(): address acquires CONTRACT {
        let contract = borrow_global<CONTRACT>(DEPLOYER);
        let messager = contract.messager;
        move messager
    }

    #[view]
    public fun viewDeployer(): address acquires CONTRACT {
        let contract = borrow_global<CONTRACT>(DEPLOYER);
        let deployer = contract.deployer;
        move deployer
    }

    #[test(account = @0x1, owner = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020)]
    public entry fun test(account: signer, owner: signer) acquires CONTRACT, BAG, STATS, HOLDERS {
        // Initialize the CurrentTimeMicroseconds resource
        init_module(&owner);
        let _owner = signer::address_of(&owner);
        supra_framework::timestamp::set_time_has_started_for_testing(&account);
        supra_framework::timestamp::update_global_time_for_test(50000);
        print(&viewContract());
        //print(&viewBalance(_owner));
        addPoints(&owner, _owner, 100);
        addPoints(&owner, _owner, 20);
        addPoints(&owner, @0x01fffa, 2000);
        deductPoints(&owner, @0x01fffa, 2000);
        print(&viewBalance(_owner));
        print(&viewStats());
        print(&viewHolders());
        print(&viewHoldersWithBalances());
    }
}
