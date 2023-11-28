use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;
use starknet::ContractAddress;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use presets::erc721::erc721::interface::IERC721DispatcherTrait;
use presets::erc1155::erc1155::interface::IERC1155DispatcherTrait;

use briq_protocol::world_config::get_world_config;
use briq_protocol::types::{FTSpec, ShapeItem};
use briq_protocol::tests::test_utils::{
    WORLD_ADMIN, DEFAULT_OWNER, ZERO, DefaultWorld, spawn_briq_test_world, mint_briqs, impersonate
};

use briq_protocol::tests::test_set_nft::convenience_for_testing::create_contract_attribute_group;
use briq_protocol::erc::mint_burn::{MintBurnDispatcher, MintBurnDispatcherTrait};
use briq_protocol::box_nft::unboxing::{UnboxingDispatcher, UnboxingSafeDispatcher, UnboxingDispatcherTrait, UnboxingSafeDispatcherTrait};
use debug::PrintTrait;

#[test]
#[available_gas(300000000)]
fn test_mint_and_unbox() {
    let DefaultWorld{world,
    briq_token,
    booklet_ducks,
    booklet_sp,
    box_nft,
    attribute_groups_addr,
    .. } =
        spawn_briq_test_world();

    create_contract_attribute_group(world, attribute_groups_addr, 0x1, booklet_sp.contract_address, Zeroable::zero());
    create_contract_attribute_group(world, attribute_groups_addr, 0x2, booklet_ducks.contract_address, Zeroable::zero());

    let box_contract_address = box_nft.contract_address;

    assert(UnboxingSafeDispatcher { contract_address: box_nft.contract_address }.unbox(0x1).is_err(), 'expect error');

    MintBurnDispatcher { contract_address: box_nft.contract_address }.mint(
        DEFAULT_OWNER(),
        0x1,
        0x4,
    );
    MintBurnDispatcher { contract_address: box_nft.contract_address }.mint(
        DEFAULT_OWNER(),
        10,
        0x1,
    );

    impersonate(DEFAULT_OWNER());

    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 0, 'bad balance');
    assert(booklet_sp.balance_of(DEFAULT_OWNER(), 0x1) == 0, 'bad balance 1');
    assert(box_nft.balance_of(DEFAULT_OWNER(), 0x1) == 4, 'bad balance 2');

    UnboxingDispatcher { contract_address: box_nft.contract_address }.unbox(0x1);

    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 434, 'bad balance 2.5');
    assert(booklet_sp.balance_of(DEFAULT_OWNER(), 0x10000000000000001) == 1, 'bad balance 3');
    assert(box_nft.balance_of(DEFAULT_OWNER(), 0x1) == 3, 'bad balance 4');

    UnboxingDispatcher { contract_address: box_nft.contract_address }.unbox(10);

    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 494, 'bad balance 5');
    assert(booklet_ducks.balance_of(DEFAULT_OWNER(), 0x20000000000000001) == 1, 'bad balance 6');
    assert(box_nft.balance_of(DEFAULT_OWNER(), 10) == 0, 'bad balance 7');

    assert(UnboxingSafeDispatcher { contract_address: box_nft.contract_address }.unbox(10).is_err(), 'expect error');
}
