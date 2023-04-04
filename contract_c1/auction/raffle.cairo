%lang starknet

// Need:
// - Balance of token per user.
// - Way to buy N tokens
// - A reveal function


@storage_var
func _balance(owner: felt) -> (balance: felt) {
}


func _increaseBalance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, number: felt,
) {
    let (balance) = _balance.read(owner);
    with_attr error_message("Mint would overflow balance") {
        assert_lt_felt(balance, balance + number);
    }
    _balance.write(owner, balance + number);
    return ();
}

func _decreaseBalance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, number: felt,
) {
    let (balance) = _balance.read(owner);
    with_attr error_message("Insufficient balance") {
        assert_lt_felt(balance - number, balance);
    }
    _balance.write(owner, balance - number);
    return ();
}



@external
func buy_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt,
    number: felt,
) {
    // Take token from contract address to player.
}



@external
func reveal_raffle{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owners_len: felt,
    owners: felt*,
) {
    onlyAdmin_();
    // Algo: generate a random-ish value, modulo it LIST_LEN, then transfer the corresponding set.
    // If the set is not owned by this contract, then it has already been raffled.
    // In that case, try the next one, then the next one, wrapping around at the start if needed.
}
