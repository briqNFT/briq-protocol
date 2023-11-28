use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use presets::erc1155::erc1155::interface::IERC1155DispatcherTrait;

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
use briq_protocol::set_nft::assembly::{ISetNftAssemblyDispatcher, ISetNftAssemblyDispatcherTrait};
use briq_protocol::types::{FTSpec, ShapeItem, ShapePacking, PackedShapeItem, AttributeItem};

use briq_protocol::erc::erc1155::interface::{IERC1155MetadataDispatcher, IERC1155MetadataDispatcherTrait};
use briq_protocol::erc::erc721::interface::{IERC721MetadataDispatcher, IERC721MetadataDispatcherTrait};

use debug::PrintTrait;

use starknet::testing::set_chain_id;

use briq_protocol::uri::get_url;

#[test]
#[available_gas(300000000)]
fn test_uri_fn() {
    set_chain_id('SN_GOERLI');

    // Doesn't preserve leading zeroes
    //get_url('booklet', 00440000000001).print();
    assert(get_url('booklet', 00440000000001) == array![
        0x68747470733a2f2f6170692e746573742e736c746563682e636f6d70616e79, 0x2f76312f7572692f, 0x626f6f6b6c6574, 0x2f737461726b6e65742d746573746e65742d646f6a6f2f, 0x34, 0x34, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x31, 0x2e6a736f6e], 'bad conversion');
    //get_url('booklet', 00440000000000).print();
    assert(get_url('booklet', 00440000000000) == array![
        0x68747470733a2f2f6170692e746573742e736c746563682e636f6d70616e79, 0x2f76312f7572692f, 0x626f6f6b6c6574, 0x2f737461726b6e65742d746573746e65742d646f6a6f2f, 0x34, 0x34, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x2e6a736f6e], 'bad conversion');
    //get_url('booklet', 10044000000000).print();
    assert(get_url('booklet', 10044000000000) == array![
        0x68747470733a2f2f6170692e746573742e736c746563682e636f6d70616e79, 0x2f76312f7572692f, 0x626f6f6b6c6574, 0x2f737461726b6e65742d746573746e65742d646f6a6f2f, 0x31, 0x30, 0x30, 0x34, 0x34, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x2e6a736f6e], 'bad conversion');
    assert(get_url('booklet', 123456789) == array![
        0x68747470733a2f2f6170692e746573742e736c746563682e636f6d70616e79, 0x2f76312f7572692f, 0x626f6f6b6c6574, 0x2f737461726b6e65742d746573746e65742d646f6a6f2f, '1', '2', '3', '4', '5', '6', '7', '8', '9', '.json'], 'bad conversion');
    //get_url('booklet', 0).print();
    assert(get_url('booklet', 0) == array![
        0x68747470733a2f2f6170692e746573742e736c746563682e636f6d70616e79, 0x2f76312f7572692f, 0x626f6f6b6c6574, 0x2f737461726b6e65742d746573746e65742d646f6a6f2f, '0', '.json'], 'bad conversion');
    //get_url('booklet', 1).print();
    assert(get_url('booklet', 1) == array![
        0x68747470733a2f2f6170692e746573742e736c746563682e636f6d70616e79, 0x2f76312f7572692f, 0x626f6f6b6c6574, 0x2f737461726b6e65742d746573746e65742d646f6a6f2f, '1', '.json'], 'bad conversion');
    //get_url('booklet', 3618502788666131106986593281521497120414687020801267626233049500247285301248).print();
    assert(get_url('booklet', 3618502788666131106986593281521497120414687020801267626233049500247285301248) == array![
        0x68747470733a2f2f6170692e746573742e736c746563682e636f6d70616e79, 0x2f76312f7572692f, 0x626f6f6b6c6574, 0x2f737461726b6e65742d746573746e65742d646f6a6f2f, 0x33, 0x36, 0x31, 0x38, 0x35, 0x30, 0x32, 0x37, 0x38, 0x38, 0x36, 0x36, 0x36, 0x31, 0x33, 0x31, 0x31, 0x30, 0x36, 0x39, 0x38, 0x36, 0x35, 0x39, 0x33, 0x32, 0x38, 0x31, 0x35, 0x32, 0x31, 0x34, 0x39, 0x37, 0x31, 0x32, 0x30, 0x34, 0x31, 0x34, 0x36, 0x38, 0x37, 0x30, 0x32, 0x30, 0x38, 0x30, 0x31, 0x32, 0x36, 0x37, 0x36, 0x32, 0x36, 0x32, 0x33, 0x33, 0x30, 0x34, 0x39, 0x35, 0x30, 0x30, 0x32, 0x34, 0x37, 0x32, 0x38, 0x35, 0x33, 0x30, 0x31, 0x32, 0x34, 0x38, '.json'], 'bad conversion');
}


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
            0x2f76312f7572692f, // /v1/uri/
            'booklet', // booklet
            0x2f737461726b6e65742d746573746e65742d646f6a6f2f, // /starknet-testnet-dojo/
            0x32, // 2
            0x34, // 4
            0x35, // 5
            0x33, // 3
            0x38, // 8
            0x38, // 8
            0x32, // 2
            0x31, // 1
            0x38, // 8
            0x38, // 8
            0x36, // 6
            0x38, // 8
            0x38, // 8
            0x39, // 9
            0x30, // 0
            0x39, // 9
            0x33, // 3
            0x31, // 1
            0x39, // 9
            0x38, // 8
            0x31, // 1
            0x39, // 9
            0x37, // 7
            0x35, // 5
            0x35, // 5
            0x35, // 5
            0x33, // 3
            0x2e6a736f6e // .json
        ], 'bad uri');

    //assert(booklet_ducks_uri.uri(attribute_id.into() + attribute_group.into() * 0x10000000000000000
    //    ) == array![
    //        0x68747470733a2f2f6170692e746573742e736c746563682e636f6d70616e79, // https://api.test.sltech.company
    //        0x2f76312f626f6f6b6c65742f32343533383832313838363838393039333139, // /v1/booklet/2453882188688909319
    //        0x38313937353535332e6a736f6e // 81975553.json
    //    ], 'bad uri');//"https://api.test.sltech.company/v1/booklet/245388218868890931981975553.json", '');
}

