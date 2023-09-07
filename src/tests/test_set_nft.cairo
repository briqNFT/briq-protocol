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

mod convenience_for_testing {
    use array::ArrayTrait;
    use serde::Serde;
    use traits::{Into, TryInto};
    use option::{OptionTrait};
    use box::{BoxTrait};
    use starknet::{ContractAddress, ClassHash, get_contract_address};

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use dojo_erc::erc_common::utils::{system_calldata};
    use briq_protocol::erc1155::mint_burn::ERC1155MintBurnParams;

    use briq_protocol::world_config::get_world_config;
    use briq_protocol::types::{FTSpec, ShapeItem, ShapePacking, PackedShapeItem, AttributeItem};
    use briq_protocol::set_nft::systems::{AssemblySystemData, DisassemblySystemData, get_token_id};
    use briq_protocol::attributes::group_systems::booklet::RegisterShapeValidatorParams;
    use briq_protocol::attributes::attribute_group::{
        CreateAttributeGroupParams, AttributeGroupOwner
    };
    use briq_protocol::tests::test_utils::{WORLD_ADMIN, ZERO};

    fn assemble(
        world: IWorldDispatcher,
        owner: ContractAddress,
        token_id_hint: felt252,
        name: Array<felt252>, // TODO string
        description: Array<felt252>, // TODO string
        fts: Array<FTSpec>,
        shape: Array<PackedShapeItem>,
        attributes: Array<AttributeItem>,
    ) -> ContractAddress {
        // The name/description is unused except to have them show up in calldata.
        let nb_briq = shape.len();

        let caller = starknet::get_tx_info().unbox().account_contract_address;
        world
            .execute(
                'set_nft_assembly',
                system_calldata(
                    AssemblySystemData { caller, owner, token_id_hint, fts, shape, attributes }
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
        attributes: Array<AttributeItem>
    ) {
        let caller = starknet::get_tx_info().unbox().account_contract_address;
        world
            .execute(
                'set_nft_disassembly',
                system_calldata(DisassemblySystemData { caller, owner, token_id, fts, attributes })
            );
    }


    //
    // Attribute Group
    //

    fn create_attribute_group_with_booklet(
        world: IWorldDispatcher,
        attribute_group_id: u64,
        target_set_contract_address: ContractAddress,
        booklet_contract_address: ContractAddress
    ) {
        world
            .execute(
                'create_attribute_group',
                system_calldata(
                    CreateAttributeGroupParams {
                        attribute_group_id,
                        owner: AttributeGroupOwner::System('agm_booklet'),
                        target_set_contract_address,
                        booklet_contract_address
                    }
                )
            );
    }


    fn create_attribute_group_with_briq_counter(world: IWorldDispatcher, attribute_group_id: u64) {
        // briq_counter is not related to a specific collection so we link it to generic_sets
        let target_set_contract_address = get_world_config(world).generic_sets;
        let booklet_contract_address = ZERO();
        world
            .execute(
                'create_attribute_group',
                system_calldata(
                    CreateAttributeGroupParams {
                        attribute_group_id,
                        owner: AttributeGroupOwner::System('agm_briq_counter'),
                        target_set_contract_address,
                        booklet_contract_address
                    }
                )
            );
    }

    //
    // Shapes ClassHash
    //

    fn get_test_shapes_class_hash() -> ClassHash {
        briq_protocol::tests::shapes::test_shapes::TEST_CLASS_HASH.try_into().unwrap()
    }

    //
    // Shape Validator
    //

    fn register_shape_validator(
        world: IWorldDispatcher, attribute_group_id: u64, attribute_id: u64, class_hash: ClassHash
    ) {
        world
            .execute(
                'RegisterShapeValidator',
                system_calldata(
                    RegisterShapeValidatorParams { attribute_group_id, attribute_id, class_hash }
                )
            );
    }

    fn register_shape_validator_shapes(world: IWorldDispatcher, attribute_group_id: u64) {
        register_shape_validator(world, attribute_group_id, 0x1, get_test_shapes_class_hash());
        register_shape_validator(world, attribute_group_id, 0x2, get_test_shapes_class_hash());
        register_shape_validator(world, attribute_group_id, 0x3, get_test_shapes_class_hash());
        register_shape_validator(
            world, attribute_group_id, 0x4, get_test_shapes_class_hash()
        ); // not handled !
    }


    fn valid_shape_1() -> Array<PackedShapeItem> {
        array![
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 5, y: 4, z: -2 }),
        ]
    }

