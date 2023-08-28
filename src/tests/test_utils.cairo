use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;

use starknet::testing::{set_caller_address, set_contract_address, set_account_contract_address};
use starknet::ContractAddress;
use starknet::get_contract_address;
use starknet::syscalls::deploy_syscall;

use debug::PrintTrait;

use dojo::test_utils::spawn_test_world;
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use briq_protocol::briq_token::BriqToken;
use briq_protocol::set_nft::SetNft;
use briq_protocol::world_config::{WorldConfig, SYSTEM_CONFIG_ID};

use dojo_erc::erc721::interface::IERC721Dispatcher;
use dojo_erc::erc1155::interface::IERC1155Dispatcher;


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
        // collection
        briq_protocol::attributes::collection::collection::TEST_CLASS_HASH,
        // shape_verifier
        briq_protocol::shape_verifier::shape_verifier::TEST_CLASS_HASH,
    ];
    // systems
    let mut systems = array![
        // world_config
        briq_protocol::world_config::SetupWorld::TEST_CLASS_HASH,
        // erc1155
        dojo_erc::erc1155::systems::ERC1155SetApprovalForAll::TEST_CLASS_HASH,
        briq_protocol::briq_token::systems::ERC1155MintBurn::TEST_CLASS_HASH,
        // erc721
        dojo_erc::erc721::systems::ERC721Approve::TEST_CLASS_HASH,
        dojo_erc::erc721::systems::ERC721SetApprovalForAll::TEST_CLASS_HASH,
        dojo_erc::erc721::systems::ERC721TransferFrom::TEST_CLASS_HASH,
        // briq_token
        briq_protocol::briq_token::systems::BriqTokenSafeTransferFrom::TEST_CLASS_HASH,
        briq_protocol::briq_token::systems::BriqTokenSafeBatchTransferFrom::TEST_CLASS_HASH,
        // set_nft
        briq_protocol::set_nft::systems::set_nft_assembly::TEST_CLASS_HASH,
        briq_protocol::set_nft::systems::set_nft_disassembly::TEST_CLASS_HASH,
        // shape_verifier
        briq_protocol::shape_verifier::register_shape_verifier::TEST_CLASS_HASH,
        briq_protocol::shape_verifier::shape_verifier_system::TEST_CLASS_HASH,
        // briq_factory
        briq_protocol::briq_factory::systems::BriqFactoryMint::TEST_CLASS_HASH,
        briq_protocol::briq_factory::systems::BriqFactoryInitialize::TEST_CLASS_HASH,
        // attributes
        briq_protocol::attributes::collection::create_collection::TEST_CLASS_HASH,
        // unboxing
        briq_protocol::box_nft::unboxing::box_unboxing::TEST_CLASS_HASH,
    ];

    let world = spawn_test_world(components, systems);

    //
    // set-up writer rights
    //

    world.grant_writer('WorldConfig', 'SetupWorld');

    world.grant_writer('Collection', 'create_collection');

    // ***************************
    // ****  erc1155   
    // ***************************

    //  erc_1155_balance
    world.grant_writer('ERC1155Balance', 'ERC1155MintBurn');

    // operator_approval
    world.grant_writer('OperatorApproval', 'ERC1155SetApprovalForAll');

    // ***************************
    // ****  erc721 
    // ***************************

    //  erc_721_balance
    world.grant_writer('ERC721Balance', 'ERC721TransferFrom');

    // erc_721_owner
    world.grant_writer('ERC721Owner', 'ERC721TransferFrom');

    // erc_721_token_approval
    world.grant_writer('ERC721TokenApproval', 'ERC721Approve');
    world.grant_writer('ERC721TokenApproval', 'ERC721TransferFrom');

    // ***************************
    // **** set_nft (erc721) 
    // ***************************

    //  set_nft_assembly
    world.grant_writer('ERC721Balance', 'set_nft_assembly');
    world.grant_writer('ERC721Owner', 'set_nft_assembly');
    world.grant_writer('ERC1155Balance', 'set_nft_assembly');

    // set_nft_disassembly
    world.grant_writer('ERC721Owner', 'set_nft_disassembly');
    world.grant_writer('ERC721Balance', 'set_nft_disassembly');
    world.grant_writer('ERC1155Balance', 'set_nft_disassembly');

    // ***************************
    // **** box_nft
    // ***************************

    world.grant_writer('ERC1155Balance', 'box_unboxing');

    // ***************************
    // **** shape_verifier
    // ***************************

    world.grant_writer('ERC1155Balance', 'shape_verifier_system');

    world
}


fn deploy_contracts(
    world: IWorldDispatcher,
) -> (ContractAddress, ContractAddress, ContractAddress, ContractAddress) {
    let constructor_calldata = array![world.contract_address.into()];

    let (briq, _) = deploy_syscall(
        BriqToken::TEST_CLASS_HASH.try_into().unwrap(), 0, constructor_calldata.span(), false
    )
        .expect('error deploying');

    let (set, _) = deploy_syscall(
        SetNft::TEST_CLASS_HASH.try_into().unwrap(), 0, constructor_calldata.span(), false
    )
        .expect('error deploying');

    let (booklet, _) = deploy_syscall(
        briq_protocol::generic_erc1155::GenericERC1155::TEST_CLASS_HASH.try_into().unwrap(),
        0,
        constructor_calldata.span(),
        false
    )
        .expect('error deploying');

    let (box, _) = deploy_syscall(
        briq_protocol::generic_erc1155::GenericERC1155::TEST_CLASS_HASH.try_into().unwrap(),
        0,
        constructor_calldata.span(),
        false
    )
        .expect('error deploying');

    (briq, set, booklet, box)
}

#[derive(Copy, Drop)]
struct DefaultWorld {
    world: IWorldDispatcher,
    briq_token: IERC1155Dispatcher,
    set_nft: IERC721Dispatcher,
    booklet: IERC1155Dispatcher,
    box_nft: IERC1155Dispatcher,
}

fn deploy_default_world() -> DefaultWorld {
    impersonate(WORLD_ADMIN());

    let world = spawn_world();
    let (briq, set, booklet, box) = deploy_contracts(world);
    world
        .execute(
            'SetupWorld',
            (array![
                TREASURY().into(),
                briq.into(),
                set.into(),
                booklet.into(),
                box.into(),
            ])
        );
    DefaultWorld {
        world,
        briq_token: IERC1155Dispatcher { contract_address: briq },
        set_nft: IERC721Dispatcher { contract_address: set },
        booklet: IERC1155Dispatcher { contract_address: booklet },
        box_nft: IERC1155Dispatcher { contract_address: box },
    }
}

#[test]
#[available_gas(30000000)]
fn test_deploy_default_world() {
    let DefaultWorld{world, briq_token, set_nft, .. } = deploy_default_world();
    assert(get!(world, (SYSTEM_CONFIG_ID), WorldConfig).briq == 0x3.try_into().unwrap(), 'totoro');
    assert(get!(world, (SYSTEM_CONFIG_ID), WorldConfig).set == 0x4.try_into().unwrap(), 'totoro');
}


fn mint_briqs(world: IWorldDispatcher, owner: ContractAddress, material: felt252, amount: u128) {
    let old_caller = get_contract_address();
    set_contract_address(WORLD_ADMIN());

    world
        .execute(
            'ERC1155MintBurn',
            (array![
                WORLD_ADMIN().into(),
                get!(world, (SYSTEM_CONFIG_ID), WorldConfig).briq.into(),
                0,
                owner.into(),
                1,
                material,
                1,
                amount.into()
            ])
        );
    set_contract_address(old_caller);
}
