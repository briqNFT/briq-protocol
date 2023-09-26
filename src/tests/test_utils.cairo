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

use dojo_erc::erc_common::utils::{system_calldata};
use dojo_erc::erc721::interface::IERC721Dispatcher;
use dojo_erc::erc1155::interface::IERC1155Dispatcher;

use briq_protocol::world_config::{get_world_config};
use briq_protocol::briq_token::BriqToken;
use briq_protocol::set_nft::SetNft;
use briq_protocol::set_nft_1155::SetNftERC1155;
use briq_protocol::mint_burn::ERC1155MintBurnParams;

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

fn spawn_world() -> IWorldDispatcher {
    // components
    let mut components = array![
        // world_config
        briq_protocol::world_config::world_config::TEST_CLASS_HASH,
        // erc1155
        dojo_erc::erc1155::components::erc_1155_balance::TEST_CLASS_HASH,
        dojo_erc::erc1155::components::operator_approval::TEST_CLASS_HASH,
        // erc721
        dojo_erc::erc721::components::erc_721_balance::TEST_CLASS_HASH,
        dojo_erc::erc721::components::erc_721_owner::TEST_CLASS_HASH,
        dojo_erc::erc721::components::erc_721_token_approval::TEST_CLASS_HASH,
        // attribute_group
        briq_protocol::attributes::attribute_group::attribute_group::TEST_CLASS_HASH,
        // shape_validator
        briq_protocol::attributes::group_systems::booklet::shape_validator::TEST_CLASS_HASH,
    ];
    // systems
    let mut systems = array![
        // world_config
        briq_protocol::world_config::SetupWorld::TEST_CLASS_HASH,
        
        // erc721
        dojo_erc::erc721::systems::ERC721Approve::TEST_CLASS_HASH,
        dojo_erc::erc721::systems::ERC721SetApprovalForAll::TEST_CLASS_HASH,
        briq_protocol::set_nft::systems_erc721::ERC721TransferFrom::TEST_CLASS_HASH,
        // erc721 specifics - set_nft
        briq_protocol::set_nft::systems::set_nft_assembly::TEST_CLASS_HASH,
        briq_protocol::set_nft::systems::set_nft_disassembly::TEST_CLASS_HASH,
        // erc1155 specifics - set_nft
        briq_protocol::set_nft::systems::set_nft_1155_assembly::TEST_CLASS_HASH,
        briq_protocol::set_nft::systems::set_nft_1155_disassembly::TEST_CLASS_HASH,

        // erc1155
        dojo_erc::erc1155::systems::ERC1155SetApprovalForAll::TEST_CLASS_HASH,
        briq_protocol::mint_burn::ERC1155MintBurn::TEST_CLASS_HASH,
        // briq_token
        briq_protocol::erc1155::briq_transfer::BriqTokenSafeTransferFrom::TEST_CLASS_HASH,
        briq_protocol::erc1155::briq_transfer::BriqTokenSafeBatchTransferFrom::TEST_CLASS_HASH,
        briq_protocol::mint_burn::BriqTokenERC1155MintBurn::TEST_CLASS_HASH,
        // unboxing
        briq_protocol::box_nft::unboxing::box_unboxing::TEST_CLASS_HASH,

        // attribute_group
        briq_protocol::attributes::attribute_group::create_attribute_group::TEST_CLASS_HASH,
        briq_protocol::attributes::attribute_group::update_attribute_group::TEST_CLASS_HASH,
        // attributes
        briq_protocol::attributes::group_systems::booklet::RegisterShapeValidator::TEST_CLASS_HASH,
        briq_protocol::attributes::group_systems::agm_booklet::TEST_CLASS_HASH,
        briq_protocol::attributes::group_systems::agm_briq_counter::TEST_CLASS_HASH,
        
        // briq_factory
        briq_protocol::briq_factory::systems::BriqFactoryMint::TEST_CLASS_HASH,
        briq_protocol::briq_factory::systems::BriqFactoryInitialize::TEST_CLASS_HASH,

        // Migration
        briq_protocol::migrate::migrate_assets::TEST_CLASS_HASH,
    ];

    let world = spawn_test_world(components, systems);

    //
    // set-up writer rights
    //

    world.grant_writer('WorldConfig', 'SetupWorld');

    // ***************************
    // ****  Factory
    // ***************************

    world.grant_writer('ERC1155Balance', 'BriqFactoryMint');
    world.grant_writer('BriqFactoryStore', 'BriqFactoryMint');

    // ***************************
    // ****  erc1155
    // ***************************

    world.grant_writer('ERC1155Balance', 'BriqTokenERC1155MintBurn');
    world.grant_writer('OperatorApproval', 'ERC1155SetApprovalForAll');

    // ***************************
    // ****  erc721
    // ***************************

    world.grant_writer('ERC721Balance', 'ERC721TransferFrom');
    world.grant_writer('ERC721Owner', 'ERC721TransferFrom');
    world.grant_writer('ERC721TokenApproval', 'ERC721Approve');
    world.grant_writer('ERC721TokenApproval', 'ERC721TransferFrom');

    // ***************************
    // **** set_nft (erc721 / 1155)
    // ***************************

    world.grant_writer('ERC721Balance', 'set_nft_assembly');
    world.grant_writer('ERC721Owner', 'set_nft_assembly');
    world.grant_writer('ERC1155Balance', 'set_nft_assembly');

    world.grant_writer('ERC721Owner', 'set_nft_disassembly');
    world.grant_writer('ERC721Balance', 'set_nft_disassembly');
    world.grant_writer('ERC1155Balance', 'set_nft_disassembly');

    world.grant_writer('ERC1155Balance', 'set_nft_1155_assembly');
    world.grant_writer('ERC1155Balance', 'set_nft_1155_disassembly');

    // ***************************
    // **** box_nft
    // ***************************

    world.grant_writer('ERC1155Balance', 'box_unboxing');

    // ***************************
    // **** attributes
    // ***************************

    world.grant_writer('AttributeGroup', 'create_attribute_group');
    world.grant_writer('ERC1155Balance', 'agm_booklet'); // for cumulative balance

    world
}


