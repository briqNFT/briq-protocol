from starkware.cairo.common.math import assert_not_zero

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

func assert_allowed_to_admin_contract(address: felt):
    # TODO: security lol
    return ()
end