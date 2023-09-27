use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;
use starknet::ContractAddress;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use dojo_erc::erc_common::utils::{system_calldata};
use dojo_erc::erc721::interface::IERC721DispatcherTrait;

use briq_protocol::tests::test_utils::{
    DefaultWorld, DEFAULT_OWNER, USER1, ZERO, spawn_briq_test_world, impersonate
};

use briq_protocol::types::{FTSpec, ShapeItem};
use briq_protocol::attributes::attribute_group::{
    CreateAttributeGroupParams, UpdateAttributeGroupParams, AttributeGroupOwner, AttributeGroupTrait
};

use debug::PrintTrait;


//
// Helpers
//

fn create_attribute_group(world: IWorldDispatcher, params: CreateAttributeGroupParams) {
    world.execute('create_attribute_group', system_calldata(params));
}

fn update_attribute_group(world: IWorldDispatcher, params: UpdateAttributeGroupParams) {
    world.execute('update_attribute_group', system_calldata(params));
}

//
// Tests create
//

#[test]
#[available_gas(30000000)]
fn test_create_attribute_groups_with_users() {
    let DefaultWorld{world, ducks_set, ducks_booklet, .. } = spawn_briq_test_world();

    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 1,
            owner: AttributeGroupOwner::Admin(USER1()),
            target_set_contract_address: ducks_set.contract_address,
            booklet_contract_address: ducks_booklet.contract_address
        }
    );

    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 2,
            owner: AttributeGroupOwner::Admin(USER1()),
            target_set_contract_address: ducks_set.contract_address,
            booklet_contract_address: ducks_booklet.contract_address
        }
    );
}


#[test]
#[available_gas(30000000)]
fn test_create_attribute_groups_with_systems() {
    let DefaultWorld{world, ducks_set, ducks_booklet, .. } = spawn_briq_test_world();

    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 1,
            owner: AttributeGroupOwner::System('system_not_created'),
            target_set_contract_address: ducks_set.contract_address,
            booklet_contract_address: ducks_booklet.contract_address
        }
    );

    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 2,
            owner: AttributeGroupOwner::System('system_not_created'),
            target_set_contract_address: ducks_set.contract_address,
            booklet_contract_address: ducks_booklet.contract_address
        }
    );
}


#[test]
#[available_gas(30000000)]
#[should_panic(
    expected: (
        'attribute_group already exists',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED'
    )
)]
fn test_create_attribute_group_collision() {
    let DefaultWorld{world, generic_sets, ducks_set, ducks_booklet, .. } = spawn_briq_test_world();
    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 1,
            owner: AttributeGroupOwner::Admin(USER1()),
            target_set_contract_address: ducks_set.contract_address,
            booklet_contract_address: ducks_booklet.contract_address
        }
    );

    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 1,
            owner: AttributeGroupOwner::Admin(USER1()),
            target_set_contract_address: ducks_set.contract_address,
            booklet_contract_address: ducks_booklet.contract_address
        }
    );
}

#[test]
#[available_gas(30000000)]
#[should_panic(
    expected: (
        'attribute_group already exists',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED'
    )
)]
fn test_create_attribute_group_collision_2() {
    let DefaultWorld{world, generic_sets, ducks_set, ducks_booklet, .. } = spawn_briq_test_world();

    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 1,
            owner: AttributeGroupOwner::Admin(USER1()),
            target_set_contract_address: generic_sets.contract_address,
            booklet_contract_address: ducks_booklet.contract_address
        }
    );

    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 1,
            owner: AttributeGroupOwner::System('system_not_created'),
            target_set_contract_address: ducks_set.contract_address,
            booklet_contract_address: ducks_booklet.contract_address
        }
    );
}


//
// Test Update
//

#[test]
#[available_gas(30000000)]
fn test_update_attribute_group_ok() {
    let DefaultWorld{world, generic_sets, ducks_set, ducks_booklet, .. } = spawn_briq_test_world();

    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 0x69,
            owner: AttributeGroupOwner::System('system_not_created'),
            target_set_contract_address: generic_sets.contract_address,
            booklet_contract_address: ducks_booklet.contract_address
        }
    );

    update_attribute_group(
        world,
        UpdateAttributeGroupParams {
            attribute_group_id: 0x69,
            owner: AttributeGroupOwner::System('system_not_created_2'),
            target_set_contract_address: ducks_set.contract_address,
            booklet_contract_address: ZERO()
        }
    );

    let attribute_group = AttributeGroupTrait::get_attribute_group(world, 0x69);

    match attribute_group.owner {
        AttributeGroupOwner::Admin(admin) => {
            panic(array!['invalid owner']);
        },
        AttributeGroupOwner::System(system_name) => {
            assert(system_name == 'system_not_created_2', 'invalid system_name');
        },
    }
    assert(
        attribute_group.target_set_contract_address == ducks_set.contract_address,
        'invalid target_address'
    );
    assert(attribute_group.booklet_contract_address == ZERO(), 'invalid booklet_address');
}


#[test]
#[available_gas(30000000)]
#[should_panic(
    expected: (
        'unexisting attribute_group_id',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED'
    )
)]
fn test_update_attribute_group_non_existing() {
    let DefaultWorld{world, generic_sets, ducks_set, .. } = spawn_briq_test_world();

    update_attribute_group(
        world,
        UpdateAttributeGroupParams {
            attribute_group_id: 0x69,
            owner: AttributeGroupOwner::System('system_not_created_2'),
            target_set_contract_address: ducks_set.contract_address,
            booklet_contract_address: ZERO()
        }
    );
}


//
// Auth
//

#[test]
#[available_gas(30000000)]
#[should_panic(
    expected: ('Not authorized', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED')
)]
fn test_create_attribute_group_with_non_world_admin() {
    let DefaultWorld{world, generic_sets, .. } = spawn_briq_test_world();

    impersonate(DEFAULT_OWNER());

    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 1,
            owner: AttributeGroupOwner::Admin(USER1()),
            target_set_contract_address: generic_sets.contract_address,
            booklet_contract_address: ZERO()
        }
    );
}


#[test]
#[available_gas(30000000)]
#[should_panic(
    expected: ('Not authorized', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED')
)]
fn test_update_attribute_group_with_non_world_admin() {
    let DefaultWorld{world, generic_sets, ducks_set, .. } = spawn_briq_test_world();

    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 0x69,
            owner: AttributeGroupOwner::System('system_not_created'),
            target_set_contract_address: generic_sets.contract_address,
            booklet_contract_address: ZERO()
        }
    );

    impersonate(DEFAULT_OWNER());

    update_attribute_group(
        world,
        UpdateAttributeGroupParams {
            attribute_group_id: 0x69,
            owner: AttributeGroupOwner::System('system_not_created_2'),
            target_set_contract_address: ducks_set.contract_address,
            booklet_contract_address: ZERO()
        }
    );
}
