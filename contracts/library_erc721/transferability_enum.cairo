%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin

from contracts.library_erc721.approvals import ERC721_approvals
from contracts.library_erc721.transferability_library import ERC721_lib_transfer

from contracts.library_erc721.enumerability import ERC721_enumerability

namespace ERC271_transferability:
    @external
    func transferFrom_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (sender: felt, recipient: felt, token_id: felt):
        ERC721_approvals._onlyApproved(sender, token_id)

        ERC721_lib_transfer._transfer(sender, recipient, token_id)

        # Unset before setting, so that self-transfers work.
        ERC721_enumerability._unsetTokenByOwner(sender, token_id)
        ERC721_enumerability._setTokenByOwner(recipient, token_id, 0)

        return ()
    end
end
