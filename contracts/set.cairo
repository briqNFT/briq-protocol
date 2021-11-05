%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_nn_le, assert_lt, assert_not_zero



@contract_interface
namespace IBriqContract:
    func transfer_from(sender: felt, recipient: felt, token_id: felt):
    end
    func set_bricks_to_set(set_id: felt, bricks_len: felt, bricks: felt*):
    end
    func unset_bricks_from_set(set_id: felt, bricks_len: felt, bricks: felt*):
    end
end






@storage_var
func owner(token_id: felt) -> (res: felt):
end


@storage_var
func nb_briqs(token_id: felt) -> (res: felt):
end

@storage_var
func balances(owner: felt) -> (nb: felt):
end

@storage_var
func balance_details(owner: felt, index: felt) -> (res: felt):
end

@storage_var
func uuid() -> (res: felt):
end


@storage_var
func initialized() -> (res: felt):
end

@storage_var
func briq_contract() -> (res: felt):
end

#### Specific bit

@external
func initialize{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } ():
    let (_initialized) = initialized.read()
    assert _initialized = 0
    initialized.write(1)
    uuid.write(1)
    return ()
end

@external
func set_briq_contract{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (address: felt):
    briq_contract.write(address)
    return ()
end

@view
func balance_of{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt) -> (res: felt):
    let (res) = balances.read(owner=owner)
    return (res)
end

@view
func owner_of{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (token_id: felt) -> (res: felt):
    let (res) = owner.read(token_id=token_id)
    return (res)
end

@view
func token_at_index{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, index: felt) -> (res: felt):
    let (res) = balances.read(owner=owner)
    assert_lt(index, res)
    let (retval) = balance_details.read(owner=owner, index=index)
    return (retval)
end

func _mint{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (recipient: felt, token_id: felt):
    let (curr_owner) = owner.read(token_id)
    assert curr_owner = 0
    let (res) = balances.read(owner=recipient)
    balances.write(recipient, res + 1)
    balance_details.write(recipient, res, token_id)
    owner.write(token_id, recipient)
    return ()
end

@external
func mint{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt, token_id: felt, bricks_len: felt, bricks: felt*):
    alloc_locals
    _mint(owner, token_id)
    let (addr) = briq_contract.read()
    local pedersen_ptr: HashBuiltin* = pedersen_ptr
    IBriqContract.set_bricks_to_set(contract_address=addr, set_id=token_id, bricks_len=bricks_len, bricks=bricks)
    nb_briqs.write(token_id, bricks_len)
    return ()
end

@external
func disassemble{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (user: felt, token_id: felt, bricks_len: felt, bricks: felt*):
    alloc_locals
    let (addr) = briq_contract.read()
    local pedersen_ptr: HashBuiltin* = pedersen_ptr
    IBriqContract.unset_bricks_from_set(contract_address=addr, set_id=token_id, bricks_len=bricks_len, bricks=bricks)

    let (res) = balances.read(owner=user)
    balances.write(user, res - 1)
    # TODO: find balance_details
    #balance_details.write(recipient, res, token_id)
    nb_briqs.write(token_id, 0)
    owner.write(token_id, 0)

    return ()
end

func _transfer{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, token_id: felt):
    let (curr_owner) = owner.read(token_id=token_id)
    assert curr_owner = sender
    owner.write(token_id, recipient)
    # TODO: transfer all individual bricks as well.
    # let (res) = IBalanceContract.get_balance(contract_address=contract_address)
    return ()
end

@external
func transfer_from{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (sender: felt, recipient: felt, token_id: felt):
    _transfer(sender, recipient, token_id)
    return ()
end

