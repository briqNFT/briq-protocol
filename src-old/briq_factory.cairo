use starknet::info::get_block_timestamp;

#[contract]
mod BriqFactory {
    struct Storage {
        last_stored_t: u128,
        last_purchase_time: u64,
    }
    const decimals: u128 = 1000000000000000000; // 18 decimals
    const estimated_fair_price: u128 = 0;//100000000000000000; // 0.1
    const slope: u128 = 100000000000000;
    const minimum: u128 = 100000000000000;
    const decay_per_second: u128 = 10000000000; // some value

    #[external]
    fn initialise(t: u128) {
        last_stored_t::write(t);
    }

    #[view]
    fn get_current_t() -> u128 {
        let t = last_stored_t::read()
        let time_since_last_purchase = get_block_timestamp() - last_purchase_time::read();
        let decay = time_since_last_purchase * decay_per_second;
        if decay > t {
            return 0;
        }
        t - decay
    }

    #[view]
    fn get_unit_price() -> u128 {
        return 1;
    }

    #[external]
    fn buy(amount: u128) {
        let t = get_current_t();
        let price = integrate(t, amount);
        last_purchase_time::write(get_block_timestamp());
        last_stored_t::write(t + amount);

        // ACTUAL BUYING HERE
    }

    fn get_integral(t: u128) -> u128 {
        if t < estimated_fair_price {
            return get_exp_integral(t);
        }
        get_lin_integral(t)
    }

    fn get_exp_integral(t: u128) -> u128 {
        0//return (math.exp(x / self.estimated_fair_price - 1) * self.a * self.estimated_fair_price * self.estimated_fair_price + self.b * x);
    }

    fn get_lin_integral(t: u128) -> u128 {
        slope * t * t / 2 + minimum * t
        //return super().get_integral(x);
    }

    fn integrate(t: u128, amount: u128) -> u128 {
        get_integral(t + amount) - get_integral(t)
        //if t + amount <= estimated_fair_price || t > self.estimated_fair_price {
        //    get_integral(t + amount) - get_integral(t)
        //} else {
        //    return self.get_exp_integral(self.estimated_fair_price) - self.get_exp_integral(t) + self.get_lin_integral(
        //        t + amount) - self.get_lin_integral(self.estimated_fair_price)
        //}
    }
}
