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

use dojo_erc::erc_common::utils::system_calldata;

use briq_protocol::briq_factory::systems::{BriqFactoryInitializeParams};
use briq_protocol::briq_factory::constants::{DECIMALS};
use briq_protocol::briq_factory::components::{BriqFactoryStoreTrait};


use debug::PrintTrait;

fn default_owner() -> ContractAddress {
    starknet::contract_address_const::<0xcafe>()
}

fn eth_address() -> ContractAddress {
    starknet::contract_address_const::<0xeeee>()
}

#[test]
#[available_gas(30000000)]
fn test_briq_factory() {
    let DefaultWorld{world, .. } = deploy_default_world();

    world
        .execute(
            'BriqFactoryInitialize',
            system_calldata(
                BriqFactoryInitializeParams {
                    t: DECIMALS(), surge_t: DECIMALS(), buy_token: eth_address()
                }
            )
        );

    let store = BriqFactoryStoreTrait::get_store(world);

    assert(store.buy_token == eth_address(), 'invalid buy_token');
    assert(store.surge_t == DECIMALS(), 'invalid surge_t');
    assert(store.last_stored_t == DECIMALS(), 'invalid last_stored_t');

    assert(BriqFactoryStoreTrait::integrate(world, 6478383, 1) == 647838450000000000000, 'bad T');
    assert(
        BriqFactoryStoreTrait::integrate(world, 6478383, 347174) == 230939137995400000000000000,
        'bad T'
    );
}
