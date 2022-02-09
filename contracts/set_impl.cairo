%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_nn_le, assert_lt, assert_le, assert_not_zero, assert_lt_felt, unsigned_div_rem
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.alloc import alloc

from starkware.cairo.common.bitwise import bitwise_and

from starkware.cairo.common.uint256 import Uint256

from contracts.Uint256_felt_conv import (
    _uint_to_felt,
    _felt_to_uint,
)

@contract_interface
namespace IBriqContract:
    func transferFT(sender: felt, recipient: felt, material: felt, qty: felt):
    end
    func transferOneNFT(sender: felt, recipient: felt, material: felt, briq_token_id: felt):
    end
end


############
############
############
# Storage variables.

@storage_var
func _owner(token_id: felt) -> (owner: felt):
end

# To save on gas costs, the LSB of the token_uri can be 1 to indicate extra data is present. A 0 indicates no extra data.
# Further, the next LSB stores whether the token URI is partly written in the token_id or not.
# Because felts are 251 bits, that means we can store at most 249 bits of information.
# This is fine because ASCII strings are 31 characters, or 248 bits.
@storage_var
func _token_uri(token_id: felt) -> (token_uri: felt):
end

# Likewise, the LSB indicates whether the data continues or not.
@storage_var
func _token_uri_extra(token_id: felt, index: felt) -> (uri_data: felt):
end

@storage_var
func _balance(owner: felt) -> (balance: felt):
end

@storage_var
func _token_by_owner(owner: felt, index: felt) -> (token_id: felt):
end

## Utility

@storage_var
func _briq_address() -> (address: felt):
end


############
############
############
# Events

## ERC721 compatibility
@event
func Transfer(from_: felt, to_: felt, token_id_: Uint256):
end

## ERC1155 compatibility
@event
func URI(value__len: felt, value_: felt*, id_: felt):
end

func _onTransfer{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, token_id: felt):
    let (tk) = _felt_to_uint(token_id)
    Transfer.emit(sender, recipient, tk)
    return ()
end

############
############
############
## Authorization patterns

from contracts.authorization import (
    _only,
    _onlyAdmin,
    _onlyAdminAnd,
)

func _onlyApproved{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, token_id: felt):
    let (caller) = get_caller_address()
    if sender == caller:
        return ()
    end
    let (isOperator) = isApprovedForAll(sender, caller)
    if isOperator - 1 == 0:
        return ()
    end
    let (approved) = getApproved_(token_id)
    _only(approved)
    return ()
end


############
############
############
# Admin functions

@external
func setBriqAddress{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (address: felt):
    _onlyAdmin()
    _briq_address.write(address)
    return ()
end

############
############
############
# Public functions - no authentication required

@view
func balanceOf_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt) -> (balance: felt):
    let (balance) = _balance.read(owner)
    return (balance)
end

func _NFTBalanceDetailsOfIdx{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, index: felt, nft_ids: felt*) -> (tokenIds: felt*):
    let (token_id) = _token_by_owner.read(owner, index)
    if token_id == 0:
        return (nft_ids)
    end
    nft_ids[0] = token_id
    return _NFTBalanceDetailsOfIdx(owner, index + 1, nft_ids + 1)
end

@view
func balanceDetailsOf_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt) -> (token_ids_len: felt, token_ids: felt*):
    alloc_locals
    let (local nfts: felt*) = alloc()
    let (nfts_full) = _NFTBalanceDetailsOfIdx(owner, 0, nfts)
    return (nfts_full - nfts, nfts)
end

# We don't implement full enumerability, just per-user
@view
func tokenOfOwnerByIndex_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, index: felt) -> (token_id: felt):
    let (token_id) = _token_by_owner.read(owner, index)
    return (token_id)
end

@view
func ownerOf_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (token_id: felt) -> (owner: felt):
    let (res) = _owner.read(token_id)
    return (res)
end

