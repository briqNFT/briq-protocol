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
use dojo_erc::erc1155::models::ERC1155BalanceTrait;

use briq_protocol::tests::test_utils::{
    WORLD_ADMIN, DEFAULT_OWNER, ZERO, DefaultWorld, spawn_briq_test_world, mint_briqs, impersonate
};
use briq_protocol::world_config::get_world_config;

use debug::PrintTrait;

use briq_protocol::migrate::MigrateAssetsParams;

#[test]
#[available_gas(3000000000)]
fn test_migrate_signature() {
    let DefaultWorld{world, .. } = spawn_briq_test_world();

    world
        .execute(
            'migrate_assets',
            system_calldata(
                MigrateAssetsParams {
                    migrator: 0x69cfa382ea9d2e81aea2d868b0dd372f70f523fa49a765f4da320f38f9343b3
                        .try_into()
                        .unwrap(),
                    current_briqs: 271,
                    briqs_to_migrate: 50,
                    set_to_migrate: 0x0,
                    backend_signature_r: 0x7e3ef759fe84319b8b2bf01d0bad2e9a3f7ca015a7f79d31427a06a5dcd1021,
                    backend_signature_s: 0x3518d16d1abf68e6d5dc93c9461cb84750a1f181084837dba7b1568daa2a135,
                }
            )
        );
}
