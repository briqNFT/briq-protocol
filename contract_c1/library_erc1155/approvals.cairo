%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero, assert_not_equal, assert_le_felt

from starkware.cairo.common.uint256 import Uint256
from contracts.utilities.Uint256_felt_conv import _felt_to_uint

from contracts.library_erc1155.balance import _balance

from contracts.utilities.authorization import _only

@event
func ApprovalForAll(_owner: felt, _operator: felt, _approved: felt) {
}

// # approved_address is 'operator' in the spec, but I find that name rather unclear.
@storage_var
func _approval_all(on_behalf_of: felt, approved_address: felt) -> (is_approved: felt) {
}

namespace ERC1155_approvals {
    @external
    func setApprovalForAll_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        approved_address: felt, is_approved: felt
    ) {
        let (caller) = get_caller_address();
        _setExplicitApprovalForAll(
            on_behalf_of=caller, approved_address=approved_address, is_approved=is_approved
        );
        return ();
    }

    func _setExplicitApprovalForAll{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(on_behalf_of: felt, approved_address: felt, is_approved: felt) {
        // Neither of these can be 0.
        with_attr error_message("ERC721: either the caller or operator is the zero address") {
            assert_not_zero(on_behalf_of * approved_address);
        }

        // Cannot approve yourself.
        with_attr error_message("ERC721: approve to caller") {
            assert_not_equal(on_behalf_of, approved_address);
        }

        // Make sure `is_approved` is a boolean (0 or 1)
        with_attr error_message("ERC721: approved is not a Cairo boolean") {
            assert is_approved * (1 - is_approved) = 0;
        }

        _approval_all.write(on_behalf_of, approved_address, is_approved);
        ApprovalForAll.emit(on_behalf_of, approved_address, is_approved);
        return ();
    }

    @view
    func isApprovedForAll_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        on_behalf_of: felt, address: felt
    ) -> (is_approved: felt) {
        let (allowed) = _approval_all.read(on_behalf_of, address);
        return (allowed,);
    }

    // ## Auth

    func _onlyApprovedAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        on_behalf_of: felt
    ) {
        let (caller) = get_caller_address();
        // You can always approve on behalf of yourself.
        if (caller == on_behalf_of) {
            return ();
        }
        let (isOperator) = isApprovedForAll_(on_behalf_of, caller);
        assert isOperator = 1;
        return ();
    }
}
