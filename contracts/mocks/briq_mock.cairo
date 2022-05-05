%lang starknet

@external
func transferFT_(sender: felt, recipient: felt, material: felt, qty: felt):
    return()
end

@external
func transferOneNFT_(sender: felt, recipient: felt, material: felt, briq_token_id: felt):
    return()
end

@external
func balanceOf_(owner: felt, material: felt) -> (balance: felt):
    return(0)
end
