%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin

from contracts.utilities.authorization import (
    _onlyAdmin,
)

############
############
### Relationship with the briq contract

@contract_interface
namespace IBriqContract:
    func transferFT_(sender: felt, recipient: felt, material: felt, qty: felt):
    end
    func transferOneNFT_(sender: felt, recipient: felt, material: felt, briq_token_id: felt):
    end
    func balanceOf_(owner: felt, material: felt) -> (balance: felt):
    end
end

@storage_var
func _briq_address() -> (address: felt):
end

namespace set_briq:
    @view
    func getBriqAddress_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } () -> (address: felt):
        let (value) = _briq_address.read()
        return (value)
    end

    @external
    func setBriqAddress_{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (address: felt):
        _onlyAdmin()
        _briq_address.write(address)
        return ()
    end
end
