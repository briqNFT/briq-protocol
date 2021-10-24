%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.starknet.common.storage import Storage
from starkware.cairo.common.math import assert_nn_le, assert_lt, assert_not_zero

@storage_var
func owner(token_id: felt) -> (res: felt):
end

@storage_var
func balances(owner: felt) -> (nb: felt):
end

@storage_var
func balance_details(owner: felt, index: felt) -> (res: felt):
end

@storage_var
func initialized() -> (res: felt):
end

#### Specific bit

# Material encodes the rarity. Values range 1-16
@storage_var
func material(token_id: felt) -> (res: felt):
end

# Says if a brick is part of set
@storage_var
func part_of_set(token_id: felt) -> (res: felt):
end


@external
func initialize{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } ():
    let (_initialized) = initialized.read()
    assert _initialized = 0
    initialized.write(1)
    return ()
end

@view
func balance_of{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt) -> (res: felt):
    let (res) = balances.read(owner=owner)
    return (res)
end

@view
func owner_of{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (token_id: felt) -> (res: felt):
    let (res) = owner.read(token_id=token_id)
    return (res)
end

@view
func token_data{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (token_id: felt) -> (res: (felt, felt)):
    let (res) = owner.read(token_id=token_id)
    let (res2) = material.read(token_id=token_id)
    let tp = (res, res2)
    return (tp)
end

@view
func token_at_index{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, index: felt) -> (res: felt):
    let (res) = balances.read(owner=owner)
    assert_lt(index, res)
    let (retval) = balance_details.read(owner=owner, index=index)
    return (retval)
end

func _mint{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (recipient: felt, token_id: felt, mat: felt):
    let (curr_owner) = owner.read(token_id)
    assert curr_owner = 0
    let (res) = balances.read(owner=recipient)
    balances.write(recipient, res + 1)
    balance_details.write(recipient, res, token_id)
    owner.write(token_id, recipient)
    part_of_set.write(token_id, 0)
    material.write(token_id, mat)
    return ()
end

@external
func mint{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt, token_id: felt, material: felt):
    assert_not_zero(material)
    _mint(owner, token_id, material)
    return ()
end

@external
func mint_multiple{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt, material:felt, token_start: felt, nb: felt):
    assert_not_zero(material)
    if nb == 0:
        return ()
    end
    _mint(owner, token_start + nb, material)
    mint_multiple(owner, material, token_start, nb - 1)
    return ()
end

@external
func set_part_of_set{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (token_id: felt, set: felt):
    let (curr_set) = part_of_set.read(token_id)
    assert curr_set = 0
    let (curr_owner) = owner.read(token_id)
    assert_not_zero(curr_owner)
    part_of_set.write(token_id, set)
    return ()
end

@external
func set_bricks_to_set{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (set_id: felt, bricks_len: felt, bricks: felt*):
    # TODO: assert reasonable range
    if bricks_len == 0:
        return ()
    end
    set_part_of_set(token_id = [bricks + bricks_len - 1], set=set_id)
    set_bricks_to_set(set_id=set_id, bricks_len=bricks_len-1, bricks=bricks)
    return ()
end

func find_item_index{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, token_id: felt, cur_idx: felt, max: felt) -> (res: felt):
    alloc_locals
    local storage: Storage* = storage_ptr
    local pedersen: HashBuiltin* = pedersen_ptr
    local range_check = range_check_ptr
    let (ct) = balance_details.read(owner, cur_idx)
    if ct == token_id:
        return (cur_idx)
    end
    if cur_idx == max:
        return (0)
    end
    return find_item_index{storage_ptr=storage, pedersen_ptr=pedersen, range_check_ptr=range_check}(owner, token_id, cur_idx + 1, max)
end

func _transfer{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, token_id: felt):
    alloc_locals
    let (local curr_owner) = owner.read(token_id=token_id)
    assert curr_owner = sender
    # Cannot transfer a brick that's part of a set.
    let (curr_set) = part_of_set.read(token_id=token_id)
    assert curr_set = 0
    owner.write(token_id, recipient)

    # updating balances is annoying
    let (local cur) = balances.read(curr_owner)
    balances.write(curr_owner, cur - 1)

    #let (it) = find_item_index(curr_owner, token_id, 0, cur)
    #let (tok) = balance_details.read(curr_owner, cur - 1)
    #balance_details.write(curr_owner, it, tok)

    #let (rcur) = balances.read(recipient)
    #balances.write(recipient, rcur + 1)
    #balance_details.write(recipient, rcur, tok)

    return ()
end

@external
func transfer_from{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (sender: felt, recipient: felt, token_id: felt):
    _transfer(sender, recipient, token_id)
    return ()
end


# Autogenerated, see scripts/generate_tokens_by_index_func.py
@view
func tokens_at_index{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, index: felt) -> (
        ret0: felt,  rMat0: felt, rSet0: felt,
        ret1: felt,  rMat1: felt, rSet1: felt,
        ret2: felt,  rMat2: felt, rSet2: felt,
        ret3: felt,  rMat3: felt, rSet3: felt,
        ret4: felt,  rMat4: felt, rSet4: felt,
        ret5: felt,  rMat5: felt, rSet5: felt,
        ret6: felt,  rMat6: felt, rSet6: felt,
        ret7: felt,  rMat7: felt, rSet7: felt,
        ret8: felt,  rMat8: felt, rSet8: felt,
        ret9: felt,  rMat9: felt, rSet9: felt,
        ret10: felt,  rMat10: felt, rSet10: felt,
        ret11: felt,  rMat11: felt, rSet11: felt,
        ret12: felt,  rMat12: felt, rSet12: felt,
        ret13: felt,  rMat13: felt, rSet13: felt,
        ret14: felt,  rMat14: felt, rSet14: felt,
        ret15: felt,  rMat15: felt, rSet15: felt,
        ret16: felt,  rMat16: felt, rSet16: felt,
        ret17: felt,  rMat17: felt, rSet17: felt,
        ret18: felt,  rMat18: felt, rSet18: felt,
        ret19: felt,  rMat19: felt, rSet19: felt,
        ret20: felt,  rMat20: felt, rSet20: felt,
        ret21: felt,  rMat21: felt, rSet21: felt,
        ret22: felt,  rMat22: felt, rSet22: felt,
        ret23: felt,  rMat23: felt, rSet23: felt,
        ret24: felt,  rMat24: felt, rSet24: felt,
        ret25: felt,  rMat25: felt, rSet25: felt,
        ret26: felt,  rMat26: felt, rSet26: felt,
        ret27: felt,  rMat27: felt, rSet27: felt,
        ret28: felt,  rMat28: felt, rSet28: felt,
        ret29: felt,  rMat29: felt, rSet29: felt,
        ret30: felt,  rMat30: felt, rSet30: felt,
        ret31: felt,  rMat31: felt, rSet31: felt,
        ret32: felt,  rMat32: felt, rSet32: felt,
        ret33: felt,  rMat33: felt, rSet33: felt,
        ret34: felt,  rMat34: felt, rSet34: felt,
        ret35: felt,  rMat35: felt, rSet35: felt,
        ret36: felt,  rMat36: felt, rSet36: felt,
        ret37: felt,  rMat37: felt, rSet37: felt,
        ret38: felt,  rMat38: felt, rSet38: felt,
        ret39: felt,  rMat39: felt, rSet39: felt,
        ret40: felt,  rMat40: felt, rSet40: felt,
        ret41: felt,  rMat41: felt, rSet41: felt,
        ret42: felt,  rMat42: felt, rSet42: felt,
        ret43: felt,  rMat43: felt, rSet43: felt,
        ret44: felt,  rMat44: felt, rSet44: felt,
        ret45: felt,  rMat45: felt, rSet45: felt,
        ret46: felt,  rMat46: felt, rSet46: felt,
        ret47: felt,  rMat47: felt, rSet47: felt,
        ret48: felt,  rMat48: felt, rSet48: felt,
        ret49: felt,  rMat49: felt, rSet49: felt,
        ret50: felt,  rMat50: felt, rSet50: felt,
        ret51: felt,  rMat51: felt, rSet51: felt,
        ret52: felt,  rMat52: felt, rSet52: felt,
        ret53: felt,  rMat53: felt, rSet53: felt,
        ret54: felt,  rMat54: felt, rSet54: felt,
        ret55: felt,  rMat55: felt, rSet55: felt,
        ret56: felt,  rMat56: felt, rSet56: felt,
        ret57: felt,  rMat57: felt, rSet57: felt,
        ret58: felt,  rMat58: felt, rSet58: felt,
        ret59: felt,  rMat59: felt, rSet59: felt,
        ret60: felt,  rMat60: felt, rSet60: felt,
        ret61: felt,  rMat61: felt, rSet61: felt,
        ret62: felt,  rMat62: felt, rSet62: felt,
        ret63: felt,  rMat63: felt, rSet63: felt,
        ret64: felt,  rMat64: felt, rSet64: felt,
        ret65: felt,  rMat65: felt, rSet65: felt,
        ret66: felt,  rMat66: felt, rSet66: felt,
        ret67: felt,  rMat67: felt, rSet67: felt,
        ret68: felt,  rMat68: felt, rSet68: felt,
        ret69: felt,  rMat69: felt, rSet69: felt,
        ret70: felt,  rMat70: felt, rSet70: felt,
        ret71: felt,  rMat71: felt, rSet71: felt,
        ret72: felt,  rMat72: felt, rSet72: felt,
        ret73: felt,  rMat73: felt, rSet73: felt,
        ret74: felt,  rMat74: felt, rSet74: felt,
        ret75: felt,  rMat75: felt, rSet75: felt,
        ret76: felt,  rMat76: felt, rSet76: felt,
        ret77: felt,  rMat77: felt, rSet77: felt,
        ret78: felt,  rMat78: felt, rSet78: felt,
        ret79: felt,  rMat79: felt, rSet79: felt,
        ret80: felt,  rMat80: felt, rSet80: felt,
        ret81: felt,  rMat81: felt, rSet81: felt,
        ret82: felt,  rMat82: felt, rSet82: felt,
        ret83: felt,  rMat83: felt, rSet83: felt,
        ret84: felt,  rMat84: felt, rSet84: felt,
        ret85: felt,  rMat85: felt, rSet85: felt,
        ret86: felt,  rMat86: felt, rSet86: felt,
        ret87: felt,  rMat87: felt, rSet87: felt,
        ret88: felt,  rMat88: felt, rSet88: felt,
        ret89: felt,  rMat89: felt, rSet89: felt,
        ret90: felt,  rMat90: felt, rSet90: felt,
        ret91: felt,  rMat91: felt, rSet91: felt,
        ret92: felt,  rMat92: felt, rSet92: felt,
        ret93: felt,  rMat93: felt, rSet93: felt,
        ret94: felt,  rMat94: felt, rSet94: felt,
        ret95: felt,  rMat95: felt, rSet95: felt,
        ret96: felt,  rMat96: felt, rSet96: felt,
        ret97: felt,  rMat97: felt, rSet97: felt,
        ret98: felt,  rMat98: felt, rSet98: felt,
        ret99: felt,  rMat99: felt, rSet99: felt,
    ):
    alloc_locals
    let (res) = balances.read(owner=owner)
    let(local retval0: felt) = balance_details.read(owner=owner, index=index*100+0)
    let(local retval1: felt) = balance_details.read(owner=owner, index=index*100+1)
    let(local retval2: felt) = balance_details.read(owner=owner, index=index*100+2)
    let(local retval3: felt) = balance_details.read(owner=owner, index=index*100+3)
    let(local retval4: felt) = balance_details.read(owner=owner, index=index*100+4)
    let(local retval5: felt) = balance_details.read(owner=owner, index=index*100+5)
    let(local retval6: felt) = balance_details.read(owner=owner, index=index*100+6)
    let(local retval7: felt) = balance_details.read(owner=owner, index=index*100+7)
    let(local retval8: felt) = balance_details.read(owner=owner, index=index*100+8)
    let(local retval9: felt) = balance_details.read(owner=owner, index=index*100+9)
    let(local retval10: felt) = balance_details.read(owner=owner, index=index*100+10)
    let(local retval11: felt) = balance_details.read(owner=owner, index=index*100+11)
    let(local retval12: felt) = balance_details.read(owner=owner, index=index*100+12)
    let(local retval13: felt) = balance_details.read(owner=owner, index=index*100+13)
    let(local retval14: felt) = balance_details.read(owner=owner, index=index*100+14)
    let(local retval15: felt) = balance_details.read(owner=owner, index=index*100+15)
    let(local retval16: felt) = balance_details.read(owner=owner, index=index*100+16)
    let(local retval17: felt) = balance_details.read(owner=owner, index=index*100+17)
    let(local retval18: felt) = balance_details.read(owner=owner, index=index*100+18)
    let(local retval19: felt) = balance_details.read(owner=owner, index=index*100+19)
    let(local retval20: felt) = balance_details.read(owner=owner, index=index*100+20)
    let(local retval21: felt) = balance_details.read(owner=owner, index=index*100+21)
    let(local retval22: felt) = balance_details.read(owner=owner, index=index*100+22)
    let(local retval23: felt) = balance_details.read(owner=owner, index=index*100+23)
    let(local retval24: felt) = balance_details.read(owner=owner, index=index*100+24)
    let(local retval25: felt) = balance_details.read(owner=owner, index=index*100+25)
    let(local retval26: felt) = balance_details.read(owner=owner, index=index*100+26)
    let(local retval27: felt) = balance_details.read(owner=owner, index=index*100+27)
    let(local retval28: felt) = balance_details.read(owner=owner, index=index*100+28)
    let(local retval29: felt) = balance_details.read(owner=owner, index=index*100+29)
    let(local retval30: felt) = balance_details.read(owner=owner, index=index*100+30)
    let(local retval31: felt) = balance_details.read(owner=owner, index=index*100+31)
    let(local retval32: felt) = balance_details.read(owner=owner, index=index*100+32)
    let(local retval33: felt) = balance_details.read(owner=owner, index=index*100+33)
    let(local retval34: felt) = balance_details.read(owner=owner, index=index*100+34)
    let(local retval35: felt) = balance_details.read(owner=owner, index=index*100+35)
    let(local retval36: felt) = balance_details.read(owner=owner, index=index*100+36)
    let(local retval37: felt) = balance_details.read(owner=owner, index=index*100+37)
    let(local retval38: felt) = balance_details.read(owner=owner, index=index*100+38)
    let(local retval39: felt) = balance_details.read(owner=owner, index=index*100+39)
    let(local retval40: felt) = balance_details.read(owner=owner, index=index*100+40)
    let(local retval41: felt) = balance_details.read(owner=owner, index=index*100+41)
    let(local retval42: felt) = balance_details.read(owner=owner, index=index*100+42)
    let(local retval43: felt) = balance_details.read(owner=owner, index=index*100+43)
    let(local retval44: felt) = balance_details.read(owner=owner, index=index*100+44)
    let(local retval45: felt) = balance_details.read(owner=owner, index=index*100+45)
    let(local retval46: felt) = balance_details.read(owner=owner, index=index*100+46)
    let(local retval47: felt) = balance_details.read(owner=owner, index=index*100+47)
    let(local retval48: felt) = balance_details.read(owner=owner, index=index*100+48)
    let(local retval49: felt) = balance_details.read(owner=owner, index=index*100+49)
    let(local retval50: felt) = balance_details.read(owner=owner, index=index*100+50)
    let(local retval51: felt) = balance_details.read(owner=owner, index=index*100+51)
    let(local retval52: felt) = balance_details.read(owner=owner, index=index*100+52)
    let(local retval53: felt) = balance_details.read(owner=owner, index=index*100+53)
    let(local retval54: felt) = balance_details.read(owner=owner, index=index*100+54)
    let(local retval55: felt) = balance_details.read(owner=owner, index=index*100+55)
    let(local retval56: felt) = balance_details.read(owner=owner, index=index*100+56)
    let(local retval57: felt) = balance_details.read(owner=owner, index=index*100+57)
    let(local retval58: felt) = balance_details.read(owner=owner, index=index*100+58)
    let(local retval59: felt) = balance_details.read(owner=owner, index=index*100+59)
    let(local retval60: felt) = balance_details.read(owner=owner, index=index*100+60)
    let(local retval61: felt) = balance_details.read(owner=owner, index=index*100+61)
    let(local retval62: felt) = balance_details.read(owner=owner, index=index*100+62)
    let(local retval63: felt) = balance_details.read(owner=owner, index=index*100+63)
    let(local retval64: felt) = balance_details.read(owner=owner, index=index*100+64)
    let(local retval65: felt) = balance_details.read(owner=owner, index=index*100+65)
    let(local retval66: felt) = balance_details.read(owner=owner, index=index*100+66)
    let(local retval67: felt) = balance_details.read(owner=owner, index=index*100+67)
    let(local retval68: felt) = balance_details.read(owner=owner, index=index*100+68)
    let(local retval69: felt) = balance_details.read(owner=owner, index=index*100+69)
    let(local retval70: felt) = balance_details.read(owner=owner, index=index*100+70)
    let(local retval71: felt) = balance_details.read(owner=owner, index=index*100+71)
    let(local retval72: felt) = balance_details.read(owner=owner, index=index*100+72)
    let(local retval73: felt) = balance_details.read(owner=owner, index=index*100+73)
    let(local retval74: felt) = balance_details.read(owner=owner, index=index*100+74)
    let(local retval75: felt) = balance_details.read(owner=owner, index=index*100+75)
    let(local retval76: felt) = balance_details.read(owner=owner, index=index*100+76)
    let(local retval77: felt) = balance_details.read(owner=owner, index=index*100+77)
    let(local retval78: felt) = balance_details.read(owner=owner, index=index*100+78)
    let(local retval79: felt) = balance_details.read(owner=owner, index=index*100+79)
    let(local retval80: felt) = balance_details.read(owner=owner, index=index*100+80)
    let(local retval81: felt) = balance_details.read(owner=owner, index=index*100+81)
    let(local retval82: felt) = balance_details.read(owner=owner, index=index*100+82)
    let(local retval83: felt) = balance_details.read(owner=owner, index=index*100+83)
    let(local retval84: felt) = balance_details.read(owner=owner, index=index*100+84)
    let(local retval85: felt) = balance_details.read(owner=owner, index=index*100+85)
    let(local retval86: felt) = balance_details.read(owner=owner, index=index*100+86)
    let(local retval87: felt) = balance_details.read(owner=owner, index=index*100+87)
    let(local retval88: felt) = balance_details.read(owner=owner, index=index*100+88)
    let(local retval89: felt) = balance_details.read(owner=owner, index=index*100+89)
    let(local retval90: felt) = balance_details.read(owner=owner, index=index*100+90)
    let(local retval91: felt) = balance_details.read(owner=owner, index=index*100+91)
    let(local retval92: felt) = balance_details.read(owner=owner, index=index*100+92)
    let(local retval93: felt) = balance_details.read(owner=owner, index=index*100+93)
    let(local retval94: felt) = balance_details.read(owner=owner, index=index*100+94)
    let(local retval95: felt) = balance_details.read(owner=owner, index=index*100+95)
    let(local retval96: felt) = balance_details.read(owner=owner, index=index*100+96)
    let(local retval97: felt) = balance_details.read(owner=owner, index=index*100+97)
    let(local retval98: felt) = balance_details.read(owner=owner, index=index*100+98)
    let(local retval99: felt) = balance_details.read(owner=owner, index=index*100+99)
    let(local retMat0: felt) = material.read(token_id=retval0)
    let(local retMat1: felt) = material.read(token_id=retval1)
    let(local retMat2: felt) = material.read(token_id=retval2)
    let(local retMat3: felt) = material.read(token_id=retval3)
    let(local retMat4: felt) = material.read(token_id=retval4)
    let(local retMat5: felt) = material.read(token_id=retval5)
    let(local retMat6: felt) = material.read(token_id=retval6)
    let(local retMat7: felt) = material.read(token_id=retval7)
    let(local retMat8: felt) = material.read(token_id=retval8)
    let(local retMat9: felt) = material.read(token_id=retval9)
    let(local retMat10: felt) = material.read(token_id=retval10)
    let(local retMat11: felt) = material.read(token_id=retval11)
    let(local retMat12: felt) = material.read(token_id=retval12)
    let(local retMat13: felt) = material.read(token_id=retval13)
    let(local retMat14: felt) = material.read(token_id=retval14)
    let(local retMat15: felt) = material.read(token_id=retval15)
    let(local retMat16: felt) = material.read(token_id=retval16)
    let(local retMat17: felt) = material.read(token_id=retval17)
    let(local retMat18: felt) = material.read(token_id=retval18)
    let(local retMat19: felt) = material.read(token_id=retval19)
    let(local retMat20: felt) = material.read(token_id=retval20)
    let(local retMat21: felt) = material.read(token_id=retval21)
    let(local retMat22: felt) = material.read(token_id=retval22)
    let(local retMat23: felt) = material.read(token_id=retval23)
    let(local retMat24: felt) = material.read(token_id=retval24)
    let(local retMat25: felt) = material.read(token_id=retval25)
    let(local retMat26: felt) = material.read(token_id=retval26)
    let(local retMat27: felt) = material.read(token_id=retval27)
    let(local retMat28: felt) = material.read(token_id=retval28)
    let(local retMat29: felt) = material.read(token_id=retval29)
    let(local retMat30: felt) = material.read(token_id=retval30)
    let(local retMat31: felt) = material.read(token_id=retval31)
    let(local retMat32: felt) = material.read(token_id=retval32)
    let(local retMat33: felt) = material.read(token_id=retval33)
    let(local retMat34: felt) = material.read(token_id=retval34)
    let(local retMat35: felt) = material.read(token_id=retval35)
    let(local retMat36: felt) = material.read(token_id=retval36)
    let(local retMat37: felt) = material.read(token_id=retval37)
    let(local retMat38: felt) = material.read(token_id=retval38)
    let(local retMat39: felt) = material.read(token_id=retval39)
    let(local retMat40: felt) = material.read(token_id=retval40)
    let(local retMat41: felt) = material.read(token_id=retval41)
    let(local retMat42: felt) = material.read(token_id=retval42)
    let(local retMat43: felt) = material.read(token_id=retval43)
    let(local retMat44: felt) = material.read(token_id=retval44)
    let(local retMat45: felt) = material.read(token_id=retval45)
    let(local retMat46: felt) = material.read(token_id=retval46)
    let(local retMat47: felt) = material.read(token_id=retval47)
    let(local retMat48: felt) = material.read(token_id=retval48)
    let(local retMat49: felt) = material.read(token_id=retval49)
    let(local retMat50: felt) = material.read(token_id=retval50)
    let(local retMat51: felt) = material.read(token_id=retval51)
    let(local retMat52: felt) = material.read(token_id=retval52)
    let(local retMat53: felt) = material.read(token_id=retval53)
    let(local retMat54: felt) = material.read(token_id=retval54)
    let(local retMat55: felt) = material.read(token_id=retval55)
    let(local retMat56: felt) = material.read(token_id=retval56)
    let(local retMat57: felt) = material.read(token_id=retval57)
    let(local retMat58: felt) = material.read(token_id=retval58)
    let(local retMat59: felt) = material.read(token_id=retval59)
    let(local retMat60: felt) = material.read(token_id=retval60)
    let(local retMat61: felt) = material.read(token_id=retval61)
    let(local retMat62: felt) = material.read(token_id=retval62)
    let(local retMat63: felt) = material.read(token_id=retval63)
    let(local retMat64: felt) = material.read(token_id=retval64)
    let(local retMat65: felt) = material.read(token_id=retval65)
    let(local retMat66: felt) = material.read(token_id=retval66)
    let(local retMat67: felt) = material.read(token_id=retval67)
    let(local retMat68: felt) = material.read(token_id=retval68)
    let(local retMat69: felt) = material.read(token_id=retval69)
    let(local retMat70: felt) = material.read(token_id=retval70)
    let(local retMat71: felt) = material.read(token_id=retval71)
    let(local retMat72: felt) = material.read(token_id=retval72)
    let(local retMat73: felt) = material.read(token_id=retval73)
    let(local retMat74: felt) = material.read(token_id=retval74)
    let(local retMat75: felt) = material.read(token_id=retval75)
    let(local retMat76: felt) = material.read(token_id=retval76)
    let(local retMat77: felt) = material.read(token_id=retval77)
    let(local retMat78: felt) = material.read(token_id=retval78)
    let(local retMat79: felt) = material.read(token_id=retval79)
    let(local retMat80: felt) = material.read(token_id=retval80)
    let(local retMat81: felt) = material.read(token_id=retval81)
    let(local retMat82: felt) = material.read(token_id=retval82)
    let(local retMat83: felt) = material.read(token_id=retval83)
    let(local retMat84: felt) = material.read(token_id=retval84)
    let(local retMat85: felt) = material.read(token_id=retval85)
    let(local retMat86: felt) = material.read(token_id=retval86)
    let(local retMat87: felt) = material.read(token_id=retval87)
    let(local retMat88: felt) = material.read(token_id=retval88)
    let(local retMat89: felt) = material.read(token_id=retval89)
    let(local retMat90: felt) = material.read(token_id=retval90)
    let(local retMat91: felt) = material.read(token_id=retval91)
    let(local retMat92: felt) = material.read(token_id=retval92)
    let(local retMat93: felt) = material.read(token_id=retval93)
    let(local retMat94: felt) = material.read(token_id=retval94)
    let(local retMat95: felt) = material.read(token_id=retval95)
    let(local retMat96: felt) = material.read(token_id=retval96)
    let(local retMat97: felt) = material.read(token_id=retval97)
    let(local retMat98: felt) = material.read(token_id=retval98)
    let(local retMat99: felt) = material.read(token_id=retval99)
    let(local retSet0: felt) = part_of_set.read(token_id=retval0)
    let(local retSet1: felt) = part_of_set.read(token_id=retval1)
    let(local retSet2: felt) = part_of_set.read(token_id=retval2)
    let(local retSet3: felt) = part_of_set.read(token_id=retval3)
    let(local retSet4: felt) = part_of_set.read(token_id=retval4)
    let(local retSet5: felt) = part_of_set.read(token_id=retval5)
    let(local retSet6: felt) = part_of_set.read(token_id=retval6)
    let(local retSet7: felt) = part_of_set.read(token_id=retval7)
    let(local retSet8: felt) = part_of_set.read(token_id=retval8)
    let(local retSet9: felt) = part_of_set.read(token_id=retval9)
    let(local retSet10: felt) = part_of_set.read(token_id=retval10)
    let(local retSet11: felt) = part_of_set.read(token_id=retval11)
    let(local retSet12: felt) = part_of_set.read(token_id=retval12)
    let(local retSet13: felt) = part_of_set.read(token_id=retval13)
    let(local retSet14: felt) = part_of_set.read(token_id=retval14)
    let(local retSet15: felt) = part_of_set.read(token_id=retval15)
    let(local retSet16: felt) = part_of_set.read(token_id=retval16)
    let(local retSet17: felt) = part_of_set.read(token_id=retval17)
    let(local retSet18: felt) = part_of_set.read(token_id=retval18)
    let(local retSet19: felt) = part_of_set.read(token_id=retval19)
    let(local retSet20: felt) = part_of_set.read(token_id=retval20)
    let(local retSet21: felt) = part_of_set.read(token_id=retval21)
    let(local retSet22: felt) = part_of_set.read(token_id=retval22)
    let(local retSet23: felt) = part_of_set.read(token_id=retval23)
    let(local retSet24: felt) = part_of_set.read(token_id=retval24)
    let(local retSet25: felt) = part_of_set.read(token_id=retval25)
    let(local retSet26: felt) = part_of_set.read(token_id=retval26)
    let(local retSet27: felt) = part_of_set.read(token_id=retval27)
    let(local retSet28: felt) = part_of_set.read(token_id=retval28)
    let(local retSet29: felt) = part_of_set.read(token_id=retval29)
    let(local retSet30: felt) = part_of_set.read(token_id=retval30)
    let(local retSet31: felt) = part_of_set.read(token_id=retval31)
    let(local retSet32: felt) = part_of_set.read(token_id=retval32)
    let(local retSet33: felt) = part_of_set.read(token_id=retval33)
    let(local retSet34: felt) = part_of_set.read(token_id=retval34)
    let(local retSet35: felt) = part_of_set.read(token_id=retval35)
    let(local retSet36: felt) = part_of_set.read(token_id=retval36)
    let(local retSet37: felt) = part_of_set.read(token_id=retval37)
    let(local retSet38: felt) = part_of_set.read(token_id=retval38)
    let(local retSet39: felt) = part_of_set.read(token_id=retval39)
    let(local retSet40: felt) = part_of_set.read(token_id=retval40)
    let(local retSet41: felt) = part_of_set.read(token_id=retval41)
    let(local retSet42: felt) = part_of_set.read(token_id=retval42)
    let(local retSet43: felt) = part_of_set.read(token_id=retval43)
    let(local retSet44: felt) = part_of_set.read(token_id=retval44)
    let(local retSet45: felt) = part_of_set.read(token_id=retval45)
    let(local retSet46: felt) = part_of_set.read(token_id=retval46)
    let(local retSet47: felt) = part_of_set.read(token_id=retval47)
    let(local retSet48: felt) = part_of_set.read(token_id=retval48)
    let(local retSet49: felt) = part_of_set.read(token_id=retval49)
    let(local retSet50: felt) = part_of_set.read(token_id=retval50)
    let(local retSet51: felt) = part_of_set.read(token_id=retval51)
    let(local retSet52: felt) = part_of_set.read(token_id=retval52)
    let(local retSet53: felt) = part_of_set.read(token_id=retval53)
    let(local retSet54: felt) = part_of_set.read(token_id=retval54)
    let(local retSet55: felt) = part_of_set.read(token_id=retval55)
    let(local retSet56: felt) = part_of_set.read(token_id=retval56)
    let(local retSet57: felt) = part_of_set.read(token_id=retval57)
    let(local retSet58: felt) = part_of_set.read(token_id=retval58)
    let(local retSet59: felt) = part_of_set.read(token_id=retval59)
    let(local retSet60: felt) = part_of_set.read(token_id=retval60)
    let(local retSet61: felt) = part_of_set.read(token_id=retval61)
    let(local retSet62: felt) = part_of_set.read(token_id=retval62)
    let(local retSet63: felt) = part_of_set.read(token_id=retval63)
    let(local retSet64: felt) = part_of_set.read(token_id=retval64)
    let(local retSet65: felt) = part_of_set.read(token_id=retval65)
    let(local retSet66: felt) = part_of_set.read(token_id=retval66)
    let(local retSet67: felt) = part_of_set.read(token_id=retval67)
    let(local retSet68: felt) = part_of_set.read(token_id=retval68)
    let(local retSet69: felt) = part_of_set.read(token_id=retval69)
    let(local retSet70: felt) = part_of_set.read(token_id=retval70)
    let(local retSet71: felt) = part_of_set.read(token_id=retval71)
    let(local retSet72: felt) = part_of_set.read(token_id=retval72)
    let(local retSet73: felt) = part_of_set.read(token_id=retval73)
    let(local retSet74: felt) = part_of_set.read(token_id=retval74)
    let(local retSet75: felt) = part_of_set.read(token_id=retval75)
    let(local retSet76: felt) = part_of_set.read(token_id=retval76)
    let(local retSet77: felt) = part_of_set.read(token_id=retval77)
    let(local retSet78: felt) = part_of_set.read(token_id=retval78)
    let(local retSet79: felt) = part_of_set.read(token_id=retval79)
    let(local retSet80: felt) = part_of_set.read(token_id=retval80)
    let(local retSet81: felt) = part_of_set.read(token_id=retval81)
    let(local retSet82: felt) = part_of_set.read(token_id=retval82)
    let(local retSet83: felt) = part_of_set.read(token_id=retval83)
    let(local retSet84: felt) = part_of_set.read(token_id=retval84)
    let(local retSet85: felt) = part_of_set.read(token_id=retval85)
    let(local retSet86: felt) = part_of_set.read(token_id=retval86)
    let(local retSet87: felt) = part_of_set.read(token_id=retval87)
    let(local retSet88: felt) = part_of_set.read(token_id=retval88)
    let(local retSet89: felt) = part_of_set.read(token_id=retval89)
    let(local retSet90: felt) = part_of_set.read(token_id=retval90)
    let(local retSet91: felt) = part_of_set.read(token_id=retval91)
    let(local retSet92: felt) = part_of_set.read(token_id=retval92)
    let(local retSet93: felt) = part_of_set.read(token_id=retval93)
    let(local retSet94: felt) = part_of_set.read(token_id=retval94)
    let(local retSet95: felt) = part_of_set.read(token_id=retval95)
    let(local retSet96: felt) = part_of_set.read(token_id=retval96)
    let(local retSet97: felt) = part_of_set.read(token_id=retval97)
    let(local retSet98: felt) = part_of_set.read(token_id=retval98)
    let(local retSet99: felt) = part_of_set.read(token_id=retval99)
    return (
        ret0=retval0, rMat0=retMat0, rSet0=retSet0,
        ret1=retval1, rMat1=retMat1, rSet1=retSet1,
        ret2=retval2, rMat2=retMat2, rSet2=retSet2,
        ret3=retval3, rMat3=retMat3, rSet3=retSet3,
        ret4=retval4, rMat4=retMat4, rSet4=retSet4,
        ret5=retval5, rMat5=retMat5, rSet5=retSet5,
        ret6=retval6, rMat6=retMat6, rSet6=retSet6,
        ret7=retval7, rMat7=retMat7, rSet7=retSet7,
        ret8=retval8, rMat8=retMat8, rSet8=retSet8,
        ret9=retval9, rMat9=retMat9, rSet9=retSet9,
        ret10=retval10, rMat10=retMat10, rSet10=retSet10,
        ret11=retval11, rMat11=retMat11, rSet11=retSet11,
        ret12=retval12, rMat12=retMat12, rSet12=retSet12,
        ret13=retval13, rMat13=retMat13, rSet13=retSet13,
        ret14=retval14, rMat14=retMat14, rSet14=retSet14,
        ret15=retval15, rMat15=retMat15, rSet15=retSet15,
        ret16=retval16, rMat16=retMat16, rSet16=retSet16,
        ret17=retval17, rMat17=retMat17, rSet17=retSet17,
        ret18=retval18, rMat18=retMat18, rSet18=retSet18,
        ret19=retval19, rMat19=retMat19, rSet19=retSet19,
        ret20=retval20, rMat20=retMat20, rSet20=retSet20,
        ret21=retval21, rMat21=retMat21, rSet21=retSet21,
        ret22=retval22, rMat22=retMat22, rSet22=retSet22,
        ret23=retval23, rMat23=retMat23, rSet23=retSet23,
        ret24=retval24, rMat24=retMat24, rSet24=retSet24,
        ret25=retval25, rMat25=retMat25, rSet25=retSet25,
        ret26=retval26, rMat26=retMat26, rSet26=retSet26,
        ret27=retval27, rMat27=retMat27, rSet27=retSet27,
        ret28=retval28, rMat28=retMat28, rSet28=retSet28,
        ret29=retval29, rMat29=retMat29, rSet29=retSet29,
        ret30=retval30, rMat30=retMat30, rSet30=retSet30,
        ret31=retval31, rMat31=retMat31, rSet31=retSet31,
        ret32=retval32, rMat32=retMat32, rSet32=retSet32,
        ret33=retval33, rMat33=retMat33, rSet33=retSet33,
        ret34=retval34, rMat34=retMat34, rSet34=retSet34,
        ret35=retval35, rMat35=retMat35, rSet35=retSet35,
        ret36=retval36, rMat36=retMat36, rSet36=retSet36,
        ret37=retval37, rMat37=retMat37, rSet37=retSet37,
        ret38=retval38, rMat38=retMat38, rSet38=retSet38,
        ret39=retval39, rMat39=retMat39, rSet39=retSet39,
        ret40=retval40, rMat40=retMat40, rSet40=retSet40,
        ret41=retval41, rMat41=retMat41, rSet41=retSet41,
        ret42=retval42, rMat42=retMat42, rSet42=retSet42,
        ret43=retval43, rMat43=retMat43, rSet43=retSet43,
        ret44=retval44, rMat44=retMat44, rSet44=retSet44,
        ret45=retval45, rMat45=retMat45, rSet45=retSet45,
        ret46=retval46, rMat46=retMat46, rSet46=retSet46,
        ret47=retval47, rMat47=retMat47, rSet47=retSet47,
        ret48=retval48, rMat48=retMat48, rSet48=retSet48,
        ret49=retval49, rMat49=retMat49, rSet49=retSet49,
        ret50=retval50, rMat50=retMat50, rSet50=retSet50,
        ret51=retval51, rMat51=retMat51, rSet51=retSet51,
        ret52=retval52, rMat52=retMat52, rSet52=retSet52,
        ret53=retval53, rMat53=retMat53, rSet53=retSet53,
        ret54=retval54, rMat54=retMat54, rSet54=retSet54,
        ret55=retval55, rMat55=retMat55, rSet55=retSet55,
        ret56=retval56, rMat56=retMat56, rSet56=retSet56,
        ret57=retval57, rMat57=retMat57, rSet57=retSet57,
        ret58=retval58, rMat58=retMat58, rSet58=retSet58,
        ret59=retval59, rMat59=retMat59, rSet59=retSet59,
        ret60=retval60, rMat60=retMat60, rSet60=retSet60,
        ret61=retval61, rMat61=retMat61, rSet61=retSet61,
        ret62=retval62, rMat62=retMat62, rSet62=retSet62,
        ret63=retval63, rMat63=retMat63, rSet63=retSet63,
        ret64=retval64, rMat64=retMat64, rSet64=retSet64,
        ret65=retval65, rMat65=retMat65, rSet65=retSet65,
        ret66=retval66, rMat66=retMat66, rSet66=retSet66,
        ret67=retval67, rMat67=retMat67, rSet67=retSet67,
        ret68=retval68, rMat68=retMat68, rSet68=retSet68,
        ret69=retval69, rMat69=retMat69, rSet69=retSet69,
        ret70=retval70, rMat70=retMat70, rSet70=retSet70,
        ret71=retval71, rMat71=retMat71, rSet71=retSet71,
        ret72=retval72, rMat72=retMat72, rSet72=retSet72,
        ret73=retval73, rMat73=retMat73, rSet73=retSet73,
        ret74=retval74, rMat74=retMat74, rSet74=retSet74,
        ret75=retval75, rMat75=retMat75, rSet75=retSet75,
        ret76=retval76, rMat76=retMat76, rSet76=retSet76,
        ret77=retval77, rMat77=retMat77, rSet77=retSet77,
        ret78=retval78, rMat78=retMat78, rSet78=retSet78,
        ret79=retval79, rMat79=retMat79, rSet79=retSet79,
        ret80=retval80, rMat80=retMat80, rSet80=retSet80,
        ret81=retval81, rMat81=retMat81, rSet81=retSet81,
        ret82=retval82, rMat82=retMat82, rSet82=retSet82,
        ret83=retval83, rMat83=retMat83, rSet83=retSet83,
        ret84=retval84, rMat84=retMat84, rSet84=retSet84,
        ret85=retval85, rMat85=retMat85, rSet85=retSet85,
        ret86=retval86, rMat86=retMat86, rSet86=retSet86,
        ret87=retval87, rMat87=retMat87, rSet87=retSet87,
        ret88=retval88, rMat88=retMat88, rSet88=retSet88,
        ret89=retval89, rMat89=retMat89, rSet89=retSet89,
        ret90=retval90, rMat90=retMat90, rSet90=retSet90,
        ret91=retval91, rMat91=retMat91, rSet91=retSet91,
        ret92=retval92, rMat92=retMat92, rSet92=retSet92,
        ret93=retval93, rMat93=retMat93, rSet93=retSet93,
        ret94=retval94, rMat94=retMat94, rSet94=retSet94,
        ret95=retval95, rMat95=retMat95, rSet95=retSet95,
        ret96=retval96, rMat96=retMat96, rSet96=retSet96,
        ret97=retval97, rMat97=retMat97, rSet97=retSet97,
        ret98=retval98, rMat98=retMat98, rSet98=retSet98,
        ret99=retval99, rMat99=retMat99, rSet99=retSet99,
    )
end

