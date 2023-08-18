use briq_protocol::set_nft::ISetNftDispatcherTrait;
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
use briq_protocol::set_nft::ISetNftDispatcher;

use briq_protocol::attributes::collection::CreateCollectionData;
use briq_protocol::check_shape::RegisterShapeVerifierData;
use briq_protocol::types::{FTSpec, ShapeItem};

use debug::PrintTrait;

fn default_owner() -> ContractAddress {
    starknet::contract_address_const::<0xcafe>()
}

#[test]
#[available_gas(30000000)]
#[should_panic]
fn test_empty_mint() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

    let set_assembler = ISetNftDispatcher { contract_address: set_nft.contract_address };

    set_contract_address(default_owner());

    let token_id = set_assembler
        .assemble_(
            default_owner(), 0xfade, array![0xcafe], array![0xfade], array![], array![], array![], 
        );
    assert(
        token_id == 0x1a61b367b44cb5cdc969ad212931f85c0dc5d31227cc1bdb8bf65238a722a6a,
        'bad token id'
    );
    assert(default_owner() == set_nft.owner_of(token_id.into()), 'bad owner');
}

#[test]
#[available_gas(3000000000)]
fn test_simple_mint_and_burn() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

    let set_assembler = ISetNftDispatcher { contract_address: set_nft.contract_address };

    set_contract_address(default_owner());

    mint_briqs(world, default_owner(), 1, 100);

    let token_id = set_assembler
        .assemble_(
            default_owner(),
            0xfade,
            array![0xcafe],
            array![0xfade],
            array![FTSpec { token_id: 1, qty: 1 }],
            array![ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }],
            array![],
        );
    assert(
        token_id == 0x3fa51acc2defe858e3cb515b7e29c6e3ba22da5657e7cc33885860a6470bfc2,
        'bad token id'
    );
    assert(default_owner() == set_nft.owner_of(token_id.into()), 'bad owner');
    assert(set_nft.balance_of(default_owner()) == 1, 'bad balance');
    assert(briq_token.balance_of(token_id.try_into().unwrap(), 1) == 1, 'bad balance');
    assert(briq_token.balance_of(default_owner(), 1) == 99, 'bad balance');

    set_assembler
        .disassemble_(default_owner(), token_id, array![FTSpec { token_id: 1, qty: 1 }], array![]);
    assert(
        starknet::contract_address_const::<0>() == set_nft.owner_of(token_id.into()), 'bad owner'
    );
    assert(set_nft.balance_of(default_owner()) == 0, 'bad balance');
    assert(briq_token.balance_of(token_id.try_into().unwrap(), 1) == 0, 'bad balance');
    assert(briq_token.balance_of(default_owner(), 1) == 100, 'bad balance');
}

#[test]
#[available_gas(3000000000)]
#[should_panic]
fn test_simple_mint_and_burn_not_enough_briqs() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

    let set_assembler = ISetNftDispatcher { contract_address: set_nft.contract_address };

    set_contract_address(default_owner());

    let token_id = set_assembler
        .assemble_(
            default_owner(),
            0xfade,
            array![0xcafe],
            array![0xfade],
            array![FTSpec { token_id: 1, qty: 1 }],
            array![ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }],
            array![],
        );
}

