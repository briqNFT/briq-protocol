use starknet::testing::{set_caller_address, set_contract_address};
use starknet::ContractAddress;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use token::erc721::interface::IERC721DispatcherTrait;
use token::erc1155::interface::IERC1155DispatcherTrait;
use token::erc1155::interface::IERC1155Dispatcher;

use briq_protocol::set_nft::assembly::{ISetNftAssemblyDispatcherTrait, ISetNftAssemblySafeDispatcherTrait};

use briq_protocol::tests::test_utils::{
    WORLD_ADMIN, DEFAULT_OWNER, ZERO, DefaultWorld, spawn_briq_test_world, mint_briqs, impersonate
};

use briq_protocol::types::{FTSpec, ShapeItem, ShapePacking, PackedShapeItem, AttributeItem};
use briq_protocol::cumulative_balance::{CUM_BALANCE_TOKEN, CB_ATTRIBUTES, CB_BRIQ};
use briq_protocol::world_config::get_world_config;

use debug::PrintTrait;

use briq_protocol::tests::test_set_nft::convenience_for_testing::{
    create_contract_attribute_group,
    get_test_shapes_class_hash,
    register_shape_validator_shapes,
    valid_shape_1,
    mint_booklet,
    as_set,
    as_set_safe,
};


#[test]
#[available_gas(3000000000)]
fn test_simple_mint_and_burn_for_1155() {
    let DefaultWorld{world, briq_token, generic_sets, sets_1155, booklet_ducks, attribute_groups_addr, register_shape_validator_addr, .. } = spawn_briq_test_world();

    let attribute_group = 0xcafafa;
    let attribute_id: u64 = 0x1;

    create_contract_attribute_group(
        world,
        attribute_groups_addr,
        attribute_group,
        booklet_ducks.contract_address,
        sets_1155.contract_address
    );

    register_shape_validator_shapes(world, register_shape_validator_addr, attribute_group);

    mint_booklet(
        booklet_ducks.contract_address,
        to: DEFAULT_OWNER(),
        id: attribute_id.into() + attribute_group.into() * 0x10000000000000000,
        amount: 3
    );
    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    impersonate(DEFAULT_OWNER());

    let token_id = (0xcafafa + 0x1 * 0x100000000);

    as_set(sets_1155).assemble(
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![AttributeItem { attribute_group_id: attribute_group, attribute_id } ],
    );

    assert(sets_1155.balance_of(DEFAULT_OWNER(), token_id.into()) == 1, 'Bad balance 1');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 0x1.into()) == 96, 'Bad balance 2');
    // TODO: change this
    assert(briq_token.balance_of(token_id.try_into().unwrap(), 0x1.into()) == 4, 'Bad balance 3');

    as_set(sets_1155).assemble(
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![AttributeItem { attribute_group_id: attribute_group, attribute_id } ],
    );

    as_set(sets_1155).assemble(
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![AttributeItem { attribute_group_id: attribute_group, attribute_id } ],
    );

    assert(sets_1155.balance_of(DEFAULT_OWNER(), token_id.into()) == 3, 'Bad balance 4');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 0x1.into()) == 88, 'Bad balance 5');
    //assert(briq_token.balance_of(DEFAULT_OWNER(), 0x1.into()) == 4, 'Bad balance 1');
    
    assert(as_set_safe(sets_1155).assemble(
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![AttributeItem { attribute_group_id: attribute_group, attribute_id } ],
    ).is_err(), 'fourth assembly shld fail');

    assert(briq_token.balance_of(token_id.try_into().unwrap(), 0x1.into()) == 12, 'Bad balance a');

    as_set(sets_1155).disassemble(
        DEFAULT_OWNER(),
        token_id,
        array![FTSpec { token_id: 1, qty: 4 }],
        array![AttributeItem { attribute_group_id: attribute_group, attribute_id } ],
    );

    assert(sets_1155.balance_of(DEFAULT_OWNER(), token_id.into()) == 2, 'Bad balance 4a');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 0x1.into()) == 92, 'Bad balance 5a');

    as_set(sets_1155).disassemble(
        DEFAULT_OWNER(),
        token_id,
        array![FTSpec { token_id: 1, qty: 4 }],
        array![AttributeItem { attribute_group_id: attribute_group, attribute_id } ],
    );
    assert(briq_token.balance_of(token_id.try_into().unwrap(), 0x1.into()) == 4, 'Bad balance b');
    assert(as_set_safe(sets_1155).disassemble(
        DEFAULT_OWNER(),
        token_id,
        array![FTSpec { token_id: 1, qty: 2 }],
        array![AttributeItem { attribute_group_id: attribute_group, attribute_id } ],
    ).is_err(), 'fourth disass shld fail');
    as_set_safe(sets_1155).disassemble(
        DEFAULT_OWNER(),
        token_id,
        array![FTSpec { token_id: 1, qty: 4 }],
        array![AttributeItem { attribute_group_id: attribute_group, attribute_id } ],
    );
    assert(as_set_safe(sets_1155).disassemble(
        DEFAULT_OWNER(),
        token_id,
        array![FTSpec { token_id: 1, qty: 4 }],
        array![AttributeItem { attribute_group_id: attribute_group, attribute_id } ],
    ).is_err(), 'fourth disass shld fail');

    assert(sets_1155.balance_of(DEFAULT_OWNER(), token_id.into()) == 0, 'Bad balance 4b');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 0x1.into()) == 100, 'Bad balance 5b');
}
