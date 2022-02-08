import json

from .backend import get_cairo, get_header, onlyAdmin, onlyFirst

def generate():
    data = json.load(open("artifacts/briq_impl.json", "r"))

    def onlyAdminAndMintContract(func_data):
        return "_onlyAdminAndMintContract()"

    spec = {
        "mintFT": onlyAdminAndMintContract,
        "mintOneNFT": onlyAdminAndMintContract,
        "transferFT": onlyFirst,
        "transferOneNFT": onlyFirst,
        "transferNFT": onlyFirst,
        #"mutateFT": onlyAdmin,
        #"mutateOneNFT": onlyAdmin,
        #"convertOneToFT": onlyAdmin,
        #"convertToFT": onlyAdmin,
        #"convertOneToNFT": onlyAdmin,
    }

    code, interface = get_cairo(data, spec, onlyAdmin)
    header = get_header()

    output = f"""
{header}

@storage_var
func _mint_contract() -> (address: felt):
end

@external
func setMintContract{{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }} (address: felt):
    _onlyAdmin()
    _mint_contract.write(address)
    return ()
end


@view
func getMintContract{{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }} () -> (address: felt):
    let (addr) = _mint_contract.read()
    return (addr)
end

func _onlyAdminAndMintContract{{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }} ():
    let (address) = _mint_contract.read()
    _onlyAdminAnd(address)
    return ()
end

{interface}
{code}
    """
    return output
