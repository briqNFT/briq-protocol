%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_nn_le, assert_lt, assert_le, assert_not_zero, assert_lt_felt, unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.alloc import alloc

from starkware.cairo.common.bitwise import bitwise_and

from contracts.utilities.authorization import (
    _only,
    _onlyAdmin,
)

from contracts.set_erc721.token_uri import (
    tokenURI_,
    _setTokenURI,
    URI,
)

from contracts.set_erc721.balance_enumerability import (
    _owner,
    _balance,
    _setTokenByOwner,
    _unsetTokenByOwner,
)

from contracts.set_erc721.transferability import (
    _onTransfer,
)

from contracts.set_erc721.link_to_briq_token import (
    IBriqContract,
    _briq_address,
)

from contracts.types import ShapeItem

############
############
# Assembly/Disassembly

from contracts.types import FTSpec

func _transferFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, index: felt, fts: FTSpec*):
    if index == 0:
        return()
    end
    let (address) = _briq_address.read()
    IBriqContract.transferFT_(address, sender, recipient, fts[index - 1].token_id, fts[index - 1].qty)
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
    IBriqContract.transferOneNFT_(address, sender, recipient, material, nfts[index - 1])
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
func assemble_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (owner: felt, token_id_hint: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*, uri_len: felt, uri: felt*):
    alloc_locals

    _only(owner)
    assert_not_zero(owner)
    # This can't actually overflow because calldata of 2^252 elements would break the universe first.
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

@external
func disassemble_{
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

# TODO
@external
func updateBriqs_{
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

    let (local curr_owner) = _owner.read(token_id)
    assert curr_owner = owner

    _transferFT(owner, token_id, add_fts_len, add_fts)
    _transferNFT(owner, token_id, add_nfts_len, add_nfts)

    _transferFT(token_id, owner, remove_fts_len, remove_fts)
    _transferNFT(token_id, owner, remove_nfts_len, remove_nfts)

    # TODO: would be nice to be able to check that the set is not empty here.

    _setTokenURI(0, token_id, uri_len, uri)

    URI.emit(uri_len, uri, token_id)

    return ()
end

########################
########################
########################
########################
########################
########################


@external
func assemble_with_shape_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (owner: felt, token_id_hint: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*, uri_len: felt, uri: felt*, shape_len: felt, shape: ShapeItem*, target_shape_token_id: felt):
    assemble_(owner, token_id_hint, fts_len, fts, nfts_len, nfts, uri_len, uri)

    # Check that the passed shape does match what we'd expect.
    # NB -> This expects the NFTs to be sorted according to the shape sorting (which itself is standardised).
    # We don't actually need to check the shape sorting or duplicate NFTs, because:
    # - shape sorting would fail to match the target
    # - duplicated NFTs would fail to transfer.
    #_check_nfts_ok(shape_len, shape, nfts_len, nfts)
    #_check_ft_numbers_ok(fts_len, fts, shape_len, shape)

    # We need to make sure that the shape tokens match our numbers, so we count fungible tokens.
    # To do that, we'll create a vector of quantities that we'll increment when iterating.
    # For simplicity, we initialise it with the fts quantity, and decrement to 0, then just check that everything is 0.
    let (qty : felt*) = alloc()
    let (qty) = _initialize_qty(fts_len, fts, qty)
    _check_numbers_ok(fts_len, fts, qty - fts_len, nfts_len, nfts, shape_len, shape)

    # Check that the shape matches the target.
    # target_shape_token_id

    return ()
end

func _initialize_qty{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (fts_len: felt, fts: FTSpec*, qty: felt*) -> (qty: felt*):
    if fts_len == 0:
        return (qty)
    end
    assert qty[0] = fts[0].qty
    return _initialize_qty(fts_len - 1, fts + FTSpec.SIZE, qty + 1)
end

func _check_qty_are_correct{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (fts_len: felt, qty: felt*) -> ():
    if fts_len == 0:
        return ()
    end
    assert qty[0] = 0
    return _check_qty_are_correct(fts_len - 1, qty + 1)
end


func _check_numbers_ok{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (fts_len: felt, fts: FTSpec*, qty: felt*, nfts_len: felt, nfts: felt*, shape_len: felt, shape: ShapeItem*):
    if shape_len == 0:
        with_attr error_message("Wrong number of briqs in shape"):
            _check_qty_are_correct(fts_len, qty)
        end
        return ()
    end
    # Algorithm:
    # If the shape item is an nft, compare with the next nft in the list, if match, carry on.
    # Otherwise, decrement the corresponding FT quantity. This is O(n) because we must copy the whole vector.
    let (nft) = is_le_felt(2**250, shape[0].color_nft_material * (2**(122)))
    if nft == 1:
        # assert_non_zero nfts_len  ?
        # Check that the material matches.
        let a = shape[0].color_nft_material - nfts[0]
        let b = a / (2 ** 64)
        let (is_same_mat) = is_le_felt(b, 2**187)
        assert is_same_mat = 1
        return _check_numbers_ok(fts_len, fts, qty, nfts_len - 1, nfts + 1, shape_len - 1, shape + ShapeItem.SIZE)
    else:
        # Find the material
        # NB: using a bitwise here is somewhat balanced with the cairo steps & range comparisons,
        # and so it ends up being more gas efficient than doing the is_le_felt trick.
        let (mat) = bitwise_and(shape[0].color_nft_material, 2**64 - 1)
        # Decrement the appropriate counter
        _decrement_ft_qty(fts_len, fts, qty, mat, remaining_ft_to_parse=fts_len)
        return _check_numbers_ok(fts_len, fts, qty + fts_len, nfts_len, nfts, shape_len - 1, shape + ShapeItem.SIZE)
    end
end

# We need to keep a counter for each material we run into.
# But because of immutability, we'll need to copy the full vector of materials every time.
func _decrement_ft_qty{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (fts_len: felt, fts: FTSpec*, qty: felt*, material: felt, remaining_ft_to_parse: felt):
    if remaining_ft_to_parse == 0:
        return ()
    end
    if material == fts[0].token_id:
        assert qty[fts_len] = qty[0] - 1
        return _decrement_ft_qty(fts_len, fts + FTSpec.SIZE, qty + 1, material, remaining_ft_to_parse - 1)
    else:
        assert qty[fts_len] = qty[0]
        return _decrement_ft_qty(fts_len, fts + FTSpec.SIZE, qty + 1, material, remaining_ft_to_parse - 1)
    end
end
