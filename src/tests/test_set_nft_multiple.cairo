use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;

use starknet::testing::{set_caller_address, set_contract_address,};
use starknet::{ContractAddress, get_contract_address};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use dojo_erc::erc_common::utils::system_calldata;
use dojo_erc::erc721::interface::IERC721DispatcherTrait;
use dojo_erc::erc1155::interface::IERC1155DispatcherTrait;
use dojo_erc::erc1155::components::ERC1155BalanceTrait;

use briq_protocol::tests::test_utils::{
    WORLD_ADMIN, DEFAULT_OWNER, ZERO, DefaultWorld, deploy_default_world, mint_briqs, impersonate
};
use briq_protocol::attributes::attribute_group::{CreateAttributeGroupParams, AttributeGroupOwner};
use briq_protocol::attributes::group_systems::booklet::RegisterShapeValidatorParams;
use briq_protocol::types::{FTSpec, ShapeItem, ShapePacking, PackedShapeItem, AttributeItem};
use briq_protocol::world_config::get_world_config;
use briq_protocol::tests::test_set_nft::convenience_for_testing::{
    assemble, disassemble, valid_shape_1, valid_shape_2, valid_shape_3, mint_booklet,
    create_attribute_group_with_booklet, register_shape_validator_shapes,
    create_attribute_group_with_briq_counter
};
use briq_protocol::cumulative_balance::{CUM_BALANCE_TOKEN, CB_ATTRIBUTES, CB_BRIQ};

use debug::PrintTrait;

#[test]
#[available_gas(3000000000)]
fn test_multiple_set() {
    let DefaultWorld{world, briq_token, generic_sets, ducks_set, ducks_booklet, .. } =
        deploy_default_world();

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    impersonate(DEFAULT_OWNER());

    let token_id = assemble(
        world,
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
    create_attribute_group_with_booklet(
        world, 0x69, ducks_set.contract_address, ducks_booklet.contract_address
    );
    register_shape_validator_shapes(world, 0x69);

    // mint a booklet for DEFAULT_OWNER
    mint_booklet(world, ducks_booklet.contract_address, DEFAULT_OWNER(), array![0x1], array![1]);

    impersonate(DEFAULT_OWNER());

    // lets assemble a duck
    let token_id_duck = assemble(
        world,
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![AttributeItem { attribute_group_id: 0x69, attribute_id: 0x1 }],
    );

    assert(ducks_set.balance_of(DEFAULT_OWNER()) == 1, 'should be 1');
    assert(ducks_set.owner_of(token_id_duck.into()) == DEFAULT_OWNER(), 'should be DEFAULT_OWNER');

    assert(generic_sets.balance_of(DEFAULT_OWNER()) == 1, 'should be 1');
    assert(generic_sets.owner_of(token_id.into()) == DEFAULT_OWNER(), 'should be DEFAULT_OWNER');
}

#[test]
#[available_gas(3000000000)]
fn test_multiple_attributes() {
    let DefaultWorld{world, briq_token, ducks_set, ducks_booklet, .. } = deploy_default_world();

    create_attribute_group_with_booklet(
        world, 0x69, ducks_set.contract_address, ducks_booklet.contract_address
    );
    register_shape_validator_shapes(world, 0x69);

    create_attribute_group_with_briq_counter(world, 0x420);

    mint_booklet(world, ducks_booklet.contract_address, DEFAULT_OWNER(), array![0x2], array![1]);
    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    impersonate(DEFAULT_OWNER());

    let token_id = assemble(
        world,
        DEFAULT_OWNER(),
        0x533d,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 3 }],
        valid_shape_2(),
        array![
            AttributeItem { attribute_group_id: 0x69, attribute_id: 0x2 },
            AttributeItem { attribute_group_id: 0x420, attribute_id: 0x3 } // at least 3 briqs attr
        ],
    );

    assert(DEFAULT_OWNER() == ducks_set.owner_of(token_id.into()), 'bad owner');
    assert(ducks_set.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(ducks_booklet.balance_of(token_id, 0x2) == 1, 'bad booklet balance 2');
    assert(
        ERC1155BalanceTrait::balance_of(world, CUM_BALANCE_TOKEN(), token_id, CB_ATTRIBUTES()) == 2,
        'should be 2'
    );
    assert(
        ERC1155BalanceTrait::balance_of(world, CUM_BALANCE_TOKEN(), token_id, CB_BRIQ()) == 1,
        'should be 1'
    );

    disassemble(
        world,
        DEFAULT_OWNER(),
        token_id,
        array![FTSpec { token_id: 1, qty: 3 }],
        array![
            AttributeItem { attribute_group_id: 0x69, attribute_id: 0x2 },
            AttributeItem { attribute_group_id: 0x420, attribute_id: 0x3 } // at least 3 briqs attr
        ]
    );
    assert(ducks_booklet.balance_of(DEFAULT_OWNER(), 0x2) == 1, 'bad booklet balance 3');
    assert(
        ERC1155BalanceTrait::balance_of(world, CUM_BALANCE_TOKEN(), token_id, CB_ATTRIBUTES()) == 0,
        'should be 0'
    );
    assert(
        ERC1155BalanceTrait::balance_of(world, CUM_BALANCE_TOKEN(), token_id, CB_BRIQ()) == 0,
        'should be 0'
    );
}
//
//
//////////////////////////////////////////////// 
//////////// TODO try to make it buggy 
// error: Failed setting up runner.
// Caused by:
//  #36142->#36143: Got 'Unknown ap change' error while moving [8].

#[derive(Serde, Drop)]
struct MyStruct {
    caller: ContractAddress,
    addr: ContractAddress,
    arr: Array<felt252>,
}

fn aaa(addr: ContractAddress) -> felt252 {
    let calldata = system_calldata(MyStruct { caller: get_contract_address(), addr: addr, arr:array![] });
    123
}

fn bbb(addr: ContractAddress) -> felt252 {
    let calldata = system_calldata(MyStruct { caller: get_contract_address(), addr: addr, arr:array![]  });
    1234
}

#[test]
#[available_gas(3000000000)]
fn test_ap_move() {
    let DefaultWorld{world, briq_token, generic_sets, ducks_set, .. } = deploy_default_world();

    let res = aaa(generic_sets.contract_address);

    let ra = MyStruct { caller: get_contract_address(), addr: generic_sets.contract_address, arr:array![]  };

    assert(res == 123, 'qqq');
    assert(generic_sets.balance_of(DEFAULT_OWNER()) == 0, 'bad balance');

    let res2 = bbb(generic_sets.contract_address);
}


