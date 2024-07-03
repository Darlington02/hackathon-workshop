use starknet::ClassHash;

#[starknet::interface]
trait IModifiedAccount<TContractState> {
    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);
    fn version(self: @TContractState) -> u8;
}

#[starknet::contract(account)]
mod ModifiedAccount {
    use core::starknet::SyscallResultTrait;
    use token_bound_accounts::account::account::AccountComponent::InternalTrait;
    use token_bound_accounts::interfaces::IAccount::IAccount;
    use starknet::{ContractAddress, ClassHash, get_caller_address};
    use token_bound_accounts::account::AccountComponent;
    use super::IModifiedAccount;

    component!(path: AccountComponent, storage: account, event: AccountEvent);

    #[abi(embed_v0)]
    impl AccountImpl = AccountComponent::AccountImpl<ContractState>;
    
    #[storage]
    struct Storage {
        #[substorage(v0)]
        account: AccountComponent::Storage,
        version: u8
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        AccountEvent: AccountComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, token_contract: ContractAddress, token_id: u256) {
        self.account.initializer(token_contract, token_id);
    }

    #[abi(embed_v0)]
    impl ModifiedAccountImpl of IModifiedAccount<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            let caller = get_caller_address();
            assert(self.account._is_valid_signer(caller), 'not permitted');
            let (lock_status, _) = self.account._is_locked();
            assert(!lock_status, 'account is locked!');
            starknet::syscalls::replace_class_syscall(new_class_hash).unwrap_syscall();
            self.version.write(self.version.read() + 1);
        }

        fn version(self: @ContractState) -> u8 {
            self.version.read()
        }
    }
}
