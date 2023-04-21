
use array::ArrayTrait;
use array::SpanTrait;

use briq_protocol::utils::check_gas;

use core::integer::u128_safe_divmod;
use core::integer::u128_as_non_zero;
use core::integer::u256_from_felt252;
use core::integer::u256_as_non_zero;
use core::integer::u256_safe_divmod;

use traits::Into;
use traits::TryInto;
use option::OptionTrait;

use briq_protocol::utils;

#[event]
fn URI(_value: Array<felt252>, _id: u256) {}

fn _getUrl(
    token_id: felt252,
    uri_p1: felt252,
    uri_p2: felt252,
    uri_p3: felt252,
    uri_p4: felt252,
) -> Array<felt252> { // -> uri
    //let (data_address) = get_label_location(label);
    //let (local uri_out: felt252*) = alloc();
    let mut uri_out = ArrayTrait::<felt252>::new();
    uri_out.append(uri_p1);
    uri_out.append(uri_p2);
    // TODO: change on a per-network basis?
    uri_out.append(uri_p3);
    
    let tok_as_ascii = felt_to_ascii_array(token_id);
    uri_out = insert_reverse(uri_out, tok_as_ascii.span());

    uri_out.append(uri_p4);

    return uri_out;
}

fn insert_reverse(mut out: Array<felt252>, mut data: Span<u256>) -> Array<felt252> {
    check_gas();
    if data.len() == 0 {
        return out;
    }
    let nb = *data.pop_back().unwrap();
    out.append(nb.try_into().unwrap());
    return insert_reverse(out, data);
}

fn felt_to_ascii_array(i: felt252) -> Array<u256> {
    let tok_u256 = u256_from_felt252(i);
    let out = ArrayTrait::<u256>::new();
    _felt_to_ascii_array(out, tok_u256)
}

fn _felt_to_ascii_array(mut out: Array<u256>, i: u256) -> Array<u256> {
    check_gas();
    let (q, r) = get_letter(i);
    out.append(r);
    if q == 0.into() {
        return out;
    }
    return _felt_to_ascii_array(out, q);
}

fn get_letter(
    i: u256,
) -> (u256, u256) {
    let (q, r) = u256_safe_divmod(i, u256_as_non_zero(10.into()));
    return (q, r + '0'.into());
}

fn get_letter_hex(
    i: u256,
) -> (u256, u256) {
    let (q, r) = u256_safe_divmod(i, u256_as_non_zero(16.into()));
    if r < 10.into() {
        return (q, r + '0'.into());
    }
    return (q, r + 'a'.into() - 10.into());
}
