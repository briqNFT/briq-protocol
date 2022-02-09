import json

from .backend import get_cairo, get_header, onlyAdmin, onlyAdminAndFirst, onlyFirst

def generate():
    data = json.load(open("artifacts/set_backend.json", "r"))

    def onlyApproved(func_data):
        return """
    _onlyApproved(sender, token_id)
    # Reset approval (0 cost if was 0 before)
    _approve_noauth(0, token_id)"""

    spec = {
        "assemble": onlyFirst,
        # "setTokenURI": onlyAdmin,
        # updateBriqs: onlyAdmin,
        "disassemble": onlyFirst,
        "transferOneNFT": onlyApproved,
    }

    code, interface = get_cairo(data, spec, onlyAdmin)
    header = get_header()

    output = f"""
{header}
{interface}

from contracts.allowance import (
    getApproved,
    isApprovedForAll,
    _setApprovalForAll_noauth,
    _approve_noauth,
)

# Not OZ interface
@external
func approve{{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }} (approved_address: felt, token_id: felt):
    let (proxy) = Proxy_implementation_address.read()
    let (owner) = ProxiedInterface.ownerOf(proxy, token_id)
    _onlyAdminAnd(owner)
    _approve_noauth(approved_address, token_id)
    return ()
end

@external
func setApprovalForAll{{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }} (approved_address: felt, allowed: felt):
    let (owner) = get_caller_address()
    _setApprovalForAll_noauth(on_behalf_of=owner, approved_address=approved_address, allowed=allowed)
    return ()
end

########################
########################

func _onlyApproved{{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }} (sender: felt, token_id: felt):
    let (caller) = get_caller_address()
    if sender == caller:
        return ()
    end
    let (isOperator) = isApprovedForAll(sender, caller)
    if isOperator - 1 == 0:
        return ()
    end
    let (approved) = getApproved(token_id)
    _only(approved)
    return ()
end

{code}
    """
    return output
