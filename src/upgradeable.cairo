use starknet::{ClassHash, SyscallResult, SyscallResultTrait};
use zeroable::Zeroable;
use result::ResultTrait;
use clone::Clone;
use serde::Serde;
use traits::PartialEq;

#[starknet::interface]
trait IUpgradeable<T> {
    fn upgrade(self: @T, new_class_hash: ClassHash);
}

#[starknet::component]
mod Upgradeable {
    use starknet::ClassHash;
    use starknet::get_caller_address;
    use briq_protocol::erc::get_world::GetWorldTrait;
    use briq_protocol::world_config::AdminTrait;

    #[storage]
    struct Storage {}

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Upgraded: Upgraded
    }

    #[derive(Drop, starknet::Event)]
    struct Upgraded {
        class_hash: ClassHash
    }

    mod Errors {
        const INVALID_CLASS: felt252 = 'Class hash cannot be zero';
    }

    #[embeddable_as(Upgradeable)]
    impl implem<
        TContractState, +HasComponent<TContractState>, +GetWorldTrait<TContractState>
    > of super::IUpgradeable<ComponentState<TContractState>> {
        fn upgrade(self: @ComponentState<TContractState>, new_class_hash: ClassHash) {
            self.get_contract().world().only_admins(@get_caller_address());
            assert(!new_class_hash.is_zero(), Errors::INVALID_CLASS);
            starknet::replace_class_syscall(new_class_hash).unwrap();
            //self.emit(Upgraded { class_hash: new_class_hash });
        }
    }
}
