%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.cairo.common.find_element import search_sorted
from starkware.cairo.common.registers import get_label_location

from starkware.starknet.common.syscalls import (
    get_caller_address,
)

from contracts.utilities.authorization import _onlyAdmin

list_start:
dw 0x00439d7ed01976d4633667dce210aa880aeadc85e6d3d621eb7b87659df54984;
list_end:

func _onlyAllowed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) {
    alloc_locals;
    let (start) = get_label_location(list_start);
    let (end) = get_label_location(list_end);
    let (caller) = get_caller_address();
    let (elm_ptr: felt*, success: felt) = search_sorted(cast(start, felt*), 1, end - start, caller);
    
    with_attr error_message("Caller is not in the allow list") {
        if (success == 1) {
            return ();
        }
        // Allow admins so they can settle the auction.
        _onlyAdmin();
    }
    
    return ();
}
