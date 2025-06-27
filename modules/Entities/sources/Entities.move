module deployer::automatizationTest{
  
    use std::signer;
    use std::vector;
    use std::account;
    use std::string;
    use std::timestamp;
    use std::table;
    use std::debug::print;
    use std::hash;
    use supra_framework::supra_coin;
    use supra_framework::coin::{Self, Coin};
    use supra_framework::transaction_context;

    struct Sent has copy, key, store {timestamp: u64, count: u32}


    const DEPLOYER: address = @deployer;

    fun init_module(sender: &signer) {
        if (!exists<Sent>(signer::address_of(sender))) {
            move_to(sender, Sent { timestamp: timestamp::now_seconds(), count: 0 });
        };
    }

    public entry fun auto_top_up(source: &signer, user: address, top_up_amount: u64) acquires Sent{
        let sent = borrow_global_mut<Sent>(signer::address_of(source));
        if (timestamp::now_seconds() > sent.timestamp) {
            coin::transfer<supra_coin::SupraCoin>(source, user, top_up_amount);
            sent.timestamp = timestamp::now_seconds();
            sent.count = sent.count + 1;
        }
    }


#[view]
public fun viewSent(): Sent acquires Sent {
    let sent = borrow_global<Sent>(DEPLOYER);
    *sent
}



    #[test(account = @0x1, owner = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020)]
    public entry fun test(account: signer, owner: signer) {
    }
}