    fn valid_shape_2() -> Array<PackedShapeItem> {
        array![
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
        ]
    }

    fn valid_shape_3() -> Array<PackedShapeItem> {
        array![
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 2, y: 4, z: -2 }),
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 3, y: 4, z: -2 }),
        ]
    }

    //
    // Booklet helper
    //

    fn mint_booklet(
        world: IWorldDispatcher,
        booklet_address: ContractAddress,
        to: ContractAddress,
        ids: Array<felt252>,
        amounts: Array<u128>
    ) {
        world
            .execute(
                'ERC1155MintBurn',
                system_calldata(
                    ERC1155MintBurnParams {
                        operator: WORLD_ADMIN(),
                        token: booklet_address,
                        from: starknet::contract_address_const::<0>(),
                        to,
                        ids, //  booklet_id == attribute_id
                        amounts,
                    }
                )
            );
    }
}
use convenience_for_testing::{
    assemble, disassemble, mint_booklet, valid_shape_1, valid_shape_2,
    create_attribute_group_with_booklet, register_shape_validator_shapes
};


#[test]
#[available_gas(30000000)]
#[should_panic]
fn test_empty_mint() {
    let DefaultWorld{world, briq_token, generic_sets, .. } = deploy_default_world();

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
    let DefaultWorld{world, briq_token, generic_sets, .. } = deploy_default_world();

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

    assert(DEFAULT_OWNER() == generic_sets.owner_of(token_id.into()), 'bad owner');
    assert(generic_sets.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(briq_token.balance_of(token_id, 1) == 1, 'bad balance');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 99, 'bad balance');

    disassemble(
        world, DEFAULT_OWNER(), token_id.into(), array![FTSpec { token_id: 1, qty: 1 }], array![]
    );
    assert(generic_sets.balance_of(DEFAULT_OWNER()) == 0, 'bad balance');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 100, 'bad balance');
// TODO: validate that token ID balance asserts as it's 0
}

#[test]
#[available_gas(3000000000)]
#[should_panic]
fn test_simple_mint_and_burn_not_enough_briqs() {
    let DefaultWorld{world, briq_token, generic_sets, .. } = deploy_default_world();

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
    let DefaultWorld{world, briq_token, generic_sets, ducks_set, .. } = deploy_default_world();

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

    assert(DEFAULT_OWNER() == generic_sets.owner_of(token_id.into()), 'bad owner');
    assert(generic_sets.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(briq_token.balance_of(token_id, 1) == 4, 'bad token balance 1');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 96, 'bad briq balance 1');

    disassemble(
        world, DEFAULT_OWNER(), token_id.into(), array![FTSpec { token_id: 1, qty: 4 }], array![]
    );
    assert(generic_sets.balance_of(DEFAULT_OWNER()) == 0, 'bad balance');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 100, 'bad briq balance 2');
// TODO: validate that token ID balance asserts as it's 0
}

#[test]
#[available_gas(3000000000)]
#[should_panic(
    expected: ('Set still has briqs', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED')
)]
fn test_simple_mint_and_burn_not_enough_briqs_in_disassembly() {
    let DefaultWorld{world, briq_token, generic_sets, ducks_set, .. } = deploy_default_world();

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
    assert(DEFAULT_OWNER() == generic_sets.owner_of(token_id.into()), 'bad owner');
    assert(generic_sets.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(briq_token.balance_of(token_id, 1) == 4, 'bad token balance 1');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 96, 'bad briq balance 1');

    disassemble(
        world, DEFAULT_OWNER(), token_id.into(), array![FTSpec { token_id: 1, qty: 1 }], array![]
    );
}


