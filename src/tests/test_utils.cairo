use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;

use starknet::testing::{set_caller_address, set_contract_address};
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

fn WORLD_ADMIN() -> ContractAddress {
    0x420.try_into().unwrap()
}

fn spawn_world() -> IWorldDispatcher {
    // components
    let mut components = array![
        dojo_erc::erc1155::components::erc_1155_balance::TEST_CLASS_HASH,
        dojo_erc::erc1155::components::operator_approval::TEST_CLASS_HASH,
        dojo_erc::erc721::components::erc_721_balance::TEST_CLASS_HASH,
        dojo_erc::erc721::components::erc_721_owner::TEST_CLASS_HASH,
        dojo_erc::erc721::components::erc_721_token_approval::TEST_CLASS_HASH,
        briq_protocol::attributes::collection::collection::TEST_CLASS_HASH,
        briq_protocol::world_config::world_config::TEST_CLASS_HASH,
    ];
    // systems
    let mut systems = array![
        dojo_erc::erc1155::systems::ERC1155SetApprovalForAll::TEST_CLASS_HASH,
        briq_protocol::briq_token::systems::BriqTokenSafeTransferFrom::TEST_CLASS_HASH,
        briq_protocol::briq_token::systems::BriqTokenSafeBatchTransferFrom::TEST_CLASS_HASH,
        briq_protocol::briq_token::systems::ERC1155MintBurn::TEST_CLASS_HASH,
        dojo_erc::erc721::systems::ERC721Approve::TEST_CLASS_HASH,
        dojo_erc::erc721::systems::ERC721SetApprovalForAll::TEST_CLASS_HASH,
        dojo_erc::erc721::systems::ERC721TransferFrom::TEST_CLASS_HASH,
        briq_protocol::set_nft::systems::set_nft_assembly::TEST_CLASS_HASH,
        briq_protocol::set_nft::systems::set_nft_disassembly::TEST_CLASS_HASH,
        briq_protocol::attributes::collection::create_collection::TEST_CLASS_HASH,
        briq_protocol::check_shape::register_shape_verifier::TEST_CLASS_HASH,
        briq_protocol::box_nft::unboxing::box_unboxing::TEST_CLASS_HASH,
        briq_protocol::world_config::SetupWorld::TEST_CLASS_HASH,
        briq_protocol::briq_factory::systems::BriqFactoryMint::TEST_CLASS_HASH,
        briq_protocol::briq_factory::systems::BriqFactoryInitialize::TEST_CLASS_HASH,
    ];

    let world = spawn_test_world(components, systems);
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
    set_caller_address(WORLD_ADMIN());
    set_contract_address(WORLD_ADMIN());

    let world = spawn_world();
    let (briq, set, booklet, box) = deploy_contracts(world);
    world
        .execute(
            'SetupWorld',
            (array![WORLD_ADMIN().into(), briq.into(), set.into(), booklet.into(), box.into(), ])
        );
    DefaultWorld {
        world, briq_token: IERC1155Dispatcher {
            contract_address: briq
            }, set_nft: IERC721Dispatcher {
            contract_address: set
            }, booklet: IERC1155Dispatcher {
            contract_address: booklet
            }, box_nft: IERC1155Dispatcher {
            contract_address: box
        },
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
