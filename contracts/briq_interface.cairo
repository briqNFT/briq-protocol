
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from contracts.briq_impl import (
	ownerOf_,
	balanceOfMaterial_,
	balanceOfMaterials_,
	materialsOf_,
	balanceDetailsOfMaterial_,
	fullBalanceOf_,
	tokenOfOwnerByIndex_,
	totalSupplyOfMaterial_,
	setSetAddress_,
	transferFT_,
	transferOneNFT_,
	transferNFT_,
	setMintContract_,
	getMintContract_,
	mintFT_,
	mintOneNFT_,
	mutateFT_,
	mutateOneNFT_,
	convertOneToFT_,
	convertToFT_,
	convertOneToNFT_,
	name_,
	symbol_,
	balanceOf_,
	balanceDetailsOf_,
	multiBalanceOf_,
	totalSupply_
)
from contracts.types import (
	BalanceSpec,
	NFTSpec
)

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (token_id: felt) -> (owner: felt):
    let (owner) = ownerOf_(token_id)
    return (owner)
end

@view
func balanceOfMaterial{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt, material: felt) -> (balance: felt):
    let (balance) = balanceOfMaterial_(owner, material)
    return (balance)
end

@view
func balanceOfMaterials{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt, materials_len: felt, materials: felt*) -> (balances_len: felt, balances: felt*):
    let (balances_len, balances) = balanceOfMaterials_(owner, materials_len, materials)
    return (balances_len, balances)
end

@view
func materialsOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt) -> (materials_len: felt, materials: felt*):
    let (materials_len, materials) = materialsOf_(owner)
    return (materials_len, materials)
end

@view
func balanceDetailsOfMaterial{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt, material: felt) -> (ft_balance: felt, nft_ids_len: felt, nft_ids: felt*):
    let (ft_balance, nft_ids_len, nft_ids) = balanceDetailsOfMaterial_(owner, material)
    return (ft_balance, nft_ids_len, nft_ids)
end

@view
func fullBalanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt) -> (balances_len: felt, balances: BalanceSpec*):
    let (balances_len, balances) = fullBalanceOf_(owner)
    return (balances_len, balances)
end

@view
func tokenOfOwnerByIndex{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt, material: felt, index: felt) -> (token_id: felt):
    let (token_id) = tokenOfOwnerByIndex_(owner, material, index)
    return (token_id)
end

@view
func totalSupplyOfMaterial{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (material: felt) -> (supply: felt):
    let (supply) = totalSupplyOfMaterial_(material)
    return (supply)
end

@external
func transferFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (sender: felt, recipient: felt, material: felt, qty: felt) -> ():
    transferFT_(sender, recipient, material, qty)
    return ()
end

@external
func transferOneNFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (sender: felt, recipient: felt, material: felt, briq_token_id: felt) -> ():
    transferOneNFT_(sender, recipient, material, briq_token_id)
    return ()
end

@external
func transferNFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (sender: felt, recipient: felt, material: felt, token_ids_len: felt, token_ids: felt*) -> ():
    transferNFT_(sender, recipient, material, token_ids_len, token_ids)
    return ()
end

@external
func mintFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt, material: felt, qty: felt) -> ():
    mintFT_(owner, material, qty)
    return ()
end

@external
func mintOneNFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt, material: felt, uid: felt) -> ():
    mintOneNFT_(owner, material, uid)
    return ()
end

@external
func mutateFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt, source_material: felt, target_material: felt, qty: felt) -> ():
    mutateFT_(owner, source_material, target_material, qty)
    return ()
end

@external
func mutateOneNFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt, source_material: felt, target_material: felt, uid: felt, new_uid: felt) -> ():
    mutateOneNFT_(owner, source_material, target_material, uid, new_uid)
    return ()
end

@external
func convertOneToFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt, material: felt, token_id: felt) -> ():
    convertOneToFT_(owner, material, token_id)
    return ()
end

@external
func convertToFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt, token_ids_len: felt, token_ids: NFTSpec*) -> ():
    convertToFT_(owner, token_ids_len, token_ids)
    return ()
end

@external
func convertOneToNFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt, material: felt, uid: felt) -> ():
    convertOneToNFT_(owner, material, uid)
    return ()
end

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } () -> (name: felt):
    let (name) = name_()
    return (name)
end

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } () -> (symbol: felt):
    let (symbol) = symbol_()
    return (symbol)
end

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt, material: felt) -> (balance: felt):
    let (balance) = balanceOf_(owner, material)
    return (balance)
end

@view
func balanceDetailsOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt, material: felt) -> (ft_balance: felt, nft_ids_len: felt, nft_ids: felt*):
    let (ft_balance, nft_ids_len, nft_ids) = balanceDetailsOf_(owner, material)
    return (ft_balance, nft_ids_len, nft_ids)
end

@view
func multiBalanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (owner: felt, materials_len: felt, materials: felt*) -> (balances_len: felt, balances: felt*):
    let (balances_len, balances) = multiBalanceOf_(owner, materials_len, materials)
    return (balances_len, balances)
end

@view
func totalSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (material: felt) -> (supply: felt):
    let (supply) = totalSupply_(material)
    return (supply)
end
