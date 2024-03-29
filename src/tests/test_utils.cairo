use traits::{Into, TryInto, Default, PartialEq};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;

use starknet::testing::{set_caller_address, set_contract_address, set_account_contract_address};
use starknet::ContractAddress;
use starknet::get_contract_address;
use starknet::syscalls::deploy_syscall;

use dojo::test_utils::spawn_test_world;
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use presets::erc721::erc721::interface::IERC721Dispatcher;
use presets::erc1155::erc1155::interface::IERC1155Dispatcher;

use briq_protocol::erc::mint_burn::{MintBurnDispatcher, MintBurnDispatcherTrait};

use briq_protocol::world_config::{get_world_config, ISetupWorldDispatcher, ISetupWorldDispatcherTrait};

use debug::PrintTrait;

fn ETH_ADDRESS() -> ContractAddress {
    starknet::contract_address_const::<0xeeee>()
}

fn WORLD_ADMIN() -> ContractAddress {
    starknet::contract_address_const::<0x420>()
}

fn TREASURY() -> ContractAddress {
    starknet::contract_address_const::<0x6969>()
}

fn DEFAULT_OWNER() -> ContractAddress {
    starknet::contract_address_const::<0xcafe>()

}
fn USER1() -> ContractAddress {
    starknet::contract_address_const::<0xfafa>()
}

fn ZERO() -> ContractAddress {
    starknet::contract_address_const::<0x0>()
}

fn impersonate(address: ContractAddress) {
    set_contract_address(address);
    set_account_contract_address(address);
}

fn deploy(world: IWorldDispatcher, class_hash: felt252) -> ContractAddress {
    world.deploy_contract(
        0, class_hash.try_into().unwrap()
    )
}

#[derive(Copy, Drop)]
struct DefaultWorld {
    world: IWorldDispatcher,
    payment_addr: ContractAddress,

    setup_world: ISetupWorldDispatcher,
    attribute_groups_addr: ContractAddress,
    register_shape_validator_addr: ContractAddress,

    briq_token: IERC1155Dispatcher,
    
    generic_sets: IERC721Dispatcher,

    sets_ducks: IERC721Dispatcher,
    sets_1155: IERC1155Dispatcher,

    booklet_ducks: IERC1155Dispatcher,
    booklet_sp: IERC1155Dispatcher,
    
    box_nft: IERC1155Dispatcher,
}


