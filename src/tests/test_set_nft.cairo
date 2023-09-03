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
use briq_protocol::attributes::attribute_manager::RegisterAttributeManagerParams;
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
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use starknet::{ContractAddress, ClassHash, get_contract_address};
    use briq_protocol::types::{FTSpec, ShapeItem, ShapePacking, PackedShapeItem, AttributeItem};
    use briq_protocol::set_nft::systems::{AssemblySystemData, DisassemblySystemData, get_token_id};
    use dojo_erc::erc_common::utils::{system_calldata};
    use briq_protocol::attributes::attribute_manager::RegisterAttributeManagerParams;
    use briq_protocol::attributes::attribute_group::{CreateAttributeGroupParams, AttributeGroupOwner};
    use briq_protocol::briq_token::systems::ERC1155MintBurnParams;
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
        attributes: Array<AttributeItem>
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


    fn register_attribute_manager(
        world: IWorldDispatcher, attribute_group_id: u64, attribute_id: u64, class_hash: ClassHash
    ) {
        world
            .execute(
                'register_attribute_manager',
                system_calldata(
                    RegisterAttributeManagerParams { attribute_group_id, attribute_id, class_hash }
                )
            );
    }

    fn register_attribute_manager_shape_69(world: IWorldDispatcher) {
        register_attribute_manager(
            world,
            0x1,
            0x69,
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
        world: IWorldDispatcher, target_set_contract_address: ContractAddress
    ) {
        world
            .execute(
                'create_attribute_group',
                system_calldata(
                    CreateAttributeGroupParams {
                        attribute_group_id: 1,
                        owner: AttributeGroupOwner::System('attribute_manager_booklet'),
                        target_set_contract_address: target_set_contract_address
                    }
                )
            );
    }


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
                        from: ZERO(),
                        to,
                        ids, //  booklet_id == attribute_id
                        amounts,
                    }
                )
            );
    }
}
use convenience_for_testing::{
    assemble, disassemble, register_attribute_manager_shape_69, valid_shape_1,
    create_attribute_group_1, mint_booklet
};

#[test]
#[available_gas(30000000)]
#[should_panic]
fn test_empty_mint() {
    let DefaultWorld{world, briq_token, briq_set, .. } = deploy_default_world();

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
    let DefaultWorld{world, briq_token, briq_set, .. } = deploy_default_world();

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

    assert(DEFAULT_OWNER() == briq_set.owner_of(token_id.into()), 'bad owner');
    assert(briq_set.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(briq_token.balance_of(token_id, 1) == 1, 'bad balance');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 99, 'bad balance');

    disassemble(
        world, DEFAULT_OWNER(), token_id.into(), array![FTSpec { token_id: 1, qty: 1 }], array![]
    );
    assert(briq_set.balance_of(DEFAULT_OWNER()) == 0, 'bad balance');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 100, 'bad balance');
// TODO: validate that token ID balance asserts as it's 0
}

#[test]
#[available_gas(3000000000)]
#[should_panic]
fn test_simple_mint_and_burn_not_enough_briqs() {
    let DefaultWorld{world, briq_token, briq_set, .. } = deploy_default_world();

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
    let DefaultWorld{world, briq_token, briq_set, ducks_set, .. } = deploy_default_world();

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

    assert(DEFAULT_OWNER() == briq_set.owner_of(token_id.into()), 'bad owner');
    assert(briq_set.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(briq_token.balance_of(token_id, 1) == 4, 'bad token balance 1');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 96, 'bad briq balance 1');

    disassemble(
        world, DEFAULT_OWNER(), token_id.into(), array![FTSpec { token_id: 1, qty: 4 }], array![]
    );
    assert(briq_set.balance_of(DEFAULT_OWNER()) == 0, 'bad balance');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 100, 'bad briq balance 2');
// TODO: validate that token ID balance asserts as it's 0
}

#[test]
#[available_gas(3000000000)]
#[should_panic(
    expected: ('Set still has briqs', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED')
)]
fn test_simple_mint_and_burn_not_enough_briqs_in_disassembly() {
    let DefaultWorld{world, briq_token, briq_set, ducks_set, .. } = deploy_default_world();

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
    assert(DEFAULT_OWNER() == briq_set.owner_of(token_id.into()), 'bad owner');
    assert(briq_set.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
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
    let DefaultWorld{world, briq_token, briq_set, .. } = deploy_default_world();

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
fn test_simple_mint_attribute_ok() {
    let DefaultWorld{world, briq_token, briq_set, booklet, .. } = deploy_default_world();

    create_attribute_group_1(world, briq_set.contract_address);

    register_attribute_manager_shape_69(world);

    mint_booklet(world, booklet.contract_address, DEFAULT_OWNER(), array![0x69], array![1]);

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
        array![AttributeItem { attribute_group_id: 0x1, attribute_id: 0x69 }],
    );
    assert(
        token_id == starknet::contract_address_const::<0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057aee0d6eda3>(),
        'bad token id'
    );
    assert(DEFAULT_OWNER() == briq_set.owner_of(token_id.into()), 'bad owner');
    assert(briq_set.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(booklet.balance_of(token_id, 0x69) == 1, 'bad booklet balance 2');
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
        array![AttributeItem { attribute_group_id: 0x1, attribute_id: 0x69 }]
    );
    assert(booklet.balance_of(DEFAULT_OWNER(), 0x69) == 1, 'bad booklet balance 3');
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
    let DefaultWorld{world, briq_token, briq_set, .. } = deploy_default_world();

    create_attribute_group_1(world, briq_set.contract_address);

    register_attribute_manager_shape_69(world);

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
        array![AttributeItem { attribute_group_id: 0x1, attribute_id: 0x69 }],
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
    let DefaultWorld{world, briq_token, briq_set, .. } = deploy_default_world();

    create_attribute_group_1(world, briq_set.contract_address);

    register_attribute_manager_shape_69(world);

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
        array![AttributeItem { attribute_group_id: 0x1, attribute_id: 0x69 }],
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
    let DefaultWorld{world, briq_token, briq_set, .. } = deploy_default_world();

    create_attribute_group_1(world, briq_set.contract_address);

    register_attribute_manager_shape_69(world);

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
        array![AttributeItem { attribute_group_id: 0x1, attribute_id: 0x69 }],
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
    let DefaultWorld{world, booklet, briq_token, briq_set, .. } = deploy_default_world();

    create_attribute_group_1(world, briq_set.contract_address);

    register_attribute_manager_shape_69(world);

    mint_booklet(world, booklet.contract_address, DEFAULT_OWNER(), array![0x69], array![1]);

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
        array![AttributeItem { attribute_group_id: 0x1, attribute_id: 0x69 }],
    );
    assert(
        token_id == starknet::contract_address_const::<0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057aee0d6eda3>(),
        'bad token id'
    );
    assert(DEFAULT_OWNER() == briq_set.owner_of(token_id.into()), 'bad owner');
    assert(briq_set.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(
        ERC1155BalanceTrait::balance_of(world, CUM_BALANCE_TOKEN(), token_id, CB_ATTRIBUTES()) == 1,
        'should be 1'
    );

    disassemble(world, DEFAULT_OWNER(), token_id, array![FTSpec { token_id: 1, qty: 4 }], array![]);
}

