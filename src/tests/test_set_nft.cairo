use core::zeroable::Zeroable;
use core::traits::{Into, Default};
use array::ArrayTrait;
use serde::Serde;
use starknet::ContractAddress;

use starknet::testing::set_contract_address;
use debug::PrintTrait;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use dojo_erc::erc721::interface::{IERC721, IERC721Dispatcher, IERC721DispatcherTrait};

use briq_protocol::tests::test_set_nft_utils::{spawn_world, deploy_set_nft, deploy_set_nft_default};


fn deployer() -> ContractAddress {
    starknet::contract_address_const::<0x420>()
}

fn user1() -> ContractAddress {
    starknet::contract_address_const::<0x111>()
}

fn user2() -> ContractAddress {
    starknet::contract_address_const::<0x222>()
}


#[test]
#[available_gas(30000000)]
fn test_deploy_set_nft_default() {
    let (world, set_nft) = deploy_set_nft_default();
    assert(set_nft.owner() == deployer(), 'invalid owner');

}
