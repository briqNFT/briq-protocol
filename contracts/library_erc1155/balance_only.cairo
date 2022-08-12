%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_nn_le, assert_lt, assert_le, assert_not_zero, assert_lt_felt, unsigned_div_rem, assert_not_equal
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.alloc import alloc

@storage_var
func _balance(owner: felt, token_id: felt) -> (balance: felt):
end
