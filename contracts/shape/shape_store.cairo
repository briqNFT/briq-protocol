%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.math import assert_le_felt, assert_not_zero

from starkware.cairo.common.bitwise import bitwise_and

struct ShapeItem:
    # Material is 64 bit so this is COLOR as short string shifted 136 bits left, and material.
    # The 128th bit indicates 'This is an NFT', at which point you need to refer to the list of NFTs.
    # (I'm shifting colors by 7 more bits so that the corresponding hex is easily readable and I don't need more).
    member color_nft_material: felt
    # Stored as reversed two's completement, shifted by 64 bits.
    # (reversed az in -> the presence of the 64th bit indicates positive number)
    # (This is done so that sorting works)
    member x_y_z: felt
end

# For reference, see also cairo-based uncompression below.
struct UncompressedShapeItem:
    member material: felt
    member color: felt
    member x: felt
    member y: felt
    member z: felt
    member nft_token_id: felt
end

#DEFINE_SHAPE

@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } ():
    alloc_locals

    let (local shape_len, shape, nfts_len, nfts) = _shape()
    # Validate that SHAPE_LEN is accurate
    with_attr error_message("SHAPE_LEN constants and shape data length do not match"):
        let (data_address) = get_label_location(shape_data)
        let (end_data) = get_label_location(shape_data_end)
        assert SHAPE_LEN = (end_data - data_address) / ShapeItem.SIZE
    end
    # Validate that the shape has no NFT/position duplicates
    with_attr error_message("Shape items contains duplicate position or NFTs"):
        _check_for_duplicates(shape_len, shape, nfts_len, nfts)
    end
    # Validate that the shape is passed properly sorted (NFTs are thus also automatically sorted).
    with_attr error_message("Shape items are not properly sorted (increasing X/Y/Z)"):
        _check_properly_sorted(shape_len, shape)
    end
    # Validate that there are the right number/material of NFTs
    _check_nft_numbers_ok(shape_len, shape, nfts_len, nfts)
    return ()
end

