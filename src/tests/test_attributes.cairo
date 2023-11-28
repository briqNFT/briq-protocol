use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;
use starknet::ContractAddress;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use presets::erc721::erc721::interface::IERC721DispatcherTrait;

use briq_protocol::tests::test_utils::{
    DefaultWorld, DEFAULT_OWNER, USER1, ZERO, spawn_briq_test_world, impersonate
};

use briq_protocol::types::{FTSpec, ShapeItem};
use briq_protocol::attributes::attribute_group::{
    IAttributeGroupsDispatcher, IAttributeGroupsDispatcherTrait, AttributeGroupOwner,
    AttributeGroupTrait
};

use debug::PrintTrait;


//
// Helpers
//

fn create_attribute_group(
    world: IWorldDispatcher,
    attr_groups_addr: ContractAddress,
    attribute_group_id: u64,
    owner: AttributeGroupOwner,
    target_set_contract_address: ContractAddress,
) {
    IAttributeGroupsDispatcher { contract_address: attr_groups_addr }
        .create_attribute_group(
            world, attribute_group_id, owner, target_set_contract_address
        )
}

fn update_attribute_group(
    world: IWorldDispatcher,
    attr_groups_addr: ContractAddress,
    attribute_group_id: u64,
    owner: AttributeGroupOwner,
    target_set_contract_address: ContractAddress
) {
    IAttributeGroupsDispatcher { contract_address: attr_groups_addr }
        .update_attribute_group(
            world, attribute_group_id, owner, target_set_contract_address
        )
}

//
// Tests create
//

#[test]
#[available_gas(300000000)]
fn test_create_attribute_groups_with_users() {
    let DefaultWorld{world, sets_ducks, booklet_ducks, attribute_groups_addr, .. } =
        spawn_briq_test_world();

    create_attribute_group(
        world,
        attribute_groups_addr,
        attribute_group_id: 1,
        owner: AttributeGroupOwner::Admin(USER1()),
        target_set_contract_address: sets_ducks.contract_address,
    );

    create_attribute_group(
        world,
        attribute_groups_addr,
        attribute_group_id: 2,
        owner: AttributeGroupOwner::Admin(USER1()),
        target_set_contract_address: sets_ducks.contract_address,
    );
}


#[test]
#[available_gas(300000000)]
fn test_create_attribute_groups_with_systems() {
    let DefaultWorld{world, sets_ducks, booklet_ducks, attribute_groups_addr, .. } =
        spawn_briq_test_world();

    create_attribute_group(
        world,
        attribute_groups_addr,
        attribute_group_id: 1,
        owner: AttributeGroupOwner::Contract(starknet::contract_address_const::<0xfafa>()),
        target_set_contract_address: sets_ducks.contract_address,
    );

    create_attribute_group(
        world,
        attribute_groups_addr,
        attribute_group_id: 2,
        owner: AttributeGroupOwner::Contract(starknet::contract_address_const::<0xfafa>()),
        target_set_contract_address: sets_ducks.contract_address,
    );
}


#[test]
#[available_gas(300000000)]
#[should_panic(
    expected: (
        'attribute_group already exists',
        'ENTRYPOINT_FAILED'
    )
)]
fn test_create_attribute_group_collision() {
    let DefaultWorld{world, generic_sets, sets_ducks, booklet_ducks, attribute_groups_addr, .. } =
        spawn_briq_test_world();
    create_attribute_group(
        world,
        attribute_groups_addr,
        attribute_group_id: 1,
        owner: AttributeGroupOwner::Admin(USER1()),
        target_set_contract_address: sets_ducks.contract_address,
    );

    create_attribute_group(
        world,
        attribute_groups_addr,
        attribute_group_id: 1,
        owner: AttributeGroupOwner::Admin(USER1()),
        target_set_contract_address: sets_ducks.contract_address,
    );
}

