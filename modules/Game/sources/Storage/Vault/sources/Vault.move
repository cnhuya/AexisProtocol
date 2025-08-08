module new_dev::testVaultV2 {
    use std::signer;
    use std::vector;
    use std::string::{String,utf8};
    use supra_framework::coin;
    use supra_framework::supra_coin::{Self, SupraCoin};
    use supra_framework::event;

    use new_dev::testConstantAddressV4::{Self as ConstantAddress};

    // Errors
    const ERROR_NOT_ADMIN: u64 = 1;
    const ERROR_VAULT_NOT_INITIALIZED: u64 = 2;
    const ERROR_INSUFFICIENT_BALANCE: u64 = 3;
    const ERROR_ACCESS_ALREADY_EXISTS: u64 = 4;

    /// Global vault stored under ADMIN address
    struct Vault has key {
        balance: coin::Coin<SupraCoin>,
    }

    /// Capability/resource that allows calling `send_win`
    /// Stored at the grantee's account if granted.
    struct Access has key, drop {}

    /// Deposit event
    #[event]
    struct DepositEvent has copy, drop, store {
        amount: u64,
        from: address,
    }

    /// Withdraw event (admin or payout)
    #[event]
    struct WithdrawEvent has copy, drop, store {
        amount: u64,
        to: address,
        by_admin: bool,
    }


    fun get_admin(): address {
        ConstantAddress::get_constantAddress_value(&ConstantAddress::viewConstant(utf8(b"Vault"), utf8(b"Withdraw")))
    }

    // -------------------------
    // Initialization
    // -------------------------
    /// Admin must call this once to create the vault resource under ADMIN.
    public entry fun init_admin(admin: &signer) {
        // ensure caller is ADMIN
        assert!(signer::address_of(admin) == get_admin(), ERROR_NOT_ADMIN);

        if (!exists<Vault>(get_admin())) {
            move_to(admin, Vault { balance: coin::zero<SupraCoin>() });
        }
    }

    // -------------------------
    // Access management
    // -------------------------
    /// This allows admin to mint the Access and store in other modules.
    public fun get_vault_access(admin: &signer): Access {
        assert!(signer::address_of(admin) == get_admin(), ERROR_NOT_ADMIN);
        Access {}
    }

    /// Revoke access from an account that holds it. Only ADMIN can call.
    /// Requires admin signer and the account to be present (the account does not need to sign).
    public entry fun revoke_access(admin: &signer) acquires Access {
        assert!(signer::address_of(admin) == get_admin(), ERROR_NOT_ADMIN);

        if (exists<Access>(signer::address_of(admin))) {
            let x = move_from<Access>(signer::address_of(admin));
        }
    }

    // -------------------------
    // Deposits
    // -------------------------
    /// Any user can deposit SupraCoin from their account into the global vault.
    public entry fun deposit(user: &signer, amount: u64) acquires Vault {
        // Ensure vault exists
        assert!(exists<Vault>(get_admin()), ERROR_VAULT_NOT_INITIALIZED);
        let vault = borrow_global_mut<Vault>(get_admin());

        // Withdraw SupraCoin from caller and merge into vault
        let coins = coin::withdraw(user, amount);
        coin::merge(&mut vault.balance, coins);

        event::emit(DepositEvent { amount, from: signer::address_of(user) });
    }

    // -------------------------
    // Admin withdrawals
    // -------------------------
    /// Admin withdraws `amount` from vault and sends it to `recipient`.
    public entry fun withdraw_admin(admin: &signer, recipient: address, amount: u64) acquires Vault {
        assert!(signer::address_of(admin) == get_admin(), ERROR_NOT_ADMIN);
        assert!(exists<Vault>(get_admin()), ERROR_VAULT_NOT_INITIALIZED);

        let vault = borrow_global_mut<Vault>(get_admin());
        // ensure enough
        let bal = coin::value(&vault.balance);
        assert!(bal >= amount, ERROR_INSUFFICIENT_BALANCE);

        let coins = coin::extract(&mut vault.balance, amount);
        coin::deposit(recipient, coins);

        event::emit(WithdrawEvent { amount, to: recipient, by_admin: true });
    }

    // -------------------------
    // Payouts (send_win)
    // -------------------------
    /// Called by code that has a reference to an Access resource. `access` must be a reference
    /// to the Access resource stored in the caller's account.
    ///
    /// This is a non-entry public function  other modules/accounts that hold `Access` can call it.
    public fun send_win(access: &Access, to: address, amount: u64) acquires Vault {
        // Access presence is enforced by type system: caller must provide &Access
        assert!(exists<Vault>(get_admin()), ERROR_VAULT_NOT_INITIALIZED);

        let vault = borrow_global_mut<Vault>(get_admin());
        let bal = coin::value(&vault.balance);
        assert!(bal >= amount, ERROR_INSUFFICIENT_BALANCE);

        let coins = coin::extract(&mut vault.balance, amount);
        coin::deposit(to, coins);

        event::emit(WithdrawEvent { amount, to, by_admin: false });
    }

    // -------------------------
    // Views
    // -------------------------
    #[view]
    public fun get_vault_balance(): u64 acquires Vault {
        if (!exists<Vault>(get_admin())) {
            return 0;
        };
        let vault = borrow_global<Vault>(get_admin());
        coin::value(&vault.balance)
    }
}
