%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from contracts.types import ShapeItem

from contracts.ecosystem.genesis_collection import GENESIS_COLLECTION

@contract_interface
namespace IShapeContract {
    func shape_(global_index: felt) -> (shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*) {
    }
}

@storage_var
func _shape_contract(token_id: felt) -> (contract_address: felt) {
}

@view
func get_shape_contract_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt
) -> (address: felt) {
    let (addr) = _shape_contract.read(token_id);
    return (addr,);
}

@view
func get_shape_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt
) -> (shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*) {
    let (addr) = _shape_contract.read(token_id);
    let (a, b, c, d) = IShapeContract.library_call_shape_(addr, (token_id - GENESIS_COLLECTION) / 2**192);
    return (a, b, c, d);
}
