%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.starknet.common.syscalls import call_contract, delegate_l1_handler, delegate_call

@storage_var
func _approval_single(token_id: felt) -> (address: felt):
end

## Aka 'Operator'
@storage_var
func _approval_all(on_behalf_of: felt, approved_address: felt) -> (address: felt):
end

## TODO: ERC20 storage of value for briq backend

func _approve_noauth{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (approved_address: felt, token_id: felt):
    _approval_single.write(token_id, approved_address)
    return ()
end

func _setApprovalForAll_noauth{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (on_behalf_of: felt, approved_address: felt, allowed: felt):
    _approval_all.write(on_behalf_of, approved_address, allowed)
    return ()
end

# Mimic OZ interface
@view
func getApproved{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (token_id: felt) -> (approved: felt):
    let (addr) = _approval_single.read(token_id)
    return (addr)
end

@view
func isApprovedForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, operator: felt) -> (is_approved: felt):
    let (allowed) = _approval_all.read(owner, operator)
    return (allowed)
end