%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from contracts.briq_erc1155_like.balance_enumerability import (
    ownerOf_,
    balanceOfMaterial_,
    balanceOfMaterials_,
    balanceDetailsOfMaterial_,
    materialsOf_,
    fullBalanceOf_,
    tokenOfOwnerByIndex_,
    totalSupplyOfMaterial_,
)

from contracts.briq_erc1155_like.minting import (
    setMintContract_,
    getMintContract_,
    mintFT_,
    mintOneNFT_,
)

from contracts.briq_erc1155_like.transferability import (
    setSetAddress_,
    transferFT_,
    transferOneNFT_,
    transferNFT_,
)

from contracts.briq_erc1155_like.convert_mutate import (
    mutateFT_,
    mutateOneNFT_,
    convertOneToFT_,
    convertToFT_,
    convertOneToNFT_,
)

####

@view
func name_() -> (name: felt):
    # briq
    return ('briq')
end

@view
func symbol_() -> (symbol: felt):
    # briq
    return ('briq')
end

# Temporary retro-compatibility interface.

@view
func balanceOf_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt, material: felt) -> (balance: felt):
    let (balance) = balanceOfMaterial_(owner, material)
    return (balance)
end

@view
func balanceDetailsOf_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt, material: felt) -> (ft_balance: felt, nft_ids_len: felt, nft_ids: felt*):
    let (ft_balance, nft_ids_len, nft_ids) = balanceDetailsOfMaterial_(owner, material)
    return (ft_balance, nft_ids_len, nft_ids)
end

@view
func multiBalanceOf_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt, materials_len: felt, materials: felt*) -> (balances_len: felt, balances: felt*):
    let (balances_len, balances) = balanceOfMaterials_(owner, materials_len, materials)
    return (balances_len, balances)
end

@view
func totalSupply_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (material: felt) -> (supply: felt):
    let (supply) = totalSupplyOfMaterial_(material)
    return (supply)
end
