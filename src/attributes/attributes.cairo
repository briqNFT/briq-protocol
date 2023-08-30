use core::serde::Serde;
use starknet::ContractAddress;
use traits::{Into, TryInto};
use array::ArrayTrait;
use array::SpanTrait;
use option::OptionTrait;
use zeroable::Zeroable;
use clone::Clone;

use briq_protocol::types::{FTSpec, PackedShapeItem};
use briq_protocol::felt_math::{FeltBitAnd, FeltOrd};
use briq_protocol::cumulative_balance::{CUM_BALANCE_TOKEN, CB_ATTRIBUTES};

use dojo::world::{Context, IWorldDispatcher, IWorldDispatcherTrait};
use dojo_erc::erc1155::components::{ERC1155Balance, ERC1155BalanceTrait};
use briq_protocol::world_config::{WorldConfig};

use briq_protocol::attributes::get_attribute_group_id;
use briq_protocol::attributes::attribute_group::{
    AttributeGroup, AttributeGroupTrait, AttributeGroupOwner
};

use debug::PrintTrait;

#[derive(Drop, starknet::Event)]
struct AttributeAssigned {
    set_token_id: ContractAddress,
    attribute_id: felt252
}

#[derive(Drop, starknet::Event)]
struct AttributeRemoved {
    set_token_id: ContractAddress,
    attribute_id: felt252
}

#[derive(Drop, Serde)]
struct AttributeAssignData {
    set_owner: ContractAddress,
    set_token_id: ContractAddress,
    attribute_id: felt252,
    shape: Array<PackedShapeItem>,
    fts: Array<FTSpec>,
}

#[derive(Drop, Serde)]
struct AttributeRemoveData {
    set_owner: ContractAddress,
    set_token_id: ContractAddress,
    attribute_id: felt252
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
    mut attributes: Array<felt252>,
    shape: @Array<PackedShapeItem>,
    fts: @Array<FTSpec>,
) {
    if attributes.len() == 0 {
        return ();
    }

    assert(set_owner.is_non_zero(), 'Bad input');
    assert(set_token_id.is_non_zero(), 'Bad input');

    loop {
        if (attributes.len() == 0) {
            break ();
        }
        inner_attribute_assign(
            ctx, set_owner, set_token_id, attributes.pop_front().unwrap(), shape, fts
        );
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
    attribute_id: felt252,
    shape: @Array<PackedShapeItem>,
    fts: @Array<FTSpec>,
) {
    assert(attribute_id != 0, 'Bad input');

    let attribute_group_id = get_attribute_group_id(attribute_id);
    let attribute_group = AttributeGroupTrait::get_attribute_group(
        ctx.world, attribute_group_id.try_into().unwrap()
    );

    match attribute_group.owner {
        AttributeGroupOwner::Admin(address) => {
            //library_erc1155::transferability::Transferability::_transfer_burnable(0, set_token_id, attribute_id, 1);
            assert(0 == 1, 'TODO');
        },
        AttributeGroupOwner::System(system_name) => {
            let mut calldata: Array<felt252> = ArrayTrait::new();
            AttributeHandlerData::Assign(
                AttributeAssignData {
                    set_owner, set_token_id, attribute_id, shape: shape.clone(), fts: fts.clone()
                }
            )
                .serialize(ref calldata);
            ctx.world.execute(system_name, calldata);
        },
    };

    emit!(ctx.world, AttributeAssigned { set_token_id: set_token_id, attribute_id });
}

fn remove_attributes(
    ctx: Context,
    set_owner: ContractAddress,
    set_token_id: ContractAddress,
    mut attributes: Array<felt252>
) {
    if attributes.len() == 0 {
        return ();
    }

    assert(set_owner.is_non_zero(), 'Bad input');
    assert(set_token_id.is_non_zero(), 'Bad input');

    loop {
        if (attributes.len() == 0) {
            break ();
        }
        remove_attribute_inner(ctx, set_owner, set_token_id, attributes.pop_front().unwrap());
    };

    // Update the cumulative balance
    ERC1155BalanceTrait::unchecked_decrease_balance(
        ctx.world, CUM_BALANCE_TOKEN(), set_token_id, CB_ATTRIBUTES(), attributes.len().into()
    );
}

fn remove_attribute_inner(
    ctx: Context, set_owner: ContractAddress, set_token_id: ContractAddress, attribute_id: felt252,
) {
    assert(attribute_id != 0, 'Bad input');

    let attribute_group_id = get_attribute_group_id(attribute_id);
    let attribute_group = AttributeGroupTrait::get_attribute_group(
        ctx.world, attribute_group_id.try_into().unwrap()
    );

    match attribute_group.owner {
        AttributeGroupOwner::Admin(address) => {
            //library_erc1155::transferability::Transferability::_transfer_burnable(set_token_id, 0, attribute_id, 1);
            assert(0 == 1, 'TODO');
        },
        AttributeGroupOwner::System(system_name) => {
            let mut calldata: Array<felt252> = ArrayTrait::new();
            AttributeHandlerData::Remove(
                AttributeRemoveData { set_owner, set_token_id, attribute_id }
            )
                .serialize(ref calldata);
            ctx.world.execute(system_name, calldata);
        },
    }

    emit!(ctx.world, AttributeRemoved { set_token_id, attribute_id });
}

