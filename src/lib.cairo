#[starknet::interface]
pub trait IPushComm<TContractState> {
    fn complete_migration(ref self: TContractState);
    fn get_migration_status(self: @TContractState) -> bool;
    fn set_push_core_address(ref self: TContractState, core_address: felt252);
    fn get_push_core_address(self: @TContractState) -> felt252;
}

#[starknet::contract]
pub mod PushComm {
    use openzeppelin::access::ownable::interface::OwnableABI;
    use core::starknet::storage::StoragePointerWriteAccess;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use starknet::ContractAddress;
    use openzeppelin::access::ownable::OwnableComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        // Ownable
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        // Users
        users: Map<ContractAddress, User>,
        users_count: u256,
        map_address_users: u256,
        user_to_channel_notifs: Map<ContractAddress, Map<ContractAddress, ByteArray>>,
        // Channels
        delegatedNotificationSenders: Map<ContractAddress, bool>,
        // Contract State
        governance: ContractAddress,
        is_migration_complete: bool,
        push_core_address: felt252
    }

    #[starknet::storage_node]
    pub struct User {
        is_activated: bool,
        is_public_key_registered: bool,
        start_block: u256,
        subscribed_count: u256,
        is_subscribed: Map<ContractAddress, u8>,
        subscribed: Map<ContractAddress, u8>,
        map_address_subscribed: Map<ContractAddress, u8>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        // Set the initial owner of the contract
        self.ownable.initializer(owner);
    }


    #[abi(embed_v0)]
    impl PushComm of super::IPushComm<ContractState> {
        fn complete_migration(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.is_migration_complete.write(true);
        }

        fn get_migration_status(self: @ContractState) -> bool {
            self.is_migration_complete.read()
        }

        fn set_push_core_address(ref self: ContractState, core_address: felt252) {
            self.ownable.assert_only_owner();
            self.push_core_address.write(core_address);
        }

        fn get_push_core_address(self: @ContractState) -> felt252 {
            self.push_core_address.read()
        }
    }
}
