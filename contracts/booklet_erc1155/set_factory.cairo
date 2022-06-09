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

from contracts.booklet_erc1155.token_uri import booklet_token_uri
from contracts.library_erc1155.balance import ERC1155_balance
from contracts.library_erc1155.transferability_library import ERC1155_lib_transfer

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

namespace booklet_set_factory:

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
            booklet_token_id: felt,
            shape_len: felt, shape: ShapeItem*,
            fts_len: felt, fts: FTSpec*,
            nfts_len: felt, nfts: felt*
        ):
        alloc_locals

        let (caller) = get_caller_address()
        let (set_addr) = getSetAddress_()
        assert caller = set_addr
        # TODO: check set is authorized still.

        # Transfer the booklet to the set (wrapping it inside the set).
        ERC1155_lib_transfer._transfer(owner, set_token_id, booklet_token_id, 1)

        # Check that the shape matches the passed data
        let (local addr) = booklet_token_uri.get_shape_contract_(booklet_token_id)
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
            booklet_token_id: felt,
        ):
        let (caller) = get_caller_address()
        let (set_addr) = getSetAddress_()
        assert caller = set_addr

        # Transfer the booklet to the set (wrapping it inside the set).
        ERC1155_lib_transfer._transfer(set_token_id, owner, booklet_token_id, 1)

        return ()
    end
end
