%lang starknet

struct FTSpec:
    member token_id: felt
    member qty: felt
end

struct NFTSpec:
    member material: felt
    member token_id: felt
end

struct BalanceSpec:
    member material: felt
    member balance: felt
end