func _fetchExtraUri{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (token_id: felt, index: felt, res: felt*) -> (nb: felt):
    let (tok) = _token_uri_extra.read(token_id, index)
    let (extra) = bitwise_and(tok, 1)
    if extra == 0:
        tempvar calc = tok / 4
        res[0] = calc
        return (index)
    end
    tempvar calc = (tok - 1) / 4
    res[0] = calc
    return _fetchExtraUri(token_id, index + 1, res + 1)
end

@view
func tokenURI_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (token_id: felt) -> (uri_len: felt, uri: felt*):
    alloc_locals
    let (tok) = _token_uri.read(token_id)
    let (extra) = bitwise_and(tok, 3) # two LSBs
    let (local res: felt*) = alloc()
    if extra == 0:
        tempvar calc = tok / 4
        res[0] = calc
        return (1, res)
    else:
        # Special token_id mode.
        if extra == 3:
            tempvar calc = (tok - 3)/ 4
            res[0] = calc
            let (toktok) = bitwise_and(token_id, 2**59 - 1)
            res[1] = toktok
            return (2, res)
        end
        tempvar calc = (tok - 1)/ 4
        res[0] = calc
        let (nb_items) = _fetchExtraUri(token_id, 0, res + 1)
        return (nb_items + 2, res)
    end
    #return (0)
end

############
############
############
# Authenticated functions


# TODOOO -> use builtins?
func _setTokenByOwner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner, token_id, index):

    let (tok_id) = _token_by_owner.read(owner, index)
    if tok_id == token_id:
        return()
    end
    if tok_id == 0:
        _token_by_owner.write(owner, index, token_id)
        return ()
    end
    return _setTokenByOwner(owner, token_id, index + 1)
end

# TODOOO -> use builtins?
# Step 1 -> find the target index.
func _unsetTokenByOwner_step1{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner, token_id, index) -> (target_index: felt, last_token_id: felt):
    
    let (tok_id) = _token_by_owner.read(owner, index)
    assert_not_zero(tok_id)
    if tok_id == token_id:
        return (index, token_id)
    end
    return _unsetTokenByOwner_step1(owner, token_id, index + 1)
end

# Step 2 -> once we're past the end, get the last item
func _unsetTokenByOwner_step2{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, index: felt, last_token_id: felt) -> (last_index: felt, last_token_id: felt):
    let (tok_id) = _token_by_owner.read(owner, index)
    if tok_id == 0:
        return (index - 1, last_token_id)
    end
    return _unsetTokenByOwner_step2(owner, index + 1, tok_id)
end

func _unsetTokenByOwner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, token_id: felt):
    alloc_locals

    let (local target_index, last_token_id) = _unsetTokenByOwner_step1(owner, token_id, 0)
    let (last_index, last_token_id) = _unsetTokenByOwner_step2(owner, target_index + 1, last_token_id)
    if last_index == target_index:
        _token_by_owner.write(owner, target_index, 0)
    else:
        _token_by_owner.write(owner, target_index, last_token_id)
        _token_by_owner.write(owner, last_index, 0)
    end
    return()
end

############
############
# Assembly/Disassembly

from contracts.types import (FTSpec)

func _transferFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, index: felt, fts: FTSpec*):
    if index == 0:
        return()
    end
    let (address) = _briq_address.read()
    IBriqContract.transferFT(address, sender, recipient, fts[index - 1].token_id, fts[index - 1].qty)
    return _transferFT(sender, recipient, index - 1, fts)
end


func _transferNFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, index: felt, nfts: felt*):
    if index == 0:
        return()
    end
    let (address) = _briq_address.read()
    let (uid, material) = unsigned_div_rem(nfts[index - 1], 2**64)
    IBriqContract.transferOneNFT(address, sender, recipient, material, nfts[index - 1])
    return _transferNFT(sender, recipient, index - 1, nfts)
end

from starkware.cairo.common.hash_state import (
    hash_init, hash_finalize, hash_update, hash_update_single
)

