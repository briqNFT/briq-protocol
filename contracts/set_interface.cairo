# ERC 721 - OZ compatibility
# The core briq interface is made of felt, but we provide a Uint256-aware interface
# by default, for easier interoperability.

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from contracts.set_impl import (
    ERC721_approvals,
    ERC721_balance,
    ERC721_enumerability,
    ERC271_transferability,
    tokenURI_,
    tokenURIData_,
)

from starkware.cairo.common.uint256 import Uint256

from contracts.utilities.Uint256_felt_conv import (
    _uint_to_felt,
    _felt_to_uint,
)

################
## Metadata extension
################

@view
func name() -> (name: felt):
    # briq
    return ('briq')
end

@view
func symbol() -> (symbol: felt):
    # briq
    return ('briq')
end

# NB: unlike OZ, this returns a list of felt
@view
func tokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*):
    let (_tok) = _uint_to_felt(tokenId)
    let (l, u) = tokenURI_(_tok)
    return (l, u)
end

@view
func tokenURIData{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*):
    let (_tok) = _uint_to_felt(tokenId)
    let (l, u) = tokenURIData_(_tok)
    return (l, u)
end

################
## Partial enumerability extension
################

@view
func tokenOfOwnerByIndex{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, index: felt) -> (token_id: Uint256):
    let (token_id) = ERC721_enumerability.tokenOfOwnerByIndex_(owner, index)
    let (t2) = _felt_to_uint(token_id)
    return (t2)
end

################
## ERC 721 interface
################

@view
func balanceOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt) -> (balance: Uint256):
    let (res) = ERC721_balance.balanceOf_(owner)
    let (res2) = _felt_to_uint(res)
    return (res2)
end

# This isn't part of ERC721 but I have it so let's have it.
@view
func balanceDetailsOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt) -> (tokenIds_len: felt, tokenIds: felt*):
    let (i, j) = ERC721_enumerability.balanceDetailsOf_(owner)
    return (i, j)
end

@view
func ownerOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (tokenId: Uint256) -> (owner: felt):
    let (_tok) = _uint_to_felt(tokenId)
    let (owner) = ERC721_balance.ownerOf_(_tok)
    return (owner)
end

@external
func transferFrom{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (from_: felt, to: felt, tokenId: Uint256):
    let (_tok) = _uint_to_felt(tokenId)
    ERC271_transferability.transferFrom_(from_, to, _tok)
    return ()
end

## TODO: implement safeTransferFrom

@external
func approve{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (approved: felt, tokenId: Uint256):
    let (_tok) = _uint_to_felt(tokenId)
    ERC721_approvals.approve_(approved, _tok)
    return ()
end


@external
func setApprovalForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (operator: felt, approved: felt):
    ERC721_approvals.setApprovalForAll_(approved, operator)
    return ()
end

@view
func getApproved{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (tokenId: Uint256) -> (approved: felt):
    let (_tok) = _uint_to_felt(tokenId)
    let (res) = ERC721_approvals.getApproved_(_tok)
    return (res)
end

@view
func isApprovedForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, operator: felt) -> (isApproved: felt):
    let (res) = ERC721_approvals.isApprovedForAll_(owner, operator)
    return (res)
end
