%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256

from contracts.library_erc721.transferability_enum import ERC721_transferability


@external
func transferFrom_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sender: felt, recipient: felt, token_id: felt
) {
    return ERC721_transferability.transferFrom_(sender, recipient, token_id);
}