# To prevent people from generating collisions, we need the token_id to be random.
# However, we need it to be predictable for good UI.
# The solution adopted is to hash a hint. Our security becomes the chain hash security.
# To be able to store e.g. sha-256 IPFS data in the tokenURI, we reserve a few bits
# off the end for extra-URI storage when minting.
func _hashTokenId{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (owner: felt, token_id_hint: felt, uri_len: felt, uri: felt*) -> (token_id: felt):
    let hash_ptr = pedersen_ptr
    with hash_ptr:
        let (hash_state_ptr) = hash_init()
        let (hash_state_ptr) = hash_update_single(hash_state_ptr, owner)
        let (hash_state_ptr) = hash_update_single(hash_state_ptr, token_id_hint)
        let (token_id) = hash_finalize(hash_state_ptr)
        # The magic number is (2**251 - 1) - (2**59 - 1), which leaves the top 192 bits for the token_id.
        let (token_id) = bitwise_and(token_id, 3618502788666131106986593281521497120414687020801267626232473039494981877760)
    end
    let pedersen_ptr = hash_ptr
    let (token_id) = _maybeAddPartOfTokenUri(token_id, uri_len, uri)
    return (token_id)
end

# If the token URI is two items long, and the second item fits in the remainder 59 bits,
# then store it there instead of writing another storage variable.
# NB: this will become an integral part of the token_id, so that even if the URI changes
# in the future, it won't change. As such, it's only a minting-time optimisation.
func _maybeAddPartOfTokenUri{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (token_id: felt, uri_len: felt, uri: felt*) -> (token_id: felt):
    if uri_len == 2:
        let (rem) = bitwise_and(uri[1], 2**59 - 1)
        if uri[1] == rem:
            let token_id = token_id + uri[1]
            return (token_id)
        end
        return (token_id)
    end
    return (token_id)
end

@external
func assemble{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (owner: felt, token_id_hint: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*, uri_len: felt, uri: felt*):
    alloc_locals

    _only(owner)
    assert_not_zero(owner)
    assert_not_zero(fts_len + nfts_len)

    let (local token_id: felt) = _hashTokenId(owner, token_id_hint, uri_len, uri)

    let (curr_owner) = _owner.read(token_id)
    assert curr_owner = 0
    _owner.write(token_id, owner)

    let (balance) = _balance.read(owner)
    _balance.write(owner, balance + 1)

    _transferFT(owner, token_id, fts_len, fts)
    _transferNFT(owner, token_id, nfts_len, nfts)

    _setTokenByOwner(owner, token_id, 0)

    _setTokenURI(1, token_id, uri_len, uri)

    _onTransfer(0, owner, token_id)
    URI.emit(uri_len, uri, token_id)

    return ()
end

func _setExtraTokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (token_id: felt, max: felt, index: felt, uri: felt*):
    assert_lt_felt(uri[0], 2**249)
    if max == index:
        _token_uri_extra.write(token_id, index, uri[0] * 4)
        return()
    end
    _token_uri_extra.write(token_id, index, uri[0] * 4 + 1)
    return _setExtraTokenURI(token_id, max, index + 1, uri + 1)
end

func _setTokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (may_use_special_token_mode: felt, token_id: felt, uri_len: felt, uri: felt*):
    assert_not_zero(uri_len)
    assert_lt_felt(uri[0], 2**249)

    # This is 0 or 1
    if uri_len * may_use_special_token_mode == 2:
        let (rem) = bitwise_and(uri[1], 2**59 - 1)
        if uri[1] == rem:
            # The rest has already been written in the token-id
            # Flag it with both special bits for continuation and 'part of token_id'.
            _token_uri.write(token_id, uri[0] * 4 + 3)
            return ()
        end
        # Write the first URI with the special continuation LSB
        _token_uri.write(token_id, uri[0] * 4 + 1)
        _setExtraTokenURI(token_id, uri_len - 2, 0, uri + 1)
        # event_uri.emit(token_id, uri_len, uri)
    else:
        if uri_len == 1:
            # Just write the URI normally.
            _token_uri.write(token_id, uri[0] * 4)
            return ()
        end
        # Write the first URI with the special continuation LSB
        _token_uri.write(token_id, uri[0] * 4 + 1)
        _setExtraTokenURI(token_id, uri_len - 2, 0, uri + 1)
        # event_uri.emit(token_id, uri_len, uri)
    end    
    return()
end

@external
func setTokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (token_id: felt, uri_len: felt, uri: felt*):
    alloc_locals
    
    _onlyAdmin()
    # TODO: is this useless?
    let (owner) = _owner.read(token_id)
    assert_not_zero(owner)
    
    _setTokenURI(0, token_id, uri_len, uri)

    URI.emit(uri_len, uri, token_id)

    return()
end


@external
func updateBriqs{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (owner: felt, token_id: felt,
        add_fts_len: felt, add_fts: FTSpec*,
        add_nfts_len: felt, add_nfts: felt*,
        remove_fts_len: felt, remove_fts: FTSpec*,
        remove_nfts_len: felt, remove_nfts: felt*,
        uri_len: felt, uri: felt*):
    alloc_locals
    _onlyAdmin()

    assert_not_zero(token_id)
    assert_not_zero(owner)

    _transferFT(owner, token_id, add_fts_len, add_fts)
    _transferNFT(owner, token_id, add_nfts_len, add_nfts)

    _transferFT(token_id, owner, remove_fts_len, remove_fts)
    _transferNFT(token_id, owner, remove_nfts_len, remove_nfts)

    # TODO: would be nice to be able to check that the set is not empty here.

    _setTokenURI(0, token_id, uri_len, uri)

    URI.emit(uri_len, uri, token_id)

    return ()
end

@external
func disassemble{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, token_id: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*):
    alloc_locals
    _only(owner)

    assert_not_zero(token_id)
    assert_not_zero(owner)

    let (local curr_owner) = _owner.read(token_id)
    assert curr_owner = owner
    _owner.write(token_id, 0)

    _transferFT(token_id, curr_owner, fts_len, fts)
    _transferNFT(token_id, curr_owner, nfts_len, nfts)

    let (balance) = _balance.read(owner)
    _balance.write(curr_owner, balance - 1)

    _unsetTokenByOwner(curr_owner, token_id)

    _onTransfer(curr_owner, 0, token_id)

    return ()
end


############
############
# Transfer

@external
func transferOneNFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, token_id: felt):
    _onlyApproved(sender, token_id)
    # Reset approval (0 cost if was 0 before)
    _approve_noauth(0, token_id)

    let (curr_owner) = _owner.read(token_id)
    assert sender = curr_owner
    _owner.write(token_id, recipient)

    let (balance) = _balance.read(sender)
    _balance.write(sender, balance - 1)
    let (balance) = _balance.read(recipient)
    _balance.write(recipient, balance + 1)

    _setTokenByOwner(recipient, token_id, 0)
    _unsetTokenByOwner(sender, token_id)

    _onTransfer(sender, recipient, token_id)

    return ()
end

################
################
################
# Approval stuff

from contracts.allowance import (
    get_approved as getApproved_,
    is_approved_for_all as isApprovedForAll_,
    _setApprovalForAll_noauth,
    _approve_noauth,
)

@external
func approve_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (approved_address: felt, token_id: felt):
    let (owner) = ownerOf_(token_id)
    _only(owner)
    _approve_noauth(approved_address, token_id)
    return ()
end

@external
func setApprovalForAll_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (approved_address: felt, allowed: felt):
    let (owner) = get_caller_address()
    _setApprovalForAll_noauth(on_behalf_of=owner, approved_address=approved_address, allowed=allowed)
    return ()
end


################
################
################
################
################
################
# ERC 721 - OZ compatibility

@view
func balanceOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt) -> (balance: Uint256):
    let (res) = balanceOf_(owner)
    let (res2) = _felt_to_uint(res)
    return (res2)
end

# This isn't part of ERC721 but I have it so let's have it.
@view
func balanceDetailsOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt) -> (token_ids_len: felt, token_ids: felt*):
    let (i, j) = balanceDetailsOf_(owner)
    return (i, j)
end

# We don't implement full enumerability, just per-user
@view
func tokenOfOwnerByIndex{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, index: felt) -> (token_id: Uint256):
    let (token_id) = tokenOfOwnerByIndex_(owner, index)
    let (t2) = _felt_to_uint(token_id)
    return (t2)
end

@view
func ownerOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (token_id: Uint256) -> (owner: felt):
    let (_tok) = _uint_to_felt(token_id)
    let (owner) = ownerOf_(_tok)
    return (owner)
end

@view
func tokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (token_id: Uint256) -> (uri_len: felt, uri: felt*):
    let (_tok) = _uint_to_felt(token_id)
    let (l, u) = tokenURI_(_tok)
    return (l, u)
end

@external
func transferFrom{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, token_id: Uint256):
    let (_tok) = _uint_to_felt(token_id)
    transferOneNFT(sender, recipient, _tok)
    return ()
end

@view
func getApproved{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (token_id: Uint256) -> (approved: felt):
    let (_tok) = _uint_to_felt(token_id)
    let (res) = getApproved_(_tok)
    return (res)
end

@view
func isApprovedForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, operator: felt) -> (is_approved: felt):
    let (res) = isApprovedForAll_(owner, operator)
    return (res)
end

@external
func approve{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (approved_address: felt, token_id: Uint256):
    let (_tok) = _uint_to_felt(token_id)
    approve_(approved_address, _tok)
    return ()
end

@external
func setApprovalForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (approved_address: felt, allowed: felt):
    setApprovalForAll(approved_address, allowed)
    return ()
end