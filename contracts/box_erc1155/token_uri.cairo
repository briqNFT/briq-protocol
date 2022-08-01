%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.uint256 import Uint256

from contracts.utilities.Uint256_felt_conv import (
    _uint_to_felt,
    _felt_to_uint,
)

from contracts.box_erc1155.data import (
    briq_data_start,
    shape_data_start,
    shape_data_end,
)

struct BoxData:
    member briq_1: felt # nb of briqs of material 0x1
    member briq_3: felt # nb of briqs of material 0x3
    member briq_4: felt # nb of briqs of material 0x4
    member briq_5: felt # nb of briqs of material 0x5
    member briq_6: felt # nb of briqs of material 0x6
    member shape_class_hash: felt # Class hash of the matching shape contract
end

namespace box_token_uri:

    @view
    func get_box_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
        } (token_id: felt) -> (data: BoxData):
        alloc_locals
        let box: BoxData* = alloc()
        let (briq_data) = get_label_location(briq_data_start)
        memcpy(box, briq_data + 5 * (token_id - 1), 5)
        let (shape_data) = get_label_location(shape_data_start)
        memcpy(box + 5, shape_data + (token_id - 1), 1)
        return (box[0])
    end

    @view
    func get_box_nb{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
        } () -> (nb: felt):
        let (_start) = get_label_location(shape_data_start)
        let (_end) = get_label_location(shape_data_end)
        let res = _end - _start
        return (res)
    end

    @view
    func tokenURI_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            bitwise_ptr: BitwiseBuiltin*,
            range_check_ptr
        } (tokenId: felt) -> (tokenURI_len: felt, tokenURI: felt*):
        alloc_locals
        tempvar toto = 'unknown'
        return (0, &[toto])
    end

    # OZ-like version, though this returns a list of felt.
    @view
    func tokenURI{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            bitwise_ptr: BitwiseBuiltin*,
            range_check_ptr
        } (tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*):
        let (_tok) = _uint_to_felt(tokenId)
        let (l, u) = tokenURI_(_tok)
        return (l, u)
    end
end
