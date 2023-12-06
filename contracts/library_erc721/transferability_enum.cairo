%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin

from contracts.library_erc721.approvals import ERC721_approvals
from contracts.library_erc721.transferability import ERC721_transferability

from contracts.library_erc721.enumerability import ERC721_enumerability

// Not namespaced for convenience
@external
func transferFrom_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sender: felt, recipient: felt, token_id: felt
) {
    // TEMP - deactivated for the briq dojo migration
    // ERC721_approvals._onlyApproved(sender, token_id);

    ERC721_transferability._transfer(sender, recipient, token_id);

    // Unset before setting, so that self-transfers work.
    ERC721_enumerability._unsetTokenByOwner(sender, token_id);
    ERC721_enumerability._setTokenByOwner(recipient, token_id, 0);

    return ();
}
