%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_nn_le, assert_lt, assert_not_zero
from starkware.cairo.common.registers import get_fp_and_pc

from contracts.ownership_utils import (
    assert_allowed_to_admin_contract
)

## Regular ERC721
@storage_var
func owner(token_id: felt) -> (res: felt):
end

@storage_var
func balances(owner: felt) -> (nb: felt):
end

@storage_var
func balance_details(owner: felt, index: felt) -> (res: felt):
end

#### Specific bit

# Address of the set contract.
@storage_var
func set_contract() -> (res: felt):
end

# Address of the minting proxy contract.
@storage_var
func mint_contract() -> (res: felt):
end

# Address of the ERC20 proxy contract.
@storage_var
func erc20_contract() -> (res: felt):
end


###

# Material encodes the rarity. Values range 1-16
@storage_var
func material(token_id: felt) -> (res: felt):
end

# Says if a brick is part of set
@storage_var
func part_of_set(token_id: felt) -> (res: felt):
end

############
############
############

@external
func initialize{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (
        set_contract_address: felt,
        mint_contract_address: felt,
        erc20_contract_address: felt
    ):

    let (caller) = get_caller_address()
    assert_allowed_to_admin_contract(caller)

    set_contract.write(set_contract_address)
    mint_contract.write(mint_contract_address)
    erc20_contract.write(erc20_contract_address)

    return ()
end


func assert_allowed_to_mint{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(minter: felt, recipient: felt):
    if minter == 0x46fda85f6ff5b7303b71d632b842e950e354fa08225c4f62eee23a1abbec4eb:
        return ()
    end
    if minter == 0x6043ed114a9a1987fe65b100d0da46fe71b2470e7e5ff8bf91be5346f5e5e3:
        return ()
    end
    let (mc) = mint_contract.read()
    if minter == mc:
        return ()
    end
    assert 0 = 1
    return ()
end

############
############
############
#
# Getters
#

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

@view
func get_mint_contract{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } () -> (res: felt):
    let (retval) = mint_contract.read()
    return (retval)
end

############
############
############

func _mint{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (recipient: felt, token_id: felt, mat: felt):
    assert_not_zero(mat)

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
    
    let (caller) = get_caller_address()
    assert_allowed_to_mint(caller, owner)
    
    _mint(owner, token_id, material)
    return ()
end

@external
func mint_multiple{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt, material:felt, token_start: felt, nb: felt):

    let (caller) = get_caller_address()
    assert_allowed_to_mint(caller, owner)

    if nb == 0:
        return ()
    end
    _mint(owner, token_start + nb - 1, material)
    mint_multiple(owner, material, token_start, nb - 1)
    return ()
end

func _set_part_of_set{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (token_id: felt, set: felt):
    let (curr_set) = part_of_set.read(token_id)
    assert curr_set = 0

    part_of_set.write(token_id, set)
    return ()
end

@external
func set_bricks_to_set{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (set_id: felt, bricks_len: felt, bricks: felt*):

    # Only let the set contract handle sets
    let (caller) = get_caller_address()
    let (set_contract_address) = set_contract.read()
    assert caller = set_contract_address

    # TODO: assert reasonable range
    if bricks_len == 0:
        return ()
    end
    _set_part_of_set(token_id = [bricks + bricks_len - 1], set=set_id)
    set_bricks_to_set(set_id=set_id, bricks_len=bricks_len-1, bricks=bricks)
    return ()
end


func _unset_part_of_set{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (token_id: felt, set: felt):
    let (curr_set) = part_of_set.read(token_id)
    assert curr_set = set

    part_of_set.write(token_id, 0)
    return ()
end

@external
func unset_bricks_from_set{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (set_id: felt, bricks_len: felt, bricks: felt*):

    # Only let the set contract handle sets
    let (caller) = get_caller_address()
    let (set_contract_address) = set_contract.read()
    assert caller = set_contract_address

    # TODO: assert reasonable range
    if bricks_len == 0:
        return ()
    end

    _unset_part_of_set(token_id = [bricks + bricks_len - 1], set=set_id)
    unset_bricks_from_set(set_id=set_id, bricks_len=bricks_len-1, bricks=bricks)

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


func _transfer{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, token_id: felt):

    let (curr_owner) = owner.read(token_id=token_id)
    assert curr_owner = sender

    let (res) = balances.read(owner=sender)
    balances.write(sender, res - 1)
    erase_balance_details(sender, token_id, res - 1)

    let (res2) = balances.read(owner=recipient)
    balances.write(recipient, res2 + 1)
    balance_details.write(recipient, res2, token_id)

    owner.write(token_id, recipient)

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

    _transfer(sender, recipient, token_id)
    return ()
end

# Transfer multiple briqs at once.
@external
func transfer_briqs{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (sender: felt, recipient: felt, bricks_len: felt, bricks: felt*):

    # Only let the set contract call this
    let (caller) = get_caller_address()
    let (set_contract_address) = set_contract.read()
    assert caller = set_contract_address

    # TODO: assert reasonable range
    if bricks_len == 0:
        return ()
    end

    # Recurse
    _transfer(sender, recipient, [bricks + bricks_len - 1])
    transfer_briqs(sender=sender, recipient=recipient, bricks_len=bricks_len-1, bricks=bricks)

    return ()
end


func _erc20_transfer{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (sender: felt, recipient: felt, amount: felt, idx: felt):
    if amount == 0:
        return ()
    end
    let (token_id) = balance_details.read(sender, idx)
    assert_not_zero(token_id)
    let (set) = part_of_set.read(token_id)
    if set == 0:
        _transfer(sender, recipient, token_id)
        _erc20_transfer(sender, recipient, amount - 1, idx)
    else:
        _erc20_transfer(sender, recipient, amount, idx + 1)
    end
    return ()
end

# Transfer multiple briqs at once, without specifying which.
@external
func ERC20_transfer{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (sender: felt, recipient: felt, amount: felt) -> (success: felt):

    # Only let the ERC20 proxy contract call this
    let (caller) = get_caller_address()
    let (addr) = erc20_contract.read()
    assert caller = addr

    _erc20_transfer(sender, recipient, amount, 0)

    return (1)
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
    let (mat) = material.read(token_id=token_id)
    let (set) = part_of_set.read(token_id=token_id)
    rett[0] = token_id
    rett[1] = mat
    rett[2] = set
    return populate_tokens(owner, rett + 3, idx - 1)
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

func _do_get_bricks_for_set{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt, set_id: felt, rett: felt*, idx: felt) -> (res: felt*):
    if idx == -1:
        return (rett)
    end
    let (token_id) = balance_details.read(owner=owner, index=idx)
    let (set) = part_of_set.read(token_id=token_id)
    if set == set_id:
        rett[0] = token_id
        return _do_get_bricks_for_set(owner, set_id, rett + 1, idx - 1)
    else:
        return _do_get_bricks_for_set(owner, set_id, rett, idx - 1)
    end
end

# Get all tokens from a set (you need the set owner which can be queried separately from the set contract).
@view
func get_bricks_for_set{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt, set_id: felt) -> (tokens_len: felt, tokens: felt*):
    alloc_locals
    let (local ret_array : felt*) = alloc()
    let (nb_tokens) = balances.read(owner=owner)
    let (nv) = _do_get_bricks_for_set(owner, set_id, ret_array, nb_tokens - 1)
    return (nv - ret_array, ret_array)
end