#[test]
#[available_gas(3000000000)]
#[should_panic(
    expected: (
        'unregistered attribute_group_id',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED'
    )
)]
fn test_simple_mint_attribute_not_exist() {
    let DefaultWorld{world, briq_token, generic_sets, .. } = deploy_default_world();

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
        array![AttributeItem { attribute_group_id: 0x1, attribute_id: 0x420 }],
    );
}

#[test]
#[available_gas(3000000000)]
fn test_simple_mint_attribute_ok_1() {
    let DefaultWorld{world, briq_token, ducks_set, ducks_booklet, .. } = deploy_default_world();

    create_attribute_group_with_booklet(
        world, 0x69, ducks_set.contract_address, ducks_booklet.contract_address
    );
    register_shape_validator_shapes(world, 0x69);

    mint_booklet(world, ducks_booklet.contract_address, DEFAULT_OWNER(), array![0x1], array![1]);
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
        array![AttributeItem { attribute_group_id: 0x69, attribute_id: 0x1 }],
    );
    assert(
        token_id == starknet::contract_address_const::<0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057aee0d6eda3>(),
        'bad token id'
    );
    assert(DEFAULT_OWNER() == ducks_set.owner_of(token_id.into()), 'bad owner');
    assert(ducks_set.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(ducks_booklet.balance_of(token_id, 0x1) == 1, 'bad booklet balance 2');
    assert(
        ERC1155BalanceTrait::balance_of(world, CUM_BALANCE_TOKEN(), token_id, CB_ATTRIBUTES()) == 1,
        'should be 1'
    );
    assert(
        ERC1155BalanceTrait::balance_of(world, CUM_BALANCE_TOKEN(), token_id, CB_BRIQ()) == 1,
        'should be 1'
    );
    // TODO validate booklet balance of owner to 0

    disassemble(
        world,
        DEFAULT_OWNER(),
        token_id,
        array![FTSpec { token_id: 1, qty: 4 }],
        array![AttributeItem { attribute_group_id: 0x69, attribute_id: 0x1 }]
    );
    assert(ducks_booklet.balance_of(DEFAULT_OWNER(), 0x1) == 1, 'bad booklet balance 3');
// TODO: validate that token ID balance asserts as it's 0
}


