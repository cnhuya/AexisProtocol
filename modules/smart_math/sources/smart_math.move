module deployer::AEXIS_SMART_MATH_BETA {

    use std::signer;
    use std::vector;
    use std::account;
    use std::debug::print;
    use std::string::utf8;
    use std::string;
    use std::table;
    use aptos_std::from_bcs;

    struct NUMBERS has key, store, drop, copy {numbers: vector<u8>}

    const DEPLOYER: address = @deployer;

    fun init_module(address: &signer) {
        if (!exists<NUMBERS>(DEPLOYER)) {
            move_to(address, NUMBERS { numbers: vector::empty() });
        }; 
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

    #[view]
    public fun MIN(numbers: vector<u256>): u256 {
        let min = pow(2, 255);
        let length = vector::length(&numbers);
        while (length > 0) {
            let number = *vector::borrow(&numbers, length - 1);
            if (min > number) {
                min = number;
            };
            length = length - 1;
        };
        move min
    }

    #[view]
    public fun MAX(numbers: vector<u256>): u256 {
        let max = 0;
        let length = vector::length(&numbers);
        while (length > 0) {
            let number = *vector::borrow(&numbers, length - 1);
            if (max < number) {
                max = number;
            };
            length = length - 1;
        };
        move max
    }

    #[view]
    public fun MIN_EXTERNAL(addr: address): u256 acquires NUMBERS {
        let min = pow(2, 255);
        let numbers = DESERIALIZE(addr);
        let length = vector::length(&numbers);
        while (length > 0) {
            let number = *vector::borrow(&numbers, length - 1);
            if (min > number) {
                min = number;
            };
            length = length - 1;
        };
        move min
    }

    #[view]
    public fun MAX_EXTERNAL(addr: address): u256 acquires NUMBERS {
        let max = 0;
        let numbers = DESERIALIZE(addr);
        let length = vector::length(&numbers);
        while (length > 0) {
            let number = *vector::borrow(&numbers, length - 1);
            if (max < number) {
                max = number;
            };
            length = length - 1;
        };
        move max
    }

    public entry fun setNumbers(addr: &signer, _numbers: vector<u8>) acquires NUMBERS {
        if (!exists<NUMBERS>(signer::address_of(addr))) {
            move_to(addr, NUMBERS { numbers: _numbers,});
        } else{
            let name = borrow_global_mut<NUMBERS>(DEPLOYER);
            name.numbers = _numbers;
        }
    }

    #[view]
    public fun getName(addr: address): NUMBERS acquires NUMBERS {
        let name = *borrow_global<NUMBERS>(addr);
        move name
    }

    #[view]
    public fun SERIALIZE(addr: address): vector<vector<u8>> acquires NUMBERS {
        let unserliazed_vector = borrow_global<NUMBERS>(addr);
        let length = vector::length(&unserliazed_vector.numbers);
        let vectors = vector::empty<vector<u8>>(); 
        let current_vector = vector::empty<u8>();

        let i = 0;
        while (i < length) {
            let numba = *vector::borrow(&unserliazed_vector.numbers, i); 

            if (numba == 32) {
                if (vector::length(&current_vector) > 0) {
                    vector::push_back(&mut vectors, current_vector);
                };
                current_vector = vector::empty<u8>();
            } else {
                vector::push_back(&mut current_vector, numba);
            };

            i = i + 1;
        };
        if (vector::length(&current_vector) > 0) {
            vector::push_back(&mut vectors, current_vector);
        };

        move vectors 
    }

    #[view] 
    public fun DESERIALIZE(addr: address): vector<u256> acquires NUMBERS {
        let _vector = SERIALIZE(addr);
        let length = vector::length(&_vector);  
        let vector_u256 = vector::empty<u256>();

        while (length > 0) {
            let vec_borrow = *vector::borrow(&_vector, length - 1); 
            let numba = ascii_bytes_to_u256(vec_borrow); 
            vector::push_back(&mut vector_u256, numba); 
            length = length - 1; 
        };

        move vector_u256
    }


    #[view]
    public fun ascii_bytes_to_u256(bytes: vector<u8>): u256 {
        let length = vector::length(&bytes); 
        let result: u256 = 0; 
        let i = 0;

        while (i < length) {
            let byte = *vector::borrow(&bytes, i); 
            let digit = ((byte - 48) as u256); 
            result = (result * 10) + digit; 
            i = i + 1;
        };

        move result
    }

    #[test(account = @0x1, owner = @0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020)]
    public entry fun test(account: signer, owner: signer) acquires NUMBERS {
        init_module(&owner);
        let number_vector: vector<u256> = vector::empty();

        vector::push_back(&mut number_vector, 2);
        vector::push_back(&mut number_vector, 100);
        vector::push_back(&mut number_vector, 5);
        vector::push_back(&mut number_vector, 11);
        vector::push_back(&mut number_vector, 250);
        vector::push_back(&mut number_vector, 200);
        vector::push_back(&mut number_vector, 1);
        vector::push_back(&mut number_vector, 0);
        setNumbers(&owner, b"100 540");
        getName(@0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020);
        print(&DESERIALIZE(@0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020));
        //print(&SERIALIZE());
        print(&MIN(number_vector));
        print(&MAX(number_vector));
        print(&MIN_EXTERNAL(@0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020));
        print(&MAX_EXTERNAL(@0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020));
    }
}