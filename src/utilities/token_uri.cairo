
use array::ArrayTrait;
use array::SpanTrait;

#[event]
fn URI(_value: Array<felt252>, _id: u256) {}


const uri_part_1: felt252 = 'https://api.briq.construction';
const uri_part_2: felt252 = '/v1/uri/box/';
const uri_part_3: felt252 = 'starknet-mainnet/';
const uri_part_4: felt252 = '.json';

use briq_protocol::utils::check_gas;

use core::integer::u128_safe_divmod;
use core::integer::u128_as_non_zero;
use core::integer::u256_from_felt252;

use traits::Into;
use traits::TryInto;
use option::OptionTrait;

fn _getUrl(
    token_id: felt252,
    uri_p1: felt252,
    uri_p2: felt252,
    uri_p3: felt252,
    uri_p4: felt252,
) -> Array<felt252> { // uri
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

fn insert_reverse(mut out: Array<felt252>, mut data: Span<u128>) -> Array<felt252> {
    check_gas();
    if data.len() == 0_u32 {
        return out;
    }
    let nb = *data.pop_back().unwrap();
    out.append(nb.into());
    return insert_reverse(out, data);
}

fn felt_to_ascii_array(i: felt252) -> Array<u128> {
    let tok_u256 = u256_from_felt252(i);
    let out = ArrayTrait::<u128>::new();
    // TODO: fix this by using u256
    let (q, low) = u128_safe_divmod(tok_u256.low, u128_as_non_zero(100000000000000000000000000000000000000_u128));
    return _felt_to_ascii_array(out, low);
}

fn _felt_to_ascii_array(mut out: Array<u128>, i: u128) -> Array<u128> {
    check_gas();
    let (q, r) = get_letter(i);
    out.append(r);
    if (q == 0_u128) {
        return out;
    }
    return _felt_to_ascii_array(out, q);
}

fn get_letter(
    i: u128,
) -> (u128, u128) {
    let (q, r) = u128_safe_divmod(i, u128_as_non_zero(10_u128));
    return (q, r + '0'.try_into().unwrap());
}

fn get_letter_hex(
    i: u128,
) -> (u128, u128) {
    let (q, r) = u128_safe_divmod(i, u128_as_non_zero(16_u128));
    if r < 10_u128 {
        return (q, r + '0'.try_into().unwrap());
    }
    return (q, r + 'a'.try_into().unwrap() - 10_u128);
}
