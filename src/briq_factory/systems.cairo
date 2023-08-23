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
    BRIQ_FACTORY_CONFIG_ID, BRIQ_FACTORY_STORE_ID, DECIMALS, INFLECTION_POINT, SLOPE, RAW_FLOOR,
    LOWER_FLOOR, LOWER_SLOPE, DECAY_PER_SECOND, SURGE_SLOPE, MINIMAL_SURGE, SURGE_DECAY_PER_SECOND,
    MIN_PURCHASE, BRIQ_MATERIAL
};

use briq_protocol::briq_factory::components::{
    BriqFactoryConfig, BriqFactoryStore, BriqFactoryStoreTrait
};


#[derive(Drop, Serde)]
struct BriqFactoryBuyParams {
    material: u8,
    amount: u16
}

#[system]
mod BriqFactoryMint {
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use array::ArrayTrait;
    use dojo::world::Context;
    use zeroable::Zeroable;
    use starknet::{ContractAddress, get_contract_address, get_caller_address, get_block_timestamp};

    use briq_protocol::world_config::{AdminTrait, get_world_config};
    use briq_protocol::felt_math::{FeltOrd};
    use briq_protocol::briq_factory::events::BriqsBought;
    use super::{BriqFactoryStoreTrait, BriqFactoryBuyParams, DECIMALS, MIN_PURCHASE, BRIQ_MATERIAL};


    #[starknet::interface]
    trait IERC20<TState> {
        fn transfer_from(
            ref self: TState, spender: ContractAddress, recipient: ContractAddress, amount: u256
        );
    }

    #[starknet::interface]
    trait IBriq<TState> {
        fn mint(ref self: TState, to: ContractAddress, id: felt252, amount: u128, data: Array<u8>);
    }

    fn execute(ctx: Context, params: BriqFactoryBuyParams) {
        let BriqFactoryBuyParams{material, amount: amount_u16 } = params;
        let amount: felt252 = amount_u16.into();
        assert(amount >= MIN_PURCHASE(), 'amount too low !');

        // ?? This also guarantees that amount isn't above 2**128 which is important to avoid an attack on amount * decimals;

        let world_config = get_world_config(ctx.world);
        let store = BriqFactoryStoreTrait::get_store(ctx.world);
        let price = BriqFactoryStoreTrait::get_price(ctx.world, amount);
        let buyer = get_caller_address();
        let t = BriqFactoryStoreTrait::get_current_t(ctx.world);
        let surge_t = BriqFactoryStoreTrait::get_surge_t(ctx.world);

        // transfer buy_tokens from buyer to super_admin
        IERC20Dispatcher {
            contract_address: store.buy_token
        }.transfer_from(buyer, world_config.super_admin, price.into());

        // update store
        let mut store = BriqFactoryStoreTrait::get_store(ctx.world);
        store.last_purchase_time = get_block_timestamp();
        store.last_stored_t = t + amount * DECIMALS();
        store.surge_t = surge_t + amount * DECIMALS();
        BriqFactoryStoreTrait::set_store(ctx.world, store);

        //  mint briqs to buyer
        let token_id = BRIQ_MATERIAL();
        let amount_u128: u128 = amount.try_into().unwrap();
        let data: Array<u8> = array![];
        IBriqDispatcher {
            contract_address: world_config.briq
        }.mint(buyer, token_id, amount_u128, data);

        emit!(ctx.world, BriqsBought { buyer: buyer, amount: amount, price: price });
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

    use briq_protocol::world_config::AdminTrait;

    use super::BriqFactoryInitializeParams;
    use super::{BriqFactoryStore, BriqFactoryStoreTrait};


    fn execute(ctx: Context, params: BriqFactoryInitializeParams) {
        // TODO: safety check

        let BriqFactoryInitializeParams{t, surge_t, buy_token } = params;

        let mut store = BriqFactoryStoreTrait::get_store(ctx.world);

        store.last_stored_t = t;
        store.surge_t = surge_t;
        store.buy_token = buy_token;
        store.last_purchase_time = starknet::info::get_block_timestamp();

        BriqFactoryStoreTrait::set_store(ctx.world, store);
    }
}

