%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_le

# Contract that limits minting for the alpha-mainnet release

@contract_interface
namespace IBriqContract:
    func mint_multiple(owner: felt, material:felt, token_start: felt, nb: felt):
    end
end

# How many free briqs a user can mint.
@storage_var
func _max_mint() -> (res: felt):
end

# How many briqs a user has minted so far.
@storage_var
func _amount_minted(user: felt) -> (res: felt):
end

# Current start token ID
@storage_var
func _cur_token_id() -> (res: felt):
end

# Address of the briq contract.
@storage_var
func _briq_contract_address() -> (res: felt):
end

@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(briq_contract_address: felt, max_mint: felt):
    _briq_contract_address.write(briq_contract_address)
    _max_mint.write(max_mint)
    _cur_token_id.write(0x1)
    return()
end

# Whether how many briqs a user has minted
@view
func amount_minted{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (user: felt) -> (res: felt):
    let (res) = _amount_minted.read(user=user)
    return (res)
end

# Mint briqs for a given user.
func _mint{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (user: felt, amount: felt):
    let (already_minted) = amount_minted(user)
    let (max) = _max_mint.read()
    assert_le(already_minted + amount, max)

    let (bca) = _briq_contract_address.read()
    let (start) = _cur_token_id.read()
    
    IBriqContract.mint_multiple(bca, user, 1, start, amount)
    _cur_token_id.write(start + amount)
    _amount_minted.write(user, already_minted + amount)
    return ()
end

# Request minting briqs for a given user.
@external
func mint{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (user: felt):
    let (ca) = get_caller_address()
    assert ca = user

    let (max) = _max_mint.read()
    _mint(user, max)
    return ()
end

# Request minting briqs for a given user.
@external
func mint_amount{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (user: felt, amount: felt):
    let (ca) = get_caller_address()
    assert ca = user

    _mint(user, amount)
    return ()
end