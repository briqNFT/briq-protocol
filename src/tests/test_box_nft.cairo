use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;

use starknet::testing::{set_caller_address, set_contract_address};
use starknet::ContractAddress;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use briq_protocol::world_config::{WorldConfig, SYSTEM_CONFIG_ID};
use briq_protocol::tests::test_utils::{WORLD_ADMIN, DefaultWorld, deploy_default_world, mint_briqs};

use dojo_erc::erc721::interface::IERC721DispatcherTrait;
use dojo_erc::erc1155::interface::IERC1155DispatcherTrait;

use briq_protocol::attributes::collection::CreateCollectionData;
use briq_protocol::check_shape::RegisterShapeVerifierData;
use briq_protocol::types::{FTSpec, ShapeItem};

use debug::PrintTrait;

use briq_protocol::world_config::get_world_config;

fn default_owner() -> ContractAddress {
    starknet::contract_address_const::<0xcafe>()
}

#[test]
#[available_gas(300000000)]
fn test_mint_and_unbox() {
    let DefaultWorld{world, briq_token, booklet, box_nft, .. } = deploy_default_world();

    world
        .execute(
            'ERC1155MintBurn',
            (array![
                WORLD_ADMIN().into(),
                get_world_config(world).box.into(),
                0,
                default_owner().into(),
                1,
                0x1,
                1,
                1
            ])
        );

    set_contract_address(default_owner());

    assert(briq_token.balance_of(default_owner(), 1) == 0, 'bad balance');
    assert(
        booklet
            .balance_of(default_owner(), 0x1000000000000000000000000000000000000000000000001) == 0,
        'bad balance 1'
    );
    assert(box_nft.balance_of(default_owner(), 1) == 1, 'bad balance 2');

    world.execute('box_unboxing', (array![0x1, ]));

    assert(briq_token.balance_of(default_owner(), 1) == 434, 'bad balance 2.5');
    assert(
        booklet
            .balance_of(default_owner(), 0x1000000000000000000000000000000000000000000000001) == 1,
        'bad balance 3'
    );
    assert(box_nft.balance_of(default_owner(), 1) == 0, 'bad balance 4');
}
