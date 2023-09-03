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
    DefaultWorld, DEFAULT_OWNER, USER1, deploy_default_world, impersonate
};

use briq_protocol::types::{FTSpec, ShapeItem};
use briq_protocol::attributes::attribute_group::{CreateAttributeGroupParams, AttributeGroupOwner};

use debug::PrintTrait;

fn create_attribute_group(world: IWorldDispatcher, params: CreateAttributeGroupParams) {
    world.execute('create_attribute_group', system_calldata(params));
}

#[test]
#[available_gas(30000000)]
fn test_create_attribute_groups_with_users() {
    let DefaultWorld{world, briq_set, .. } = deploy_default_world();

    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 1,
            owner: AttributeGroupOwner::Admin(USER1()),
            target_set_contract_address: briq_set.contract_address
        }
    );

    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 2,
            owner: AttributeGroupOwner::Admin(USER1()),
            target_set_contract_address: briq_set.contract_address
        }
    );
}


#[test]
#[available_gas(30000000)]
fn test_create_attribute_groups_with_systems() {
    let DefaultWorld{world, briq_set, ducks_set, .. } = deploy_default_world();

    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 1,
            owner: AttributeGroupOwner::System('system_not_created'),
            target_set_contract_address: briq_set.contract_address
        }
    );

    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 2,
            owner: AttributeGroupOwner::System('system_not_created'),
            target_set_contract_address: briq_set.contract_address
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
    let DefaultWorld{world, briq_set, ducks_set, .. } = deploy_default_world();
    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 1,
            owner: AttributeGroupOwner::Admin(USER1()),
            target_set_contract_address: ducks_set.contract_address
        }
    );

    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 1,
            owner: AttributeGroupOwner::Admin(USER1()),
            target_set_contract_address: ducks_set.contract_address
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
    let DefaultWorld{world, briq_set, ducks_set, .. } = deploy_default_world();

    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 1,
            owner: AttributeGroupOwner::Admin(USER1()),
            target_set_contract_address: briq_set.contract_address
        }
    );

    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 1,
            owner: AttributeGroupOwner::System('system_not_created'),
            target_set_contract_address: ducks_set.contract_address
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
    let DefaultWorld{world, briq_set, .. } = deploy_default_world();

    impersonate(DEFAULT_OWNER());

    create_attribute_group(
        world,
        CreateAttributeGroupParams {
            attribute_group_id: 1,
            owner: AttributeGroupOwner::Admin(USER1()),
            target_set_contract_address: briq_set.contract_address
        }
    );
}
