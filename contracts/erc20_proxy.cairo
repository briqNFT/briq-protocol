%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import split_felt

@contract_interface
namespace IBriqBackendContract {
    func balanceOf(owner: felt, material: felt) -> (balance: felt) {
    }
    func totalSupply(material: felt) -> (supply: felt) {
    }

    func transferFT(sender: felt, recipient: felt, material: felt, qty: felt) {
    }
    func transferOneNFT(sender: felt, recipient: felt, material: felt, briq_token_id: felt) {
    }
}

const MATERIAL = 1;
const PROXY = 0x123456;

@view
func name() -> (name: felt) {
    return (0x62726971,);
}

@view
func symbol() -> (symbol: felt) {
    return (0x62726971,);
}

@view
func decimals() -> (decimals: felt) {
    return (0,);
}

@view
func totalSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    totalSupply: Uint256
) {
    let (supply) = IBriqBackendContract.totalSupply(PROXY, MATERIAL);
    let (high, low) = split_felt(supply);
    tempvar res: Uint256;
    res.high = 0;
    res.low = 0;
    return (res,);
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) -> (
    balance: Uint256
) {
    let (balance) = IBriqBackendContract.balanceOf(PROXY, account, MATERIAL);
    let (high, low) = split_felt(balance);
    tempvar res: Uint256;
    res.high = high;
    res.low = low;
    return (res,);
}

@view
func allowance(owner: felt, spender: felt) -> (remaining: Uint256) {
    tempvar res: Uint256;
    res.high = 0;
    res.low = 0;
    return (res,);
}

@external
func transfer(recipient: felt, amount: Uint256) -> (success: felt) {
    return (0,);
}

@external
func transferFrom(sender: felt, recipient: felt, amount: Uint256) -> (success: felt) {
    return (0,);
}

@external
func approve(spender: felt, amount: Uint256) -> (success: felt) {
    return (0,);
}
