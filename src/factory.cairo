use starknet::ContractAddress;

#[starknet::interface]
trait IFactory<TContractState> {
    fn create_account(
        ref self: TContractState,
        nft_contract_address: ContractAddress,
        nft_token_id: u256,
        implementation_hash: felt252,
        salt: felt252,
    ) -> ContractAddress;
    fn get_account(
        self: @TContractState,
        nft_contract_address: ContractAddress,
        nft_token_id: u256,
        implementation_hash: felt252,
        salt: felt252,
    ) -> ContractAddress;
}

#[starknet::contract]
mod TBAFactory {
    use starknet::ContractAddress;
    use workshop::interfaces::IRegistry::{IRegistryDispatcher, IRegistryDispatcherTrait, IRegistryLibraryDispatcher};
    use super::IFactory;

    #[storage]
    struct Storage {
        total_deployed: u8
    }

    const REGISTRY_CLASS_HASH: felt252 = 0x46163525551f5a50ed027548e86e1ad023c44e0eeb0733f0dab2fb1fdc31ed0;

    #[abi(embed_v0)]
    impl FactoryImpl of IFactory<ContractState> {
        fn create_account(
            ref self: ContractState,
            nft_contract_address: ContractAddress,
            nft_token_id: u256,
            implementation_hash: felt252,
            salt: felt252,
        ) -> ContractAddress {
            let contract_address = IRegistryLibraryDispatcher {
                class_hash: REGISTRY_CLASS_HASH.try_into().unwrap()
            }
                .create_account(implementation_hash, nft_contract_address, nft_token_id, salt);
            self.total_deployed.write(self.total_deployed.read() + 1);
            return contract_address;
        }

        fn get_account(
            self: @ContractState,
            nft_contract_address: ContractAddress,
            nft_token_id: u256,
            implementation_hash: felt252,
            salt: felt252,
        ) -> ContractAddress {
            IRegistryLibraryDispatcher {
                class_hash: REGISTRY_CLASS_HASH.try_into().unwrap()
            }
                .get_account(implementation_hash, nft_contract_address, nft_token_id, salt)
        }
    }
}