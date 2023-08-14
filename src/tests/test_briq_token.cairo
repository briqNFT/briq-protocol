use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;

use starknet::ContractAddress;
use starknet::syscalls::deploy_syscall;
use starknet::testing::set_contract_address;

use debug::PrintTrait;

use dojo::test_utils::spawn_test_world;
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use briq_protocol::briq_token::BriqErc1155;

fn spawn_world() -> IWorldDispatcher {
    // components
    let mut components = array![
        briq_protocol::erc::erc1155::components::balance::TEST_CLASS_HASH,
        dojo_erc::erc1155::components::operator_approval::TEST_CLASS_HASH,
        briq_protocol::world_config::world_config::TEST_CLASS_HASH,
    ];

    // systems
    let mut systems = array![
        dojo_erc::erc1155::systems::ERC1155SetApprovalForAll::TEST_CLASS_HASH,
        dojo_erc::erc1155::systems::ERC1155Update::TEST_CLASS_HASH,
        briq_protocol::world_config::SetupWorld::TEST_CLASS_HASH,
    ];

    let world = spawn_test_world(components, systems);
    world.execute('SetupWorld', (array![
        0x1,
        0x2,
        0x3,
        0x4,
        0x5,
    ]));
    world
}


fn deploy_briq_token(
    world: IWorldDispatcher,
) -> ContractAddress {
    let world = spawn_world();

    let constructor_calldata = array![
        world.contract_address.into()
    ];

    let (deployed_address, _) = deploy_syscall(
        BriqErc1155::TEST_CLASS_HASH.try_into().unwrap(), 0, constructor_calldata.span(), false
    )
        .expect('error deploying');
    //.unwrap();

    deployed_address
}


fn deploy_default() -> (IWorldDispatcher, ContractAddress) {
    let deployer = starknet::contract_address_const::<0x420>();

    let world = spawn_world();
    let briq_token_address = deploy_briq_token(world);
    (world, briq_token_address)
}

#[test]
#[available_gas(30000000)]
fn test_deploy_default() {
    let (world, briq_token) = deploy_default();
    assert(true == false, 'toto');
}