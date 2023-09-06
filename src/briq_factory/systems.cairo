use core::array::SpanTrait;
use starknet::{ContractAddress, get_contract_address, get_caller_address};
use zeroable::Zeroable;
use array::ArrayTrait;
use option::OptionTrait;
use serde::Serde;
use clone::Clone;
use traits::{Into, TryInto};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use briq_protocol::briq_factory::constants::{
    DECIMALS, INFLECTION_POINT, SLOPE, RAW_FLOOR, LOWER_FLOOR, LOWER_SLOPE, DECAY_PER_SECOND,
    SURGE_SLOPE, MINIMAL_SURGE, SURGE_DECAY_PER_SECOND, MIN_PURCHASE, BRIQ_MATERIAL
};

use briq_protocol::briq_factory::components::{BriqFactoryStore, BriqFactoryTrait};

#[derive(Drop, PartialEq, starknet::Event)]
struct BriqsBought {
    buyer: ContractAddress,
    amount: u32,
    price: u128
}

#[event]
#[derive(Drop, starknet::Event)]
enum Event {
    BriqsBought: BriqsBought,
}

#[derive(Drop, Serde)]
struct BriqFactoryBuyParams {
    material: u64,
    amount: u32
}

#[system]
mod BriqFactoryMint {
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use array::ArrayTrait;
    use dojo::world::Context;
    use zeroable::Zeroable;
    use starknet::{ContractAddress, get_contract_address, get_caller_address, get_block_timestamp};

    use briq_protocol::world_config::{get_world_config};
    use briq_protocol::felt_math::{FeltOrd};
    use super::{
        BriqsBought, BriqFactoryTrait, BriqFactoryBuyParams, DECIMALS, MIN_PURCHASE, BRIQ_MATERIAL
    };
    #[event]
    use super::Event;
    use briq_protocol::world_config::AdminTrait;


    #[starknet::interface]
    trait IERC20<TState> {
        fn transferFrom(
            ref self: TState, spender: ContractAddress, recipient: ContractAddress, amount: u256
        );
    }

    fn execute(ctx: Context, params: BriqFactoryBuyParams) {
        let BriqFactoryBuyParams{material, amount: amount_u32 } = params;
        let amount: felt252 = amount_u32.into();
        assert(amount >= MIN_PURCHASE(), 'amount too low !');

        let mut briq_factory = BriqFactoryTrait::get_briq_factory(ctx.world);

        let price = briq_factory.get_price(amount);
        let t = briq_factory.get_current_t();
        let surge_t = briq_factory.get_surge_t();

        // Transfer funds to receiver wallet
        // TODO: use something other than the super-admin address for this.
        let world_config = get_world_config(ctx.world);
        let buyer = ctx.origin;
        IERC20Dispatcher { contract_address: briq_factory.buy_token }
            .transferFrom(buyer, world_config.treasury, price.into());

        // update store
        briq_factory.last_purchase_time = get_block_timestamp();
        briq_factory.last_stored_t = t + amount * DECIMALS();
        briq_factory.surge_t = surge_t + amount * DECIMALS();
        BriqFactoryTrait::set_briq_factory(ctx.world, briq_factory);

        //  mint briqs to buyer
        let amount_u128: u128 = amount.try_into().unwrap();
        briq_protocol::briq_token::systems::update_nocheck(
            ctx.world,
            buyer,
            world_config.briq,
            from: Zeroable::zero(),
            to: buyer,
            ids: array![BRIQ_MATERIAL()],
            amounts: array![amount_u128],
            data: array![]
        );

        emit!(
            ctx.world, BriqsBought { buyer, amount: amount_u32, price: price.try_into().unwrap() }
        );
    }
}

#[derive(Drop, Serde)]
struct BriqFactoryInitializeParams {
    t: felt252,
    surge_t: felt252,
    buy_token: ContractAddress
}

#[system]
mod BriqFactoryInitialize {
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use array::ArrayTrait;
    use dojo::world::Context;
    use zeroable::Zeroable;
    use starknet::ContractAddress;

    use super::BriqFactoryInitializeParams;
    use super::{BriqFactoryStore, BriqFactoryTrait};
    use briq_protocol::world_config::AdminTrait;


    fn execute(ctx: Context, params: BriqFactoryInitializeParams) {
        ctx.world.only_admins(@ctx.origin);

        let BriqFactoryInitializeParams{t, surge_t, buy_token } = params;

        let mut briq_factory = BriqFactoryTrait::get_briq_factory(ctx.world);

        briq_factory.last_stored_t = t;
        briq_factory.surge_t = surge_t;
        briq_factory.buy_token = buy_token;
        briq_factory.last_purchase_time = starknet::info::get_block_timestamp();

        BriqFactoryTrait::set_briq_factory(ctx.world, briq_factory);
    }
}

