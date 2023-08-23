use starknet::ContractAddress;

#[derive( Drop, starknet::Event)]
struct BriqsBought {
    buyer: ContractAddress,
    amount: felt252,
    price: felt252
}
