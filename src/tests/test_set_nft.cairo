mod convenience_for_testing {
    use starknet::{ContractAddress, ClassHash, get_contract_address};

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use briq_protocol::world_config::get_world_config;

    use briq_protocol::types::{FTSpec, ShapeItem, ShapePacking, PackedShapeItem, AttributeItem};

    use briq_protocol::set_nft::assembly::{get_token_id, get_target_contract_from_attributes};

    use briq_protocol::tests::test_utils::WORLD_ADMIN;

    use briq_protocol::erc::mint_burn::{MintBurnDispatcher, MintBurnDispatcherTrait};

    use presets::erc721::erc721::interface::IERC721Dispatcher;
    use presets::erc1155::erc1155::interface::IERC1155Dispatcher;
    use briq_protocol::set_nft::assembly::{ISetNftAssemblyDispatcher, ISetNftAssemblySafeDispatcher};

    trait Dispatcher<T> { fn contract_address(self: T) -> ContractAddress; }
    impl D1155 of Dispatcher<IERC1155Dispatcher> { fn contract_address(self: IERC1155Dispatcher) -> ContractAddress { self.contract_address } }
    impl D721 of Dispatcher<IERC721Dispatcher> { fn contract_address(self: IERC721Dispatcher) -> ContractAddress { self.contract_address } }
    fn as_set<T, impl TD: Dispatcher<T>>(dispatcher: T) -> ISetNftAssemblyDispatcher {
        ISetNftAssemblyDispatcher { contract_address: dispatcher.contract_address() }
    }
    fn as_set_safe<T, impl TD: Dispatcher<T>>(dispatcher: T) -> ISetNftAssemblySafeDispatcher {
        ISetNftAssemblySafeDispatcher { contract_address: dispatcher.contract_address() }
    }

    //
    // Shapes ClassHash
    //

    fn get_test_shapes_class_hash() -> ClassHash {
        briq_protocol::tests::shapes::test_shapes::TEST_CLASS_HASH.try_into().unwrap()
    }

    use briq_protocol::booklet::attribute::{IRegisterShapeValidatorDispatcher, IRegisterShapeValidatorDispatcherTrait};

    fn register_shape_validator_shapes(world: IWorldDispatcher, rsva: ContractAddress, attribute_group_id: u64) {
        let rsv = IRegisterShapeValidatorDispatcher { contract_address: rsva };
        rsv.execute(world, attribute_group_id, 0x1, get_test_shapes_class_hash());
        rsv.execute(world, attribute_group_id, 0x2, get_test_shapes_class_hash());
        rsv.execute(world, attribute_group_id, 0x3, get_test_shapes_class_hash());
        rsv.execute(
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

    use briq_protocol::attributes::attribute_group::{IAttributeGroupsDispatcher, IAttributeGroupsDispatcherTrait, AttributeGroupOwner};
    fn create_contract_attribute_group(world: IWorldDispatcher, attribute_groups_addr: ContractAddress, attribute_group_id: u64, owner: ContractAddress, target_sets: ContractAddress) {
        IAttributeGroupsDispatcher { contract_address: attribute_groups_addr }.create_attribute_group(
        world, attribute_group_id, AttributeGroupOwner::Contract(owner), target_sets
    );
    }


    fn mint_booklet(
        booklet_address: ContractAddress,
        to: ContractAddress,
        id: felt252,
        amount: u128
    ) {
        MintBurnDispatcher { contract_address: booklet_address }.mint(
            to,
            id,
            amount,
        )
    }
}

use starknet::testing::{set_caller_address, set_contract_address};
use starknet::ContractAddress;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use presets::erc721::erc721::interface::IERC721DispatcherTrait;
use presets::erc1155::erc1155::interface::IERC1155DispatcherTrait;

use briq_protocol::tests::test_utils::{
    WORLD_ADMIN, DEFAULT_OWNER, DefaultWorld, spawn_briq_test_world, mint_briqs, impersonate
};

use briq_protocol::erc::erc1155::models::ERC1155Balance;

use briq_protocol::types::{FTSpec, ShapeItem, ShapePacking, PackedShapeItem, AttributeItem};
use briq_protocol::cumulative_balance::{CUM_BALANCE_TOKEN, CB_ATTRIBUTES, CB_BRIQ};
use briq_protocol::world_config::get_world_config;

use briq_protocol::attributes::attribute_group::{IAttributeGroupsDispatcher, IAttributeGroupsDispatcherTrait, AttributeGroupOwner};

use briq_protocol::set_nft::assembly::{ISetNftAssemblyDispatcherTrait, ISetNftAssemblySafeDispatcherTrait};
use briq_protocol::tokens::set_nft::set_nft::Transfer as SetNftTransfer;

use debug::PrintTrait;

use convenience_for_testing::{
    as_set, as_set_safe, mint_booklet, valid_shape_1, valid_shape_2,
    register_shape_validator_shapes, create_contract_attribute_group
};


#[test]
#[available_gas(300000000)]
fn test_hash() {
    assert(briq_protocol::set_nft::assembly::get_token_id(
        starknet::contract_address_const::<0x3ef5b02bcc5d30f3f0d35d55f365e6388fe9501eca216cb1596940bf41083e2>(), 0x6111956b2a0842138b2df81a3e6e88f8, 25, 0
    ) == 0xc40763dbee89f284bf9215e353171229b4cbc645fa8c0932cb68c100000000, 'Bad token Id');
    assert(briq_protocol::set_nft::assembly::get_token_id(
        starknet::contract_address_const::<0x3ef5b02bcc5d30f3f0d35d55f365eca216cb1596940bf41083e2>(), 0x6111956b2a06e88f8, 1, 0
    ) == 0x3011789e95d63923025646fcbf5230513b8b347ff1371b871a9968600000000, 'Bad token Id 2');
    assert(briq_protocol::set_nft::assembly::get_token_id(
        starknet::contract_address_const::<0x3ef5b02bcc5d305f365e6388fe9501eca216cb1596940bf41083e2>(), 0x611195842138b2df81a3e6e88f8, 2, 0
    ) == 0x19d7b6f61cec829e2e1c424e11b40c8198912a71d75b14a781db83800000000, 'Bad token Id 3');
    assert(briq_protocol::set_nft::assembly::get_token_id(
        starknet::contract_address_const::<0x3ef5b02bcc5d30f3f0d35d55f365e63801eca216cb1596940bf41083e2>(), 0x6111956b42138b2df81a3e6e88f8, 3, 0x34153
    ) == 0x7805905ca794dd2afcf54520b89b0a5520f51614e3ce357c7c2852700034153, 'Bad token Id 4');
    assert(briq_protocol::set_nft::assembly::get_token_id(
        starknet::contract_address_const::<0x3ef5b02bcc5d30f3f35d55f365e6388fe9501eca216cb1596940bf41083e2>(), 0x6111956b2ae88f8, 4, 0
    ) == 0x6f003d687db73af9b0675080e87208027881dccf5a6fd35eed4f88500000000, 'Bad token Id 5');
    assert(briq_protocol::set_nft::assembly::get_token_id(
        starknet::contract_address_const::<0x3ef5b02bcc5d30f3f0d35d55f365e6388fe9501e216cb1596940bf41083e2>(), 0x6111956b2a0842138b26e88f8, 5, 0x3435
    ) == 0x3f7dc95b8ce50f4c0e75d7c2c6cf04190e45c3cb4c26e52b9993df000003435, 'Bad token Id 6');
    assert(briq_protocol::set_nft::assembly::get_token_id(
        starknet::contract_address_const::<0x3ef5b02b30f3f0d35d55f365e6388fe9501eca216cb1596940bf41083e2>(), 0x6111938b2df81a3e6e88f8, 6, 0
    ) == 0x5289ebc74ed85b93bd3f2da93cb3b836b0b8bd6c3924b29d916f68800000000, 'Bad token Id 7');
    assert(briq_protocol::set_nft::assembly::get_token_id(
        starknet::contract_address_const::<0x3ef5b0388fe9501eca216cb1596940bf41083e2>(), 0x6111956b2a02138b2df81a3e6e88f8, 7, 0
    ) == 0x7e49695c97a0b7779bfcc0f532866b5f8ed03999a7d3cd093d585dd00000000, 'Bad token Id 8');
    assert(briq_protocol::set_nft::assembly::get_token_id(
        starknet::contract_address_const::<0x3ef5b02bcc5d30f3f0d35d5cb1596940bf41083e2>(), 0x611138b2df81a3e6e88f8, 8, 0
    ) == 0x1fcea5dd923ed43f376c2ff1fc86fecf221b1fad82d6caf6221f5b700000000, 'Bad token Id 9');
}

#[test]
#[available_gas(300000000)]
#[should_panic]
fn test_empty_mint() {
    let DefaultWorld{world, briq_token, generic_sets, .. } = spawn_briq_test_world();

    impersonate(DEFAULT_OWNER());

    let token_id = as_set(generic_sets).assemble(
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
fn test_simple_mint_and_burn_1() {
    let DefaultWorld{world, briq_token, generic_sets, .. } = spawn_briq_test_world();

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

    assert(DEFAULT_OWNER() == generic_sets.owner_of(token_id.into()), 'bad owner');
    assert(generic_sets.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(briq_token.balance_of(token_id.try_into().unwrap(), 1) == 1, 'bad balance');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 99, 'bad balance');

    as_set(generic_sets).disassemble(
        DEFAULT_OWNER(), token_id.into(), array![FTSpec { token_id: 1, qty: 1 }], array![]
    );
    assert(generic_sets.balance_of(DEFAULT_OWNER()) == 0, 'bad balance');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 100, 'bad balance');
    // TODO: validate that token ID balance asserts as it's 0

    let (a, b) = starknet::testing::pop_log_raw(generic_sets.contract_address).unwrap();

    let tev = starknet::testing::pop_log::<SetNftTransfer>(generic_sets.contract_address).unwrap();
    assert(tev.from == Zeroable::zero(), 'bad from');
    assert(tev.to == DEFAULT_OWNER(), 'bad to');
    assert(tev.token_id == token_id.into(), 'bad token id');
    let tev = starknet::testing::pop_log::<SetNftTransfer>(generic_sets.contract_address).unwrap();
    assert(tev.from == DEFAULT_OWNER(), 'bad from');
    assert(tev.to == Zeroable::zero(), 'bad to');
    assert(tev.token_id == token_id.into(), 'bad token id');
}

#[test]
#[available_gas(3000000000)]
#[should_panic]
fn test_simple_mint_and_burn_not_enough_briqs() {
    let DefaultWorld{world, briq_token, generic_sets, .. } = spawn_briq_test_world();

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
}

#[test]
#[available_gas(3000000000)]
fn test_simple_mint_and_burn_2() {
    let DefaultWorld{world, briq_token, generic_sets, .. } = spawn_briq_test_world();

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    impersonate(DEFAULT_OWNER());

    let token_id = as_set(generic_sets).assemble(
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![],
    );

    assert(
        token_id == 0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057ae00000000,
        'bad token id'
    );

    assert(DEFAULT_OWNER() == generic_sets.owner_of(token_id.into()), 'bad owner');
    assert(generic_sets.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(briq_token.balance_of(token_id.try_into().unwrap(), 1) == 4, 'bad token balance 1');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 96, 'bad briq balance 1');

    as_set(generic_sets).disassemble(
        DEFAULT_OWNER(), token_id, array![FTSpec { token_id: 1, qty: 4 }], array![]
    );

    assert(generic_sets.balance_of(DEFAULT_OWNER()) == 0, 'bad balance');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 100, 'bad briq balance 2');
}

#[test]
#[available_gas(3000000000)]
#[should_panic(
    expected: ('Set still has briqs', 'ENTRYPOINT_FAILED')
)]
fn test_simple_mint_and_burn_not_enough_briqs_in_disassembly() {
    let DefaultWorld{world, briq_token, generic_sets, .. } = spawn_briq_test_world();

    impersonate(DEFAULT_OWNER());

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    let token_id = as_set(generic_sets).assemble(
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![],
    );

    assert(
        token_id == 0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057ae00000000,
        'bad token id'
    );
    assert(DEFAULT_OWNER() == generic_sets.owner_of(token_id.into()), 'bad owner');
    assert(generic_sets.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(briq_token.balance_of(token_id.try_into().unwrap(), 1) == 4, 'bad token balance 1');
    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 96, 'bad briq balance 1');

    as_set(generic_sets).disassemble(
        DEFAULT_OWNER(), token_id, array![FTSpec { token_id: 1, qty: 1 }], array![]
    );
}