@view
func _check_properly_sorted{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (shape_len: felt, shape: ShapeItem*) -> ():
    if shape_len == 0:
        return ()
    end
    return _check_properly_sorted_impl(shape_len, shape)
end

func _check_properly_sorted_impl{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (shape_len: felt, shape: ShapeItem*) -> ():
    # nothing more to sort
    if shape_len == 1:
        return ()
    end
    assert_le_felt(shape[0].x_y_z, shape[1].x_y_z)
    return _check_properly_sorted_impl(shape_len - 1, shape + ShapeItem.SIZE)
end

@view
func _check_for_duplicates{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*) -> ():
    if shape_len == 0:
        assert nfts_len = 0
        return ()
    end
    _check_for_duplicates_shape_impl(shape_len, shape)
    if nfts_len == 0:
        return ()
    end
    _check_for_duplicates_nfts_impl(nfts_len, nfts)
    return ()
end

func _check_for_duplicates_shape_impl{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (shape_len: felt, shape: ShapeItem*) -> ():
    if shape_len == 1:
        return ()
    end
    if shape[0].x_y_z == shape[1].x_y_z:
        assert 0 = 1
    end
    return _check_for_duplicates_shape_impl(shape_len - 1, shape + ShapeItem.SIZE)
end

func _check_for_duplicates_nfts_impl{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (nfts_len: felt, nfts: felt*) -> ():
    if nfts_len == 1:
        return ()
    end
    if nfts[0] == nfts[1]:
        assert 0 = 1
    end
    return _check_for_duplicates_nfts_impl(nfts_len - 1, nfts + 1)
end

@view
func _shape{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } () -> (shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*):
    let (_shape_data_start) = get_label_location(shape_data)
    let (_shape_data_end) = get_label_location(shape_data_end)

    let (_nft_data_start) = get_label_location(nft_data)
    let (_nft_data_end) = get_label_location(nft_data_end)

    return (
        (_shape_data_end - _shape_data_start) / ShapeItem.SIZE, cast(_shape_data_start, ShapeItem*),
        (_nft_data_end - _nft_data_start), cast(_nft_data_start, felt*),
    )
end

# Assumes the shape passed in is properly sorted.
@view
func check_shape{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*):
    assert shape_len = SHAPE_LEN
    let (data_address) = get_label_location(shape_data)
    _check_shape_impl(shape_len, shape, cast(data_address, ShapeItem*))

    let (data_start) = get_label_location(nft_data)
    let (data_end) = get_label_location(nft_data_end)
    assert nfts_len = data_end - data_start
    _check_nfts_impl(nfts_len, nfts, cast(data_start, felt*))
    return ()
end

func _check_shape_impl{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (length: felt, a: ShapeItem*, b: ShapeItem*):
    if length == 0:
        return ()
    end
    with_attr error_message("Shapes do not match"):
        assert a[0].color_nft_material = b[0].color_nft_material
        assert a[0].x_y_z = b[0].x_y_z
    end
    return _check_shape_impl(length - 1, a + ShapeItem.SIZE, b + ShapeItem.SIZE)
end

func _check_nfts_impl{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (length: felt, a: felt*, b: felt*):
    if length == 0:
        return ()
    end
    with_attr error_message("NFTs do not match"):
        assert a[0] = b[0]
    end
    return _check_nfts_impl(length - 1, a + 1, b + 1)
end

func _check_nft_numbers_ok{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (shape_len: felt, shape: ShapeItem*, nfts_len: felt, nfts: felt*):
    if shape_len == 0:
        with_attr error_message("Shape does not have the right number of NFTs"):
            assert nfts_len = 0
        end
        return ()
    end
    let (nft) = bitwise_and(shape[0].color_nft_material, 2**128)
    if nft == 2**128:
        with_attr error_message("Shape does not have the right number of NFTs"):
            assert_not_zero(nfts_len)
        end
        with_attr error_message("NFT does not have the right material"):
            let (material_shape) = bitwise_and(shape[0].color_nft_material, 2**64 - 1)
            let (material_nft) = bitwise_and(nfts[0], 2**64 - 1)
            assert material_shape = material_nft
        end
        return _check_nft_numbers_ok(shape_len - 1, shape + ShapeItem.SIZE, nfts_len - 1, nfts + 1)
    else:
        return _check_nft_numbers_ok(shape_len - 1, shape + ShapeItem.SIZE, nfts_len, nfts)
    end
end

#@view
func compute_shape_hash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } ():
    return ()
end

# Iterate through positions until we find the right one, incrementing the NFT counter so we return the correct ID.
func _find_nft{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (x_y_z: felt, current_item: ShapeItem*, nft_index: felt) -> (token_id: felt):
    if current_item.x_y_z == x_y_z:
        let (data_address) = get_label_location(nft_data)
        let value = [data_address + nft_index]
        return (value)
    end
    let (nft) = bitwise_and(current_item.color_nft_material, 2**128)
    if nft == 2**128:
        return _find_nft(x_y_z, current_item + ShapeItem.SIZE, nft_index + 1)
    else:
        return _find_nft(x_y_z, current_item + ShapeItem.SIZE, nft_index)
    end
end

@view
func decompress_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (data: ShapeItem) -> (data: UncompressedShapeItem):
    let (nft) = bitwise_and(data.color_nft_material, 2**128)
    if nft != 2**128:
        let (color) = bitwise_and(data.color_nft_material, 2**251 - 1 - 2**136 + 1)
        let (material) = bitwise_and(data.color_nft_material, 2**64 - 1)
        let (x) = bitwise_and(data.x_y_z, 2**251 - 1 - 2**128 + 1)
        let (y) = bitwise_and(data.x_y_z, 2**128 - 1 - 2**64 + 1)
        let (z) = bitwise_and(data.x_y_z, 2**64 - 1)
        tempvar out = UncompressedShapeItem(material, color / 2 ** 136, x / 2 ** 128 - 0x8000000000000000, y / 2 ** 64 - 0x8000000000000000, z - 0x8000000000000000, nft)
        return (out)
    end
    let (data_address) = get_label_location(shape_data)
    let (token_id) = _find_nft(data.x_y_z, cast(data_address, ShapeItem*), 0)
    let (color) = bitwise_and(data.color_nft_material, 2**251 - 1 - 2**136 + 1)
    let (material) = bitwise_and(data.color_nft_material, 2**64 - 1)
    let (x) = bitwise_and(data.x_y_z, 2**251 - 1 - 2**128 + 1)
    let (y) = bitwise_and(data.x_y_z, 2**128 - 1 - 2**64 + 1)
    let (z) = bitwise_and(data.x_y_z, 2**64 - 1)
    tempvar out = UncompressedShapeItem(material, color / 2 ** 136, x / 2 ** 128 - 0x8000000000000000, y / 2 ** 64 - 0x8000000000000000, z - 0x8000000000000000, token_id)
    return (out)
end
