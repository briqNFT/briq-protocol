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
use dojo_erc::erc_common::utils::{system_calldata};
use briq_protocol::utils::IntoContractAddressU256;

use debug::PrintTrait;


mod convenience_for_testing {
    use array::ArrayTrait;
    use serde::Serde;
    use traits::{Into, TryInto};
    use option::{OptionTrait};
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use starknet::{ContractAddress, ClassHash, get_contract_address};
    use briq_protocol::types::{FTSpec, ShapeItem, ShapePacking, PackedShapeItem};
    use briq_protocol::set_nft::systems::{AssemblySystemData, DisassemblySystemData, get_token_id};
    use dojo_erc::erc_common::utils::{system_calldata};
    use briq_protocol::shape_verifier::RegisterShapeVerifierData;
    use briq_protocol::attributes::attribute_group::{CreateAttributeGroupData, AttributeGroupOwner};


    fn assemble(
        world: IWorldDispatcher,
        owner: ContractAddress,
        token_id_hint: felt252,
        name: Array<felt252>, // TODO string
        description: Array<felt252>, // TODO string
        fts: Array<FTSpec>,
        shape: Array<PackedShapeItem>,
        attributes: Array<felt252>,
    ) -> ContractAddress {
        // The name/description is unused except to have them show up in calldata.
        let nb_briq = shape.len();

        world
            .execute(
                'set_nft_assembly',
                system_calldata(
                    AssemblySystemData {
                        caller: get_contract_address(), owner, token_id_hint, fts, shape, attributes
                    }
                )
            );

        let token_id = get_token_id(owner, token_id_hint, nb_briq);
        token_id
    }

    fn disassemble(
        world: IWorldDispatcher,
        owner: ContractAddress,
        token_id: ContractAddress,
        fts: Array<FTSpec>,
        attributes: Array<felt252>
    ) {
        world
            .execute(
                'set_nft_disassembly',
                system_calldata(
                    DisassemblySystemData {
                        caller: get_contract_address(), owner, token_id, fts, attributes
                    }
                )
            );
    }


    fn register_shape_verifier(
        world: IWorldDispatcher, attribute_id: felt252, class_hash: ClassHash
    ) {
        world
            .execute(
                'register_shape_verifier',
                system_calldata(RegisterShapeVerifierData { attribute_id: 0x1, class_hash })
            );
    }

    fn register_shape_verifier_shape_1(world: IWorldDispatcher) {
        register_shape_verifier(
            world,
            0x1,
            briq_protocol::tests::shapes::test_shape_1::TEST_CLASS_HASH.try_into().unwrap()
        )
    }

    fn valid_shape_1() -> Array<PackedShapeItem> {
        array![
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ]
    }


    fn create_attribute_group_1(
        world: IWorldDispatcher, briq_set_contract_address: ContractAddress
    ) {
        world
            .execute(
                'create_attribute_group',
                system_calldata(
                    CreateAttributeGroupData {
                        attribute_group_id: 1,
                        owner: AttributeGroupOwner::System('shape_verifier_system'),
                        briq_set_contract_address: briq_set_contract_address
                    }
                )
            );
    }
}
use convenience_for_testing::{
    assemble, disassemble, register_shape_verifier_shape_1, valid_shape_1, create_attribute_group_1
};

#[test]
#[available_gas(30000000)]
#[should_panic]
fn test_empty_mint() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

    impersonate(DEFAULT_OWNER());

    let token_id = assemble(
        world,
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![],
        array![],
        array![],
    );
}

#[test]
#[available_gas(3000000000)]
fn test_simple_mint_and_burn() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

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

    assert(
        token_id == starknet::contract_address_const::<0x3fa51acc2defe858e3cb515b7e29c6e3ba22da5657e7cc33885860a6470bfc2>(),
        'bad token id'
    );

    assert(DEFAULT_OWNER() == set_nft.owner_of(token_id.into()), 'bad owner');
    assert(set_nft.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(briq_token.balance_of(token_id, 1) == 1, 'bad balance');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 99, 'bad balance');

    disassemble(
        world, DEFAULT_OWNER(), token_id.into(), array![FTSpec { token_id: 1, qty: 1 }], array![]
    );
    assert(set_nft.balance_of(DEFAULT_OWNER()) == 0, 'bad balance');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 100, 'bad balance');
// TODO: validate that token ID balance asserts as it's 0
}

#[test]
#[available_gas(3000000000)]
#[should_panic]
fn test_simple_mint_and_burn_not_enough_briqs() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

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
}

#[test]
#[available_gas(3000000000)]
fn test_simple_mint_and_burn_2() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    impersonate(DEFAULT_OWNER());

    let token_id = assemble(
        world,
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![],
    );

    assert(
        token_id == starknet::contract_address_const::<0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057aee0d6eda3>(),
        'bad token id'
    );

    assert(DEFAULT_OWNER() == set_nft.owner_of(token_id.into()), 'bad owner');
    assert(set_nft.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(briq_token.balance_of(token_id, 1) == 4, 'bad token balance 1');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 96, 'bad briq balance 1');

    disassemble(
        world, DEFAULT_OWNER(), token_id.into(), array![FTSpec { token_id: 1, qty: 4 }], array![]
    );
    assert(set_nft.balance_of(DEFAULT_OWNER()) == 0, 'bad balance');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 100, 'bad briq balance 2');
