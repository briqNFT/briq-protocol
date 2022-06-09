%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_lt_felt
from starkware.starknet.common.syscalls import get_caller_address

from contracts.library_erc1155.transferability_library import ERC1155_lib_transfer
from contracts.library_erc1155.balance import _balance

from contracts.booklet_erc1155.token_uri import _shape_contract

namespace box_minting:

    @external
    func mint_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (owner: felt, token_id: felt, number: felt):

        let (balance) = _balance.read(owner, token_id)
        with_attr error_message("Mint would overflow balance"):
            assert_lt_felt(balance, balance + number)
        end
        _balance.write(owner, token_id, balance + number)

        let (caller) = get_caller_address()
        ERC1155_lib_transfer._onTransfer(caller, 0, owner, token_id, number)

        return ()
    end

end