#[test]
#[available_gas(3000000000)]
fn test_simple_mint_and_burn_2() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

    let set_assembler = ISetNftDispatcher { contract_address: set_nft.contract_address };

    set_contract_address(default_owner());

    mint_briqs(world, default_owner(), 1, 100);

    let token_id = set_assembler
        .assemble_(
            default_owner(),
            0xfade,
            array![0xcafe],
            array![0xfade],
            array![FTSpec { token_id: 1, qty: 4 }],
            array![
                ShapeItem {
                    color: '#ffaaff', material: 1, x: 2, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 2, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 2, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 2, y: 4, z: -2
                },
            ],
            array![],
        );
    assert(
        token_id == 0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057aee0d6eda3,
        'bad token id'
    );
    assert(default_owner() == set_nft.owner_of(token_id.into()), 'bad owner');
    assert(set_nft.balance_of(default_owner()) == 1, 'bad balance');
    assert(briq_token.balance_of(token_id.try_into().unwrap(), 1) == 4, 'bad token balance 1');
    assert(briq_token.balance_of(default_owner(), 1) == 96, 'bad briq balance 1');

    set_assembler
        .disassemble_(default_owner(), token_id, array![FTSpec { token_id: 1, qty: 4 }], array![]);
    assert(
        starknet::contract_address_const::<0>() == set_nft.owner_of(token_id.into()), 'bad owner'
    );
    assert(set_nft.balance_of(default_owner()) == 0, 'bad balance');
    assert(briq_token.balance_of(token_id.try_into().unwrap(), 1) == 0, 'bad token balance 2');
    assert(briq_token.balance_of(default_owner(), 1) == 100, 'bad briq balance 2');
}

#[test]
#[available_gas(3000000000)]
#[should_panic(
    expected: (
        'Set still has briqs',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED'
    )
)]
fn test_simple_mint_and_burn_not_enough_briqs_in_disassembly() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

    let set_assembler = ISetNftDispatcher { contract_address: set_nft.contract_address };

    set_contract_address(default_owner());

    mint_briqs(world, default_owner(), 1, 100);

    let token_id = set_assembler
        .assemble_(
            default_owner(),
            0xfade,
            array![0xcafe],
            array![0xfade],
            array![FTSpec { token_id: 1, qty: 4 }],
            array![
                ShapeItem {
                    color: '#ffaaff', material: 1, x: 2, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 2, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 2, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 2, y: 4, z: -2
                },
            ],
            array![],
        );
    assert(
        token_id == 0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057aee0d6eda3,
        'bad token id'
    );
    assert(default_owner() == set_nft.owner_of(token_id.into()), 'bad owner');
    assert(set_nft.balance_of(default_owner()) == 1, 'bad balance');
    assert(briq_token.balance_of(token_id.try_into().unwrap(), 1) == 4, 'bad token balance 1');
    assert(briq_token.balance_of(default_owner(), 1) == 96, 'bad briq balance 1');

    set_assembler
        .disassemble_(default_owner(), token_id, array![FTSpec { token_id: 1, qty: 1 }], array![]);
    assert(
        starknet::contract_address_const::<0>() == set_nft.owner_of(token_id.into()), 'bad owner'
    );
    assert(set_nft.balance_of(default_owner()) == 0, 'bad balance');
    assert(briq_token.balance_of(token_id.try_into().unwrap(), 1) == 0, 'bad token balance 2');
    assert(briq_token.balance_of(default_owner(), 1) == 100, 'bad briq balance 2');
}


#[test]
#[available_gas(30000000)]
#[should_panic]
fn test_simple_mint_attribute_not_exist() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

    let set_assembler = ISetNftDispatcher { contract_address: set_nft.contract_address };

    set_contract_address(default_owner());

    mint_briqs(world, default_owner(), 1, 100);

    let token_id = set_assembler
        .assemble_(
            default_owner(),
            0xfade,
            array![0xcafe],
            array![0xfade],
            array![FTSpec { token_id: 1, qty: 4 }],
            array![
                ShapeItem {
                    color: '#ffaaff', material: 1, x: 2, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 2, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 2, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 2, y: 4, z: -2
                },
            ],
            array![0x1],
        );
}


