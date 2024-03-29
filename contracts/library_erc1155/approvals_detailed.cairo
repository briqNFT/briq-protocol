%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero, assert_not_equal, assert_le_felt

from starkware.cairo.common.uint256 import Uint256
from contracts.utilities.Uint256_felt_conv import _felt_to_uint

from contracts.library_erc1155.balance import _balance

from contracts.utilities.authorization import _only

@event
func ApprovalFor(_token_id: Uint256, _owner: felt, _approved_address: felt, _value: felt) {
}

@storage_var
func _approval_n(token_id: felt, owner: felt, approved_address: felt) -> (value: felt) {
}

namespace ERC1155_extension_approvals {
    func approve_nocheck_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        caller: felt, to: felt, token_id: felt, value: felt
    ) {
        _approval_n.write(token_id, caller, to, value);
        let (tk) = _felt_to_uint(token_id);
        ApprovalFor.emit(tk, caller, to, value);
        return ();
    }

    @external
    func approve_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        to: felt, token_id: felt, value: felt
    ) {
        alloc_locals;
        let (caller) = get_caller_address();

        with_attr error_message("Cannot approve from the zero address") {
            assert_not_zero(caller);
        }

        with_attr error_message("Approval to current caller") {
            assert_not_equal(caller, to);
        }

        // Checks that either approving for yourself or
        // caller isApprovedForAll on behalf of caller
        _onlyApprovedAll(on_behalf_of=caller);

        approve_nocheck_(caller, to, token_id, value);
        return ();
    }

    @view
    func getApproved_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        on_behalf_of: felt, token_id: felt, address: felt
    ) -> (approved_value: felt) {
        let (value) = _approval_n.read(token_id, on_behalf_of, address);
        return (value,);
    }

    // ## Auth

    func _onlyApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        on_behalf_of: felt, token_id: felt, value: felt
    ) {
        let (caller) = get_caller_address();
        // You can always approve on behalf of yourself.
        if (on_behalf_of == caller) {
            return ();
        }
        let (isOperator) = isApprovedForAll_(on_behalf_of, caller);
        if (isOperator == 1) {
            return ();
        }
        let (approved_value) = getApproved_(on_behalf_of, token_id, caller);
        with_attr error_message("Insufficient approval balance") {
            assert_le_felt(value, approved_value);
        }
        return ();
    }
}
