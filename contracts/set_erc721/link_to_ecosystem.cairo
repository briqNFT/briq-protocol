%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin

from contracts.utilities.authorization import _onlyAdmin

from contracts.types import ShapeItem, FTSpec

//###########
//###########
// ## Relationship with the briq contract

@contract_interface
namespace IBriqContract {
    func transferFT_(sender: felt, recipient: felt, material: felt, qty: felt) {
    }
    func transferOneNFT_(sender: felt, recipient: felt, material: felt, briq_token_id: felt) {
    }
    func materialsOf_(owner: felt) -> (materials_len: felt, materials: felt*) {
    }
    func balanceOf_(owner: felt, material: felt) -> (balance: felt) {
    }
}

@contract_interface
namespace IBookletContract {
    func wrap_(
        owner: felt,
        set_token_id: felt,
        booklet_token_id: felt,
        shape_len: felt,
        shape: ShapeItem*,
        fts_len: felt,
        fts: FTSpec*,
        nfts_len: felt,
        nfts: felt*,
    ) {
    }
    func unwrap_(owner: felt, set_token_id: felt, booklet_token_id: felt) {
    }
    func balanceOf_(owner: felt, token_id: felt) -> (balance: felt) {
    }
}

@storage_var
func _briq_address() -> (address: felt) {
}

@storage_var
func _booklet_address() -> (address: felt) {
}

namespace set_ecosystem {
    @view
    func getBriqAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        address: felt
    ) {
        let (value) = _briq_address.read();
        return (value,);
    }

    @external
    func setBriqAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        address: felt
    ) {
        _onlyAdmin();
        _briq_address.write(address);
        return ();
    }

    @view
    func getBookletAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        address: felt
    ) {
        let (value) = _booklet_address.read();
        return (value,);
    }

    @external
    func setBookletAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        address: felt
    ) {
        _onlyAdmin();
        _booklet_address.write(address);
        return ();
    }
}
