
module deployer::randomv12{
    use std::debug::print;
    use std::string::utf8;
    use std::vector;
    use std::string;
    use supra_oracle::supra_oracle_storage;
    use std::hash;
    use std::timestamp;
    use supra_framework::transaction_context;
    use supra_framework::coin;
    //use 0x1928893148d317947c302185417e2c1d32640c6ef8521b48e1ae6308ab1a41c3::smart_math;


    #[view]
    public fun random(index:vector<u32>, range:u64): (vector<u8>, u256) {
        let hash = transaction_context::get_transaction_hash();
        let leng = vector::length(&hash);
        let random_number = vector::pop_back(&mut hash);
        let random_number2 = extremeRandomNumber(index,range);

        let _random = (random_number as u256) * random_number2;
        let result = _random % (range as u256);
        (hash, result)
    }



    #[view]
    public fun pow(base: u256, exponent: u256): u256 {
        let result = 1;
        let i = 0;
        while (i < exponent) {
            result = result * base;
            i = i + 1;
        };
        move result
    }

    // use case -> user firstly calls randomNumber to actually receive random value, then extracts a random value
    // stored in any vector from position (index) by the random value, after that he has a custom random number from
    // own input.

    // This is better solution for generating large arrays. Now you might be able to generate random array containing
    // near 1000 values, however if you need more you can take data from any public vector that contains more stored numbers than 1000
    // and take the numbers from them for generating own custom random number.

    // Please take in mind that the process above would generate static "random" values, if you would wish to actually create a "soft-random" values
    // add again randomNumber to your own pulled numbers, to achieve "true" kind of randomness algorithm.

    #[view]
    public fun customrandomNumber(number:u256, range:u64): u256{
        let random_number = number % (range as u256);
        move random_number
    }

    #[view]
    public fun randomNumber(index:u32, range:u64): u256{
        let _price = 0;
        let (price, decimals, timestamp, round_id) = supra_oracle_storage::get_price(index);
        let adjusted_price = (price as u256) / pow(10, (decimals as u256));
        _price = _price + adjusted_price + (timestamp as u256) + (round_id as u256);
        let random_number = _price % (range as u256);
        move random_number
    }
    // Function which combines multiple price oracles, which might reduce the propability of "breaking" down the algoritm and "predicting" the potencial outcome.
    #[view]
    public fun extremeRandomNumber(indexes:vector<u32>, range:u64): u256 {
        let random_number = 0;
        let _price = 0;
        let prices = supra_oracle_storage::get_prices(indexes);
        let leng = vector::length(&prices);
        
        // Loop through all elements in the vector
        while (leng > 0) {
            let wrapped_price = vector::borrow(&prices, leng);
            let (index, price, decimals, timestamp, round_id) = supra_oracle_storage::extract_price(wrapped_price);
            _price = _price + (price as u256);
            random_number = _price % (range as u256);
            leng = leng - 1;
        };
        random_number
    }

    
    /*#[view]
    public fun generateRange(min:u64, max:u64): u256 {
        let _price = 0;
        let i = 0;
        // Loop through all elements in the vector
        while (_price < (min as u256) || _price > (max as u256)) {
            let empty_vec = vector::empty();
            vector::push_back(&mut empty_vec, i);
            let random_number = extremeRandomNumber(empty_vec, max);
            _price = random_number;
            i = i + 1;
        };
        _price
    }*/

    //

/*    #[view]
    public fun generateArray(index: vector<u32>, max: u64, values:u64): vector<u256>{
        let empty_vec = vector::empty();
        while(values > 0){
            let number = extremeRandomNumber(index, max);
            let time = timestamp::now_microseconds();
            vector::push_back(&mut empty_vec, (time as u256));
            values = values - 1;
        };
        empty_vec
    }*/


    // there might be a hard limit cap for 25 lenght of vector.
    #[view]
    public fun generateArray(indexes: vector<u32>,max: u64, values:u64): vector<u256>{
        let empty_vec = vector::empty();
        let prices = supra_oracle_storage::get_prices(indexes);
        let leng2 = vector::length(&prices);
        // Loop through all elements in the vector
        while(leng2 > 0 ){
            let leng = vector::length(&prices);
           // let supply = coin::supply<SupraCoin>();
            let random = (randomNumber((leng2 as u32),max) as u256);
            while (leng > 0) {
                let wrapped_price = vector::borrow(&prices, leng-1);
                let (index, price, decimals, timestamp, round_id) = supra_oracle_storage::extract_price(wrapped_price);
                let random_number = ((price as u256)+random) % (max as u256);
                vector::push_back(&mut empty_vec, random_number);
                leng = leng - 1;
              };
              leng2 = leng2 - 1;
        };
        empty_vec
    }



    #[view]
    public fun generateUniqueArray(indexes: vector<u32>,max: u64, values:u64): vector<u256>{
        let empty_vec = vector::empty();
        let prices = supra_oracle_storage::get_prices(indexes);
        let leng2 = vector::length(&prices);
        // Loop through all elements in the vector
        while(leng2 > 0 ){
            let leng = vector::length(&prices);
           // let supply = coin::supply<SupraCoin>();
            let random = (randomNumber((leng2 as u32),max) as u256);
            while (leng > 0) {
                let wrapped_price = vector::borrow(&prices, leng-1);
                let (index, price, decimals, timestamp, round_id) = supra_oracle_storage::extract_price(wrapped_price);
                let random_number = ((price as u256)+random) % (max as u256);
                if(!vector::contains(&empty_vec, &random_number)){
                    vector::push_back(&mut empty_vec, random_number);
                };
                leng = leng - 1;
              };
              leng2 = leng2 - 1;
        };
        empty_vec
    }


 
    #[test(account = @0x1, owner = @0x392727cb3021ab76bd867dd7740579bc9e42215d98197408b667897eb8e13a1f)]
     public entry fun test(account: signer, owner: signer)  { 
        //timestamp::set_time_has_started_for_testing(&account);  
        init_module(&owner);
        print(&randomNumber(1,100));
  }
}   


/*    #[view]
    public fun generateArray(max: u64, values:u64): vector<u256>{
        let empty_vec = vector::empty();
        while(index > 0){
            let supply = coin::supply<SupraCoin>();
            let randomFromSupply = supply % 20;
            let firstRandom = randomNumber(randomFromSupply, max);
            
            let seconds = timestamp::now_microseconds();

            let value = (supply as u256) + (seconds as u256);

            let number = randomNumber(index, max);
            vector::push_back(&mut empty_vec, number);
            index = index - 1;
        };
        empty_vec
    }*/

    