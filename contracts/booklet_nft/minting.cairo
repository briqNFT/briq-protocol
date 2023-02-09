%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_lt_felt
from starkware.starknet.common.syscalls import get_caller_address

from contracts.library_erc1155.transferability import ERC1155_transferability
from contracts.library_erc1155.balance import ERC1155_balance

from contracts.booklet_nft.token_uri import _shape_contract

from contracts.ecosystem.to_box import _box_address

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
    let (box_addr) = _box_address.read();
    _onlyAdminAnd(box_addr);
    ERC1155_transferability._onTransfer(caller, 0, owner, token_id, 1);

    return ();
}