fn deploy_contracts(
    world: IWorldDispatcher,
) -> (
    ContractAddress,
    ContractAddress,
    ContractAddress,
    ContractAddress,
    ContractAddress,
    ContractAddress,
    ContractAddress,
    ContractAddress
) {
    let constructor_calldata = array![world.contract_address.into()];

    // sets
    let generic_sets_constructor_calldata = array![world.contract_address.into(), 'briq set', 'B7'];
    let ducks_set_constructor_calldata = array![world.contract_address.into(), 'ducks set', 'D7'];
    let planets_set_constructor_calldata = array![
        world.contract_address.into(), 'planets set', 'P7'
    ];

    // booklets
    let ducks_booklet_constructor_calldata = array![
        world.contract_address.into(),
    ];
    let planets_booklet_constructor_calldata = array![
        world.contract_address.into(),
    ];

    // briq token

    let (briq, _) = deploy_syscall(
        BriqToken::TEST_CLASS_HASH.try_into().unwrap(), 0, constructor_calldata.span(), false
    )
        .expect('error deploying');

    // sets 
    let (generic_sets, _) = deploy_syscall(
        SetNft::TEST_CLASS_HASH.try_into().unwrap(), 0, generic_sets_constructor_calldata.span(), false
    )
        .expect('error deploying');

    let (ducks_set, _) = deploy_syscall(
        SetNft::TEST_CLASS_HASH.try_into().unwrap(), 0, ducks_set_constructor_calldata.span(), false
    )
        .expect('error deploying');

    let (planets_set, _) = deploy_syscall(
        SetNft::TEST_CLASS_HASH.try_into().unwrap(),
        0,
        planets_set_constructor_calldata.span(),
        false
    )
        .expect('error deploying');

    let (lilducks_1155_set, _) = deploy_syscall(
        SetNftERC1155::TEST_CLASS_HASH.try_into().unwrap(), 0, array![world.contract_address.into()].span(), false
    )
        .expect('error deploying');

    // booklets 
    let (ducks_booklet, _) = deploy_syscall(
        briq_protocol::erc1155::GenericERC1155::TEST_CLASS_HASH.try_into().unwrap(),
        0,
        ducks_booklet_constructor_calldata.span(),
        false
    )
        .expect('error deploying');

    let (planets_booklet, _) = deploy_syscall(
        briq_protocol::erc1155::GenericERC1155::TEST_CLASS_HASH.try_into().unwrap(),
        0,
        planets_booklet_constructor_calldata.span(),
        false
    )
        .expect('error deploying');

    // boxes 
    let (box, _) = deploy_syscall(
        briq_protocol::erc1155::GenericERC1155::TEST_CLASS_HASH.try_into().unwrap(),
        0,
        constructor_calldata.span(),
        false
    )
        .expect('error deploying');

    // TODO: briq factory

    (briq, generic_sets, ducks_set, planets_set, lilducks_1155_set, ducks_booklet, planets_booklet, box)
}

