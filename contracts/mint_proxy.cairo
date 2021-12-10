%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

# Contract that limits minting for the alpha-mainnet release


@contract_interface
namespace IBriqContract:
    func mint_multiple(owner: felt, material:felt, token_start: felt, nb: felt):
    end
end

# Whether a user minted.
@storage_var
func _has_minted(user: felt) -> (res: felt):
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
    }(briq_contract_address: felt):
    _briq_contract_address.write(briq_contract_address)
    _cur_token_id.write(0x1)
    return()
end

# Whether a user already minted his briqs
@view
func has_minted{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (user: felt) -> (res: felt):
    let (res) = _has_minted.read(user=user)
    return (res)
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

    let (already_minted) = has_minted(user)
    assert already_minted = 0

    let (bca) = _briq_contract_address.read()
    let (start) = _cur_token_id.read()
    IBriqContract.mint_multiple(bca, user, 1, start, 100)
    _cur_token_id.write(start + 100)
    _has_minted.write(user, 1)
    return ()
end