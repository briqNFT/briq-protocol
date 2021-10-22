%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.starknet.common.storage import Storage
from starkware.cairo.common.math import assert_nn_le, assert_lt

@storage_var
func owner(token_id: felt) -> (res: felt):
end

@storage_var
func balances(owner: felt) -> (nb: felt):
end

@storage_var
func balance_details(owner: felt, index: felt) -> (res: felt):
end

@storage_var
func initialized() -> (res: felt):
end

#### Specific bit

# Material encodes the rarity. Values range 1-16
@storage_var
func material(token_id: felt) -> (res: felt):
end

@external
func initialize{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } ():
    let (_initialized) = initialized.read()
    assert _initialized = 0
    initialized.write(1)
    return ()
end

@view
func balance_of{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt) -> (res: felt):
    let (res) = balances.read(owner=owner)
    return (res)
end

@view
func owner_of{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (token_id: felt) -> (res: felt):
    let (res) = owner.read(token_id=token_id)
    return (res)
end

@view
func token_at_index{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, index: felt) -> (res: felt):
    let (res) = balances.read(owner=owner)
    assert_lt(index, res)
    let (retval) = balance_details.read(owner=owner, index=index)
    return (retval)
end

func _mint{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (recipient: felt, token_id: felt, mat: felt):
    let (curr_owner) = owner.read(token_id)
    assert curr_owner = 0
    let (res) = balances.read(owner=recipient)
    balances.write(recipient, res + 1)
    balance_details.write(recipient, res, token_id)
    owner.write(token_id, recipient)
    material.write(token_id, mat)
    return ()
end

@external
func mint{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt, token_id: felt, material: felt):
    assert material = 1
    _mint(owner, token_id, material)
    return ()
end


func _transfer{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, token_id: felt):
    let (curr_owner) = owner.read(token_id=token_id)
    assert curr_owner = sender
    owner.write(token_id, recipient)
    return ()
end

@external
func transfer_from{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (sender: felt, recipient: felt, token_id: felt):
    _transfer(sender, recipient, token_id)
    return ()
end
