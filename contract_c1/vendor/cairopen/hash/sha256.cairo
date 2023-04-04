%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.alloc import alloc
from src.cairopen.binary.bits import Bits

func sha256{bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(input: felt*, n_bits: felt) -> (
    output: felt*
) {
    // Computes SHA256 of 'input'. See https://en.wikipedia.org/wiki/SHA-2
    //
    // Parameters:
    //   input: array of 32-bit words
    //   n_bits: number of bits to consider from input
    //
    // Returns:
    //   output: an array of 8 32-bit words (big endian).

    alloc_locals;

    // Initialize hash values
    let (hash: felt*) = alloc();
    assert hash[0] = 0x6a09e667;
    assert hash[1] = 0xbb67ae85;
    assert hash[2] = 0x3c6ef372;
    assert hash[3] = 0xa54ff53a;
    assert hash[4] = 0x510e527f;
    assert hash[5] = 0x9b05688c;
    assert hash[6] = 0x1f83d9ab;
    assert hash[7] = 0x5be0cd19;

    // Pre-processing (Padding)

    let (len_chunks: felt, chunks: felt**) = create_chunks(input, n_bits, 0);

    return for_all_chunks(hash, len_chunks, chunks);
}

func create_chunks{range_check_ptr}(input: felt*, n_bits: felt, bits_prefix: felt) -> (
    len_chunks: felt, chunks: felt**
) {
    // Creates an array of chunks of length 512 bits (16 32-bit words) from 'input'.
    //
    // Parameters:
    //   input: array of 32-bit words
    //   n_bits: length of input
    //   bits_prefix: number of bits to skip

    alloc_locals;

    // if that's the last chunk
    // we need to append a single bit at 1, zeros and the length as a 64 bit integer
    // so that's 512-65=447 bits free
    let len = n_bits - bits_prefix;

    // n_bits-bits_prefix <= 511
    let test = is_le(len, 511);
    if (test == TRUE) {
        let (msg: felt*) = alloc();
        Bits.extract(input, bits_prefix, len, msg);

        // one followed by 31 0
        let (one: felt*) = alloc();
        assert [one] = 2147483648;

        // we will bind it to get full words
        let (full_words, _) = unsigned_div_rem(len, 32);
        let size = (full_words + 1) * 32 - len;
        let (chunk: felt*, new_len: felt) = Bits.merge(msg, len, one, size);
        let words_len = new_len / 32;

        let test = is_le(len, 447);
        // if that's the last chunk
        // we need to append 447-len '0' and len on 64 bits (2 felt words)
        // so that's 512-65=447 bits free
        if (test == TRUE) {
            let zero_words = 14 - words_len;
            append_zeros(chunk + words_len, zero_words);
            // now chunk is 448 bits long = 14 words
            // todo: support > 32 bits longs size
            // current maximum size = 2^33-1
            // = 8589934591 bits ~= 8.6GB

            assert chunk[14] = 0;
            assert chunk[15] = n_bits;
            let (chunks: felt**) = alloc();
            assert chunks[0] = chunk;
            return (1, chunks);
        } else {
            // here we can put 0 until the 512 bits and get an empty next chunk
            let zero_words = 16 - words_len;
            append_zeros(chunk + words_len, zero_words);
            let (chunks: felt**) = alloc();
            let (last_chunk) = alloc();
            assert last_chunk[15] = n_bits;
            assert chunks[0] = last_chunk;
            append_zeros(last_chunk, 15);
            assert chunks[1] = chunk;
            return (2, chunks);
        }
    }

    // if 512 <= n_bits
    // 512/32 = 16
    let (len_chunks: felt, chunks: felt**) = create_chunks(input, n_bits, bits_prefix + 512);

    let (chunk: felt*) = alloc();
    Bits.extract(input, bits_prefix, 512, chunk);
    assert chunks[len_chunks] = chunk;

    return (len_chunks + 1, chunks);
}

func append_zeros{range_check_ptr}(ptr: felt*, amount: felt) {
    if (amount == 0) {
        return ();
    }
    assert [ptr] = 0;
    return append_zeros(ptr + 1, amount - 1);
}

func for_all_chunks{bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    hash: felt*, chunks_len: felt, chunks: felt**
) -> (output: felt*) {
    if (chunks_len == 0) {
        return (hash,);
    }
    let chunk: felt* = chunks[chunks_len - 1];
    let (updated_hash: felt*) = process_chunk(chunk, hash);
    return for_all_chunks(updated_hash, chunks_len - 1, chunks);
}

const SHIFTS = 1 + 2 ** 35 + 2 ** (35 * 2) + 2 ** (35 * 3) + 2 ** (35 * 4) + 2 ** (35 * 5) +
    2 ** (35 * 6);

func process_chunk{bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(chunk: felt*, hash: felt*) -> (
    output: felt*
) {
    alloc_locals;
    // Extend the first 16 words into a total of 64 words
    compute_message_schedule(chunk);
    let (k: felt*) = get_constants();
    compute_compression(hash, chunk, k, 0);

    let shifted_hash: felt* = hash + 8 * 64;

    // additions are mod 2^32
    let (_, mod32bits) = unsigned_div_rem(hash[0] + shifted_hash[0], 4294967296);
    assert shifted_hash[8] = mod32bits;
    let (_, mod32bits) = unsigned_div_rem(hash[1] + shifted_hash[1], 4294967296);
    assert shifted_hash[9] = mod32bits;
    let (_, mod32bits) = unsigned_div_rem(hash[2] + shifted_hash[2], 4294967296);
    assert shifted_hash[10] = mod32bits;
    let (_, mod32bits) = unsigned_div_rem(hash[3] + shifted_hash[3], 4294967296);
    assert shifted_hash[11] = mod32bits;
    let (_, mod32bits) = unsigned_div_rem(hash[4] + shifted_hash[4], 4294967296);
    assert shifted_hash[12] = mod32bits;
    let (_, mod32bits) = unsigned_div_rem(hash[5] + shifted_hash[5], 4294967296);
    assert shifted_hash[13] = mod32bits;
    let (_, mod32bits) = unsigned_div_rem(hash[6] + shifted_hash[6], 4294967296);
    assert shifted_hash[14] = mod32bits;
    let (_, mod32bits) = unsigned_div_rem(hash[7] + shifted_hash[7], 4294967296);
    assert shifted_hash[15] = mod32bits;

    return (shifted_hash + 8,);
}

func compute_compression{bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    hash: felt*, w: felt*, k: felt*, index: felt
) {
    alloc_locals;
    if (index == 64) {
        return ();
    }

    // s1 := (h4 rightrotate 6) xor (h4 rightrotate 11) xor (h4 rightrotate 25)
    let (a) = Bits.rightrotate(hash[4], 6);
    let (b) = Bits.rightrotate(hash[4], 11);
    assert bitwise_ptr[0].x = a;
    assert bitwise_ptr[0].y = b;
    let a = bitwise_ptr[0].x_xor_y;
    let (b) = Bits.rightrotate(hash[4], 25);
    assert bitwise_ptr[1].x = a;
    assert bitwise_ptr[1].y = b;
    let s1: felt = bitwise_ptr[1].x_xor_y;

    // ch := (h4 and h5) xor ((not h4) and h6)
    assert bitwise_ptr[2].x = hash[4];
    assert bitwise_ptr[2].y = hash[5];
    let a = bitwise_ptr[2].x_and_y;

    let hey = hash[4];
    let hello = 4294967295 - hash[4];
    assert bitwise_ptr[3].x = 4294967295 - hash[4];

    assert bitwise_ptr[3].y = hash[6];
    let b = bitwise_ptr[3].x_and_y;
    assert bitwise_ptr[4].x = a;
    assert bitwise_ptr[4].y = b;
    let ch: felt = bitwise_ptr[4].x_xor_y;

    // temp1 := hash[7] + s1 + ch + k[i] + w[i]
    let temp1: felt = hash[7] + s1 + ch + k[index] + w[index];

    // s0 := (hash[0] rightrotate 2) xor (hash[0] rightrotate 13) xor (a rightrotate 22)
    let (a) = Bits.rightrotate(hash[0], 2);
    let (b) = Bits.rightrotate(hash[0], 13);
    assert bitwise_ptr[5].x = a;
    assert bitwise_ptr[5].y = b;
    let a = bitwise_ptr[5].x_xor_y;
    let (b) = Bits.rightrotate(hash[0], 22);
    assert bitwise_ptr[6].x = a;
    assert bitwise_ptr[6].y = b;
    let s0: felt = bitwise_ptr[6].x_xor_y;

    // maj := (hash[0] and hash[1]) xor (hash[0] and hash[2]) xor (hash[1] and hash[2])
    assert bitwise_ptr[7].x = hash[0];
    assert bitwise_ptr[7].y = hash[1];
    let a = bitwise_ptr[7].x_and_y;
    assert bitwise_ptr[8].x = hash[0];
    assert bitwise_ptr[8].y = hash[2];
    let b = bitwise_ptr[8].x_and_y;
    assert bitwise_ptr[9].x = hash[1];
    assert bitwise_ptr[9].y = hash[2];
    let c = bitwise_ptr[9].x_and_y;
    assert bitwise_ptr[10].x = a;
    assert bitwise_ptr[10].y = b;
    let a = bitwise_ptr[10].x_xor_y;
    assert bitwise_ptr[11].x = a;
    assert bitwise_ptr[11].y = c;
    let maj: felt = bitwise_ptr[11].x_xor_y;

    // additions are mod 2^32
    let (_, mod32bits) = unsigned_div_rem(temp1 + s0 + maj, 4294967296);
    assert hash[8] = mod32bits;
    assert hash[9] = hash[0];
    assert hash[10] = hash[1];
    assert hash[11] = hash[2];
    let (_, mod32bits) = unsigned_div_rem(hash[3] + temp1, 4294967296);
    assert hash[12] = mod32bits;
    assert hash[13] = hash[4];
    assert hash[14] = hash[5];
    assert hash[15] = hash[6];

    local bitwise_ptr: BitwiseBuiltin* = bitwise_ptr + 12 * BitwiseBuiltin.SIZE;
    return compute_compression(hash + 8, w, k, index + 1);
}

func compute_message_schedule{bitwise_ptr: BitwiseBuiltin*}(message: felt*) {
    // Code from Lior's implementation
    // Given an array of size 16, extends it to the message schedule array (of size 64) by writing
    // 48 more values.
    // Each element represents 7 32-bit words from 7 difference instances, starting at bits
    // 0, 35, 35 * 2, ..., 35 * 6.

    alloc_locals;

    // Defining the following constants as local variables saves some instructions.
    local shift_mask3 = SHIFTS * (2 ** 32 - 2 ** 3);
    local shift_mask7 = SHIFTS * (2 ** 32 - 2 ** 7);
    local shift_mask10 = SHIFTS * (2 ** 32 - 2 ** 10);
    local shift_mask17 = SHIFTS * (2 ** 32 - 2 ** 17);
    local shift_mask18 = SHIFTS * (2 ** 32 - 2 ** 18);
    local shift_mask19 = SHIFTS * (2 ** 32 - 2 ** 19);
    local mask32ones = SHIFTS * (2 ** 32 - 1);

    // Loop variables.
    tempvar bitwise_ptr = bitwise_ptr;
    tempvar message = message + 16;
    tempvar n = 64 - 16;

    loop:
    // Compute s0 = right_rot(w[i - 15], 7) ^ right_rot(w[i - 15], 18) ^ (w[i - 15] >> 3).
    tempvar w0 = message[-15];
    assert bitwise_ptr[0].x = w0;
    assert bitwise_ptr[0].y = shift_mask7;
    let w0_rot7 = (2 ** (32 - 7)) * w0 + (1 / 2 ** 7 - 2 ** (32 - 7)) * bitwise_ptr[0].x_and_y;
    assert bitwise_ptr[1].x = w0;
    assert bitwise_ptr[1].y = shift_mask18;
    let w0_rot18 = (2 ** (32 - 18)) * w0 + (1 / 2 ** 18 - 2 ** (32 - 18)) * bitwise_ptr[1].x_and_y;
    assert bitwise_ptr[2].x = w0;
    assert bitwise_ptr[2].y = shift_mask3;
    let w0_shift3 = (1 / 2 ** 3) * bitwise_ptr[2].x_and_y;
    assert bitwise_ptr[3].x = w0_rot7;
    assert bitwise_ptr[3].y = w0_rot18;
    assert bitwise_ptr[4].x = bitwise_ptr[3].x_xor_y;
    assert bitwise_ptr[4].y = w0_shift3;
    let s0 = bitwise_ptr[4].x_xor_y;
    let bitwise_ptr = bitwise_ptr + 5 * BitwiseBuiltin.SIZE;

    // Compute s1 = right_rot(w[i - 2], 17) ^ right_rot(w[i - 2], 19) ^ (w[i - 2] >> 10).
    tempvar w1 = message[-2];
    assert bitwise_ptr[0].x = w1;
    assert bitwise_ptr[0].y = shift_mask17;
    let w1_rot17 = (2 ** (32 - 17)) * w1 + (1 / 2 ** 17 - 2 ** (32 - 17)) * bitwise_ptr[0].x_and_y;
    assert bitwise_ptr[1].x = w1;
    assert bitwise_ptr[1].y = shift_mask19;
    let w1_rot19 = (2 ** (32 - 19)) * w1 + (1 / 2 ** 19 - 2 ** (32 - 19)) * bitwise_ptr[1].x_and_y;
    assert bitwise_ptr[2].x = w1;
    assert bitwise_ptr[2].y = shift_mask10;
    let w1_shift10 = (1 / 2 ** 10) * bitwise_ptr[2].x_and_y;
    assert bitwise_ptr[3].x = w1_rot17;
    assert bitwise_ptr[3].y = w1_rot19;
    assert bitwise_ptr[4].x = bitwise_ptr[3].x_xor_y;
    assert bitwise_ptr[4].y = w1_shift10;
    let s1 = bitwise_ptr[4].x_xor_y;
    let bitwise_ptr = bitwise_ptr + 5 * BitwiseBuiltin.SIZE;

    assert bitwise_ptr[0].x = message[-16] + s0 + message[-7] + s1;
    assert bitwise_ptr[0].y = mask32ones;
    assert message[0] = bitwise_ptr[0].x_and_y;
    let bitwise_ptr = bitwise_ptr + BitwiseBuiltin.SIZE;

    tempvar bitwise_ptr = bitwise_ptr;
    tempvar message = message + 1;
    tempvar n = n - 1;
    jmp loop if n != 0;

    return ();
}

func get_constants() -> (data: felt*) {
    let (data_address) = get_label_location(data_start);
    return (data=cast(data_address, felt*));

    data_start:
    dw 0x428a2f98;
    dw 0x71374491;
    dw 0xb5c0fbcf;
    dw 0xe9b5dba5;
    dw 0x3956c25b;
    dw 0x59f111f1;
    dw 0x923f82a4;
    dw 0xab1c5ed5;
    dw 0xd807aa98;
    dw 0x12835b01;
    dw 0x243185be;
    dw 0x550c7dc3;
    dw 0x72be5d74;
    dw 0x80deb1fe;
    dw 0x9bdc06a7;
    dw 0xc19bf174;
    dw 0xe49b69c1;
    dw 0xefbe4786;
    dw 0x0fc19dc6;
    dw 0x240ca1cc;
    dw 0x2de92c6f;
    dw 0x4a7484aa;
    dw 0x5cb0a9dc;
    dw 0x76f988da;
    dw 0x983e5152;
    dw 0xa831c66d;
    dw 0xb00327c8;
    dw 0xbf597fc7;
    dw 0xc6e00bf3;
    dw 0xd5a79147;
    dw 0x06ca6351;
    dw 0x14292967;
    dw 0x27b70a85;
    dw 0x2e1b2138;
    dw 0x4d2c6dfc;
    dw 0x53380d13;
    dw 0x650a7354;
    dw 0x766a0abb;
    dw 0x81c2c92e;
    dw 0x92722c85;
    dw 0xa2bfe8a1;
    dw 0xa81a664b;
    dw 0xc24b8b70;
    dw 0xc76c51a3;
    dw 0xd192e819;
    dw 0xd6990624;
    dw 0xf40e3585;
    dw 0x106aa070;
    dw 0x19a4c116;
    dw 0x1e376c08;
    dw 0x2748774c;
    dw 0x34b0bcb5;
    dw 0x391c0cb3;
    dw 0x4ed8aa4a;
    dw 0x5b9cca4f;
    dw 0x682e6ff3;
    dw 0x748f82ee;
    dw 0x78a5636f;
    dw 0x84c87814;
    dw 0x8cc70208;
    dw 0x90befffa;
    dw 0xa4506ceb;
    dw 0xbef9a3f7;
    dw 0xc67178f2;
}
