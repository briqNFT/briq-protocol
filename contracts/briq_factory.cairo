%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from contracts.upgrades.upgradable_mixin import (
    getAdmin_,
    getImplementation_,
    upgradeImplementation_,
    setRootAdmin_,
)

from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.math import (unsigned_div_rem, assert_lt_felt)
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address, get_block_timestamp)

from contracts.vendor.openzeppelin.token.erc20.IERC20 import IERC20
from contracts.utilities.Uint256_felt_conv import _felt_to_uint
from contracts.ecosystem.to_briq import _briq_address


@storage_var
func last_stored_t() -> (res: felt) {
}

@storage_var
func last_purchase_time() -> (res: felt) {
}

@storage_var
func erc20_address() -> (addr: felt) {
}

const decimals = 10**18; // 18 decimals
const estimated_fair_price = 0;//100000000000000000; // 0.1
const slope = 10**14; // Slope: Buying 1000 briqs increases price by 0.1, so one briq bu 0.0001
const floor = 10**11;
const decay_per_second = 10**10; // decay: for each second, reduce the price by so many wei (there are 24*3600*365 = 31536000 seconds in a year)
const briq_material = 1;

@contract_interface
namespace IBriqContract {
    func mintFT_(owner: felt, material: felt, qty: felt) {
    }
}



@external
func initialise{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(t: felt) {
    // TODO: only admin
    last_stored_t.write(t);
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
func get_price{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(amount: felt) -> (price: felt, ) {
    let (t) = get_current_t();
    let price = integrate(t, amount * decimals);
    return (price,);
}

@external
func buy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(amount: felt) {
    alloc_locals;
    let (t) = get_current_t();
    let price = integrate(t, amount * decimals);
    let (tmstp) = get_block_timestamp();
    last_purchase_time.write(tmstp);
    last_stored_t.write(t + amount * decimals);

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

func get_exp_integral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(t2: felt, t1: felt) -> felt {
    return 0; //return (math.exp(x / self.estimated_fair_price - 1) * self.a * self.estimated_fair_price * self.estimated_fair_price + self.b * x);
}

func get_lin_integral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(t2: felt, t1: felt) -> felt {
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
    let is_lower_part = is_le_felt(t + amount, estimated_fair_price);
    if (is_lower_part == 1) {
        return get_exp_integral(t, t + amount);
    }
    let is_higher_part = is_le_felt(estimated_fair_price, t - 1);
    if (is_higher_part == 1) {
        return get_lin_integral(t, t + amount);
    }

    return get_exp_integral(t, estimated_fair_price) +
        get_lin_integral(estimated_fair_price, t + amount);
}
