use core::zeroable::Zeroable;
use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;

use starknet::testing::{set_caller_address, set_contract_address, set_block_timestamp};
use starknet::ContractAddress;
use starknet::info::get_block_timestamp;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use briq_protocol::world_config::{WorldConfig, SYSTEM_CONFIG_ID};
use briq_protocol::tests::test_utils::{WORLD_ADMIN, DefaultWorld, deploy_default_world, mint_briqs};

use dojo_erc::erc_common::utils::system_calldata;

use briq_protocol::briq_factory::systems::{BriqFactoryInitializeParams};
use briq_protocol::briq_factory::constants::{
    DECIMALS, LOWER_FLOOR, LOWER_SLOPE, INFLECTION_POINT, DECAY_PER_SECOND, MINIMAL_SURGE, SLOPE,
    RAW_FLOOR
};
use briq_protocol::briq_factory::components::{BriqFactoryStore, BriqFactoryTrait};

use briq_protocol::felt_math::{FeltOrd, FeltDiv};

use debug::PrintTrait;

fn default_owner() -> ContractAddress {
    starknet::contract_address_const::<0xcafe>()
}

fn eth_address() -> ContractAddress {
    starknet::contract_address_const::<0xeeee>()
}

fn init_briq_factory(world: IWorldDispatcher, t: felt252, surge_t: felt252,) -> BriqFactoryStore {
    world
        .execute(
            'BriqFactoryInitialize',
            system_calldata(BriqFactoryInitializeParams { t, surge_t, buy_token: eth_address() })
        );
    BriqFactoryTrait::get_briq_factory(world)
}

#[test]
#[available_gas(90000000)]
fn test_briq_factory_init() {
    let DefaultWorld{world, .. } = deploy_default_world();
    let briq_factory = init_briq_factory(world, DECIMALS(), DECIMALS());

    assert(briq_factory.buy_token == eth_address(), 'invalid buy_token');
    assert(briq_factory.surge_t == DECIMALS(), 'invalid surge_t');
    assert(briq_factory.last_stored_t == DECIMALS(), 'invalid last_stored_t');
}


#[test]
#[available_gas(90000000)]
fn test_briq_factory_integrate() {
    let DefaultWorld{world, .. } = deploy_default_world();

    let briq_factory = init_briq_factory(world, 0, 0);
    assert(briq_factory.get_current_t() == 0, 'invalid current_t');

    let price_for_1 = briq_factory.get_price(1);
    let expected_price = LOWER_FLOOR() + LOWER_SLOPE() / 2;
    //10000025000000
    assert(price_for_1 == expected_price, 'invalid price 1');

    let price_for_1000 = briq_factory.get_price(1000);
    // 10025000000000000
    assert(price_for_1000 == 10025000000000000, 'invalid price 1000');
}


#[test]
#[available_gas(90000000)]
fn test_briq_factory_integrate_above_inflection_point() {
    let DefaultWorld{world, .. } = deploy_default_world();

    let briq_factory = init_briq_factory(world, INFLECTION_POINT(), 0);
    let price_for_1000 = briq_factory.get_price(1000);

    let expected_price_1000 = 3005 * 10000000000000; // 0.03005 * 10**18
    assert(price_for_1000 == expected_price_1000, 'invalid price 1000');

    let timestamp = get_block_timestamp();
    set_block_timestamp(timestamp + 10000);

    let current_t = briq_factory.get_current_t();
    let expected_current_t = INFLECTION_POINT() - DECAY_PER_SECOND() * 10000;
    assert(current_t == expected_current_t, 'invalid current_t');

    let timestamp = get_block_timestamp();
    set_block_timestamp(timestamp + 3600 * 24 * 365 * 5);
    assert(briq_factory.get_current_t() == 0, 'invalid current_t 1y');
    assert(briq_factory.get_surge_t() == 0, 'invalid surge_t 1y');
}


