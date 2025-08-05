module deployer::testAccountsV5 {
    use std::string::{String, utf8};
    use std::signer;
    use std::table::{Self as Table, Table};

    const ERROR_NOT_OWNER: u64 = 1;
    const ERROR_NOT_REGISTERED: u64 = 2;
    const ERROR_INVALID_TYPE: u64 = 3;

    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

    /// Registry resource stored under OWNER
    struct AccountRegistry has key {
        accounts: Table<address, u8>
    }

    /// Initialize registry
    fun init_module(admin: &signer) {
        assert!(signer::address_of(admin) == OWNER, ERROR_NOT_OWNER);
        if (!exists<AccountRegistry>(OWNER)) {
            move_to(admin, AccountRegistry { accounts: Table::new<address, u8>() });
        }
    }

    /// Set or update an account type
    public entry fun set_acc(admin: &signer, addr: address, acc_type: u8) acquires AccountRegistry {
        assert!(signer::address_of(admin) == OWNER, ERROR_NOT_OWNER);
        assert!(acc_type <= 2, ERROR_INVALID_TYPE);

        let registry = borrow_global_mut<AccountRegistry>(OWNER);
        if (Table::contains<address, u8>(&registry.accounts, addr)) {
            Table::remove<address, u8>(&mut registry.accounts, addr);
        };
        Table::add<address, u8>(&mut registry.accounts, addr, acc_type);
    }

    /// Remove an account
    public entry fun remove_acc(admin: &signer, addr: address) acquires AccountRegistry {
        assert!(signer::address_of(admin) == OWNER, ERROR_NOT_OWNER);

        let registry = borrow_global_mut<AccountRegistry>(OWNER);
        assert!(Table::contains<address, u8>(&registry.accounts, addr), ERROR_NOT_REGISTERED);
        Table::remove<address, u8>(&mut registry.accounts, addr);
    }

    /// View account type
    #[view]
    public fun view_acc_type(addr: address): String acquires AccountRegistry {
        if (!exists<AccountRegistry>(OWNER)) {
            return utf8(b"On-chain");
        };

        let registry = borrow_global<AccountRegistry>(OWNER);
        if (Table::contains<address, u8>(&registry.accounts, addr)) {
            let t = *Table::borrow<address, u8>(&registry.accounts, addr);
            return convert_acc_type(t);
        };
        utf8(b"On-chain")
    }

    /// Convert account type to string
    fun convert_acc_type(acc_type: u8): String {
        if (acc_type == 1) {
            utf8(b"Third-Party Chain")
        } else if (acc_type == 2) {
            utf8(b"Off-chain")
        } else {
            utf8(b"On-chain")
        }
    }
}