fn spawn_briq_test_world() -> DefaultWorld {
    impersonate(WORLD_ADMIN());
    // components
    let mut components = array![
        // world_config
        briq_protocol::world_config::world_config::TEST_CLASS_HASH,

        //presets::erc20::models::erc_20_balance::TEST_CLASS_HASH,
        //presets::erc20::models::erc_20_allowance::TEST_CLASS_HASH,
        //presets::erc20::models::erc_20_meta::TEST_CLASS_HASH,

        briq_protocol::erc::erc1155::models::erc_1155_balance::TEST_CLASS_HASH,
        briq_protocol::erc::erc1155::models::erc_1155_operator_approval::TEST_CLASS_HASH,

        briq_protocol::erc::erc721::models::erc_721_balance::TEST_CLASS_HASH,
        briq_protocol::erc::erc721::models::erc_721_owner::TEST_CLASS_HASH,
        briq_protocol::erc::erc721::models::erc_721_token_approval::TEST_CLASS_HASH,
        briq_protocol::erc::erc721::models::erc_721_operator_approval::TEST_CLASS_HASH,

        briq_protocol::attributes::attribute_group::attribute_group::TEST_CLASS_HASH,

        briq_protocol::booklet::attribute::shape_validator::TEST_CLASS_HASH,
    ];
    let world = spawn_test_world(components);
    // ERC 20 token for payment
    // let (payment_addr, _) = deploy_syscall(presets::erc20::erc20::ERC20::TEST_CLASS_HASH.try_into().unwrap(), 0, array![
    //     world.contract_address.into(),
    //     'cash',
    //     'money',
    //     0, 100000000000000000000,
    //     DEFAULT_OWNER().into(),
    // ].span(), false).unwrap();

    // systems
    let setup_world_addr = deploy(world, briq_protocol::world_config::setup_world::TEST_CLASS_HASH);

    let attribute_groups_addr = deploy(world, briq_protocol::attributes::attribute_group::attribute_groups::TEST_CLASS_HASH);
    let register_shape_validator_addr = deploy(world, briq_protocol::booklet::attribute::register_shape_validator::TEST_CLASS_HASH);

    let briq_factory_addr = deploy(world, briq_protocol::briq_factory::briq_factory::TEST_CLASS_HASH);

    // Specific tokens below
    let briq_token_addr = deploy(world, briq_protocol::tokens::briq_token::briq_token::TEST_CLASS_HASH);

    let sets_generic_addr = deploy(world, briq_protocol::tokens::set_nft::set_nft::TEST_CLASS_HASH);
    let sets_ducks_addr = deploy(world, briq_protocol::tokens::set_nft_ducks::set_nft_ducks::TEST_CLASS_HASH);
    let sets_1155_addr = deploy(world, briq_protocol::tokens::set_nft_1155_ducks_frens::set_nft_1155_ducks_frens::TEST_CLASS_HASH);

    let booklet_ducks_addr = deploy(world, briq_protocol::tokens::booklet_ducks::booklet_ducks::TEST_CLASS_HASH);
    let booklet_starknet_planet_addr = deploy(world, briq_protocol::tokens::booklet_starknet_planet::booklet_starknet_planet::TEST_CLASS_HASH);

    let box_nft_addr = deploy(world, briq_protocol::tokens::box_nft_sp::box_nft_sp::TEST_CLASS_HASH);

    //
    // set-up writer rights
    //

    //world.grant_writer('ERC20Balance', payment_addr);
    //world.grant_writer('ERC20Allowance', payment_addr);
    //world.grant_writer('ERC20Meta', payment_addr);

    world.grant_writer('WorldConfig', setup_world_addr);
    world.grant_writer('SetContracts', setup_world_addr);

    world.grant_writer('BriqFactoryStore', briq_factory_addr);

    world.grant_writer('ERC1155Balance', briq_token_addr);
    world.grant_writer('ERC1155OperatorApproval', briq_token_addr);

    world.grant_writer('ERC1155Balance', sets_1155_addr);
    world.grant_writer('ERC1155OperatorApproval', sets_1155_addr);

    world.grant_writer('ERC1155Balance', booklet_ducks_addr);
    world.grant_writer('ERC1155OperatorApproval', booklet_ducks_addr);
    world.grant_writer('ERC1155Balance', booklet_starknet_planet_addr);
    world.grant_writer('ERC1155OperatorApproval', booklet_starknet_planet_addr);
    world.grant_writer('ERC1155Balance', box_nft_addr);
    world.grant_writer('ERC1155OperatorApproval', box_nft_addr);

    world.grant_writer('ERC721Balance', sets_generic_addr);
    world.grant_writer('ERC721Owner', sets_generic_addr);
    world.grant_writer('ERC721TokenApproval', sets_generic_addr);
    world.grant_writer('ERC721OperatorApproval', sets_generic_addr);

    world.grant_writer('ERC721Balance', sets_ducks_addr);
    world.grant_writer('ERC721Owner', sets_ducks_addr);
    world.grant_writer('ERC721TokenApproval', sets_ducks_addr);
    world.grant_writer('ERC721OperatorApproval', sets_ducks_addr);
    // For some cumulative data
    world.grant_writer('ERC1155Balance', sets_ducks_addr);
    world.grant_writer('ERC1155OperatorApproval', sets_ducks_addr);

    world.grant_writer('AttributeGroup', attribute_groups_addr);

    // Setup
    ISetupWorldDispatcher { contract_address: setup_world_addr }.execute(
        world,
        TREASURY(),
        briq_token_addr,
        sets_generic_addr,
        briq_factory_addr,
    );

    ISetupWorldDispatcher { contract_address: setup_world_addr }.register_set_contract(
        world,
        sets_generic_addr,
        true,
    );
    ISetupWorldDispatcher { contract_address: setup_world_addr }.register_set_contract(
        world,
        sets_ducks_addr,
        true,
    );
    ISetupWorldDispatcher { contract_address: setup_world_addr }.register_set_contract(
        world,
        sets_1155_addr,
        true,
    );
    ISetupWorldDispatcher { contract_address: setup_world_addr }.register_box_contract(
        world,
        box_nft_addr,
        true,
    );

    DefaultWorld {
        world,
        payment_addr: starknet::contract_address_const::<0x0>(),
        setup_world: ISetupWorldDispatcher { contract_address: setup_world_addr },
        attribute_groups_addr,
        register_shape_validator_addr,
        briq_token: IERC1155Dispatcher { contract_address: briq_token_addr },
        generic_sets: IERC721Dispatcher { contract_address: sets_generic_addr },
        sets_ducks: IERC721Dispatcher { contract_address: sets_ducks_addr },
        sets_1155: IERC1155Dispatcher { contract_address: sets_1155_addr },
        booklet_ducks: IERC1155Dispatcher { contract_address: booklet_ducks_addr },
        booklet_sp: IERC1155Dispatcher { contract_address: booklet_starknet_planet_addr },
        box_nft: IERC1155Dispatcher { contract_address: box_nft_addr },
    }
}

#[test]
#[available_gas(300000000)]
fn test_spawn_briq_test_world() {
    let DefaultWorld{world, briq_token, generic_sets, .. } = spawn_briq_test_world();
    assert(get_world_config(world).briq == 0x8.try_into().unwrap(), 'bad setup');
    assert(get_world_config(world).generic_sets == 0x9.try_into().unwrap(), 'bad setup');
}

// Convenience functions

fn mint_briqs(world: IWorldDispatcher, owner: ContractAddress, material: felt252, amount: u128) {
    let old_caller = get_contract_address();
    set_contract_address(WORLD_ADMIN());

    MintBurnDispatcher { contract_address: get_world_config(world).briq }.mint( 
        owner,
        material,
        amount,
    );

    set_contract_address(old_caller);
}
