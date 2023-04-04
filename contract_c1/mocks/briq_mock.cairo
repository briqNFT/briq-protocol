%lang starknet

@external
func transferFT_(sender: felt, recipient: felt, material: felt, qty: felt) {
    return ();
}

@external
func transferOneNFT_(sender: felt, recipient: felt, material: felt, briq_token_id: felt) {
    return ();
}

@external
func balanceOf_(owner: felt, material: felt) -> (balance: felt) {
    return (0,);
}
