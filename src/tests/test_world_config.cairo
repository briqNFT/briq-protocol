use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use briq_protocol::world_config::{WorldConfig, SYSTEM_CONFIG_ID};
use briq_protocol::tests::test_utils::{
    DefaultWorld, spawn_world, deploy_contracts, WORLD_ADMIN, TREASURY, DEFAULT_OWNER, impersonate,
    deploy_default_world
};


use briq_protocol::types::{FTSpec, ShapeItem};

use debug::PrintTrait;

use briq_protocol::attributes::collection::CreateCollectionData;

#[test]
#[available_gas(30000000)]
fn test_world_admin_can_setup_world() {
    impersonate(WORLD_ADMIN());

    let world = spawn_world();
    let (briq, set, booklet, box) = deploy_contracts(world);
    world
        .execute(
            'SetupWorld',
            (array![
                TREASURY().into(),
                briq.into(),
                set.into(),
                booklet.into(),
                box.into(),
            ])
        );
}


#[test]
#[available_gas(30000000)]
#[should_panic]
fn test_not_world_admin_cannot_setup_world() {
    impersonate(WORLD_ADMIN());

    let world = spawn_world();
    let (briq, set, booklet, box) = deploy_contracts(world);

    impersonate(DEFAULT_OWNER());

    world
        .execute(
            'SetupWorld',
            (array![
                TREASURY().into(),
                briq.into(),
                set.into(),
                booklet.into(),
                box.into(),
            ])
        );
}