#[test]
#[available_gas(3000000000)]
fn test_simple_mint_attribute_ok() {
    let DefaultWorld{world, briq_token, set_nft, booklet, .. } = deploy_default_world();

    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        CreateCollectionData {
            collection_id: 1, params: 2, admin_or_system: 'check_shape_booklet'.try_into().unwrap()
        }.serialize(ref calldata);
        world.execute('create_collection', (calldata));
    }

    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        RegisterShapeVerifierData {
            attribute_id: 0x1,
            class_hash: briq_protocol::tests::shapes::test_shape_1::TEST_CLASS_HASH
                .try_into()
                .unwrap()
        }.serialize(ref calldata);
        world.execute('register_shape_verifier', (calldata));
    }

    let set_assembler = ISetNftDispatcher { contract_address: set_nft.contract_address };

    world
        .execute(
            'ERC1155MintBurn',
            (array![
                WORLD_ADMIN().into(),
                get!(world, (SYSTEM_CONFIG_ID), WorldConfig).booklet.into(),
                0,
                default_owner().into(),
                1,
                0x1,
                1,
                1
            ])
        );

    set_contract_address(default_owner());

    mint_briqs(world, default_owner(), 1, 100);

    let token_id = set_assembler
        .assemble_(
            default_owner(),
            0xfade,
            array![0xcafe],
            array![0xfade],
            array![FTSpec { token_id: 1, qty: 4 }],
            array![
                ShapeItem {
                    color: '#ffaaff', material: 1, x: 1, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 2, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 3, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 4, y: 4, z: -2
                },
            ],
            array![0x1],
        );
    assert(
        token_id == 0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057aee0d6eda3,
        'bad token id'
    );
    assert(default_owner() == set_nft.owner_of(token_id.into()), 'bad owner');
    assert(set_nft.balance_of(default_owner()) == 1, 'bad balance');
    assert(booklet.balance_of(default_owner(), 0x1) == 0, 'bad booklet balance 1');
    assert(booklet.balance_of(token_id.try_into().unwrap(), 0x1) == 1, 'bad booklet balance 2');

    set_assembler
        .disassemble_(
            default_owner(), token_id, array![FTSpec { token_id: 1, qty: 4 }], array![0x1]
        );
    assert(
        starknet::contract_address_const::<0>() == set_nft.owner_of(token_id.into()), 'bad owner'
    );
    assert(set_nft.balance_of(default_owner()) == 0, 'bad balance');
    assert(booklet.balance_of(default_owner(), 0x1) == 1, 'bad booklet balance 3');
    assert(booklet.balance_of(token_id.try_into().unwrap(), 0x1) == 0, 'bad booklet balance 4');
}

