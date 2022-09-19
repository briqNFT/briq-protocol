%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.math import (
    assert_nn_le,
    assert_lt,
    assert_le,
    assert_not_zero,
    assert_lt_felt,
    assert_le_felt,
)
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

from contracts.library_erc1155.transferability_library import ERC1155_lib_transfer

from contracts.ecosystem.to_box import _box_address

from contracts.utilities.authorization import _onlyAdminAnd

func _onlyAdminAndBoxContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (address) = _box_address.read();
    _onlyAdminAnd(address);
    return ();
}

@external
func mintFT_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, material: felt, qty: felt
) {
    _onlyAdminAndBoxContract();

    assert_not_zero(owner);
    assert_not_zero(material);
    assert_lt_felt(material, 2 ** 64);
    assert_not_zero(qty);

    // Update total supply.
    let (res) = _total_supply.read(material);
    with_attr error_message("Overflow in total supply") {
        assert_lt_felt(res, res + qty);
    }
    _total_supply.write(material, res + qty);

    // FT conversion
    let briq_token_id = material;

    let (balance) = _balance.read(owner, briq_token_id);
    with_attr error_message("Overflow in balance") {
        assert_lt_felt(balance, balance + qty);
    }
    _balance.write(owner, briq_token_id, balance + qty);

    _setMaterialByOwner(owner, material, 0);

    let (__addr) = get_contract_address();
    ERC1155_lib_transfer._onTransfer(__addr, 0, owner, briq_token_id, qty);

    return ();
}

@external
func mintOneNFT_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, material: felt, uid: felt
) {
    _onlyAdminAndBoxContract();

    assert_not_zero(owner);
    assert_not_zero(material);
    assert_lt_felt(material, 2 ** 64);
    assert_not_zero(uid);
    assert_lt_felt(uid, 2 ** 188);

    // Update total supply.
    let (res) = _total_supply.read(material);
    with_attr error_message("Overflow in total supply") {
        assert_lt_felt(res, res + 1);
    }
    _total_supply.write(material, res + 1);

    // NFT conversion
    let briq_token_id = uid * 2 ** 64 + material;

    let (curr_owner) = _owner.read(briq_token_id);
    assert curr_owner = 0;
    _owner.write(briq_token_id, owner);

    _setMaterialByOwner(owner, material, 0);
    _setTokenByOwner(owner, material, briq_token_id, 0);

    let (__addr) = get_contract_address();
    ERC1155_lib_transfer._onTransfer(__addr, 0, owner, briq_token_id, 1);

    return ();
}
