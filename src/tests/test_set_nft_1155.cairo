use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;

use starknet::testing::{set_caller_address, set_contract_address};
use starknet::ContractAddress;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use dojo_erc::erc_common::utils::{system_calldata};
use dojo_erc::erc721::interface::IERC721DispatcherTrait;
use dojo_erc::erc721::erc721::ERC721::{
    Approval, Transfer, ApprovalForAll, Event
};
use dojo_erc::erc1155::interface::{IERC1155DispatcherTrait};
use dojo_erc::erc1155::components::ERC1155BalanceTrait;

use briq_protocol::tests::test_utils::{
    WORLD_ADMIN, DEFAULT_OWNER, ZERO, DefaultWorld, deploy_default_world, mint_briqs, impersonate
};
use briq_protocol::attributes::attribute_group::{CreateAttributeGroupParams, AttributeGroupOwner};
use briq_protocol::types::{FTSpec, ShapeItem, ShapePacking, PackedShapeItem, AttributeItem};
use briq_protocol::world_config::get_world_config;
use briq_protocol::utils::IntoContractAddressU256;
use briq_protocol::cumulative_balance::{CUM_BALANCE_TOKEN, CB_ATTRIBUTES, CB_BRIQ};

use debug::PrintTrait;

use briq_protocol::tests::test_set_nft::convenience_for_testing::{
    create_attribute_group_with_booklet,
    get_test_shapes_class_hash,
    register_shape_validator,
    valid_shape_1,
    mint_booklet
};
use dojo_erc::erc1155::interface::IERC1155Dispatcher;

#[starknet::interface]
trait SetNftInterface<ContractState> {
    fn assemble(
        self: @ContractState,
        owner: ContractAddress,
        token_id_hint: felt252,
        name: Array<felt252>, // todo string
        description: Array<felt252>, // todo string
        fts: Array<FTSpec>,
        shape: Array<PackedShapeItem>,
        attributes: Array<AttributeItem>
    );

    #[external(v0)]
    fn disassemble(
        self: @ContractState,
        owner: ContractAddress,
        token_id: ContractAddress,
        fts: Array<FTSpec>,
        attributes: Array<AttributeItem>
    );
}

fn rewrap(d: IERC1155Dispatcher) -> SetNftInterfaceDispatcher {
    SetNftInterfaceDispatcher { contract_address: d.contract_address }
}

fn rewrap_safe(d: IERC1155Dispatcher) -> SetNftInterfaceSafeDispatcher {
    SetNftInterfaceSafeDispatcher { contract_address: d.contract_address }
}

#[test]
#[available_gas(3000000000)]
fn test_simple_mint_and_burn_1155() {
    let DefaultWorld{world, briq_token, generic_sets, lilducks_1155_set, ducks_booklet, .. } = deploy_default_world();

    let attribute_group = 0xcafafa;
    let attribute_id: u64 = 0x1;

    mint_booklet(
        world,
        ducks_booklet.contract_address, // doesn't matter it's not the right one
        to: DEFAULT_OWNER(),
        ids: array![attribute_id.into()],
        amounts: array![3]
    );

    create_attribute_group_with_booklet(
        world,
        attribute_group,
        target_set_contract_address: lilducks_1155_set.contract_address,
        booklet_contract_address: ducks_booklet.contract_address,
    );

    register_shape_validator(world, attribute_group, attribute_id, get_test_shapes_class_hash());

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    impersonate(DEFAULT_OWNER());

    let token_id = (0x1 * 0x100000000 + 0xcafafa).try_into().unwrap();

    rewrap(lilducks_1155_set).assemble(
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![AttributeItem { attribute_group_id: attribute_group, attribute_id } ],
    );

    assert(lilducks_1155_set.balance_of(DEFAULT_OWNER(), token_id.into()) == 1, 'Bad balance 1');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 0x1.into()) == 96, 'Bad balance 2');
    // TODO: change this
    assert(briq_token.balance_of(token_id, 0x1.into()) == 4, 'Bad balance 3');

    rewrap(lilducks_1155_set).assemble(
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![AttributeItem { attribute_group_id: attribute_group, attribute_id } ],
    );
    rewrap(lilducks_1155_set).assemble(
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![AttributeItem { attribute_group_id: attribute_group, attribute_id } ],
    );
    assert(lilducks_1155_set.balance_of(DEFAULT_OWNER(), token_id.into()) == 3, 'Bad balance 4');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 0x1.into()) == 88, 'Bad balance 5');
    //assert(briq_token.balance_of(DEFAULT_OWNER(), 0x1.into()) == 4, 'Bad balance 1');
    
    assert(rewrap_safe(lilducks_1155_set).assemble(
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![AttributeItem { attribute_group_id: attribute_group, attribute_id } ],
    ).is_err(), 'fourth assembly shld fail');

    assert(briq_token.balance_of(token_id, 0x1.into()) == 12, 'Bad balance a');

    rewrap(lilducks_1155_set).disassemble(
        DEFAULT_OWNER(),
        token_id,
        array![FTSpec { token_id: 1, qty: 4 }],
        array![AttributeItem { attribute_group_id: attribute_group, attribute_id } ],
    );

    assert(lilducks_1155_set.balance_of(DEFAULT_OWNER(), token_id.into()) == 2, 'Bad balance 4a');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 0x1.into()) == 92, 'Bad balance 5a');

    rewrap(lilducks_1155_set).disassemble(
        DEFAULT_OWNER(),
        token_id,
        array![FTSpec { token_id: 1, qty: 4 }],
        array![AttributeItem { attribute_group_id: attribute_group, attribute_id } ],
    );
    assert(briq_token.balance_of(token_id, 0x1.into()) == 4, 'Bad balance b');
    assert(rewrap_safe(lilducks_1155_set).disassemble(
        DEFAULT_OWNER(),
        token_id,
        array![FTSpec { token_id: 1, qty: 2 }],
        array![AttributeItem { attribute_group_id: attribute_group, attribute_id } ],
    ).is_err(), 'fourth disass shld fail');
    rewrap_safe(lilducks_1155_set).disassemble(
        DEFAULT_OWNER(),
        token_id,
        array![FTSpec { token_id: 1, qty: 4 }],
        array![AttributeItem { attribute_group_id: attribute_group, attribute_id } ],
    );
    assert(rewrap_safe(lilducks_1155_set).disassemble(
        DEFAULT_OWNER(),
        token_id,
        array![FTSpec { token_id: 1, qty: 4 }],
        array![AttributeItem { attribute_group_id: attribute_group, attribute_id } ],
    ).is_err(), 'fourth disass shld fail');

    assert(lilducks_1155_set.balance_of(DEFAULT_OWNER(), token_id.into()) == 0, 'Bad balance 4b');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 0x1.into()) == 100, 'Bad balance 5b');

}