#[test]
#[available_gas(3000000000)]
#[should_panic(
    expected: (
        'unregistered attribute_group_id',
        'ENTRYPOINT_FAILED',
    )
)]
fn test_simple_mint_attribute_not_exist() {
    let DefaultWorld{world, briq_token, generic_sets, .. } = spawn_briq_test_world();

    impersonate(DEFAULT_OWNER());

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    let token_id = as_set(generic_sets).assemble(
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
    let DefaultWorld{world, briq_token, sets_ducks, booklet_ducks, attribute_groups_addr, register_shape_validator_addr, .. } = spawn_briq_test_world();

    create_contract_attribute_group(world, attribute_groups_addr, 0x69, booklet_ducks.contract_address, sets_ducks.contract_address);
    register_shape_validator_shapes(world, register_shape_validator_addr, 0x69);
    mint_booklet(booklet_ducks.contract_address, DEFAULT_OWNER(), 0x690000000000000001, 1);
    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    impersonate(DEFAULT_OWNER());

    let token_id = as_set(sets_ducks).assemble(
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![AttributeItem { attribute_group_id: 0x69, attribute_id: 0x1 }],
    );
    assert(
        token_id == 0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057ae00000069,
        'bad token id'
    );
    assert(DEFAULT_OWNER() == sets_ducks.owner_of(token_id.into()), 'bad owner');
    assert(sets_ducks.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(booklet_ducks.balance_of(token_id.try_into().unwrap(), 0x690000000000000001) == 1, 'bad booklet balance 2');
    assert(
        get!(world, (CUM_BALANCE_TOKEN(), token_id, CB_ATTRIBUTES()), ERC1155Balance).amount == 1,
        'should be 1'
    );
    assert(
        get!(world, (CUM_BALANCE_TOKEN(), token_id, CB_BRIQ()), ERC1155Balance).amount == 1,
        'should be 1'
    );

    as_set(sets_ducks).disassemble(
        DEFAULT_OWNER(),
        token_id,
        array![FTSpec { token_id: 1, qty: 4 }],
        array![AttributeItem { attribute_group_id: 0x69, attribute_id: 0x1 }]
    );
    assert(booklet_ducks.balance_of(DEFAULT_OWNER(), 0x690000000000000001) == 1, 'bad booklet balance 3');

    let (a, b) = starknet::testing::pop_log_raw(sets_ducks.contract_address).unwrap();

    let tev = starknet::testing::pop_log::<SetNftTransfer>(sets_ducks.contract_address).unwrap();
    assert(tev.from == Zeroable::zero(), 'bad from');
    assert(tev.to == DEFAULT_OWNER(), 'bad to');
    assert(tev.token_id == token_id.into(), 'bad token id');
    let tev = starknet::testing::pop_log::<SetNftTransfer>(sets_ducks.contract_address).unwrap();
    assert(tev.from == DEFAULT_OWNER(), 'bad from');
    assert(tev.to == Zeroable::zero(), 'bad to');
    assert(tev.token_id == token_id.into(), 'bad token id');
}


#[test]
#[available_gas(3000000000)]
fn test_simple_mint_attribute_ok_2() {
    let DefaultWorld{world, briq_token, sets_ducks, booklet_ducks, attribute_groups_addr, register_shape_validator_addr, .. } = spawn_briq_test_world();
    create_contract_attribute_group(world, attribute_groups_addr, 0x69, booklet_ducks.contract_address, sets_ducks.contract_address);
    register_shape_validator_shapes(world, register_shape_validator_addr, 0x69);

    mint_booklet(booklet_ducks.contract_address, DEFAULT_OWNER(), 0x690000000000000002, 1);
    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    impersonate(DEFAULT_OWNER());

    let token_id = as_set(sets_ducks).assemble(
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 3 }],
        valid_shape_2(),
        array![AttributeItem { attribute_group_id: 0x69, attribute_id: 0x2 }],
    );

    assert(
        token_id == 0x76a2334b023640f0bc1be745cfa047fc4ba4fd7289e8a82690291da00000069,
        'bad token id'
    );
    assert(DEFAULT_OWNER() == sets_ducks.owner_of(token_id.into()), 'bad owner');
    assert(sets_ducks.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(booklet_ducks.balance_of(token_id.try_into().unwrap(), 0x690000000000000002) == 1, 'bad booklet balance 2');
    assert(
        get!(world, (CUM_BALANCE_TOKEN(), token_id, CB_ATTRIBUTES()), ERC1155Balance).amount == 1,
        'should be 1'
    );
    assert(
        get!(world, (CUM_BALANCE_TOKEN(), token_id, CB_BRIQ()), ERC1155Balance).amount == 1,
        'should be 1'
    );
    // TODO validate booklet balance of owner to 0

    as_set(sets_ducks).disassemble(
        DEFAULT_OWNER(),
        token_id,
        array![FTSpec { token_id: 1, qty: 3 }],
        array![AttributeItem { attribute_group_id: 0x69, attribute_id: 0x2 }]
    );
    assert(booklet_ducks.balance_of(DEFAULT_OWNER(), 0x690000000000000002) == 1, 'bad booklet balance 3');
// TODO: validate that token ID balance asserts as it's 0
}

#[test]
#[available_gas(3000000000)]
#[should_panic(
    expected: (
        'u256_sub Overflow',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
    )
)]
fn test_simple_mint_attribute_dont_have_the_booklet() {
    let DefaultWorld{world, briq_token, sets_ducks, booklet_ducks, attribute_groups_addr, register_shape_validator_addr, .. } = spawn_briq_test_world();

    create_contract_attribute_group(world, attribute_groups_addr, 0x69, booklet_ducks.contract_address, sets_ducks.contract_address);
    register_shape_validator_shapes(world, register_shape_validator_addr, 0x69);

    impersonate(DEFAULT_OWNER());

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    let token_id = as_set(sets_ducks).assemble(
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
        'ENTRYPOINT_FAILED'
    )
)]
fn test_simple_mint_attribute_bad_shape_item() {
    let DefaultWorld{world, briq_token, sets_ducks, booklet_ducks, attribute_groups_addr, register_shape_validator_addr, .. } = spawn_briq_test_world();

    create_contract_attribute_group(world, attribute_groups_addr, 0x69, booklet_ducks.contract_address, sets_ducks.contract_address);
    register_shape_validator_shapes(world, register_shape_validator_addr, 0x69);

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    impersonate(DEFAULT_OWNER());

    let token_id = as_set(sets_ducks).assemble(
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
    )
)]
fn test_simple_mint_attribute_shape_fts_mismatch() {
    let DefaultWorld{world, briq_token, sets_ducks, booklet_ducks, attribute_groups_addr, register_shape_validator_addr, .. } = spawn_briq_test_world();

    create_contract_attribute_group(world, attribute_groups_addr, 0x69, booklet_ducks.contract_address, sets_ducks.contract_address);
    register_shape_validator_shapes(world, register_shape_validator_addr, 0x69);

    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    impersonate(DEFAULT_OWNER());

    let token_id = as_set(sets_ducks).assemble(
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
        'Set still attributed', 'ENTRYPOINT_FAILED'
    )
)]
fn test_simple_mint_attribute_forgot_in_disassembly() {
    let DefaultWorld{world, briq_token, generic_sets, sets_ducks, booklet_ducks, attribute_groups_addr, register_shape_validator_addr, .. } = spawn_briq_test_world();

    create_contract_attribute_group(world, attribute_groups_addr, 0x69, booklet_ducks.contract_address, sets_ducks.contract_address);
    register_shape_validator_shapes(world, register_shape_validator_addr, 0x69);

    mint_booklet(booklet_ducks.contract_address, DEFAULT_OWNER(), 0x690000000000000001, 1);
    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    impersonate(DEFAULT_OWNER());

    let token_id = as_set(sets_ducks).assemble(
        DEFAULT_OWNER(),
        0xfade,
        array![0xcafe],
        array![0xfade],
        array![FTSpec { token_id: 1, qty: 4 }],
        valid_shape_1(),
        array![AttributeItem { attribute_group_id: 0x69, attribute_id: 0x1 }],
    );
    assert(
        token_id == 0x2d4276d22e1b24bb462c255708ae8293302ff6b17691ed07f5057ae00000069,
        'bad token id'
    );
    assert(DEFAULT_OWNER() == sets_ducks.owner_of(token_id.into()), 'bad owner');
    assert(sets_ducks.balance_of(DEFAULT_OWNER()) == 1, 'bad balance');
    assert(
        get!(world, (CUM_BALANCE_TOKEN(), token_id, CB_ATTRIBUTES()), ERC1155Balance).amount == 1,
        'should be 1'
    );
    // This fails as 'not the correct contract', as expected
    assert(as_set_safe(sets_ducks).disassemble(DEFAULT_OWNER(), token_id, array![FTSpec { token_id: 1, qty: 4 }], array![]).is_err(), 'should error');

    as_set(generic_sets).disassemble(DEFAULT_OWNER(), token_id, array![FTSpec { token_id: 1, qty: 4 }], array![]);
}


#[test]
#[available_gas(3000000000)]
#[should_panic(
    expected: (
        'unhandled attribute_id',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
        'ENTRYPOINT_FAILED',
    )
)]
fn test_simple_mint_registered_but_unhandled_shape() {
    let DefaultWorld{world, briq_token, sets_ducks, booklet_ducks, attribute_groups_addr, register_shape_validator_addr, .. } = spawn_briq_test_world();

    create_contract_attribute_group(world, attribute_groups_addr, 0x69, booklet_ducks.contract_address, sets_ducks.contract_address);
    register_shape_validator_shapes(world, register_shape_validator_addr, 0x69); // register shape 1/2/3/4 (4 not handled)

    mint_booklet(booklet_ducks.contract_address, DEFAULT_OWNER(), 0x690000000000000004, 1);
    mint_briqs(world, DEFAULT_OWNER(), 1, 100);

    impersonate(DEFAULT_OWNER());

    let token_id = as_set(sets_ducks).assemble(
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

