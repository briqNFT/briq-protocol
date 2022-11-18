%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from contracts.utilities.Uint256_felt_conv import _uint_to_felt, _felt_to_uint, _uints_to_felts, _felts_to_uints

from contracts.library_erc1155.IERC1155 import (
    balanceOf_,
    balanceOfBatch_,
    setApprovalForAll_,
    isApprovedForAll_,
    safeTransferFrom_,
    uri_
)

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, id: Uint256
) -> (balance: Uint256) {
    let (tid) = _uint_to_felt(id);
    let (b) = balanceOf_(owner=account, token_id=tid);
    let (uintb) = _felt_to_uint(b);
    return (uintb,);
}

@view
func balanceOfBatch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    accounts_len: felt, accounts: felt*, ids_len: felt, ids: Uint256*
) -> (balances_len: felt, balances: Uint256*) {
    let (tid_l, tid) = _uints_to_felts(ids_len, ids);
    let (bs_l, bs) = balanceOfBatch_(owners_len=accounts_len, owners=accounts, token_ids_len=tid_l, token_ids=tid);
    let (ubs_l, ubs) = _felts_to_uints(bs_l, bs);
    return (ubs_l, ubs);
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    return setApprovalForAll_(approved_address=operator, is_approved=approved);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, operator: felt
) -> (isApproved: felt) {
    let (r) = isApprovedForAll_(on_behalf_of=account, address=operator);
    return (r,);
}

@external
func safeTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, to: felt, id: Uint256, amount: Uint256, data_len: felt, data: felt*
) {
    let (tid) = _uint_to_felt(id);
    let (tam) = _uint_to_felt(amount);
    return safeTransferFrom_(sender=from_, recipient=to, token_id=tid, value=tam, data_len=data_len, data=data);
}

// Not quite OZ compliant -> I return a list of felt.
@view
func uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    id: Uint256
) -> (uri_len: felt, uri: felt*) {
    let (tid) = _uint_to_felt(id);
    return uri_(token_id=tid);
}