// TODO: validate that token ID balance asserts as it's 0
}

#[test]
#[available_gas(3000000000)]
#[should_panic(
    expected: ('Set still has briqs', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED')
)]
fn test_simple_mint_and_burn_not_enough_briqs_in_disassembly() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

    impersonate(DEFAULT_OWNER());

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    let token_id = assemble(
        world,
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![],
    );

    assert(
        token_id == starknet::contract_address_const::<0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057aee0d6eda3>(),
        'bad token id'
    );
    assert(DEFAULT_OWNER() == set_nft.owner_of(token_id.into()), 'bad owner');
    assert(set_nft.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(briq_token.balance_of(token_id, 1) == 4, 'bad token balance 1');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 96, 'bad briq balance 1');

    disassemble(
        world, DEFAULT_OWNER(), token_id.into(), array![FTSpec { token_id: 1, qty: 1 }], array![]
    );
}


#[test]
#[available_gas(30000000)]
#[should_panic]
fn test_simple_mint_attribute_not_exist() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

    impersonate(DEFAULT_OWNER());

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    let token_id = assemble(
        world,
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![0x1],
    );
}

#[test]
#[available_gas(3000000000)]
fn test_simple_mint_attribute_ok() {
    let DefaultWorld{world, briq_token, set_nft, booklet, .. } = deploy_default_world();

    create_attribute_group_1(world, set_nft.contract_address);

    register_shape_verifier_shape_1(world);

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

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    impersonate(DEFAULT_OWNER());

    let token_id = assemble(
        world,
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![0x1],
    );
    assert(
        token_id == starknet::contract_address_const::<0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057aee0d6eda3>(),
        'bad token id'
    );
    assert(DEFAULT_OWNER() == set_nft.owner_of(token_id.into()), 'bad owner');
    assert(set_nft.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(booklet.balance_of(token_id, 0x1) == 1, 'bad booklet balance 2');
    // TODO validate booklet balance of owner to 0

    disassemble(
        world, DEFAULT_OWNER(), token_id, array![FTSpec { token_id: 1, qty: 4 }], array![0x1]
    );
    assert(booklet.balance_of(DEFAULT_OWNER(), 0x1) == 1, 'bad booklet balance 3');
// TODO: validate that token ID balance asserts as it's 0
}

#[test]
#[available_gas(3000000000)]
#[should_panic(
    expected: (
        'u128_sub Overflow',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED'
    )
)]
fn test_simple_mint_attribute_dont_have_the_booklet() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

    create_attribute_group_1(world, set_nft.contract_address);

    register_shape_verifier_shape_1(world);

    impersonate(DEFAULT_OWNER());

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    let token_id = assemble(
        world,
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![0x1],
    );
    assert(
        token_id == starknet::contract_address_const::<0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057aee0d6eda3>(),
        'bad token id'
    );
    assert(DEFAULT_OWNER() == set_nft.owner_of(token_id.into()), 'bad owner');
    assert(set_nft.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');

    disassemble(
        world, DEFAULT_OWNER(), token_id, array![FTSpec { token_id: 1, qty: 4 }], array![0x1]
    );
    assert(
        starknet::contract_address_const::<0>() == set_nft.owner_of(token_id.into()), 'bad owner'
    );
    assert(set_nft.balance_of(DEFAULT_OWNER()) == 0, 'bad balance');
}

#[test]
#[available_gas(3000000000)]
#[should_panic(
    expected: (
        'bad shape item',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED'
    )
)]
fn test_simple_mint_attribute_bad_shape_item() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

    create_attribute_group_1(world, set_nft.contract_address);

    register_shape_verifier_shape_1(world);

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    impersonate(DEFAULT_OWNER());

    let token_id = assemble(
        world,
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        array![
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: -100, y: 4, z: -2 }),
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ],
        array![0x1],
    );
}

#[test]
#[available_gas(3000000000)]
#[should_panic(
    expected: (
        'bad shape length',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED'
    )
)]
fn test_simple_mint_attribute_shape_fts_mismatch() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

    create_attribute_group_1(world, set_nft.contract_address);

    register_shape_verifier_shape_1(world);

    impersonate(DEFAULT_OWNER());

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    let token_id = assemble(
        world,
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        array![
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 1, y: 4, z: -2 }),
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
        ],
        array![0x1],
    );
}

#[test]
#[available_gas(3000000000)]
#[should_panic]
fn test_simple_mint_attribute_forgot_in_disassembly() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

    create_attribute_group_1(world, set_nft.contract_address);

    register_shape_verifier_shape_1(world);

    impersonate(DEFAULT_OWNER());

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    let token_id = assemble(
        world,
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![0x1],
    );
    assert(
        token_id == starknet::contract_address_const::<0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057aee0d6eda3>(),
        'bad token id'
    );
    assert(DEFAULT_OWNER() == set_nft.owner_of(token_id.into()), 'bad owner');
    assert(set_nft.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');

    disassemble(world, DEFAULT_OWNER(), token_id, array![FTSpec { token_id: 1, qty: 4 }], array![]);
}

