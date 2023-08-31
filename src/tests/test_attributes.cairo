use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;
use starknet::ContractAddress;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use briq_protocol::tests::test_utils::{
    DefaultWorld, DEFAULT_OWNER, USER1, deploy_default_world, impersonate
};

use dojo_erc::erc721::interface::IERC721DispatcherTrait;

use briq_protocol::types::{FTSpec, ShapeItem};

use debug::PrintTrait;

use briq_protocol::attributes::attribute_group::{CreateAttributeGroupData, AttributeGroupOwner};
use dojo_erc::erc_common::utils::{system_calldata};


#[test]
#[available_gas(30000000)]
fn test_create_attribute_groups() {
    let DefaultWorld{world, briq_set, .. } = deploy_default_world();

    {
        world
            .execute(
                'create_attribute_group',
                system_calldata(
                    CreateAttributeGroupData {
                        attribute_group_id: 1,
                        owner: AttributeGroupOwner::Admin(USER1()),
                        briq_set_contract_address: briq_set.contract_address
                    }
                )
            );
    }

    {
        world
            .execute(
                'create_attribute_group',
                system_calldata(
                    CreateAttributeGroupData {
                        attribute_group_id: 2,
                        owner: AttributeGroupOwner::Admin(USER1()),
                        briq_set_contract_address: briq_set.contract_address
                    }
                )
            );
    }
}

#[test]
#[available_gas(30000000)]
#[should_panic]
fn test_create_attribute_group_collision() {
    let DefaultWorld{world, briq_set, .. } = deploy_default_world();

    {
        world
            .execute(
                'create_attribute_group',
                system_calldata(
                    CreateAttributeGroupData {
                        attribute_group_id: 1,
                        owner: AttributeGroupOwner::Admin(USER1()),
                        briq_set_contract_address: briq_set.contract_address
                    }
                )
            );
    }

    {
        world
            .execute(
                'create_attribute_group',
                system_calldata(
                    CreateAttributeGroupData {
                        attribute_group_id: 1,
                        owner: AttributeGroupOwner::Admin(USER1()),
                        briq_set_contract_address: briq_set.contract_address
                    }
                )
            );
    }
}


#[test]
#[available_gas(30000000)]
#[should_panic]
fn test_create_attribute_group_with_non_world_admin() {
    let DefaultWorld{world, briq_set, .. } = deploy_default_world();

    impersonate(DEFAULT_OWNER());

    world
        .execute(
            'create_attribute_group',
            system_calldata(
                CreateAttributeGroupData {
                    attribute_group_id: 1,
                    owner: AttributeGroupOwner::Admin(USER1()),
                    briq_set_contract_address: briq_set.contract_address
                }
            )
        );
}
