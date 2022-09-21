%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from contracts.types import BalanceSpec, NFTSpec

from contracts.briq.balance_enumerability import (
    ownerOf_,
    balanceOfMaterial_,
    balanceOfMaterials_,
    balanceDetailsOfMaterial_,
    materialsOf_,
    fullBalanceOf_,
    tokenOfOwnerByIndex_,
    totalSupplyOfMaterial_,
)

from contracts.briq.minting import mintFT_, mintOneNFT_

from contracts.briq.transferability import (
    transferFT_,
    transferOneNFT_,
    transferNFT_,
)

from contracts.briq.convert_mutate import (
    mutateFT_,
    mutateOneNFT_,
    convertOneToFT_,
    convertToFT_,
    convertOneToNFT_,
)

from contracts.upgrades.upgradable_mixin import (
    getAdmin_,
    getImplementation_,
    upgradeImplementation_,
    setRootAdmin_,
)


from contracts.ecosystem.to_set import (
    getSetAddress_,
    setSetAddress_,
)
from contracts.ecosystem.to_box import (getBoxAddress_, setBoxAddress_)

//

@view
func name_() -> (name: felt) {
    // briq
    return ('briq',);
}

@view
func symbol_() -> (symbol: felt) {
    // briq
    return ('briq',);
}

//// OZ-compatible interface

@view
func ownerOf{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(token_id: felt) -> (owner: felt) {
    let (owner) = ownerOf_(token_id);
    return (owner,);
}

@view
func balanceOfMaterial{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(owner: felt, material: felt) -> (balance: felt) {
    let (balance) = balanceOfMaterial_(owner, material);
    return (balance,);
}

@view
func balanceOfMaterials{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(owner: felt, materials_len: felt, materials: felt*) -> (balances_len: felt, balances: felt*) {
    let (balances_len, balances) = balanceOfMaterials_(owner, materials_len, materials);
    return (balances_len, balances);
}

@view
func materialsOf{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(owner: felt) -> (materials_len: felt, materials: felt*) {
    let (materials_len, materials) = materialsOf_(owner);
    return (materials_len, materials);
}

@view
func balanceDetailsOfMaterial{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(owner: felt, material: felt) -> (ft_balance: felt, nft_ids_len: felt, nft_ids: felt*) {
    let (ft_balance, nft_ids_len, nft_ids) = balanceDetailsOfMaterial_(owner, material);
    return (ft_balance, nft_ids_len, nft_ids);
}

@view
func fullBalanceOf{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(owner: felt) -> (balances_len: felt, balances: BalanceSpec*) {
    let (balances_len, balances) = fullBalanceOf_(owner);
    return (balances_len, balances);
}

@view
func tokenOfOwnerByIndex{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(owner: felt, material: felt, index: felt) -> (token_id: felt) {
    let (token_id) = tokenOfOwnerByIndex_(owner, material, index);
    return (token_id,);
}

@view
func totalSupplyOfMaterial{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(material: felt) -> (supply: felt) {
    let (supply) = totalSupplyOfMaterial_(material);
    return (supply,);
}

@external
func transferFT{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(sender: felt, recipient: felt, material: felt, qty: felt) -> () {
    transferFT_(sender, recipient, material, qty);
    return ();
}

@external
func transferOneNFT{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(sender: felt, recipient: felt, material: felt, briq_token_id: felt) -> () {
    transferOneNFT_(sender, recipient, material, briq_token_id);
    return ();
}

@external
func transferNFT{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(sender: felt, recipient: felt, material: felt, token_ids_len: felt, token_ids: felt*) -> () {
    transferNFT_(sender, recipient, material, token_ids_len, token_ids);
    return ();
}

@external
func mintFT{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(owner: felt, material: felt, qty: felt) -> () {
    mintFT_(owner, material, qty);
    return ();
}

@external
func mintOneNFT{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(owner: felt, material: felt, uid: felt) -> () {
    mintOneNFT_(owner, material, uid);
    return ();
}

@external
func mutateFT{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(owner: felt, source_material: felt, target_material: felt, qty: felt) -> () {
    mutateFT_(owner, source_material, target_material, qty);
    return ();
}

@external
func mutateOneNFT{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(owner: felt, source_material: felt, target_material: felt, uid: felt, new_uid: felt) -> () {
    mutateOneNFT_(owner, source_material, target_material, uid, new_uid);
    return ();
}

@external
func convertOneToFT{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(owner: felt, material: felt, token_id: felt) -> () {
    convertOneToFT_(owner, material, token_id);
    return ();
}

@external
func convertToFT{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(owner: felt, token_ids_len: felt, token_ids: NFTSpec*) -> () {
    convertToFT_(owner, token_ids_len, token_ids);
    return ();
}

@external
func convertOneToNFT{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(owner: felt, material: felt, uid: felt) -> () {
    convertOneToNFT_(owner, material, uid);
    return ();
}

@view
func name{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}() -> (name: felt) {
    let (name) = name_();
    return (name,);
}

@view
func symbol{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}() -> (symbol: felt) {
    let (symbol) = symbol_();
    return (symbol,);
}
