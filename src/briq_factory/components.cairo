use starknet::ContractAddress;
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use zeroable::Zeroable;
use array::{ArrayTrait, SpanTrait};
use option::OptionTrait;
use traits::{Into, TryInto};

use briq_protocol::world_config::SYSTEM_CONFIG_ID;

use briq_protocol::briq_factory::constants::{
    DECIMALS, INFLECTION_POINT, SLOPE, RAW_FLOOR, LOWER_FLOOR, LOWER_SLOPE, DECAY_PER_SECOND,
    SURGE_SLOPE, MINIMAL_SURGE, SURGE_DECAY_PER_SECOND, MIN_PURCHASE, BRIQ_MATERIAL
};

use briq_protocol::felt_math::{FeltOrd, FeltDiv};

use debug::PrintTrait;

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct BriqFactoryStore {
    #[key]
    store_id: u64,
    buy_token: ContractAddress,
    last_stored_t: felt252,
    surge_t: felt252,
    last_purchase_time: u64,
}

trait BriqFactoryTrait {
    fn get_briq_factory(world: IWorldDispatcher) -> BriqFactoryStore;
    fn set_briq_factory(world: IWorldDispatcher, new_store: BriqFactoryStore);

    fn get_current_t(self: @BriqFactoryStore) -> felt252;
    fn get_surge_t(self: @BriqFactoryStore) -> felt252;
    fn get_surge_price(self: @BriqFactoryStore, amount: felt252) -> felt252;
    fn get_price(self: @BriqFactoryStore, amount: felt252) -> felt252;
    fn get_lin_integral(
        self: @BriqFactoryStore, slope: felt252, floor: felt252, t2: felt252, t1: felt252
    ) -> felt252;
    fn get_lin_integral_negative_floor(
        self: @BriqFactoryStore, slope: felt252, floor: felt252, t2: felt252, t1: felt252
    ) -> felt252;
    fn integrate(self: @BriqFactoryStore, t: felt252, amount: felt252) -> felt252;
}

// #[generate_trait]
impl BriqFactoryStoreImpl of BriqFactoryTrait {
    #[always(inline)]
    fn get_briq_factory(world: IWorldDispatcher) -> BriqFactoryStore {
        get!(world, (SYSTEM_CONFIG_ID), BriqFactoryStore)
    }

    #[always(inline)]
    fn set_briq_factory(world: IWorldDispatcher, new_store: BriqFactoryStore) {
        set!(world, (new_store));
    }

    fn get_current_t(self: @BriqFactoryStore) -> felt252 {
        let store = *self; // TODO: clean this up

        let time_since_last_purchase: felt252 = (starknet::info::get_block_timestamp()
            - store.last_purchase_time)
            .into();
        let decay = time_since_last_purchase * DECAY_PER_SECOND();

        if store.last_stored_t <= decay {
            0
        } else {
            store.last_stored_t - decay
        }
    }

    fn get_surge_t(self: @BriqFactoryStore) -> felt252 {
        let store = *self; // TODO: clean this up

        let time_since_last_purchase: felt252 = (starknet::info::get_block_timestamp()
            - store.last_purchase_time)
            .into();

        let decay = time_since_last_purchase * SURGE_DECAY_PER_SECOND();

        if store.surge_t <= decay {
            0
        } else {
            store.surge_t - decay
        }
    }

    fn get_surge_price(self: @BriqFactoryStore, amount: felt252) -> felt252 {
        let surge_t = self.get_surge_t();

        if (surge_t + amount) <= MINIMAL_SURGE() {
            return 0;
        };

        if surge_t > MINIMAL_SURGE() {
            self
                .get_lin_integral(
                    SURGE_SLOPE(), 0, surge_t - MINIMAL_SURGE(), surge_t + amount - MINIMAL_SURGE()
                )
        } else {
            self.get_lin_integral(SURGE_SLOPE(), 0, 0, surge_t + amount - MINIMAL_SURGE())
        }
    }


    fn get_price(self: @BriqFactoryStore, amount: felt252) -> felt252 {
        let t = self.get_current_t();
        let price = self.integrate(t, amount * DECIMALS());
        let surge = self.get_surge_price(amount * DECIMALS());

        price + surge
    }

    fn get_lin_integral(
        self: @BriqFactoryStore, slope: felt252, floor: felt252, t2: felt252, t1: felt252,
    ) -> felt252 {
        assert(t2 < t1, 't1 >= t2');
        // briq machine broke above 10^12 bricks of demand.
        assert(t2 < DECIMALS() * 1000000000000, 't2 >= 10**12');
        assert(t1 - t2 < DECIMALS() * 10000000000, 't1-t2 >= 10**10');

        // Integral between t2 and t1:
        // slope * t1 * t1 / 2 + floor * t1 - (slope * t2 * t2 / 2 + floor * t2);
        // Factored as slope * (t1 + t2) * (t1 - t2) / 2 + floor * (t1 - t2);
        // Then adding divisors for decimals, trying to avoid overflows and precision loss.

        let interm = slope * (t1 + t2);
        let q = interm / DECIMALS();
        let interm = q * (t1 - t2);
        let q = interm / DECIMALS() / 2;

        let floor_q = floor * (t1 - t2) / DECIMALS();
        q + floor_q
    }


    fn get_lin_integral_negative_floor(
        self: @BriqFactoryStore, slope: felt252, floor: felt252, t2: felt252, t1: felt252,
    ) -> felt252 {
        assert(t2 < t1, 't1 >= t2');
        // briq machine broke above 10^12 bricks of demand.
        assert(t2 < DECIMALS() * 1000000000000, 't2 >= 10**12');
        assert(t1 - t2 < DECIMALS() * 10000000000, 't1-t2 >= 10**10');

        // Integral between t2 and t1:
        // slope * t1 * t1 / 2 + floor * t1 - (slope * t2 * t2 / 2 + floor * t2);
        // Factored as slope * (t1 + t2) * (t1 - t2) / 2 + floor * (t1 - t2);
        // Then adding divisors for decimals, trying to avoid overflows and precision loss.

        let interm = slope * (t1 + t2);
        let q = interm / DECIMALS();
        let interm = q * (t1 - t2);
        let q = interm / DECIMALS() / 2;
        // Floor is negative. t2 < t1 so invert these, then subtract instead of adding.
        let floor_q = floor * (t2 - t1) / DECIMALS();
        q - floor_q
    }


    fn integrate(self: @BriqFactoryStore, t: felt252, amount: felt252) -> felt252 {
        if (t + amount) <= INFLECTION_POINT() {
            return self.get_lin_integral(LOWER_SLOPE(), LOWER_FLOOR(), t, t + amount);
        }

        if INFLECTION_POINT() <= t {
            return self.get_lin_integral_negative_floor(SLOPE(), RAW_FLOOR(), t, t + amount);
        }

        self.get_lin_integral(LOWER_SLOPE(), LOWER_FLOOR(), t, INFLECTION_POINT())
            + self
                .get_lin_integral_negative_floor(
                    SLOPE(), RAW_FLOOR(), INFLECTION_POINT(), t + amount
                )
    }
}