#[test]
#[available_gas(3000000000)]
fn test_simple_mint_attribute_ok_2() {
    let DefaultWorld{world, briq_token, ducks_set, ducks_booklet, .. } = deploy_default_world();

    create_attribute_group_with_booklet(
        world, 0x69, ducks_set.contract_address, ducks_booklet.contract_address
    );
    register_shape_validator_shapes(world, 0x69);

    mint_booklet(world, ducks_booklet.contract_address, DEFAULT_OWNER(), array![0x2], array![1]);
    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    impersonate(DEFAULT_OWNER());

    let token_id = assemble(
        world,
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 3 }],
        valid_shape_2(),
        array![AttributeItem { attribute_group_id: 0x69, attribute_id: 0x2 }],
    );

    assert(
        token_id == starknet::contract_address_const::<0x76a2334b023640f0bc1be745cfa047fc4ba4fd7289e8a82690291da3ad04837>(),
        'bad token id'
    );
    assert(DEFAULT_OWNER() == ducks_set.owner_of(token_id.into()), 'bad owner');
    assert(ducks_set.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(ducks_booklet.balance_of(token_id, 0x2) == 1, 'bad booklet balance 2');
    assert(
        ERC1155BalanceTrait::balance_of(world, CUM_BALANCE_TOKEN(), token_id, CB_ATTRIBUTES()) == 1,
        'should be 1'
    );
    assert(
        ERC1155BalanceTrait::balance_of(world, CUM_BALANCE_TOKEN(), token_id, CB_BRIQ()) == 1,
        'should be 1'
    );
    // TODO validate booklet balance of owner to 0

    disassemble(
        world,
        DEFAULT_OWNER(),
        token_id,
        array![FTSpec { token_id: 1, qty: 3 }],
        array![AttributeItem { attribute_group_id: 0x69, attribute_id: 0x2 }]
    );
    assert(ducks_booklet.balance_of(DEFAULT_OWNER(), 0x2) == 1, 'bad booklet balance 3');
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
    let DefaultWorld{world, briq_token, ducks_set, ducks_booklet, .. } = deploy_default_world();

    create_attribute_group_with_booklet(
        world, 0x69, ducks_set.contract_address, ducks_booklet.contract_address
    );
    register_shape_validator_shapes(world, 0x69);

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
        array![AttributeItem { attribute_group_id: 0x69, attribute_id: 0x1 }],
    );
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
    let DefaultWorld{world, briq_token, ducks_set, ducks_booklet, .. } = deploy_default_world();

    create_attribute_group_with_booklet(
        world, 0x69, ducks_set.contract_address, ducks_booklet.contract_address
    );
    register_shape_validator_shapes(world, 0x69);

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
        array![AttributeItem { attribute_group_id: 0x69, attribute_id: 0x1 }],
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
    let DefaultWorld{world, briq_token, ducks_set, ducks_booklet, .. } = deploy_default_world();

    create_attribute_group_with_booklet(
        world, 0x69, ducks_set.contract_address, ducks_booklet.contract_address
    );
    register_shape_validator_shapes(world, 0x69);

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
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 1, y: 4, z: -2 }),
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: 4, y: 4, z: -2 }),
        ],
        array![AttributeItem { attribute_group_id: 0x69, attribute_id: 0x1 }],
    );
}

#[test]
#[available_gas(3000000000)]
#[should_panic(
    expected: (
        'Set still attributed', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'
    )
)]
fn test_simple_mint_attribute_forgot_in_disassembly() {
    let DefaultWorld{world, briq_token, ducks_set, ducks_booklet, .. } = deploy_default_world();

    create_attribute_group_with_booklet(
        world, 0x69, ducks_set.contract_address, ducks_booklet.contract_address
    );
    register_shape_validator_shapes(world, 0x69);

    mint_booklet(world, ducks_booklet.contract_address, DEFAULT_OWNER(), array![0x1], array![1]);
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
        array![AttributeItem { attribute_group_id: 0x69, attribute_id: 0x1 }],
    );
    assert(
        token_id == starknet::contract_address_const::<0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057aee0d6eda3>(),
        'bad token id'
    );
    assert(DEFAULT_OWNER() == ducks_set.owner_of(token_id.into()), 'bad owner');
    assert(ducks_set.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(
        ERC1155BalanceTrait::balance_of(world, CUM_BALANCE_TOKEN(), token_id, CB_ATTRIBUTES()) == 1,
        'should be 1'
    );

    disassemble(world, DEFAULT_OWNER(), token_id, array![FTSpec { token_id: 1, qty: 4 }], array![]);
}


#[test]
#[available_gas(3000000000)]
#[should_panic(
    expected: (
        'unhandled attribute_id',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED'
    )
)]
fn test_simple_mint_registered_but_unhandled_shape() {
    let DefaultWorld{world, briq_token, ducks_set, ducks_booklet, .. } = deploy_default_world();

    create_attribute_group_with_booklet(
        world, 0x69, ducks_set.contract_address, ducks_booklet.contract_address
    );
    register_shape_validator_shapes(world, 0x69); // register shape 1/2/3/4 (4 not handled)

    mint_booklet(world, ducks_booklet.contract_address, DEFAULT_OWNER(), array![0x4], array![1]);
    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    impersonate(DEFAULT_OWNER());

    let token_id = assemble(
        world,
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 1 }],
        array![
            ShapePacking::pack(ShapeItem { color: '#ffaaff', material: 1, x: -100, y: 4, z: -2 }),
        ],
        array![AttributeItem { attribute_group_id: 0x69, attribute_id: 0x4 }],
    );
}