#[test]
#[available_gas(300000000)]
fn test_uri_721() {
    let DefaultWorld{world, generic_sets, .. } = spawn_briq_test_world();

    set_chain_id('SN_GOERLI');

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

    assert(
        token_id == 0x3fa51acc2defe858e3cb515b7e29c6e3ba22da5657e7cc33885860a00000000,
        'bad token id'
    );

    let generic_sets_uri = IERC721MetadataDispatcher { contract_address: generic_sets.contract_address };

    assert(generic_sets_uri.token_uri(0x3fa51acc2defe858e3cb515b7e29c6e3ba22da5657e7cc33885860a00000000
        ) == array![
            0x68747470733a2f2f6170692e746573742e736c746563682e636f6d70616e79, // https://api.test.sltech.company
            0x2f76312f7572692f, // /v1/uri/
            'set',
            0x2f737461726b6e65742d746573746e65742d646f6a6f2f, // /starknet-testnet-dojo/
            0x31, // 1
            0x37, // 7
            0x39, // 9
            0x39, // 9
            0x32, // 2
            0x31, // 1
            0x34, // 4
            0x30, // 0
            0x31, // 1
            0x31, // 1
            0x30, // 0
            0x33, // 3
            0x31, // 1
            0x36, // 6
            0x33, // 3
            0x31, // 1
            0x31, // 1
            0x32, // 2
            0x30, // 0
            0x33, // 3
            0x32, // 2
            0x39, // 9
            0x34, // 4
            0x36, // 6
            0x31, // 1
            0x39, // 9
            0x37, // 7
            0x37, // 7
            0x34, // 4
            0x30, // 0
            0x38, // 8
            0x37, // 7
            0x30, // 0
            0x35, // 5
            0x30, // 0
            0x38, // 8
            0x38, // 8
            0x39, // 9
            0x32, // 2
            0x34, // 4
            0x30, // 0
            0x39, // 9
            0x37, // 7
            0x39, // 9
            0x39, // 9
            0x31, // 1
            0x38, // 8
            0x32, // 2
            0x34, // 4
            0x31, // 1
            0x38, // 8
            0x30, // 0
            0x30, // 0
            0x37, // 7
            0x34, // 4
            0x32, // 2
            0x37, // 7
            0x34, // 4
            0x33, // 3
            0x37, // 7
            0x32, // 2
            0x35, // 5
            0x37, // 7
            0x37, // 7
            0x33, // 3
            0x30, // 0
            0x39, // 9
            0x35, // 5
            0x31, // 1
            0x30, // 0
            0x30, // 0
            0x37, // 7
            0x34, // 4
            0x33, // 3
            0x36, // 6
            0x38, // 8
            0x2e6a736f6e // .json
        ], 'bad uri');
}

