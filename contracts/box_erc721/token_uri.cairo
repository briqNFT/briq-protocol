%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from contracts.types import ShapeItem

@contract_interface
namespace IShapeContract:
    func _shape() -> (shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*):
    end

    func check_shape(shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*):
    end

end

@storage_var
func _shape_contract(token_id: felt) -> (contract_address: felt):
end

namespace box_token_uri:

    @view
    func get_shape_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
        } (token_id: felt) -> (shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*):
        let (addr) = _shape_contract.read(token_id)
        let (a, b, c, d) = IShapeContract._shape(addr)
        return (a, b, c, d)
    end

    @view
    func check_shape_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
        } (token_id: felt, shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*) -> ():
        alloc_locals
        local pedersen_ptr: HashBuiltin* = pedersen_ptr
        local bitwise_ptr: BitwiseBuiltin* = bitwise_ptr
        let (addr) = _shape_contract.read(token_id)
        IShapeContract.check_shape(addr, shape_len, shape, nfts_len, nfts)
        return ()
    end

end
