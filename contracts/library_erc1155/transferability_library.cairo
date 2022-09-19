// Partial implementation of an ERC721-like contract for the set contract.

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import (
    assert_nn_le,
    assert_lt,
    assert_le,
    assert_not_zero,
    assert_lt_felt,
    unsigned_div_rem,
    assert_not_equal,
)
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.alloc import alloc

from starkware.cairo.common.uint256 import Uint256

from contracts.utilities.Uint256_felt_conv import _felt_to_uint

from contracts.library_erc1155.approvals import ERC1155_approvals

from contracts.library_erc1155.balance_only import _balance

//###########
//###########
//###########
// Events

// # ERC1155 compatibility
@event
func TransferSingle(_operator: felt, _from: felt, _to: felt, _id: Uint256, _value: Uint256) {
}

@event
func TransferBatch(
    _operator: felt,
    _from: felt,
    _to: felt,
    _ids_len: felt,
    _ids: Uint256*,
    _values_len: felt,
    _values: Uint256*,
) {
}

namespace ERC1155_lib_transfer {
    func _onTransfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        operator: felt, sender: felt, recipient: felt, token_id: felt, amount: felt
    ) {
        let (tk) = _felt_to_uint(token_id);
        let (amt) = _felt_to_uint(amount);
        TransferSingle.emit(operator, sender, recipient, tk, amt);
        return ();
    }

    //###########
    //###########
    // Transfer

    func _transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        sender: felt, recipient: felt, token_id: felt, value: felt
    ) {
        assert_not_zero(recipient);
        assert_not_zero(sender - recipient);
        assert_not_zero(token_id);
        assert_not_zero(value);

        // Reset approval (0 cost if was 0 before on starknet I believe)
        // let (caller) = get_caller_address()
        // let (approved_value) = ERC1155_approvals.getApproved_(sender, token_id, caller)
        // ERC1155_approvals.approve_nocheck_(0, token_id)

        let (balance) = _balance.read(sender, token_id);
        with_attr error_message("Insufficient balance") {
            assert_lt_felt(balance - value, balance);
        }
        _balance.write(sender, token_id, balance - value);
        let (balance) = _balance.read(recipient, token_id);
        with_attr error_message("Transfer would overflow recipient balance") {
            assert_lt_felt(balance, balance + value);
        }
        _balance.write(recipient, token_id, balance + value);

        // Is caller correct here?
        let (caller) = get_caller_address();
        _onTransfer(caller, sender, recipient, token_id, value);

        return ();
    }
}
