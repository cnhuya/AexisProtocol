module deployer::caller1 {
    use deployer::testStats1;
    use std::signer;

    const ADMIN: address = @deployer; 
    struct CapHolder has key {
        cap: testStats1::AccessCap,
    }

    /// Called ONCE to initialize cap and store it at the ADMIN address
    public entry fun init_trusted(admin: &signer) {
        assert!(signer::address_of(admin) == ADMIN, 1000);
        let cap = testStats1::grant_cap(admin);
        move_to(admin, CapHolder { cap });
    }

    /// This can be called by *any* user, but always uses the cap from the fixed ADMIN address
    public entry fun update_stats(_user: &signer) acquires CapHolder {
        let holder = borrow_global<CapHolder>(ADMIN); // Always use the fixed address
        testStats1::add_unique_player_count(&holder.cap);
        testStats1::add_tx_count(&holder.cap);
        testStats1::add_points(&holder.cap, 1000);
    }
}
