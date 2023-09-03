#[starknet::contract]
mod ContractUpgrade {
    use starknet::ContractAddress;

    #[storage]
    struct Storage { }

    #[starknet::interface]
    trait IUselessContract<TState> {
        fn plz_more_tps(self: @TState) -> felt252;
    }

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[external(v0)]
    impl UselessContract of IUselessContract<ContractState> {
        fn plz_more_tps(self: @ContractState) -> felt252 {
            'daddy'
        }
    }
}
