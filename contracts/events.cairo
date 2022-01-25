%lang starknet

# TODO: ERC721/1155 compatibiltiy
@event
func transfer_token(_from: felt, _to: felt, _token_id: felt):
end

@event
func transfer_value(_from: felt, _to: felt, _value: felt):
end

@event
func uri(_id: felt, _value_len: felt, _value: felt*):
end
