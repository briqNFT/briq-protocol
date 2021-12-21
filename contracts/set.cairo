%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_nn_le, assert_lt, assert_not_zero

from contracts.ownership_utils import (
    assert_allowed_to_mint,
    assert_allowed_to_admin_contract
)

@contract_interface
namespace IBriqContract:
    func transfer_briqs(sender: felt, recipient: felt, bricks_len: felt, bricks: felt*):
    end
    func set_bricks_to_set(set_id: felt, bricks_len: felt, bricks: felt*):
    end
    func unset_bricks_from_set(set_id: felt, bricks_len: felt, bricks: felt*):
    end
    func get_bricks_for_set(owner: felt, set_id: felt) -> (bricks_len: felt, bricks: felt*):
    end
end




@storage_var
func token_owner(token_id: felt) -> (res: felt):
end

@storage_var
func balances(owner: felt) -> (nb: felt):
end

@storage_var
func balance_details(owner: felt, index: felt) -> (res: felt):
end

#### Specific bit

@storage_var
func nb_briqs(token_id: felt) -> (res: felt):
end

@storage_var
func briq_contract() -> (res: felt):
end

@external
func initialize{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (briq_contract_address: felt):

    let (caller) = get_caller_address()
    assert_allowed_to_admin_contract(caller)

    let (addr) = briq_contract.read()
    assert addr = 0
    briq_contract.write(briq_contract_address)
    return ()
end

@view
func balance_of{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt) -> (res: felt):
    let (res) = balances.read(owner=owner)
    return (res)
end

@view
func owner_of{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (token_id: felt) -> (res: felt):
    let (res) = token_owner.read(token_id=token_id)
    return (res)
end

@view
func token_at_index{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, index: felt) -> (res: felt):
    let (res) = balances.read(owner=owner)
    assert_lt(index, res)
    let (retval) = balance_details.read(owner=owner, index=index)
    return (retval)
end

func _mint{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (recipient: felt, token_id: felt):
    let (curr_owner) = token_owner.read(token_id)
    assert curr_owner = 0
    let (res) = balances.read(owner=recipient)
    balances.write(recipient, res + 1)
    balance_details.write(recipient, res, token_id)
    token_owner.write(token_id, recipient)
    return ()
end

@external
func mint{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt, token_id: felt, bricks_len: felt, bricks: felt*):
    alloc_locals

    let (caller) = get_caller_address()
    assert_allowed_to_mint(caller, owner)

    assert_not_zero(bricks_len)
    _mint(owner, token_id)
    let (addr) = briq_contract.read()
    local pedersen_ptr: HashBuiltin* = pedersen_ptr
    IBriqContract.set_bricks_to_set(contract_address=addr, set_id=token_id, bricks_len=bricks_len, bricks=bricks)
    nb_briqs.write(token_id, bricks_len)
    return ()
end

func erase_balance_details{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt, token_id: felt, index: felt):
    let (token_at_index) = balance_details.read(owner, index)
    if token_at_index == token_id:
        let (res) = balances.read(owner=owner)
        if res == 0:
            return ()
        else:
            # swap and erase. Note that the old end is at 'res + 1' at this point, so we need index 'res'.
            let (last_tok) = balance_details.read(owner, res)
            balance_details.write(owner, index, last_tok)
            return ()
        end
    end
    # If index is 0 here, we haven't found the token, which should be impossible.
    assert_not_zero(index)
    return erase_balance_details(owner, token_id, index - 1)
end

func _disassemble{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt, token_id: felt, bricks_len: felt, bricks: felt*):
    alloc_locals

    let (nbbr) = nb_briqs.read(token_id)
    assert bricks_len = nbbr

    local pedersen_ptr: HashBuiltin* = pedersen_ptr
    let (addr) = briq_contract.read()
    IBriqContract.unset_bricks_from_set(contract_address=addr, set_id=token_id, bricks_len=bricks_len, bricks=bricks)

    let (res) = balances.read(owner=owner)
    balances.write(owner, res - 1)
    erase_balance_details(owner, token_id, res - 1)
    nb_briqs.write(token_id, 0)
    token_owner.write(token_id, 0)
    return()
end

@external
func disassemble{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt, token_id: felt):
    let (caller) = get_caller_address()
    assert_allowed_to_mint(caller, owner)

    let (addr) = briq_contract.read()
    let (bricks_len, bricks) = IBriqContract.get_bricks_for_set(contract_address=addr, owner=owner, set_id=token_id)

    _disassemble(owner, token_id, bricks_len, bricks)
    return ()
end

@external
func disassemble_hinted{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt, token_id: felt, bricks_len: felt, bricks: felt*):
    let (caller) = get_caller_address()
    assert_allowed_to_mint(caller, owner)

    _disassemble(owner, token_id, bricks_len, bricks)
    return ()
end

func _transfer{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, token_id: felt, bricks_len: felt, bricks: felt*):
    alloc_locals

    let (curr_owner) = token_owner.read(token_id=token_id)
    assert curr_owner = sender

    let (addr) = briq_contract.read()
    let (nbbr) = nb_briqs.read(token_id)
    assert bricks_len = nbbr
    
    local pedersen_ptr: HashBuiltin* = pedersen_ptr
    IBriqContract.transfer_briqs(contract_address=addr, sender=sender, recipient=recipient, bricks_len=bricks_len, bricks=bricks)

    let (res) = balances.read(owner=sender)
    balances.write(sender, res - 1)
    erase_balance_details(sender, token_id, res - 1)

    let (res2) = balances.read(owner=recipient)
    balances.write(recipient, res2 + 1)
    balance_details.write(recipient, res2, token_id)

    token_owner.write(token_id, recipient)

    return ()
end

@external
func transfer_from{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (sender: felt, recipient: felt, token_id: felt):

    let (caller) = get_caller_address()
    assert caller = sender

    let (addr) = briq_contract.read()
    let (bricks_len, bricks) = IBriqContract.get_bricks_for_set(contract_address=addr, owner=sender, set_id=token_id)

    _transfer(sender, recipient, token_id, bricks_len, bricks)
    return ()
end

@external
func transfer_from_hinted{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (sender: felt, recipient: felt, token_id: felt, bricks_len: felt, bricks: felt*):

    let (caller) = get_caller_address()
    assert caller = sender

    _transfer(sender, recipient, token_id, bricks_len, bricks)
    return ()
end



############
############
############
#
# Enumerability
#

func populate_tokens{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt, rett: felt*, idx: felt) -> (res: felt*):
    if idx == -1:
        return (rett)
    end
    let (token_id) = balance_details.read(owner=owner, index=idx)
    rett[0] = token_id
    return populate_tokens(owner, rett + 1, idx - 1)
end

from starkware.cairo.common.alloc import alloc

# Get all tokens from an address
@view
func get_all_tokens_for_owner{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt) -> (tokens_len: felt, tokens: felt*):
    alloc_locals
    let (local ret_array : felt*) = alloc()
    let (nb_tokens) = balances.read(owner=owner)
    let (nv) = populate_tokens(owner, ret_array, nb_tokens - 1)
    return (nv - ret_array, ret_array)
end