%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_lt_felt, assert_le_felt
from starkware.starknet.common.syscalls import get_caller_address

from starkware.cairo.common.registers import get_label_location

from contracts.library_erc1155.transferability import ERC1155_transferability
from contracts.library_erc1155.balance import ERC1155_balance

from contracts.utilities.authorization import _onlyAdmin

from contracts.box_nft.data import shape_data_start, shape_data_end

@external
func mint_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, token_id: felt, number: felt
) {
    _onlyAdmin();

    ERC1155_balance._increaseBalance(owner, token_id, number);

    let (caller) = get_caller_address();
    ERC1155_transferability._onTransfer(caller, 0, owner, token_id, number);

    // Make sure we have data for that token ID
    let (_shape_data_start) = get_label_location(shape_data_start);
    let (_shape_data_end) = get_label_location(shape_data_end);
    assert_lt_felt(0, token_id);
    assert_le_felt(token_id, _shape_data_end - _shape_data_start);

    return ();
}
