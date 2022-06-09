%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero

from contracts.library_erc1155.approvals import ERC1155_approvals
from contracts.library_erc1155.transferability_library import ERC1155_lib_transfer

namespace ERC1155_transferability:
    @external
    func safeTransferFrom_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (sender: felt, recipient: felt, token_id: felt, value: felt, data_len : felt, data : felt*):
        # TODO -> support detailed approvals.
        ERC1155_approvals._onlyApprovedAll(sender)

        ERC1155_lib_transfer._transfer(sender, recipient, token_id, value)

        # TODO: called the receiver function. I'm not entirely sure how to handle accounts yet...

        return ()
    end
end
