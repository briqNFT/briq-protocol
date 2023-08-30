#[starknet::contract]
mod ContractUpgrade {
    use array::ArrayTrait;
    use option::OptionTrait;
    use clone::Clone;
    use array::ArrayTCloneImpl;
    use starknet::{ContractAddress, get_caller_address};
    use traits::{Into, TryInto};
    use zeroable::Zeroable;
    use starknet::ClassHash;
    use starknet::SyscallResult;
    use serde::Serde;
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};


    #[storage]
    struct Storage {
        world: IWorldDispatcher,
    }

    #[starknet::interface]
    trait IUselessContract<TState> {
        fn plz_more_tps(self: @TState) -> felt252;
    }

    //
    // Constructor
    //

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[external(v0)]
    impl UselessContract of IUselessContract<ContractState> {
        fn plz_more_tps(self: @ContractState) -> felt252 {
            'daddy'
        }
    }
}
