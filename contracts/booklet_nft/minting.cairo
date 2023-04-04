%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_lt_felt
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math_cmp import is_le_felt

from contracts.library_erc1155.transferability import ERC1155_transferability
from contracts.library_erc1155.balance import ERC1155_balance

from contracts.booklet_nft.token_uri import _shape_contract

from contracts.ecosystem.to_box import _box_address
from contracts.ecosystem.genesis_collection import DUCKS_COLLECTION
from contracts.utilities.authorization import _onlyAdminAnd

@external
func mint_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, token_id: felt, shape_contract: felt
) {
    alloc_locals;
    ERC1155_balance._increaseBalance(owner, token_id, 1);

    _shape_contract.write(token_id, shape_contract);

    // Can only be minted by the box contract or an admin of the contract.
    let (caller) = get_caller_address();
    if (caller == 0x02ef9325a17d3ef302369fd049474bc30bfeb60f59cca149daa0a0b7bcc278f8) {
        // Allow OutSmth to mint ducks.
        let tid = (token_id - DUCKS_COLLECTION) / 2**192;
        // Check this is below an arbitrary low number to make sure the range is correct
        assert_lt_felt(tid, 10000);

        ERC1155_transferability._onTransfer(caller, 0, owner, token_id, 1);
        return ();
    } else {
        let (box_addr) = _box_address.read();
        _onlyAdminAnd(box_addr);

        ERC1155_transferability._onTransfer(caller, 0, owner, token_id, 1);
        return ();
    }
}
