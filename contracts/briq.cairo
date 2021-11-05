%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_nn_le, assert_lt, assert_not_zero

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

# Says if a brick is part of set
@storage_var
func part_of_set(token_id: felt) -> (res: felt):
end


@external
func initialize{
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
    let (res) = owner.read(token_id=token_id)
    return (res)
end

@view
func token_data{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (token_id: felt) -> (res: (felt, felt)):
    let (res) = owner.read(token_id=token_id)
    let (res2) = material.read(token_id=token_id)
    let tp = (res, res2)
    return (tp)
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
    } (recipient: felt, token_id: felt, mat: felt):
    let (curr_owner) = owner.read(token_id)
    assert curr_owner = 0
    let (res) = balances.read(owner=recipient)
    balances.write(recipient, res + 1)
    balance_details.write(recipient, res, token_id)
    owner.write(token_id, recipient)
    part_of_set.write(token_id, 0)
    material.write(token_id, mat)
    return ()
end

@external
func mint{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt, token_id: felt, material: felt):
    assert_not_zero(material)
    _mint(owner, token_id, material)
    return ()
end

@external
func mint_multiple{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt, material:felt, token_start: felt, nb: felt):
    assert_not_zero(material)
    if nb == 0:
        return ()
    end
    _mint(owner, token_start + nb - 1, material)
    mint_multiple(owner, material, token_start, nb - 1)
    return ()
end

@external
func set_part_of_set{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (token_id: felt, set: felt):
    let (curr_set) = part_of_set.read(token_id)
    assert curr_set = 0
    let (curr_owner) = owner.read(token_id)
    assert_not_zero(curr_owner)
    part_of_set.write(token_id, set)
    return ()
end

@external
func set_bricks_to_set{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (set_id: felt, bricks_len: felt, bricks: felt*):
    # TODO: assert reasonable range
    if bricks_len == 0:
        return ()
    end
    set_part_of_set(token_id = [bricks + bricks_len - 1], set=set_id)
    set_bricks_to_set(set_id=set_id, bricks_len=bricks_len-1, bricks=bricks)
    return ()
end


@external
func unset_part_of_set{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (token_id: felt, set: felt):
    let (curr_set) = part_of_set.read(token_id)
    assert curr_set = set
    let (curr_owner) = owner.read(token_id)
    assert_not_zero(curr_owner)
    part_of_set.write(token_id, 0)
    return ()
end

@external
func unset_bricks_from_set{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (set_id: felt, bricks_len: felt, bricks: felt*):
    # TODO: assert reasonable range
    if bricks_len == 0:
        return ()
    end
    unset_part_of_set(token_id = [bricks + bricks_len - 1], set=set_id)
    unset_bricks_from_set(set_id=set_id, bricks_len=bricks_len-1, bricks=bricks)

    return ()
end


func find_item_index{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt, token_id: felt, cur_idx: felt, max: felt) -> (res: felt):
    alloc_locals
    local pedersen: HashBuiltin* = pedersen_ptr
    local range_check = range_check_ptr
    let (ct) = balance_details.read(owner, cur_idx)
    if ct == token_id:
        return (cur_idx)
    end
    if cur_idx == max:
        return (0)
    end
    return find_item_index{pedersen_ptr=pedersen, range_check_ptr=range_check}(owner, token_id, cur_idx + 1, max)
end

func _transfer{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (sender: felt, recipient: felt, token_id: felt):
    alloc_locals
    let (local curr_owner) = owner.read(token_id=token_id)
    assert curr_owner = sender
    # Cannot transfer a brick that's part of a set.
    let (curr_set) = part_of_set.read(token_id=token_id)
    assert curr_set = 0
    owner.write(token_id, recipient)

    # updating balances is annoying
    let (local cur) = balances.read(curr_owner)
    balances.write(curr_owner, cur - 1)

    #let (it) = find_item_index(curr_owner, token_id, 0, cur)
    #let (tok) = balance_details.read(curr_owner, cur - 1)
    #balance_details.write(curr_owner, it, tok)

    #let (rcur) = balances.read(recipient)
    #balances.write(recipient, rcur + 1)
    #balance_details.write(recipient, rcur, tok)

    return ()
end

@external
func transfer_from{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (sender: felt, recipient: felt, token_id: felt):
    _transfer(sender, recipient, token_id)
    return ()
end

func populate_tokens{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt, rett: felt*, ret_index: felt, max: felt):
    alloc_locals
    if ret_index == max:
        return ()
    end
    let(local retval0: felt) = balance_details.read(owner=owner, index=ret_index)
    let(local retMat0: felt) = material.read(token_id=retval0)
    let(local retSet0: felt) = part_of_set.read(token_id=retval0)
    rett[0] = retval0
    rett[1] = retMat0
    rett[2] = retSet0
    populate_tokens(owner, rett + 3, ret_index + 1, max)
    return ()
end

from starkware.cairo.common.alloc import alloc

@view
func get_all_tokens_for_owner{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt) -> (bricks_len: felt, bricks: felt*):
    alloc_locals
    let (local res: felt) = balances.read(owner=owner)
    
    let (local ret_array : felt*) = alloc()
    local ret_index = 0
    populate_tokens(owner, ret_array, ret_index, res)
    return (res * 3, ret_array)
end