#[derive(Copy, Drop)]
struct DefaultWorld {
    world: IWorldDispatcher,
    briq_token: IERC1155Dispatcher,
    //sets
    generic_sets: IERC721Dispatcher,
    ducks_set: IERC721Dispatcher,
    planets_set: IERC721Dispatcher,
    lilducks_1155_set: IERC1155Dispatcher,
    //booklets
    ducks_booklet: IERC1155Dispatcher,
    planets_booklet: IERC1155Dispatcher,
    // boxes
    box_nft: IERC1155Dispatcher,
}

fn deploy_default_world() -> DefaultWorld {
    impersonate(WORLD_ADMIN());

    let world = spawn_world();
    let (briq, generic_sets, ducks_set, planets_set, lilducks_1155_set, ducks_booklet, planets_booklet, box) =
        deploy_contracts(
        world
    );

    //   treasury: ContractAddress,
    //     briq: ContractAddress,
    //     generic_sets: ContractAddress,
    //     ducks_set: ContractAddress,
    //     ducks_booklet: ContractAddress,
    //     box: ContractAddress

    world
        .execute(
            'SetupWorld',
            (array![
                TREASURY().into(),
                briq.into(),
                generic_sets.into(),
                0,
            ])
        );
    DefaultWorld {
        world,
        briq_token: IERC1155Dispatcher { contract_address: briq },
        generic_sets: IERC721Dispatcher { contract_address: generic_sets },
        planets_set: IERC721Dispatcher { contract_address: planets_set },
        ducks_set: IERC721Dispatcher { contract_address: ducks_set },
        ducks_booklet: IERC1155Dispatcher { contract_address: ducks_booklet },
        planets_booklet: IERC1155Dispatcher { contract_address: planets_booklet },
        lilducks_1155_set: IERC1155Dispatcher { contract_address: lilducks_1155_set },
        box_nft: IERC1155Dispatcher { contract_address: box },
    }
}

#[test]
#[available_gas(30000000)]
fn test_deploy_default_world() {
    let DefaultWorld{world, briq_token, generic_sets, .. } = deploy_default_world();
    assert(get_world_config(world).briq == 0x3.try_into().unwrap(), 'totoro');
    assert(get_world_config(world).generic_sets == 0x4.try_into().unwrap(), 'totoro');
}


fn mint_briqs(world: IWorldDispatcher, owner: ContractAddress, material: felt252, amount: u128) {
    let old_caller = get_contract_address();
    set_contract_address(WORLD_ADMIN());

    world
        .execute(
            'BriqTokenERC1155MintBurn',
            system_calldata(
                ERC1155MintBurnParams {
                    token: get_world_config(world).briq.into(),
                    operator: WORLD_ADMIN().into(),
                    from: ZERO(),
                    to: owner,
                    ids: array![material.into()],
                    amounts: array![amount],
                }
            )
        );

    set_contract_address(old_caller);
}
