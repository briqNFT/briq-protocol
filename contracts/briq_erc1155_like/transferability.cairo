%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.math import assert_nn_le, assert_lt, assert_le, assert_not_zero, assert_lt_felt, assert_le_felt
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.alloc import alloc

from contracts.briq_erc1155_like.balance_enumerability import (
    _owner,
    _balance,
    _total_supply,
    _setTokenByOwner,
    _unsetTokenByOwner,
    _setMaterialByOwner,
    _maybeUnsetMaterialByOwner,
)

## ERC1155 compatibility (without URI - there is none)

# NB: Operator is set to the address of the current contract.
# I don't really want to forward a semi-arbitrary operator for this.
# NB2: Mutate does two transfer events & a single Mutate event
@event
func TransferSingle(operator_: felt, from_: felt, to_: felt, id_: felt, value_: felt):
end


@storage_var
func _set_backend_address() -> (address: felt):
end

############
############
############
## Authorization patterns

from contracts.utilities.authorization import (
    _only,
    _onlyAdmin,
    _onlyAdminAnd,
)

func _onlySetAnd{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (address: felt):
    let (caller) = get_caller_address()
    let (setaddr) = _set_backend_address.read()
    if caller == setaddr:
        return()
    end
    _only(address)
    return ()
end

############
############
############
# Admin functions

@external
func setSetAddress_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (address: felt):
    _onlyAdmin()
    _set_backend_address.write(address)
    return ()
end


## TODO -> mint multiple NFT

@external
func transferFT_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, material: felt, qty: felt):
    _onlySetAnd(sender)
    
    assert_not_zero(sender)
    assert_not_zero(material)
    assert_not_zero(qty)
    
    # FT conversion
    let briq_token_id = material

    let (balance_sender) = _balance.read(sender, briq_token_id)
    assert_le_felt(qty, balance_sender)
    _balance.write(sender, briq_token_id, balance_sender - qty)
    
    let (balance) = _balance.read(recipient, briq_token_id)
    _balance.write(recipient, briq_token_id, balance + qty)

    _setMaterialByOwner(recipient, material, 0)
    _maybeUnsetMaterialByOwner(sender, material)

    let (__addr) = get_contract_address()
    TransferSingle.emit(__addr, sender, recipient, briq_token_id, qty)

    return ()
end

@external
func transferOneNFT_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, material: felt, briq_token_id: felt):
    _onlySetAnd(sender)

    assert_not_zero(sender)
    assert_not_zero(material)
    assert_not_zero(briq_token_id)

    let (curr_owner) = _owner.read(briq_token_id)
    assert sender = curr_owner
    _owner.write(briq_token_id, recipient)

    # Unset before setting, so that self-transfers work.
    _unsetTokenByOwner(sender, material, briq_token_id)
    _setTokenByOwner(recipient, material, briq_token_id, 0)

    _maybeUnsetMaterialByOwner(sender, material) # Keep after unset token or it won't unset
    _setTokenByOwner(recipient, material, briq_token_id, 0)

    let (__addr) = get_contract_address()
    TransferSingle.emit(__addr, sender, recipient, briq_token_id, 1)

    return ()
end

func _transferNFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, material: felt, index: felt, token_ids: felt*):
    if index == 0:
        return ()
    end
    transferOneNFT_(sender, recipient, material, token_ids[index - 1])
    return _transferNFT(sender, recipient, material, index - 1, token_ids)
end

@external
func transferNFT_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, material: felt, token_ids_len: felt, token_ids: felt*):
    # Calls authorized methods, no need to check here.
    _transferNFT(sender, recipient, material, token_ids_len, token_ids)
    return ()
end