#[test]
#[available_gas(300000000)]
#[should_panic(
    expected: (
        'attribute_group already exists',
        'ENTRYPOINT_FAILED'
    )
)]
fn test_create_attribute_group_collision_2() {
    let DefaultWorld{world, generic_sets, sets_ducks, booklet_ducks, attribute_groups_addr, .. } =
        spawn_briq_test_world();

    create_attribute_group(
        world,
        attribute_groups_addr,
        attribute_group_id: 1,
        owner: AttributeGroupOwner::Admin(USER1()),
        target_set_contract_address: generic_sets.contract_address,
    );

    create_attribute_group(
        world,
        attribute_groups_addr,
        attribute_group_id: 1,
        owner: AttributeGroupOwner::Contract(starknet::contract_address_const::<0xfade>()),
        target_set_contract_address: sets_ducks.contract_address,
    );
}


//
// Test Update
//

#[test]
#[available_gas(300000000)]
fn test_update_attribute_group_ok() {
    let DefaultWorld{world, generic_sets, sets_ducks, booklet_ducks, attribute_groups_addr, .. } =
        spawn_briq_test_world();

    create_attribute_group(
        world,
        attribute_groups_addr,
        attribute_group_id: 0x69,
        owner: AttributeGroupOwner::Contract(starknet::contract_address_const::<0xfafa>()),
        target_set_contract_address: generic_sets.contract_address,
    );

    update_attribute_group(
        world,
        attribute_groups_addr,
        attribute_group_id: 0x69,
        owner: AttributeGroupOwner::Contract(starknet::contract_address_const::<0xfafade>()),
        target_set_contract_address: sets_ducks.contract_address,
    );

    let attribute_group = AttributeGroupTrait::get_attribute_group(world, 0x69);

    match attribute_group.owner {
        AttributeGroupOwner::Admin(admin) => {
            panic(array!['invalid owner']);
        },
        AttributeGroupOwner::Contract(addr) => {
            assert(
                addr == starknet::contract_address_const::<0xfafade>(), 'invalid cintract address'
            );
        },
    }
    assert(
        attribute_group.target_set_contract_address == sets_ducks.contract_address,
        'invalid target_address'
    );
}


#[test]
#[available_gas(300000000)]
#[should_panic(
    expected: (
        'unexisting attribute_group_id',
        'ENTRYPOINT_FAILED'
    )
)]
fn test_update_attribute_group_non_existing() {
    let DefaultWorld{world, generic_sets, sets_ducks, attribute_groups_addr, .. } =
        spawn_briq_test_world();

    update_attribute_group(
        world,
        attribute_groups_addr,
        attribute_group_id: 0x69,
        owner: AttributeGroupOwner::Contract(starknet::contract_address_const::<0xfafade>()),
        target_set_contract_address: sets_ducks.contract_address,
    );
}


//
// Auth
//

#[test]
#[available_gas(300000000)]
#[should_panic(
    expected: ('Not authorized', 'ENTRYPOINT_FAILED')
)]
fn test_create_attribute_group_with_non_world_admin() {
    let DefaultWorld{world, generic_sets, attribute_groups_addr, .. } = spawn_briq_test_world();

    impersonate(DEFAULT_OWNER());

    create_attribute_group(
        world,
        attribute_groups_addr,
        attribute_group_id: 1,
        owner: AttributeGroupOwner::Admin(USER1()),
        target_set_contract_address: generic_sets.contract_address,
    );
}


#[test]
#[available_gas(300000000)]
#[should_panic(
    expected: ('Not authorized', 'ENTRYPOINT_FAILED')
)]
fn test_update_attribute_group_with_non_world_admin() {
    let DefaultWorld{world, generic_sets, sets_ducks, attribute_groups_addr, .. } =
        spawn_briq_test_world();

    create_attribute_group(
        world,
        attribute_groups_addr,
        attribute_group_id: 0x69,
        owner: AttributeGroupOwner::Contract(sets_ducks.contract_address),
        target_set_contract_address: generic_sets.contract_address,
    );

    impersonate(DEFAULT_OWNER());

    update_attribute_group(
        world,
        attribute_groups_addr,
        attribute_group_id: 0x69,
        owner: AttributeGroupOwner::Contract(sets_ducks.contract_address),
        target_set_contract_address: sets_ducks.contract_address,
    );
}
