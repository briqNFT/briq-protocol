%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero, assert_not_equal, assert_le_felt

from starkware.cairo.common.uint256 import Uint256
from contracts.utilities.Uint256_felt_conv import (
    _felt_to_uint,
)

from contracts.library_erc1155.balance_only import (
    _balance
)

from contracts.utilities.authorization import (
    _only,
)

@event
func ApprovalFor(_token_id: Uint256, _owner: felt, _approved_address: felt, _value: felt):
end

@event
func ApprovalForAll(_owner: felt, _operator: felt, _approved: felt):
end


@storage_var
func _approval_n(token_id: felt, owner: felt, approved_address: felt) -> (value: felt):
end

## approved_address aka 'operator'
@storage_var
func _approval_all(on_behalf_of: felt, approved_address: felt) -> (is_approved: felt):
end

namespace ERC1155_approvals:
    func approve_nocheck_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (caller: felt, to: felt, token_id: felt, value: felt):
        _approval_n.write(token_id, caller, to, value)
        let (tk) = _felt_to_uint(token_id)
        ApprovalFor.emit(tk, caller, to, value)
        return ()
    end

    @external
    func approve_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (to: felt, token_id: felt, value: felt):
        alloc_locals
        let (caller) = get_caller_address()

        with_attr error_message("Cannot approve from the zero address"):
            assert_not_zero(caller)
        end
        
        with_attr error_message("Approval to current caller"):
            assert_not_equal(caller, to)
        end

        # Checks that either approving for yourself or
        # caller isApprovedForAll on behalf of caller
        _onlyApprovedAll(on_behalf_of=caller)

        approve_nocheck_(caller, to, token_id, value)
        return ()
    end

    @external
    func setApprovalForAll_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (approved_address: felt, is_approved: felt):
        let (caller) = get_caller_address()
        _setExplicitApprovalForAll(on_behalf_of=caller, approved_address=approved_address, is_approved=is_approved)
        return ()
    end

    func _setExplicitApprovalForAll{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (on_behalf_of: felt, approved_address: felt, is_approved: felt):
        # Neither of these can be 0.
        with_attr error_message("ERC721: either the caller or operator is the zero address"):
            assert_not_zero(on_behalf_of * approved_address)
        end

        # Cannot approve yourself.
        with_attr error_message("ERC721: approve to caller"):
            assert_not_equal(on_behalf_of, approved_address)
        end

        # Make sure `is_approved` is a boolean (0 or 1)
        with_attr error_message("ERC721: approved is not a Cairo boolean"):
            assert is_approved * (1 - is_approved) = 0
        end

        _approval_all.write(on_behalf_of, approved_address, is_approved)
        ApprovalForAll.emit(on_behalf_of, approved_address, is_approved)
        return ()
    end

    @view
    func getApproved_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (on_behalf_of: felt, token_id: felt, address: felt) -> (approved_value: felt):
        let (value) = _approval_n.read(token_id, on_behalf_of, address)
        return (value)
    end

    @view
    func isApprovedForAll_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (on_behalf_of: felt, address: felt) -> (is_approved: felt):
        let (allowed) = _approval_all.read(on_behalf_of, address)
        return (allowed)
    end

    ### Auth

    func _onlyApproved{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (on_behalf_of: felt, token_id: felt, value: felt):
        let (caller) = get_caller_address()
        # You can always approve on behalf of yourself.
        if on_behalf_of == caller:
            return ()
        end
        let (isOperator) = isApprovedForAll_(on_behalf_of, caller)
        if isOperator == 1:
            return ()
        end
        let (approved_value) = getApproved_(on_behalf_of, token_id, caller)
        with_attr error_message ("Insufficient approval balance"):
            assert_le_felt(value, approved_value)
        end
        return ()
    end

    func _onlyApprovedAll{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (on_behalf_of: felt):
        let (caller) = get_caller_address()
        # You can always approve on behalf of yourself.
        if caller == on_behalf_of:
            return ()
        end
        let (isOperator) = isApprovedForAll_(on_behalf_of, caller)
        assert isOperator = 1
        return ()
    end
end
