use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use briq_protocol::tests::test_utils::{
    DefaultWorld, spawn_briq_test_world, WORLD_ADMIN, DEFAULT_OWNER, impersonate,
};
use briq_protocol::world_config::ISetupWorldDispatcherTrait;

#[test]
#[available_gas(300000000)]
fn test_world_admin_can_setup_world() {
    impersonate(WORLD_ADMIN());

    let DefaultWorld { world, setup_world, .. } = spawn_briq_test_world();
    setup_world.execute(
        world,
        starknet::contract_address_const::<1>(),
        starknet::contract_address_const::<2>(),
        starknet::contract_address_const::<3>(),
        starknet::contract_address_const::<4>(),
    );
}


#[test]
#[available_gas(300000000)]
#[should_panic]
fn test_not_world_admin_cannot_setup_world() {
    impersonate(WORLD_ADMIN());
    
    let DefaultWorld { world, setup_world, .. } = spawn_briq_test_world();

    impersonate(DEFAULT_OWNER());

    setup_world.execute(
        world,
        starknet::contract_address_const::<1>(),
        starknet::contract_address_const::<2>(),
        starknet::contract_address_const::<3>(),
        starknet::contract_address_const::<4>(),
    );
}
