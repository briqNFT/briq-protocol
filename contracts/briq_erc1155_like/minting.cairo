%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.math import assert_nn_le, assert_lt, assert_le, assert_not_zero, assert_lt_felt, assert_le_felt
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.alloc import alloc

from contracts.utilities.authorization import (
    _onlyAdmin,
    _onlyAdminAnd,
)

from contracts.briq_erc1155_like.balance_enumerability import (
    _owner,
    _balance,
    _total_supply,
    _setTokenByOwner,
    _unsetTokenByOwner,
    _setMaterialByOwner,
    _maybeUnsetMaterialByOwner,
)

from contracts.briq_erc1155_like.transferability import (
    TransferSingle,
)

####################
####################
####################
# Mint Contract

@storage_var
func _mint_contract() -> (address: felt):
end

@external
func setMintContract_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (address: felt):
    _onlyAdmin()
    _mint_contract.write(address)
    return ()
end


@view
func getMintContract_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } () -> (address: felt):
    let (addr) = _mint_contract.read()
    return (addr)
end

func _onlyAdminAndMintContract{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } ():
    let (address) = _mint_contract.read()
    _onlyAdminAnd(address)
    return ()
end

################
################
################

@external
func mintFT_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, material: felt, qty: felt):
    _onlyAdminAndMintContract()

    assert_not_zero(owner)
    assert_not_zero(material)
    assert_not_zero(qty)

    # Update total supply.
    let (res) = _total_supply.read(material)
    _total_supply.write(material, res + qty)

    # FT conversion
    let briq_token_id = material

    let (balance) = _balance.read(owner, briq_token_id)
    _balance.write(owner, briq_token_id, balance + qty)

    _setMaterialByOwner(owner, material, 0)

    let (__addr) = get_contract_address()
    TransferSingle.emit(__addr, 0, owner, briq_token_id, qty)

    return ()    
end

@external
func mintOneNFT_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, material: felt, uid: felt):
    _onlyAdminAndMintContract()

    assert_not_zero(owner)
    assert_not_zero(material)
    assert_not_zero(uid)
    assert_lt_felt(uid, 2**188)

    # Update total supply.
    let (res) = _total_supply.read(material)
    _total_supply.write(material, res + 1)

    # NFT conversion
    let briq_token_id = uid * 2**64 + material

    let (curr_owner) = _owner.read(briq_token_id)
    assert curr_owner = 0
    _owner.write(briq_token_id, owner)

    _setMaterialByOwner(owner, material, 0)
    _setTokenByOwner(owner, material, briq_token_id, 0)

    let (__addr) = get_contract_address()
    TransferSingle.emit(__addr, 0, owner, briq_token_id, 1)

    return ()
end