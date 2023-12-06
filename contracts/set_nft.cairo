// Just a proxy for importing from the subfiles.
// TODO: auto-generate this maybe.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from contracts.types import FTSpec
from starkware.cairo.common.uint256 import Uint256
from contracts.utilities.Uint256_felt_conv import _uint_to_felt, _felt_to_uint
from contracts.ecosystem.to_migration import (getMigrationAddress_, setMigrationAddress_)


from contracts.upgrades.upgradable_mixin import (
    getAdmin_,
    getImplementation_,
    upgradeImplementation_,
    setRootAdmin_,
)


from contracts.ecosystem.to_briq import (
    getBriqAddress_,
    setBriqAddress_,
)

from contracts.ecosystem.to_attributes_registry import (
    getAttributesRegistryAddress_,
    setAttributesRegistryAddress_,
)

from contracts.library_erc721.IERC721 import (
    approve_,
    setApprovalForAll_,
    getApproved_,
    isApprovedForAll_,
    ownerOf_,
    balanceOf_,
    balanceDetailsOf_,
    tokenOfOwnerByIndex_,
    supportsInterface,
)

from contracts.library_erc721.IERC721_enumerable import (
    transferFrom_,
)

from contracts.set_nft.token_uri import tokenURI_
from contracts.set_nft.assembly import assemble_, disassemble_


//###############
// # Metadata extension
//###############

@view
func name() -> (name: felt) {
    // briq
    return ('briq',);
}

@view
func symbol() -> (symbol: felt) {
    // briq
    return ('briq',);
}


// OZ-like version, though this returns a list of felt.
@view
func tokenURI{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr,
}(tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*) {
    let (_tok) = _uint_to_felt(tokenId);
    let (l, u) = tokenURI_(_tok);
    return (l, u);
}


//###############
// # Partial enumerability extension
//###############

@view
func tokenOfOwnerByIndex{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, index: felt
) -> (token_id: Uint256) {
    let (token_id) = tokenOfOwnerByIndex_(owner, index);
    let (t2) = _felt_to_uint(token_id);
    return (t2,);
}

//###############
// # ERC 721 interface
//###############

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    balance: Uint256
) {
    let (res) = balanceOf_(owner);
    let (res2) = _felt_to_uint(res);
    return (res2,);
}

// This isn't part of ERC721 but I have it so let's have it.
@view
func balanceDetailsOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt
) -> (tokenIds_len: felt, tokenIds: felt*) {
    let (i, j) = balanceDetailsOf_(owner);
    return (i, j);
}

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    owner: felt
) {
    let (_tok) = _uint_to_felt(tokenId);
    let (owner) = ownerOf_(_tok);
    return (owner,);
}

@external
func transferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256
) {
    let (_tok) = _uint_to_felt(tokenId);
    transferFrom_(from_, to, _tok);
    return ();
}

// # TODO: implement safeTransferFrom

@external
func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    approved: felt, tokenId: Uint256
) {
    let (_tok) = _uint_to_felt(tokenId);
    approve_(approved, _tok);
    return ();
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    setApprovalForAll_(approved_address=operator, is_approved=approved);
    return ();
}

@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (approved: felt) {
    let (_tok) = _uint_to_felt(tokenId);
    let (res) = getApproved_(_tok);
    return (res,);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, operator: felt
) -> (isApproved: felt) {
    let (res) = isApprovedForAll_(owner, operator);
    return (res,);
}