#[test]
#[available_gas(90000000)]
fn test_briq_factory_surge() {
    let DefaultWorld{world, .. } = deploy_default_world();

    let briq_factory = init_briq_factory(world, 0, 0);
    let expected = 10000025000000; //price_below_ip(0, 1)
    assert(briq_factory.get_price(1) == expected, 'invalid price A');

    let briq_factory = init_briq_factory(world, 0, MINIMAL_SURGE());
    let expected = 10000075000000; // price_below_ip(0, 1) + 10**8 / 2
    assert(briq_factory.get_price(1) == expected, 'invalid price B');

    let briq_factory = init_briq_factory(world, 0, 0);
    let expected = 4062500000000000000; // price_below_ip(0, 250000)
    assert(briq_factory.get_price(250000) == expected, 'invalid price C');

    let briq_factory = init_briq_factory(world, 0, 0);
    let expected = 4062522500075000000; // price_below_ip(0, 250001) + 10**8 // 2
    assert(briq_factory.get_price(250001) == expected, 'invalid price D');

    let briq_factory = init_briq_factory(world, 0, 200000 * DECIMALS());
    let expected = 1375000000000000000; // price_below_ip(0, 100000) + 10**8 * 50000 * 50000 // 2
    assert(briq_factory.get_price(100000) == expected, 'invalid price E');

    let briq_factory = init_briq_factory(world, 0, 250000 * DECIMALS());
    let expected = 250000 * DECIMALS();
    assert(briq_factory.get_surge_t() == expected, 'invalid surge_t A');

    let timestamp = get_block_timestamp();
    set_block_timestamp(timestamp + 3600 * 24 * 3);

    //  Has about halved in half a week
    let expected = 250000 * DECIMALS() - 4134 * 100000000000000 * 3600 * 24 * 3;
    assert(briq_factory.get_surge_t() == expected, 'invalid surge_t B');

    let timestamp = get_block_timestamp();
    set_block_timestamp(timestamp + 3600 * 24 * 12);
    assert(briq_factory.get_surge_t() == 0, 'invalid surge_t C');
}

#[test]
#[available_gas(30000000)]
fn test_inflection_point() {
    let DefaultWorld{world, .. } = deploy_default_world();

    let briq_factory = init_briq_factory(world, INFLECTION_POINT() - 100000 * DECIMALS(), 0);

    // Compute the average price-per-briq below the inflection point
    let lower_price_per_briq = LOWER_FLOOR()
        + LOWER_SLOPE() * (INFLECTION_POINT() / DECIMALS() - 100000 / 2);

    assert(
        briq_factory.get_price(100000) == lower_price_per_briq * 100000, 'bad price calculation 1'
    );

    // And the price per briq above the curve
    let higher_price_per_briq = RAW_FLOOR()
        + SLOPE() * (INFLECTION_POINT() / DECIMALS() + 100000 / 2);

    // Check that integrating across the inflection point works
    assert(
        briq_factory.get_price(200000) == lower_price_per_briq * 100000
            + higher_price_per_briq * 100000,
        'bad price calculation 2'
    );
}

#[test]
#[available_gas(30000000)]
fn test_overflows_ok() {
    let DefaultWorld{world, .. } = deploy_default_world();

    let briq_factory = init_briq_factory(world, INFLECTION_POINT(), 0);

    // Try to check the max amount of briqs that can be bought
    assert(
        briq_factory
            .get_price(10000000000 - 1) == 0x204fd8f4cf25bc04864d1100, // I trust the computer
        'bad price calculation 0'
    );

    //Try with the maximum value allowed and ensure that we don't get overflows.
    let briq_factory = init_briq_factory(world, DECIMALS() * (1000000000000 - 1), 0);

    assert(
        briq_factory.get_price(1) == RAW_FLOOR()
            + (SLOPE() * (1000000000000 - 1) + SLOPE() * (1000000000000)) / 2,
        'bad price calculation'
    );
}

#[test]
#[available_gas(30000000)]
#[should_panic(expected: ('t1-t2 >= 10**10',))]
fn test_overflows_bad_max_amnt() {
    let DefaultWorld{world, .. } = deploy_default_world();
    let briq_factory = init_briq_factory(world, INFLECTION_POINT(), 0);

    briq_factory.get_price(10000000000);
}

#[test]
#[available_gas(30000000)]
#[should_panic(expected: ('t2 >= 10**12',))]
fn test_overflows_bad_max_t() {
    let DefaultWorld{world, .. } = deploy_default_world();
    let briq_factory = init_briq_factory(world, 1000000000000 * DECIMALS(), 0);

    briq_factory.get_price(1);
}

#[test]
#[available_gas(90000000)]
fn test_briq_factory_buy() {// TODO deploy buy token & test buy
}
