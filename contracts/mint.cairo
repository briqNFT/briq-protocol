%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_le

// Contract that limits minting for the alpha release

const MATERIAL = 1;

@contract_interface
namespace IBriqContract {
    func mintFT(owner: felt, material: felt, qty: felt) {
    }
}

// How many free briqs a user can mint.
@storage_var
func _max_mint() -> (res: felt) {
}

// How many briqs a user has minted so far.
@storage_var
func _amount_minted(user: felt) -> (res: felt) {
}

// Address of the briq (proxy) contract.
@storage_var
func _briq_contract_address() -> (res: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    briq_contract_address: felt, max_mint: felt
) {
    _briq_contract_address.write(briq_contract_address);
    _max_mint.write(max_mint);
    return ();
}

// Whether how many briqs a user has minted
@view
func amountMinted{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(user: felt) -> (
    res: felt
) {
    let (res) = _amount_minted.read(user=user);
    return (res,);
}

// Mint briqs for a given user.
func _mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    user: felt, amount: felt
) {
    let (already_minted) = amountMinted(user);
    let (max) = _max_mint.read();
    assert_le(already_minted + amount, max);

    let (bca) = _briq_contract_address.read();
    IBriqContract.mintFT(bca, user, MATERIAL, amount);
    _amount_minted.write(user, already_minted + amount);
    return ();
}

// Request minting briqs for a given user.
@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(user: felt) {
    let (ca) = get_caller_address();
    assert ca = user;

    let (max) = _max_mint.read();
    _mint(user, max);
    return ();
}

// Request minting briqs for a given user.
@external
func mintAmount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    user: felt, amount: felt
) {
    let (ca) = get_caller_address();
    assert ca = user;

    _mint(user, amount);
    return ();
}
