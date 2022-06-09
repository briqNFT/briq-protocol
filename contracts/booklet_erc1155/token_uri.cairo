%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from contracts.types import ShapeItem

@contract_interface
namespace IShapeContract:
    func _shape() -> (shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*):
    end
end

@storage_var
func _shape_contract(token_id: felt) -> (contract_address: felt):
end

namespace booklet_token_uri:

    @view
    func get_shape_contract_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
        } (token_id: felt) -> (address: felt):
        let (addr) = _shape_contract.read(token_id)
        return (addr)
    end

    @view
    func get_shape_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
        } (token_id: felt) -> (shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*):
        let (addr) = _shape_contract.read(token_id)
        let (a, b, c, d) = IShapeContract._shape(addr)
        return (a, b, c, d)
    end

end