#[test]
#[available_gas(3000000000)]
#[should_panic(
    expected: (
        'u128_sub Overflow',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED'
    )
)]
fn test_simple_mint_attribute_dont_have_the_booklet() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        CreateCollectionData {
            collection_id: 1, params: 2, admin_or_system: 'check_shape_booklet'.try_into().unwrap()
        }.serialize(ref calldata);
        world.execute('create_collection', (calldata));
    }

    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        RegisterShapeVerifierData {
            attribute_id: 0x1,
            class_hash: briq_protocol::tests::shapes::test_shape_1::TEST_CLASS_HASH
                .try_into()
                .unwrap()
        }.serialize(ref calldata);
        world.execute('register_shape_verifier', (calldata));
    }

    let set_assembler = ISetNftDispatcher { contract_address: set_nft.contract_address };

    set_contract_address(default_owner());

    mint_briqs(world, default_owner(), 1, 100);

    let token_id = set_assembler
        .assemble_(
            default_owner(),
            0xfade,
            array![0xcafe],
            array![0xfade],
            array![FTSpec { token_id: 1, qty: 4 }],
            array![
                ShapeItem {
                    color: '#ffaaff', material: 1, x: 1, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 2, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 3, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 4, y: 4, z: -2
                },
            ],
            array![0x1],
        );
    assert(
        token_id == 0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057aee0d6eda3,
        'bad token id'
    );
    assert(default_owner() == set_nft.owner_of(token_id.into()), 'bad owner');
    assert(set_nft.balance_of(default_owner()) == 1, 'bad balance');

    set_assembler
        .disassemble_(
            default_owner(), token_id, array![FTSpec { token_id: 1, qty: 4 }], array![0x1]
        );
    assert(
        starknet::contract_address_const::<0>() == set_nft.owner_of(token_id.into()), 'bad owner'
    );
    assert(set_nft.balance_of(default_owner()) == 0, 'bad balance');
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
        'ENTRYPOINT_FAILED'
    )
)]
fn test_simple_mint_attribute_bad_shape_item() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        CreateCollectionData {
            collection_id: 1, params: 2, admin_or_system: 'check_shape_booklet'.try_into().unwrap()
        }.serialize(ref calldata);
        world.execute('create_collection', (calldata));
    }

    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        RegisterShapeVerifierData {
            attribute_id: 0x1,
            class_hash: briq_protocol::tests::shapes::test_shape_1::TEST_CLASS_HASH
                .try_into()
                .unwrap()
        }.serialize(ref calldata);
        world.execute('register_shape_verifier', (calldata));
    }

    let set_assembler = ISetNftDispatcher { contract_address: set_nft.contract_address };

    set_contract_address(default_owner());

    mint_briqs(world, default_owner(), 1, 100);

    let token_id = set_assembler
        .assemble_(
            default_owner(),
            0xfade,
            array![0xcafe],
            array![0xfade],
            array![FTSpec { token_id: 1, qty: 4 }],
            array![
                ShapeItem {
                    color: '#ffaaff', material: 1, x: 1, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 2, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 0, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 4, y: 4, z: -2
                },
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
        'ENTRYPOINT_FAILED'
    )
)]
fn test_simple_mint_attribute_shape_fts_mismatch() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        CreateCollectionData {
            collection_id: 1, params: 2, admin_or_system: 'check_shape_booklet'.try_into().unwrap()
        }.serialize(ref calldata);
        world.execute('create_collection', (calldata));
    }

    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        RegisterShapeVerifierData {
            attribute_id: 0x1,
            class_hash: briq_protocol::tests::shapes::test_shape_1::TEST_CLASS_HASH
                .try_into()
                .unwrap()
        }.serialize(ref calldata);
        world.execute('register_shape_verifier', (calldata));
    }

    let set_assembler = ISetNftDispatcher { contract_address: set_nft.contract_address };

    set_contract_address(default_owner());

    mint_briqs(world, default_owner(), 1, 100);

    let token_id = set_assembler
        .assemble_(
            default_owner(),
            0xfade,
            array![0xcafe],
            array![0xfade],
            array![FTSpec { token_id: 1, qty: 4 }],
            array![
                ShapeItem {
                    color: '#ffaaff', material: 1, x: 1, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 4, y: 4, z: -2
                },
            ],
            array![0x1],
        );
}


#[test]
#[available_gas(3000000000)]
#[should_panic]
fn test_simple_mint_attribute_forgot_in_disassembly() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();

    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        CreateCollectionData {
            collection_id: 1, params: 2, admin_or_system: 'check_shape_booklet'.try_into().unwrap()
        }.serialize(ref calldata);
        world.execute('create_collection', (calldata));
    }

    {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        RegisterShapeVerifierData {
            attribute_id: 0x1,
            class_hash: briq_protocol::tests::shapes::test_shape_1::TEST_CLASS_HASH
                .try_into()
                .unwrap()
        }.serialize(ref calldata);
        world.execute('register_shape_verifier', (calldata));
    }

    let set_assembler = ISetNftDispatcher { contract_address: set_nft.contract_address };

    set_contract_address(default_owner());

    mint_briqs(world, default_owner(), 1, 100);

    let token_id = set_assembler
        .assemble_(
            default_owner(),
            0xfade,
            array![0xcafe],
            array![0xfade],
            array![FTSpec { token_id: 1, qty: 4 }],
            array![
                ShapeItem {
                    color: '#ffaaff', material: 1, x: 1, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 2, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 3, y: 4, z: -2
                    }, ShapeItem {
                    color: '#ffaaff', material: 1, x: 4, y: 4, z: -2
                },
            ],
            array![0x1],
        );
    assert(
        token_id == 0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057aee0d6eda3,
        'bad token id'
    );
    assert(default_owner() == set_nft.owner_of(token_id.into()), 'bad owner');
    assert(set_nft.balance_of(default_owner()) == 1, 'bad balance');

    set_assembler
        .disassemble_(default_owner(), token_id, array![FTSpec { token_id: 1, qty: 4 }], array![]);
}
