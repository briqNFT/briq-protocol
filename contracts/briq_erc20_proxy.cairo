%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_lt, unsigned_div_rem
from starkware.starknet.common.syscalls import get_caller_address

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IBriqContract:
    func balance_of(account: felt) -> (balance: felt):
    end
    func ERC20_transfer(sender: felt, recipient: felt, amount: felt) -> (success: felt):
    end
end


@storage_var
func ERC20_name() -> (name: felt):
end

@storage_var
func ERC20_symbol() -> (symbol: felt):
end

@storage_var
func ERC20_briq_contract() -> (address: felt):
end

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        name: felt,
        symbol: felt,
        briq_contract: felt
        # Will need some token_id for ERC1155
    ):
    ERC20_name.write(name)
    ERC20_symbol.write(symbol)
    ERC20_briq_contract.write(briq_contract)
    return ()
end

@view
func name{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name: felt):
    let (n) = ERC20_name.read()
    return (n)
end

@view
func symbol{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (n) = ERC20_symbol.read()
    return (n)
end

@view
func decimals() -> (decimals: felt):
    return (0)
end

@view
func totalSupply() -> (totalSupply: felt):
    # some random pseudo infinite value for now.
    return (10000000)
end

@view
func balanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account: felt) -> (balance: felt):
    let (addr) = ERC20_briq_contract.read()
    let (val) = IBriqContract.balance_of(addr, account)
    return (val)
end

@external
func transferFrom{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        sender: felt, 
        recipient: felt, 
        amount: Uint256
    ) -> (success: felt):

    # Convert from uint256 to felt with some laziness thrown in.
    const SHIFT = 2 ** 128
    assert_lt(amount.low, 2 ** 120)
    tempvar val = amount.low * SHIFT + amount.high
    
    let (addr) = ERC20_briq_contract.read()
    let (succ) = IBriqContract.ERC20_transfer(addr, sender, recipient, val)
    return (succ)
end

@external
func transfer{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (recipient: felt, amount: Uint256) -> (success: felt):
    let (sender) = get_caller_address()
    let (succ) = transferFrom(sender, recipient, amount)
    return (succ)
end

@external
func allowance(owner: felt, spender: felt) -> (remaining: felt):
    return (0)
end

@external
func approve(spender: felt, amount: felt) -> (success: felt):
    return (0)
end
