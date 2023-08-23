use core::serde::Serde;
use starknet::ContractAddress;
use traits::Into;
use traits::TryInto;
use array::ArrayTrait;
use array::SpanTrait;
use option::OptionTrait;
use zeroable::Zeroable;
use clone::Clone;

use briq_protocol::types::{FTSpec, PackedShapeItem};
use briq_protocol::felt_math::{FeltBitAnd, FeltOrd};
use briq_protocol::cumulative_balance::{CUM_BALANCE_TOKEN, CB_BRIQ, CB_ATTRIBUTES};

use dojo::world::{Context, IWorldDispatcher, IWorldDispatcherTrait};
use dojo_erc::erc1155::components::ERC1155Balance;
use briq_protocol::world_config::{SYSTEM_CONFIG_ID, WorldConfig};

use briq_protocol::attributes::get_collection_id;
use briq_protocol::attributes::collection::{Collection, CollectionTrait};

use debug::PrintTrait;


#[derive(Drop, starknet::Event)]
struct AttributeAssigned {
    set_token_id: u256,
    attribute_id: felt252
}

#[derive(Drop, starknet::Event)]
struct AttributeRemoved {
    set_token_id: u256,
    attribute_id: felt252
}

#[derive(Drop, Serde)]
struct AttributeAssignData {
    set_owner: ContractAddress,
    set_token_id: felt252,
    attribute_id: felt252,
    shape: Array<PackedShapeItem>,
    fts: Array<FTSpec>,
}

#[derive(Drop, Serde)]
struct AttributeRemoveData {
    set_owner: ContractAddress,
    set_token_id: felt252,
    attribute_id: felt252
}

#[derive(Drop, Serde)]
enum AttributeHandlerData
{
    Assign: AttributeAssignData,
    Remove: AttributeRemoveData,
}

fn assign_attributes(
    ctx: Context,
    set_owner: ContractAddress,
    set_token_id: felt252,
    mut attributes: Array<felt252>,
    shape: @Array<PackedShapeItem>,
    fts: @Array<FTSpec>,
) {
    loop {
        if (attributes.len() == 0) {
            break ();
        }
        assign_attribute(ctx, set_owner, set_token_id, attributes.pop_front().unwrap(), shape, fts);
    }
}

fn assign_attribute(
    ctx: Context,
    set_owner: ContractAddress,
    set_token_id: felt252,
    attribute_id: felt252,
    shape: @Array<PackedShapeItem>,
    fts: @Array<FTSpec>,
) {
    assert(set_owner.is_non_zero(), 'Bad input');
    assert(set_token_id != 0, 'Bad input');
    assert(attribute_id != 0, 'Bad input');
 
    let collection_id = get_collection_id(attribute_id);
    let (admin, system) = get!(ctx.world, (collection_id), Collection).get_admin_or_system();
    if admin.is_some() {
        //library_erc1155::transferability::Transferability::_transfer_burnable(0, set_token_id, attribute_id, 1);
        assert(0 == 1, 'TODO');
    } else {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        AttributeHandlerData::Assign(AttributeAssignData { set_owner, set_token_id, attribute_id, shape: shape.clone(), fts: fts.clone() }).serialize(ref calldata);
        ctx.world.execute(system.unwrap().into(), calldata);
    }
    emit!(ctx.world, AttributeAssigned { set_token_id: set_token_id.into(), attribute_id });

    // Update the cumulative balance
    let balance = get!(
        ctx.world, (CUM_BALANCE_TOKEN(), CB_ATTRIBUTES, set_token_id), ERC1155Balance
    )
        .amount;
    assert(balance < balance + 1, 'Balance overflow');
    set!(
        ctx.world, ERC1155Balance {
            token: CUM_BALANCE_TOKEN(),
            token_id: CB_ATTRIBUTES,
            account: set_token_id.try_into().unwrap(),
            amount: balance + 1
        }
    );
}

fn remove_attributes(
    ctx: Context, set_owner: ContractAddress, set_token_id: felt252, mut attributes: Array<felt252>
) {
    loop {
        if (attributes.len() == 0) {
            break ();
        }
        remove_attribute(ctx, set_owner, set_token_id, attributes.pop_front().unwrap());
    }
}

fn remove_attribute(
    ctx: Context, set_owner: ContractAddress, set_token_id: felt252, attribute_id: felt252, 
) {
    assert(set_owner.is_non_zero(), 'Bad input');
    assert(set_token_id != 0, 'Bad input');
    assert(attribute_id != 0, 'Bad input');

    let collection_id = get_collection_id(attribute_id);
    let (admin, system) = get!(ctx.world, (collection_id), Collection).get_admin_or_system();
    if admin.is_some() {
        //library_erc1155::transferability::Transferability::_transfer_burnable(set_token_id, 0, attribute_id, 1);
        assert(0 == 1, 'TODO');
    } else {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        AttributeHandlerData::Remove(AttributeRemoveData { set_owner, set_token_id, attribute_id }).serialize(ref calldata);
        ctx.world.execute(system.unwrap().into(), calldata);
    }

    emit!(ctx.world, AttributeRemoved { set_token_id: set_token_id.into(), attribute_id });

    // Update the cumulative balance
    let balance = get!(
        ctx.world, (CUM_BALANCE_TOKEN(), CB_ATTRIBUTES, set_token_id), ERC1155Balance
    )
        .amount;
    assert(balance > balance - 1, 'Balance underflow');
    set!(
        ctx.world, ERC1155Balance {
            token: CUM_BALANCE_TOKEN(),
            token_id: CB_ATTRIBUTES,
            account: set_token_id.try_into().unwrap(),
            amount: balance - 1
        }
    );
}
