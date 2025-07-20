module deployer::testStats2 {
    use std::debug::print;
    use std::string::{String, utf8};
    use std::signer;
    use std::account;
    use std::vector;
    use std::timestamp; 
// Structs

    struct Snapshot has copy, drop, store, key {lasttime: u64, database: vector<Stats>}

    struct Stats has copy, key, drop, store {
        unique_players: u64,
        total_heroes: u64,
        total_txs: u128,
        points_given: u256
    }
    struct AccessCap has store {}

    struct PointsAccessCap has store {}

    const OWNER: address = @0x281d0fce12a353b1f6e8bb6d1ae040a6deba248484cf8e9173a5b428a6fb74e7;

// Initialize stats
    fun init_module(address: &signer) {
        let deploy_addr = signer::address_of(address);
        if (!exists<Stats>(deploy_addr)) {
            move_to(address, Stats { unique_players: 0, total_heroes: 0, total_txs: 0, points_given: 0 });
        };
        if (!exists<Snapshot>(deploy_addr)) {
            move_to(address, Snapshot { lasttime: timestamp::now_seconds(), database: vector::empty<Stats>()});
        }
    }

// Grant capability to trusted modules
    public fun grant_cap(caller: &signer): AccessCap {
        let addr = signer::address_of(caller);
        assert!(addr == OWNER, 999);
        AccessCap {}
    }

// Restricted functions
    public fun add_unique_player_count(_cap: &AccessCap) acquires Stats,Snapshot{
        check_for_snapshot();
        let stats = borrow_global_mut<Stats>(OWNER);
        stats.unique_players = stats.unique_players + 1;
    }

    public fun add_total_hero_count(_cap: &AccessCap) acquires Stats,Snapshot{
        check_for_snapshot();
        let stats = borrow_global_mut<Stats>(OWNER);
        stats.total_heroes = stats.total_heroes + 1;
    }

    public fun add_tx_count(_cap: &AccessCap) acquires Stats,Snapshot{
        check_for_snapshot();
        let stats = borrow_global_mut<Stats>(OWNER);
        stats.total_txs = stats.total_txs + 1;
    }

    public fun add_points(_cap: &AccessCap, points: u256) acquires Stats,Snapshot{
        check_for_snapshot();
        let stats = borrow_global_mut<Stats>(OWNER);
        stats.points_given = stats.points_given + points;
    }
    

// View functions
    #[view]
    public fun view_stats(): Stats acquires Stats{
        *borrow_global<Stats>(OWNER)
    }

    #[view]
    public fun view_stats_unique_players(): u64 acquires Stats{
        let stats = borrow_global<Stats>(OWNER);
        stats.unique_players
    }

    #[view]
    public fun view_stats_total_heroes(): u64 acquires Stats{
        let stats = borrow_global<Stats>(OWNER);
        stats.total_heroes
    }

    #[view]
    public fun view_stats_tx_count(): u128 acquires Stats{
        let stats = borrow_global<Stats>(OWNER);
        stats.total_txs
    }
    
    #[view]
    public fun view_stats_points_given(): u256 acquires Stats{
        let stats = borrow_global<Stats>(OWNER);
        stats.points_given
    }

    #[view]
    public fun viewSnapshots(): vector<Stats> acquires Snapshot{
        let snapshot = borrow_global<Snapshot>(OWNER);
        snapshot.database
    }
// Utils
    fun check_for_snapshot() acquires Snapshot, Stats {
        let snapshot = borrow_global_mut<Snapshot>(OWNER);

        if (timestamp::now_seconds() < snapshot.lasttime + 60) {
            return;
        };

        let stats = borrow_global<Stats>(OWNER);
        snapshot.lasttime = timestamp::now_seconds();
        vector::push_back(&mut snapshot.database, *stats);
    }

}
