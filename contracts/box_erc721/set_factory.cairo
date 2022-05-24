%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and
from starkware.starknet.common.syscalls import get_caller_address

from contracts.utilities.authorization import (
    _onlyAdmin,
)

from contracts.types import FTSpec, ShapeItem

from contracts.box_erc721.token_uri import box_token_uri
from contracts.library_erc721.balance import ERC721
from contracts.library_erc721.transferability_library import ERC721_lib_transfer

############
############
### Relationship with the set contract

@contract_interface
namespace ISetContract:
    func assemble_(owner: felt, token_id_hint: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*, uri_len: felt, uri: felt*):
    end
end

@contract_interface
namespace IShapeContract:
    func _shape() -> (shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*):
    end

    func check_shape_numbers_(shape_len: felt, shape: ShapeItem*, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*):
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
    func wrap_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            bitwise_ptr: BitwiseBuiltin*,
            range_check_ptr
        } (
            owner: felt,
            set_token_id: felt,
            box_token_id: felt,
            shape_len: felt, shape: ShapeItem*,
            fts_len: felt, fts: FTSpec*,
            nfts_len: felt, nfts: felt*
        ):
        alloc_locals

        let (caller) = get_caller_address()
        let (set_addr) = getSetAddress_()
        assert caller = set_addr
        # TODO: check set is authorized still.

        let (box_owner) = ERC721.ownerOf_(box_token_id)
        # we trust 'owner' will be correct because it's passed from the set address.
        assert box_owner = owner

        # Transfer the box to the set (wrapping it inside the set).
        ERC721_lib_transfer._transfer(owner, set_token_id, box_token_id)

        # Check that the shape matches the passed data
        let (local addr) = box_token_uri.get_shape_contract_(box_token_id)
        local pedersen_ptr: HashBuiltin* = pedersen_ptr
        IShapeContract.check_shape_numbers_(
            addr, shape_len, shape, fts_len, fts, nfts_len, nfts
        )

        return ()
    end

    @external
    func unwrap_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            bitwise_ptr: BitwiseBuiltin*,
            range_check_ptr
        } (
            owner: felt,
            set_token_id: felt,
            box_token_id: felt,
        ):
        let (caller) = get_caller_address()
        let (set_addr) = getSetAddress_()
        assert caller = set_addr

        let (box_owner) = ERC721.ownerOf_(box_token_id)
        # TODO: auth ?
        assert box_owner = set_token_id

        # Transfer the box to the set (wrapping it inside the set).
        ERC721_lib_transfer._transfer(set_token_id, owner, box_token_id)

        return ()
    end
end
