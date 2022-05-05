%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and

from contracts.utilities.authorization import (
    _onlyAdmin,
)

from contracts.types import FTSpec, ShapeItem

from contracts.box_erc721.token_uri import box_token_uri

############
############
### Relationship with the set contract

@contract_interface
namespace ISetContract:
    func assemble_(owner: felt, token_id_hint: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*, uri_len: felt, uri: felt*):
    end
end

@storage_var
func _set_address() -> (address: felt):
end

namespace box_set_factory:

    @view
    func getSetAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
        } () -> (address: felt):
        let (value) = _set_address.read()
        return (value)
    end

    @external
    func setSetAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
        } (address: felt):
        _onlyAdmin()
        _set_address.write(address)
        return ()
    end

    ############
    ############

    @external
    func assemble_with_shape_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            bitwise_ptr: BitwiseBuiltin*,
            range_check_ptr
        } (owner: felt, token_id_hint: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*, uri_len: felt, uri: felt*, shape_len: felt, shape: ShapeItem*, target_shape_token_id: felt):
        alloc_locals

        local pedersen_ptr: HashBuiltin* = pedersen_ptr
        let (addr) = getSetAddress_()
        ISetContract.assemble_(addr, owner, token_id_hint, fts_len, fts, nfts_len, nfts, uri_len, uri)

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
        box_token_uri.check_shape_(target_shape_token_id, shape_len, shape, nfts_len, nfts)

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

end
