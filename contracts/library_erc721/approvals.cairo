%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero, assert_not_equal

from contracts.library_erc721.balance import (
    _owner
)

from contracts.utilities.authorization import (
    _only,
)

@storage_var
func _approval_single(token_id: felt) -> (approved_address: felt):
end

## approved_address aka 'operator'
@storage_var
func _approval_all(on_behalf_of: felt, approved_address: felt) -> (is_approved: felt):
end

namespace ERC721_approvals:
    func approve_nocheck_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (to: felt, token_id: felt):
        _approval_single.write(token_id, to)
        return ()
    end

    @external
    func approve_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (to: felt, token_id: felt):
        let (owner) = _owner.read(token_id)

        with_attr error_message("ERC721: cannot approve from the zero address"):
            assert_not_zero(owner)
        end
        
        with_attr error_message("ERC721: approval to current owner"):
            assert_not_equal(owner, to)
        end

        # Checks that either caller equals owner or
        # caller isApprovedForAll on behalf of owner
        _onlyApprovedAll(on_behalf_of=owner)

        _approval_single.write(token_id, to)
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
        return ()
    end

    @view
    func getApproved_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (token_id: felt) -> (approved: felt):
        let (addr) = _approval_single.read(token_id)
        return (addr)
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
        } (on_behalf_of: felt, token_id: felt):
        let (caller) = get_caller_address()
        # You can always approve on behalf of yourself.
        if on_behalf_of == caller:
            return ()
        end
        let (isOperator) = isApprovedForAll_(on_behalf_of, caller)
        if isOperator == 1:
            return ()
        end
        let (approved) = getApproved_(token_id)
        _only(approved)
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
