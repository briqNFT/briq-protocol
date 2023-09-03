use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;

use starknet::testing::{set_caller_address, set_contract_address,};
use starknet::{ContractAddress, get_contract_address};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use dojo_erc::erc721::interface::IERC721DispatcherTrait;
use dojo_erc::erc1155::interface::IERC1155DispatcherTrait;
use dojo_erc::erc_common::utils::system_calldata;

use briq_protocol::tests::test_utils::{
    WORLD_ADMIN, DEFAULT_OWNER, ZERO, DefaultWorld, deploy_default_world, mint_briqs, impersonate
};
use briq_protocol::briq_token::systems::ERC1155MintBurnParams;
use briq_protocol::attributes::attribute_group::{CreateAttributeGroupParams, AttributeGroupOwner};
use briq_protocol::attributes::attribute_manager::RegisterAttributeManagerParams;
use briq_protocol::types::{FTSpec, ShapeItem, ShapePacking, PackedShapeItem, AttributeItem};
use briq_protocol::world_config::get_world_config;
use briq_protocol::utils::IntoContractAddressU256;
use briq_protocol::tests::test_set_nft::convenience_for_testing::{
    assemble, disassemble, create_attribute_group_1, register_attribute_manager_shape_69, valid_shape_1, mint_booklet
};

use debug::PrintTrait;


#[test]
#[available_gas(3000000000)]
fn test_multiple_set() {
    let DefaultWorld{world, briq_token, briq_set, ducks_set, booklet, .. } = deploy_default_world();

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

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

    assert(
        token_id == starknet::contract_address_const::<0x3fa51acc2defe858e3cb515b7e29c6e3ba22da5657e7cc33885860a6470bfc2>(),
        'bad token id'
    );

    assert(briq_set.balance_of(DEFAULT_OWNER()) == 1, 'should be 1');
    assert(briq_set.owner_of(token_id.into()) == DEFAULT_OWNER(), 'should be DEFAULT_OWNER');

    // create attribute_group for ducks_set
    create_attribute_group_1(world, ducks_set.contract_address);
    // register shape verifier for attribute_id = 0x69
    register_attribute_manager_shape_69(world);

    // mint a booklet for DEFAULT_OWNER
    mint_booklet(world,booklet.contract_address,DEFAULT_OWNER(), array![0x69],array![1]);
    
    // lets assemble a duck
    let token_id_duck = assemble(
        world,
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![AttributeItem { attribute_group_id: 0x1, attribute_id: 0x69 }],
    );

    assert(
        token_id_duck == starknet::contract_address_const::<0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057aee0d6eda3>(),
        'bad token id'
    );

    assert(ducks_set.balance_of(DEFAULT_OWNER()) == 1, 'should be 1');
    assert(ducks_set.owner_of(token_id_duck.into()) == DEFAULT_OWNER(), 'should be DEFAULT_OWNER');

    assert(briq_set.balance_of(DEFAULT_OWNER()) == 1, 'should be 1');
    assert(briq_set.owner_of(token_id.into()) == DEFAULT_OWNER(), 'should be DEFAULT_OWNER');
}
//////////////////////////////////////////////// 
//////////// TODO try to make it buggy 
// error: Failed setting up runner.
// Caused by:
//  #36142->#36143: Got 'Unknown ap change' error while moving [8].

// #[derive(Serde, Drop)]
// struct MyStruct {
//     caller: ContractAddress,
//     addr: ContractAddress,
//     arr: Array<felt252>,
// }

// fn aaa(addr: ContractAddress) -> felt252 {
//     let calldata = system_calldata(MyStruct { caller: get_contract_address(), addr: addr, arr:array![] });
//     123
// }

// fn bbb(addr: ContractAddress) -> felt252 {
//     let calldata = system_calldata(MyStruct { caller: get_contract_address(), addr: addr, arr:array![]  });
//     1234
// }

// #[test]
// #[available_gas(3000000000)]
// fn test_ap_move() {
//     let DefaultWorld{world, briq_token, briq_set, ducks_set, .. } = deploy_default_world();

//     let res = aaa(briq_set.contract_address);

//     assert(res == 123, 'qqq');
//     assert(briq_set.balance_of(DEFAULT_OWNER()) == 0, 'bad balance');

//     let res2 = bbb(briq_set.contract_address);
// }


