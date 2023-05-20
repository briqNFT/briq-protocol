%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from contracts.upgrades.upgradable_mixin import (
    getAdmin_,
    getImplementation_,
    upgradeImplementation_,
    setRootAdmin_,
)

from contracts.utilities.authorization import _onlyAdmin

from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.math import (unsigned_div_rem, assert_lt_felt)
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address, get_block_timestamp)

from contracts.vendor.openzeppelin.token.erc20.IERC20 import IERC20
from contracts.utilities.Uint256_felt_conv import _felt_to_uint
from contracts.ecosystem.to_briq import (_briq_address, getBriqAddress_, setBriqAddress_,)


@storage_var
func last_stored_t() -> (res: felt) {
}

@storage_var
func surge_t() -> (res: felt) {
}

@storage_var
func last_purchase_time() -> (res: felt) {
}

@storage_var
func erc20_address() -> (addr: felt) {
}

const decimals = 10**18; // 18 decimals
const estimated_fair_price = 5 * 10**13; // 0.01 for 200 briqs
const slope = 5 * 10**8; // Slope: Buying 100 000 briqs increases price for 200 briqs by 0.01, so pp by 0.00005
const inflection_point = 60000 * 10**18; // The inflection point is T such that T = (estimated_fair_price - raw_foor) / slope
const raw_floor = 2 * 10**13;

const lower_floor = 3 * 10**13; // should include raw_floor
const lower_slope = 333333333; // (estimated_fair_price - lower_floor) / inflection_point;

const decay_per_second = 10**10; // decay: for each second, reduce the price by so many wei (there are 24*3600*365 = 31536000 seconds in a year)

const surge_slope = 10**12;
const minimal_surge = 10000 * 10**18;
const surge_decay_per_second = 2315 * 10**14;

const briq_material = 1;
const minimum_purchase = 200;

@contract_interface
namespace IBriqContract {
    func mintFT_(owner: felt, material: felt, qty: felt) {
    }
}

@external
func initialise{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(t: felt, surget: felt, erc20: felt) {
    _onlyAdmin();

    last_stored_t.write(t);
    surge_t.write(surget);
    erc20_address.write(erc20);

    let (tmstp) = get_block_timestamp();
    last_purchase_time.write(tmstp);
    return ();
}

@view
func get_current_t{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> (t: felt) {
    let (t) = last_stored_t.read();
    let (tmstp) = get_block_timestamp();
    let (last_pt) = last_purchase_time.read();
    let time_since_last_purchase = tmstp - last_pt;
    let decay = time_since_last_purchase * decay_per_second;

    let cmp = is_le_felt(t, decay);
    if (cmp == 1) {
        return (0,);
    }
    return (t - decay,);
}

@view
func get_surge_t{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> (t: felt) {
    let (t) = surge_t.read();
    let (tmstp) = get_block_timestamp();
    let (last_pt) = last_purchase_time.read();
    let time_since_last_purchase = tmstp - last_pt;
    let decay = time_since_last_purchase * surge_decay_per_second;

    let cmp = is_le_felt(t, decay);
    if (cmp == 1) {
        return (0,);
    }
    return (t - decay,);
}

func get_surge_price{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(amount: felt) -> felt {
    let (t) = get_surge_t();
    let surge_mode = is_le_felt(t + amount, minimal_surge);
    if (surge_mode == 1) {
        return 0;
    }
    let full_surge = is_le_felt(t, minimal_surge);
    if (full_surge == 0) {
        return get_lin_integral(surge_slope, 0, t - minimal_surge, t + amount - minimal_surge);
    }
    return get_lin_integral(surge_slope, 0, 0, t + amount - minimal_surge);
}

@view
func get_price{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(amount: felt) -> (price: felt, ) {
    alloc_locals;
    let (t) = get_current_t();
    let price = integrate(t, amount * decimals);
    let surge = get_surge_price(amount * decimals);
    return (price + surge,);
}


// This doesn't account for surge and is mostly for debug purposes.
@view
func get_price_at_t{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(t: felt, amount: felt) -> (price: felt, ) {
    let price = integrate(t, amount * decimals);
    return (price,);
}


@external
func buy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(amount: felt) {
    alloc_locals;
    _onlyAdmin();

    with_attr error_message("At least 200 briqs must be purchased at a time") {
        assert_lt_felt(minimum_purchase, amount);
    }

    let (price) = get_price(amount);
    let (tmstp) = get_block_timestamp();
    last_purchase_time.write(tmstp);
    
    let (t) = get_current_t();
    last_stored_t.write(t + amount * decimals);

    let (csurget) = get_surge_t();
    surge_t.write(csurget + amount * decimals);

    let (buyer) = get_caller_address();
    transfer_funds(buyer, price);

    let (briq_addr) = _briq_address.read();
    IBriqContract.mintFT_(briq_addr, buyer, briq_material, amount);

    return ();
}

func transfer_funds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(buyer: felt, price: felt) {
    let (price_uint) = _felt_to_uint(price);
    let (contract_address) = get_contract_address();
    let (erc20_addr) = erc20_address.read();
    with_attr error_message("Could not transfer funds") {
        IERC20.transferFrom(erc20_addr, buyer, contract_address, price_uint);
    }
    return ();
}

func get_lin_integral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(slope: felt, floor: felt, t2: felt, t1: felt) -> felt {
    assert_lt_felt(t2, t1);
    // briq machine broke above 10^12 bricks of demand.
    assert_lt_felt(t2, 10**18 * 10**12);
    assert_lt_felt(t1 - t2, 10**18 * 10**10);
    //return slope * t1 * t1 / 2 + floor * t1 - 
    //    slope * t2 * t2 / 2 + floor * t2;
    // slightly factored form for lower numbers
    let a_interm = slope * (t1 + t2);
    let (q, r) = unsigned_div_rem(a_interm, decimals);
    let a_interm = q * (t1 - t2);
    let (q, r) = unsigned_div_rem(a_interm, decimals);
    let (q, r) = unsigned_div_rem(q, 2);
    let (floor_q, r) = unsigned_div_rem(floor * (t1 - t2), decimals);
    let interm_value = q + floor_q;
    return interm_value;
}

func integrate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(t: felt, amount: felt) -> felt {
    alloc_locals;

    let is_lower_part = is_le_felt(t + amount, inflection_point);
    if (is_lower_part == 1) {
        return get_lin_integral(lower_slope, lower_floor, t, t + amount);
    }

    let is_higher_part = is_le_felt(inflection_point, t);
    if (is_higher_part == 1) {
        return get_lin_integral(slope, raw_floor, t, t + amount);
    }

    return get_lin_integral(lower_slope, lower_floor, t, inflection_point) +
        get_lin_integral(slope, raw_floor, inflection_point, t + amount);
}
