%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256

from contracts.library_erc721.approvals import ERC721_approvals
from contracts.library_erc721.balance import ERC721
from contracts.library_erc721.enumerability import ERC721_enumerability
from contracts.library_erc721.transferability import ERC721_transferability

from contracts.utilities.IERC165 import (TRUE, FALSE, IERC165_ID, IERC721_ID, IERC721_METADATA_ID)

@external
func approve_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, token_id: felt
) {
    return ERC721_approvals.approve_(to, token_id);
}

@external
func setApprovalForAll_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    approved_address: felt, is_approved: felt
) {
    return ERC721_approvals.setApprovalForAll_(approved_address, is_approved);
}

@view
func getApproved_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt
) -> (approved: felt) {
    return ERC721_approvals.getApproved_(token_id);
}

@view
func isApprovedForAll_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    on_behalf_of: felt, address: felt
) -> (is_approved: felt) {
    return ERC721_approvals.isApprovedForAll_(on_behalf_of, address);
}

@view
func ownerOf_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt
) -> (owner: felt) {
    return ERC721.ownerOf_(token_id);
}

@view
func balanceOf_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt
) -> (balance: felt) {
    return ERC721.balanceOf_(owner);
}

@view
func balanceDetailsOf_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt
) -> (token_ids_len: felt, token_ids: felt*) {
    return ERC721_enumerability.balanceDetailsOf_(owner);
}

@view
func tokenOfOwnerByIndex_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, index: felt
) -> (token_id: felt) {
    return ERC721_enumerability.tokenOfOwnerByIndex_(owner, index);
}

@external
func transferFrom_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sender: felt, recipient: felt, token_id: felt
) {
    return ERC721_transferability.transferFrom_(sender, recipient, token_id);
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    if (interfaceId == IERC165_ID) {
        return (success=TRUE);
    }
    if (interfaceId == IERC721_ID) {
        return (success=TRUE);
    }
    if (interfaceId == IERC721_METADATA_ID) {
        return (success=TRUE);
    }
    return (success=FALSE);
}
