use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;

use starknet::testing::{set_caller_address, set_contract_address};
use starknet::ContractAddress;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use briq_protocol::tests::test_utils::{
    WORLD_ADMIN, DEFAULT_OWNER, DefaultWorld, deploy_default_world, mint_briqs, impersonate
};

use dojo_erc::erc721::interface::IERC721DispatcherTrait;
use dojo_erc::erc1155::interface::IERC1155DispatcherTrait;

use briq_protocol::attributes::attribute_group::{CreateAttributeGroupData, AttributeGroupOwner};
use briq_protocol::shape_verifier::RegisterShapeVerifierData;
use briq_protocol::types::{FTSpec, ShapeItem, ShapePacking, PackedShapeItem};
use briq_protocol::world_config::get_world_config;

use debug::PrintTrait;

use briq_protocol::tests::test_set_nft::convenience_for_testing::{assemble, disassemble};


//   fn assemble(
//         world: IWorldDispatcher,
//         owner: ContractAddress,
//         token_id_hint: felt252,
//         name: Array<felt252>, // TODO string
//         description: Array<felt252>, // TODO string
//         fts: Array<FTSpec>,
//         shape: Array<PackedShapeItem>,
//         attributes: Array<felt252>
//     ) -> felt252 {

#[test]
#[available_gas(3000000000)]
fn test_simple_double_briq_set() {
    let DefaultWorld{world, briq_token, set_nft, set2_nft, .. } = deploy_default_world();

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    impersonate(DEFAULT_OWNER());

    // assemble set_nft without attribute 

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
        token_id == 0x3fa51acc2defe858e3cb515b7e29c6e3ba22da5657e7cc33885860a6470bfc2,
        'bad token id'
    );

    /////////////////////////////////////////

    // create attribute_group : id 1, set_nft2
    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        CreateAttributeGroupData {
            attribute_group_id: 1,
            owner: AttributeGroupOwner::System('shape_verifier_system'),
            briq_set_contract_address: set2_nft.contract_address
        }
            .serialize(ref calldata);
        world.execute('create_attribute_group', (calldata));
    }

    // register shape verifier
    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        RegisterShapeVerifierData {
            attribute_id: 0x1,
            class_hash: briq_protocol::tests::shapes::test_shape_1::TEST_CLASS_HASH
                .try_into()
                .unwrap()
        }
            .serialize(ref calldata);
        world.execute('register_shape_verifier', (calldata));
    }

    // create booklet
    world
        .execute(
            'ERC1155MintBurn',
            (array![
                WORLD_ADMIN().into(),
                get_world_config(world).booklet.into(),
                0,
                DEFAULT_OWNER().into(),
                1,
                0x1,
                1,
                1
            ])
        );

    // assemble set_nft with attribute --> set2_nft
    let token_id = assemble(
        world,
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        array![
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ],
        array![0x1],
    );
    assert(
        token_id == 0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057aee0d6eda3,
        'bad token id'
    );
// assert(DEFAULT_OWNER() == set_nft.owner_of(token_id.into()), 'bad owner');
// assert(set_nft.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
// assert(briq_token.balance_of(token_id.try_into().unwrap(), 1) == 1, 'bad balance');
// assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 99, 'bad balance');

// disassemble(world, DEFAULT_OWNER(), token_id, array![FTSpec { token_id: 1, qty: 1 }], array![]);
// assert(set_nft.balance_of(DEFAULT_OWNER()) == 0, 'bad balance');
// assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 100, 'bad balance');

}
