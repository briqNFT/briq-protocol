%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256

from contracts.library_erc1155.approvals import ERC1155_approvals
from contracts.library_erc1155.balance import ERC1155_balance
from contracts.library_erc1155.token_uri import ERC1155_token_uri
from contracts.library_erc1155.transferability import ERC1155_transferability

from contracts.utilities.IERC165 import (TRUE, FALSE, IERC165_ID, IERC1155_ID, IERC1155_METADATA_ID)

//@external
//func approve_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//    to: felt, token_id: felt, value: felt
//) {
//    return ERC1155_approvals.approve_(to, token_id, value);
//}

@external
func setApprovalForAll_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    approved_address: felt, is_approved: felt
) {
    return ERC1155_approvals.setApprovalForAll_(approved_address, is_approved);
}

//@view
//func getApproved_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//    on_behalf_of: felt, token_id: felt, address: felt
//) -> (approved_value: felt) {
//    return ERC1155_approvals.getApproved_(on_behalf_of, token_id, address);
//}

@view
func isApprovedForAll_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    on_behalf_of: felt, address: felt
) -> (is_approved: felt) {
    return ERC1155_approvals.isApprovedForAll_(on_behalf_of, address);
}

@view
func balanceOf_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, token_id: felt
) -> (balance: felt) {
    return ERC1155_balance.balanceOf_(owner, token_id);
}

@view
func balanceOfBatch_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owners_len: felt, owners: felt*, token_ids_len: felt, token_ids: felt*
) -> (balances_len: felt, balances: felt*) {
    return ERC1155_balance.balanceOfBatch_(owners_len, owners, token_ids_len, token_ids);
}

@view
func uri_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    token_id: felt
) -> (uri_len: felt, uri: felt*) {
    return ERC1155_token_uri.uri_(token_id);
}

@external
func safeTransferFrom_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sender: felt, recipient: felt, token_id: felt, value: felt, data_len: felt, data: felt*
) {
    return ERC1155_transferability.safeTransferFrom_(sender, recipient, token_id, value, data_len, data);
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    if (interfaceId == IERC165_ID) {
        return (success=TRUE);
    }
    if (interfaceId == IERC1155_ID) {
        return (success=TRUE);
    }
    if (interfaceId == IERC1155_METADATA_ID) {
        return (success=TRUE);
    }
    return (success=FALSE);
}
