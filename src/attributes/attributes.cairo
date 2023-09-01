use core::serde::Serde;
use starknet::ContractAddress;
use traits::{Into, TryInto};
use array::ArrayTrait;
use array::SpanTrait;
use option::OptionTrait;
use zeroable::Zeroable;
use clone::Clone;

use briq_protocol::types::{FTSpec, PackedShapeItem, AttributeItem};
use briq_protocol::felt_math::{FeltBitAnd, FeltOrd};
use briq_protocol::cumulative_balance::{CUM_BALANCE_TOKEN, CB_ATTRIBUTES};

use dojo::world::{Context, IWorldDispatcher, IWorldDispatcherTrait};
use dojo_erc::erc1155::components::{ERC1155Balance, ERC1155BalanceTrait};
use briq_protocol::world_config::{WorldConfig};

use briq_protocol::attributes::attribute_group::{
    AttributeGroup, AttributeGroupTrait, AttributeGroupOwner
};

use dojo_erc::erc_common::utils::system_calldata;


use debug::PrintTrait;

#[derive(Drop, starknet::Event)]
struct AttributeAssigned {
    set_token_id: ContractAddress,
    attribute_group_id: u64,
    attribute_id: u64
}

#[derive(Drop, starknet::Event)]
struct AttributeRemoved {
    set_token_id: ContractAddress,
    attribute_group_id: u64,
    attribute_id: u64
}

#[derive(Drop, Serde)]
struct AttributeAssignData {
    set_owner: ContractAddress,
    set_token_id: ContractAddress,
    attribute_group_id: u64,
    attribute_id: u64,
    shape: Array<PackedShapeItem>,
    fts: Array<FTSpec>,
}

#[derive(Drop, Serde)]
struct AttributeRemoveData {
    set_owner: ContractAddress,
    set_token_id: ContractAddress,
    attribute_group_id: u64,
    attribute_id: u64
}

#[derive(Drop, Serde)]
enum AttributeHandlerData {
    Assign: AttributeAssignData,
    Remove: AttributeRemoveData,
}

fn assign_attributes(
    ctx: Context,
    set_owner: ContractAddress,
    set_token_id: ContractAddress,
    attributes: @Array<AttributeItem>,
    shape: @Array<PackedShapeItem>,
    fts: @Array<FTSpec>,
) {
    if attributes.len() == 0 {
        return ();
    }
    assert(set_owner.is_non_zero(), 'Bad input');
    assert(set_token_id.is_non_zero(), 'Bad input');

    let mut attr_span = attributes.span();
    loop {
        match attr_span.pop_front() {
            Option::Some(attribute) => {
                inner_attribute_assign(ctx, set_owner, set_token_id, *attribute, shape, fts);
            },
            Option::None => {
                break ();
            }
        };
    };

    // Update the cumulative balance
    ERC1155BalanceTrait::unchecked_increase_balance(
        ctx.world, CUM_BALANCE_TOKEN(), set_token_id, CB_ATTRIBUTES(), attributes.len().into()
    );
}

fn inner_attribute_assign(
    ctx: Context,
    set_owner: ContractAddress,
    set_token_id: ContractAddress,
    attribute: AttributeItem,
    shape: @Array<PackedShapeItem>,
    fts: @Array<FTSpec>,
) {
    assert(attribute.attribute_id != 0, 'Bad input');

    let attribute_group = AttributeGroupTrait::get_attribute_group(
        ctx.world, attribute.attribute_group_id
    );

    match attribute_group.owner {
        AttributeGroupOwner::Admin(address) => {
            //library_erc1155::transferability::Transferability::_transfer_burnable(0, set_token_id, attribute_id, 1);
            assert(0 == 1, 'TODO assign');
        },
        AttributeGroupOwner::System(system_name) => {
            ctx
                .world
                .execute(
                    system_name,
                    system_calldata(
                        AttributeHandlerData::Assign(
                            AttributeAssignData {
                                set_owner,
                                set_token_id,
                                attribute_group_id: attribute.attribute_group_id,
                                attribute_id: attribute.attribute_id,
                                shape: shape.clone(),
                                fts: fts.clone()
                            }
                        )
                    )
                );
        },
    };

    emit!(
        ctx.world,
        AttributeAssigned {
            set_token_id: set_token_id,
            attribute_group_id: attribute.attribute_group_id,
            attribute_id: attribute.attribute_id
        }
    );
}

fn remove_attributes(
    ctx: Context,
    set_owner: ContractAddress,
    set_token_id: ContractAddress,
    attributes: Array<AttributeItem>
) {
    if attributes.len() == 0 {
        return ();
    }

    assert(set_owner.is_non_zero(), 'Bad input');
    assert(set_token_id.is_non_zero(), 'Bad input');

    let mut attr_span = attributes.span();
    loop {
        match attr_span.pop_front() {
            Option::Some(attribute) => {
                remove_attribute_inner(ctx, set_owner, set_token_id, *attribute);
            },
            Option::None => {
                break ();
            }
        };
    };

    // Update the cumulative balance
    ERC1155BalanceTrait::unchecked_decrease_balance(
        ctx.world, CUM_BALANCE_TOKEN(), set_token_id, CB_ATTRIBUTES(), attributes.len().into()
    );
}

fn remove_attribute_inner(
    ctx: Context,
    set_owner: ContractAddress,
    set_token_id: ContractAddress,
    attribute: AttributeItem,
) {
    assert(attribute.attribute_id != 0, 'Bad input');

    let attribute_group = AttributeGroupTrait::get_attribute_group(
        ctx.world, attribute.attribute_group_id
    );

    match attribute_group.owner {
        AttributeGroupOwner::Admin(address) => {
            //library_erc1155::transferability::Transferability::_transfer_burnable(set_token_id, 0, attribute_id, 1);
            assert(0 == 1, 'TODO remove');
        },
        AttributeGroupOwner::System(system_name) => {
            ctx
                .world
                .execute(
                    system_name,
                    system_calldata(
                        AttributeHandlerData::Remove(
                            AttributeRemoveData {
                                set_owner,
                                set_token_id,
                                attribute_group_id: attribute.attribute_group_id,
                                attribute_id: attribute.attribute_id
                            }
                        )
                    )
                );
        },
    }

    emit!(
        ctx.world,
        AttributeRemoved {
            set_token_id,
            attribute_group_id: attribute.attribute_group_id,
            attribute_id: attribute.attribute_id
        }
    );
}

