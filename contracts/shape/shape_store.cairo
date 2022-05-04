%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.math import assert_le_felt

from starkware.cairo.common.bitwise import bitwise_and

struct ShapeItem:
    # Material is 64 bit so this is COLOR as short string shifted 128 bits left, and material.
    member color_material: felt
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

    let (local a, b) = _shape()
    # Validate that SHAPE_LEN is accurate
    with_attr error_message("SHAPE_LEN constants and shape data length do not match"):
        let (data_address) = get_label_location(shape_data)
        let (end_data) = get_label_location(shape_data_end)
        assert SHAPE_LEN = (end_data - data_address) / ShapeItem.SIZE
    end
    # Validate that the shape has no position duplicates
    with_attr error_message("Shape items contains duplicate position"):
        _check_for_duplicates(a, b)
    end
    # Validate that the shape is passed properly sorted.
    with_attr error_message("Shape items are not properly sorted (increasing X/Y/Z)"):
        _check_properly_sorted(a, b)
    end
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
    } (shape_len: felt, shape: ShapeItem*) -> ():
    if shape_len == 0:
        return ()
    end
    return _check_for_duplicates_impl(shape_len, shape)
end

func _check_for_duplicates_impl{
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
    return _check_for_duplicates_impl(shape_len - 1, shape + ShapeItem.SIZE)
end

@view
func _shape{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } () -> (shape_len: felt, shape: ShapeItem*):

    let (data_address) = get_label_location(shape_data)
    let (end_data) = get_label_location(shape_data_end)
    return ((end_data - data_address) / ShapeItem.SIZE, cast(data_address, ShapeItem*))
end

# Assumes the shape passed in is properly sorted.
@view
func check_shape{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (shape_len: felt, shape: ShapeItem*):
    assert shape_len = SHAPE_LEN
    let (data_address) = get_label_location(shape_data)
    _check_shape_impl(shape_len, shape, cast(data_address, ShapeItem*))
    return ()
end

func _check_shape_impl{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (shape_len: felt, a: ShapeItem*, b: ShapeItem*):
    if shape_len == 0:
        return ()
    end
    with_attr error_message("Shapes do not match"):
        assert a[0].color_material = b[0].color_material
        assert a[0].x_y_z = b[0].x_y_z
    end
    return _check_shape_impl(shape_len - 1, a + ShapeItem.SIZE, b + ShapeItem.SIZE)
end

#@view
func compute_shape_hash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } ():
    return ()
end

@view
func decompress_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    } (data: ShapeItem) -> (data: UncompressedShapeItem):
    let (color) = bitwise_and(data.color_material, 2**251 - 1 - 2**128 + 1)
    let (material) = bitwise_and(data.color_material, 2**64 - 1)
    let (x) = bitwise_and(data.x_y_z, 2**251 - 1 - 2**128 + 1)
    let (y) = bitwise_and(data.x_y_z, 2**128 - 1 - 2**64 + 1)
    let (z) = bitwise_and(data.x_y_z, 2**64 - 1)
    tempvar out = UncompressedShapeItem(material, color / 2 **128, x / 2 ** 128 - 0x8000000000000000, y / 2 ** 64 - 0x8000000000000000, z - 0x8000000000000000)
    return (out)
end
