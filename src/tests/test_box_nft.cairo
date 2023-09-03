use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;
use starknet::ContractAddress;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use dojo_erc::erc721::interface::IERC721DispatcherTrait;
use dojo_erc::erc1155::interface::IERC1155DispatcherTrait;

use briq_protocol::world_config::get_world_config;
use briq_protocol::attributes::shape_verifier::RegisterShapeVerifierData;
use briq_protocol::types::{FTSpec, ShapeItem};
use briq_protocol::tests::test_utils::{
    WORLD_ADMIN, DEFAULT_OWNER, DefaultWorld, deploy_default_world, mint_briqs, impersonate
};

use debug::PrintTrait;



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
                DEFAULT_OWNER().into(),
                1,
                0x1,
                1,
                1
            ])
        );

    impersonate(DEFAULT_OWNER());

    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 0, 'bad balance');
    assert(
        booklet
            .balance_of(DEFAULT_OWNER(), 0x1000000000000000000000000000000000000000000000001) == 0,
        'bad balance 1'
    );
    assert(box_nft.balance_of(DEFAULT_OWNER(), 1) == 1, 'bad balance 2');

    world.execute('box_unboxing', (array![0x1,]));

    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 434, 'bad balance 2.5');
    assert(
        booklet
            .balance_of(DEFAULT_OWNER(), 0x1000000000000000000000000000000000000000000000001) == 1,
        'bad balance 3'
    );
    assert(box_nft.balance_of(DEFAULT_OWNER(), 1) == 0, 'bad balance 4');
}
