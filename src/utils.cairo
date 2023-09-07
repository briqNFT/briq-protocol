use traits::{Into, TryInto, Default, PartialEq};
use array::ArrayTrait;
use starknet::ContractAddress;

impl IntoContractAddressU256 of Into<ContractAddress, u256> {
    fn into(self: ContractAddress) -> u256 {
        let felt: felt252 = self.into();
        felt.into()
    }
}
