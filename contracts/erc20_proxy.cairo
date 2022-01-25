%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import split_felt

@contract_interface
namespace IBriqBackendContract:
    func balanceOf(owner: felt, material: felt) -> (balance: felt):
    end
    func totalSupply(material: felt) -> (supply: felt):
    end

    func transferFT(sender: felt, recipient: felt, material: felt, qty: felt):
    end
    func transferOneNFT(sender: felt, recipient: felt, material: felt, briq_token_id: felt):
    end
end

const MATERIAL = 1
const PROXY = 0x123456

@view
func name() -> (name: felt):
    return (0x62726971)
end

@view
func symbol() -> (symbol: felt):
    return (0x62726971)
end

@view
func decimals() -> (decimals: felt):
    return (0)
end

@view
func totalSupply{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } () -> (totalSupply: Uint256):
    let (supply) = IBriqBackendContract.totalSupply(PROXY, MATERIAL)
    let (high, low) = split_felt(supply)
    tempvar res: Uint256
    res.high = 0
    res.low = 0
    return (res)
end

@view
func balanceOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (account: felt) -> (balance: Uint256):
    let (balance) = IBriqBackendContract.balanceOf(PROXY, account, MATERIAL)
    let (high, low) = split_felt(balance)
    tempvar res: Uint256
    res.high = high
    res.low = low
    return (res)
end

@view
func allowance(owner: felt, spender: felt) -> (remaining: Uint256):
    tempvar res: Uint256
    res.high = 0
    res.low = 0
    return (res)
end

@external
func transfer(recipient: felt, amount: Uint256) -> (success: felt):
    return (0)
end

@external
func transferFrom(
        sender: felt,
        recipient: felt,
        amount: Uint256
    ) -> (success: felt):
    return (0)
end

@external
func approve(spender: felt, amount: Uint256) -> (success: felt):
    return (0)
end
