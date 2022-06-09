%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_lt_felt
from starkware.starknet.common.syscalls import get_caller_address

from contracts.library_erc1155.transferability_library import ERC1155_lib_transfer
from contracts.library_erc1155.balance import _balance

from contracts.booklet_erc1155.token_uri import _shape_contract

namespace box_unboxing:

    # Unbox burns the box NFT, and mints briqs & booklet corresponding to the token URI.
    @external
    func unbox_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (owner: felt, token_id: felt):

        let (balance) = _balance.read(owner, token_id)
        with_attr error_message("Insufficient balance"):
            assert_lt_felt(balance - 1, balance)
        end
        
        _balance.write(owner, token_id, balance - 1)

        let (caller) = get_caller_address()
        ERC1155_lib_transfer._onTransfer(caller, owner, 0, token_id, 1)

        return ()
    end

end
