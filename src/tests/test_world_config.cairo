use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use briq_protocol::tests::test_utils::{
    DefaultWorld, spawn_world, deploy_contracts, WORLD_ADMIN, TREASURY, DEFAULT_OWNER, impersonate,
};


#[test]
#[available_gas(30000000)]
fn test_world_admin_can_setup_world() {
    impersonate(WORLD_ADMIN());

    let world = spawn_world();
    let (briq, set, set2, booklet, box) = deploy_contracts(world);
    world
        .execute(
            'SetupWorld',
            (array![
                TREASURY().into(), briq.into(), set.into(), set2.into(), booklet.into(), box.into(),
            ])
        );
}


#[test]
#[available_gas(30000000)]
#[should_panic]
fn test_not_world_admin_cannot_setup_world() {
    impersonate(WORLD_ADMIN());

    let world = spawn_world();
    let (briq, set, set2, booklet, box) = deploy_contracts(world);

    impersonate(DEFAULT_OWNER());

    world
        .execute(
            'SetupWorld',
            (array![
                TREASURY().into(), briq.into(), set.into(), set2.into(), booklet.into(), box.into(),
            ])
        );
}
