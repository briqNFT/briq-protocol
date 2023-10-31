use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use dojo_erc::token::erc1155::interface::IERC1155DispatcherTrait;

use briq_protocol::tests::test_utils::{
    WORLD_ADMIN, DEFAULT_OWNER, DefaultWorld, spawn_briq_test_world, mint_briqs, impersonate
};

use briq_protocol::tests::test_set_nft::convenience_for_testing::{
    create_contract_attribute_group,
    get_test_shapes_class_hash,
    register_shape_validator_shapes,
    valid_shape_1,
    mint_booklet,
    as_set,
    as_set_safe,
};

use briq_protocol::erc::erc1155::interface::{IERC1155MetadataDispatcher, IERC1155MetadataDispatcherTrait};

use debug::PrintTrait;

use starknet::testing::set_chain_id;

#[test]
#[available_gas(300000000)]
fn test_uri_booklet() {
    let DefaultWorld{world, booklet_ducks, .. } = spawn_briq_test_world();

    let attribute_group = 0xcafafa;
    let attribute_id: u64 = 0x1;

    set_chain_id('SN_GOERLI');

    mint_booklet(
        booklet_ducks.contract_address,
        to: DEFAULT_OWNER(),
        id: attribute_id.into() + attribute_group.into() * 0x10000000000000000,
        amount: 3
    );

    let booklet_ducks_uri = IERC1155MetadataDispatcher { contract_address: booklet_ducks.contract_address };

    assert(booklet_ducks_uri.uri(attribute_id.into() + attribute_group.into() * 0x10000000000000000
        ) == array![
            0x68747470733a2f2f6170692e746573742e736c746563682e636f6d70616e79, // https://api.test.sltech.company
            0x2f76312f626f6f6b6c65742f32343533383832313838363838393039333139, // /v1/booklet/2453882188688909319
            0x38313937353535332e6a736f6e // 81975553.json
        ], 'bad uri');//"https://api.test.sltech.company/v1/booklet/245388218868890931981975553.json", '');
}
