use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;

use starknet::testing::{set_caller_address, set_contract_address,};
use starknet::{ContractAddress, get_contract_address};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use dojo_erc::token::erc721::interface::IERC721DispatcherTrait;
use dojo_erc::token::erc1155::interface::IERC1155DispatcherTrait;

use briq_protocol::erc::erc1155::models::ERC1155Balance;

use briq_protocol::tests::test_utils::{
    WORLD_ADMIN, DEFAULT_OWNER, ZERO, DefaultWorld, spawn_briq_test_world, mint_briqs, impersonate, deploy
};
use briq_protocol::attributes::attribute_group::{IAttributeGroupsDispatcher, IAttributeGroupsDispatcherTrait, AttributeGroupOwner};
use briq_protocol::types::{FTSpec, ShapeItem, ShapePacking, PackedShapeItem, AttributeItem};
use briq_protocol::world_config::get_world_config;
use briq_protocol::tests::test_set_nft::convenience_for_testing::{
    as_set, valid_shape_1, valid_shape_2, valid_shape_3, mint_booklet, register_shape_validator_shapes, create_contract_attribute_group
};
use briq_protocol::cumulative_balance::{CUM_BALANCE_TOKEN, CB_ATTRIBUTES, CB_BRIQ};
use briq_protocol::set_nft::assembly::ISetNftAssemblyDispatcherTrait;
use briq_protocol::tokens::set_nft::set_nft::Transfer as SetNftTransfer;

use debug::PrintTrait;

#[test]
#[available_gas(3000000000)]
fn test_multiple_set() {
    let DefaultWorld{world, briq_token, generic_sets, sets_ducks, booklet_ducks, attribute_groups_addr, register_shape_validator_addr, .. } = spawn_briq_test_world();

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    impersonate(DEFAULT_OWNER());

    let token_id = as_set(generic_sets).assemble(
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 1 }],
        array![ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 })],
        array![],
    );

    assert(generic_sets.balance_of(DEFAULT_OWNER()) == 1, 'should be 1');
    assert(generic_sets.owner_of(token_id.into()) == DEFAULT_OWNER(), 'should be DEFAULT_OWNER');

    impersonate(WORLD_ADMIN());

    // create attribute_group for ducks_set & register shapes
    create_contract_attribute_group(world, attribute_groups_addr, 0xbaba, booklet_ducks.contract_address, sets_ducks.contract_address);
    register_shape_validator_shapes(world, register_shape_validator_addr, 0xbaba);

    // mint a booklet for DEFAULT_OWNER
    mint_booklet(booklet_ducks.contract_address, DEFAULT_OWNER(), 0xbaba0000000000000001, 1);

    impersonate(DEFAULT_OWNER());

    // lets assemble a duck
    let token_id_duck = as_set(sets_ducks).assemble(
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![AttributeItem { attribute_group_id: 0xbaba, attribute_id: 0x1 }],
    );

    assert(sets_ducks.balance_of(DEFAULT_OWNER()) == 1, 'should be 1');
    assert(sets_ducks.owner_of(token_id_duck.into()) == DEFAULT_OWNER(), 'should be DEFAULT_OWNER');

    assert(generic_sets.balance_of(DEFAULT_OWNER()) == 1, 'should be 1');
    assert(generic_sets.owner_of(token_id.into()) == DEFAULT_OWNER(), 'should be DEFAULT_OWNER');
}

#[test]
#[available_gas(3000000000)]
fn test_multiple_attributes() {
    let DefaultWorld{world, briq_token, sets_ducks, booklet_ducks, attribute_groups_addr, register_shape_validator_addr, .. } = spawn_briq_test_world();

    create_contract_attribute_group(world, attribute_groups_addr, 0xbaba, booklet_ducks.contract_address, sets_ducks.contract_address);
    register_shape_validator_shapes(world, register_shape_validator_addr, 0xbaba);

    // mint a booklet for DEFAULT_OWNER
    mint_booklet(booklet_ducks.contract_address, DEFAULT_OWNER(), 0xbaba0000000000000002, 1);

    // Deploy another system for this test.
    let briq_counter_addr = deploy(world, briq_protocol::tests::briq_counter::TestBriqCounterAttributeHandler::TEST_CLASS_HASH);
    create_contract_attribute_group(world, attribute_groups_addr, 0xf00, briq_counter_addr, Zeroable::zero());
    
    // Test start

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    impersonate(DEFAULT_OWNER());

    let token_id = as_set(sets_ducks).assemble(
        DEFAULT_OWNER(),
        0x533d,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 3 }],
        valid_shape_2(),
        array![
            AttributeItem { attribute_group_id: 0xbaba, attribute_id: 0x2 },
            AttributeItem { attribute_group_id: 0xf00, attribute_id: 0x3 } // at least 3 briqs attr
        ],
    );

    assert(DEFAULT_OWNER() == sets_ducks.owner_of(token_id.into()), 'bad owner');
    assert(sets_ducks.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(booklet_ducks.balance_of(token_id.try_into().unwrap(), 0xbaba0000000000000002) == 1, 'bad booklet balance 2');
    assert(
        get!(world, (CUM_BALANCE_TOKEN(), token_id, CB_ATTRIBUTES()), ERC1155Balance).amount == 2,
        'should be 2'
    );
    assert(
        get!(world, (CUM_BALANCE_TOKEN(), token_id, CB_BRIQ()), ERC1155Balance).amount == 1,
        'should be 1'
    );

    as_set(sets_ducks).disassemble(
        DEFAULT_OWNER(),
        token_id,
        array![FTSpec { token_id: 1, qty: 3 }],
        array![
            AttributeItem { attribute_group_id: 0xbaba, attribute_id: 0x2 },
            AttributeItem { attribute_group_id: 0xf00, attribute_id: 0x3 } // at least 3 briqs attr
        ]
    );
    assert(booklet_ducks.balance_of(DEFAULT_OWNER(), 0xbaba0000000000000002) == 1, 'bad booklet balance 3');
    assert(
        get!(world, (CUM_BALANCE_TOKEN(), token_id, CB_ATTRIBUTES()), ERC1155Balance).amount == 0,
        'should be 0'
    );
    assert(
        get!(world, (CUM_BALANCE_TOKEN(), token_id, CB_BRIQ()), ERC1155Balance).amount == 0,
        'should be 0'
    );
}
