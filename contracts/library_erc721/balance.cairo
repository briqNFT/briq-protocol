%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_nn_le, assert_lt, assert_le, assert_not_zero, assert_lt_felt, unsigned_div_rem, assert_not_equal
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.alloc import alloc

############
############
############
# Storage variables.

@storage_var
func _balance(owner: felt) -> (balance: felt):
end

@storage_var
func _owner(token_id: felt) -> (owner: felt):
end

namespace ERC721:
    @view
    func ownerOf_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (token_id: felt) -> (owner: felt):
        let (res) = _owner.read(token_id)
        # OZ ∆: don't fail on res == 0
        return (res)
    end

    @view
    func balanceOf_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (owner: felt) -> (balance: felt):
        # OZ ∆: No 0 check, I don't see the point.
        let (balance) = _balance.read(owner)
        return (balance)
    end
end