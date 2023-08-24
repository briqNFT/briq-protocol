use core::serde::Serde;
use starknet::ContractAddress;
use traits::Into;
use traits::TryInto;
use array::ArrayTrait;
use array::SpanTrait;
use option::OptionTrait;
use zeroable::Zeroable;
use clone::Clone;

use briq_protocol::types::{FTSpec, ShapeItem};
use briq_protocol::felt_math::{FeltBitAnd, FeltOrd};
use briq_protocol::cumulative_balance::{CUM_BALANCE_TOKEN, CB_BRIQ, CB_ATTRIBUTES};

use dojo::world::{Context, IWorldDispatcherTrait};
use dojo_erc::erc1155::components::ERC1155Balance;
use briq_protocol::world_config::{SYSTEM_CONFIG_ID, WorldConfig};

use briq_protocol::attributes::get_collection_id;
use briq_protocol::attributes::collection::{Collection, CollectionTrait};

use briq_protocol::check_shape::{ShapeVerifier, CheckShapeTrait};

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

fn assign_attributes(
    ctx: Context,
    set_owner: ContractAddress,
    set_token_id: felt252,
    mut attributes: Array<felt252>,
    shape: @Array<ShapeItem>,
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
    shape: @Array<ShapeItem>,
    fts: @Array<FTSpec>,
) {
    assert(set_owner.is_non_zero(), 'Bad input');
    assert(set_token_id != 0, 'Bad input');
    assert(attribute_id != 0, 'Bad input');

    let caller = ctx.origin;
    let set_addr = get!(ctx.world, (SYSTEM_CONFIG_ID), WorldConfig).set;
    // TODO: Set permissions on the collection (owner / set) ?
    assert(caller == set_addr, 'Bad caller');

    let collection_id = get_collection_id(attribute_id);
    let (admin, system) = get!(ctx.world, (collection_id), Collection).get_admin_or_system();
    if admin.is_some() {
        //library_erc1155::transferability::Transferability::_transfer_burnable(0, set_token_id, attribute_id, 1);
        assert(0 == 1, 'TODO');
    } else {
        let shape_verifier = get!(ctx.world, (attribute_id), ShapeVerifier);
        shape_verifier
            .assign_attribute(ctx.world, set_owner, set_token_id, attribute_id, shape, fts);
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

    let caller = ctx.origin;
    let set_addr = get!(ctx.world, (SYSTEM_CONFIG_ID), WorldConfig).set;
    // TODO: Set permissions on the collection (owner / set) ?
    assert(caller == set_addr, 'Bad caller');

    let collection_id = get_collection_id(attribute_id);
    let (admin, system) = get!(ctx.world, (collection_id), Collection).get_admin_or_system();
    if admin.is_some() {
        //library_erc1155::transferability::Transferability::_transfer_burnable(set_token_id, 0, attribute_id, 1);
        assert(0 == 1, 'TODO');
    } else {
        let shape_verifier = get!(ctx.world, (attribute_id), ShapeVerifier);
        shape_verifier.remove_attribute(ctx.world, set_owner, set_token_id, attribute_id);
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
