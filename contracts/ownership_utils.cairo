from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.cairo_builtins import HashBuiltin

func assert_allowed_to_mint(minter: felt, recipient: felt):
    assert minter = recipient
    assert_not_zero(recipient)
    return ()
end

func assert_allowed_to_set_part_of_set(setter: felt, owner: felt):
    assert setter = owner
    assert_not_zero(owner)
    return ()
end

func assert_allowed_to_admin_contract{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(address: felt):
    # TODO: delegate to a proxy contract? At least setup in the constructor.
    if address == 0x46fda85f6ff5b7303b71d632b842e950e354fa08225c4f62eee23a1abbec4eb:
        return ()
    end
    if address == 0x6043ed114a9a1987fe65b100d0da46fe71b2470e7e5ff8bf91be5346f5e5e3:
        return ()
    end
    assert 0 = 1
    return ()
end
