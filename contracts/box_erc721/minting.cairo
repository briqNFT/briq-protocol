%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin

from contracts.library_erc721.transferability_library import ERC721_lib_transfer
from contracts.library_erc721.balance import _owner, _balance

from contracts.box_erc721.token_uri import _shape_contract

namespace box_minting:

    @external
    func mint_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (owner: felt, token_id: felt, shape_contract: felt):

        _owner.write(token_id, owner)
        let (balance) = _balance.read(owner)
        _balance.write(owner, balance + 1)

        _shape_contract.write(token_id, shape_contract)

        ERC721_lib_transfer._onTransfer(0, owner, token_id)

        return ()
    end

end
