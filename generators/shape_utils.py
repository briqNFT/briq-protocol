from starkware.cairo.lang.compiler.test_utils import short_string_to_felt

def compress_shape_item(color: str, material: int, x: int, y: int, z: int, has_token_id: bool = False):
    if material < 0 or material >= 2 ** 64:
        raise Exception("Material must be between 0 and 2^64")
    if len(color) != 7:
        raise Exception("Color must be formatted like '#001122'")
    color_nft_material = short_string_to_felt(color) * (2 ** 136) + (has_token_id) * (2 ** 128) + material

    if x <= -2**63 or x >= 2**63 or y <= -2**63 or y >= 2**63 or z <= -2**63 or z >= 2**63:
        raise Exception("The shape contract currently cannot support positions beyond 2^63 in any direction")

    x_y_z = to_storage_form(x) * 2 ** 128 + to_storage_form(y) * 2 ** 64 + to_storage_form(z)
    return (color_nft_material, x_y_z)

# I want to preserve ordering in felt, so just add 2**63. 0 becomes -2**63 + 1, 2**64 - 1 becomes 2**63 - 1
def to_storage_form(v):
    return v + 0x8000000000000000

def from_storage_form(v):
    return v - 0x8000000000000000

# NB -> This can't actually tell what the NFT is, since that depends on other metadata
def uncompress_shape_item(col_nft_mat: int, x_y_z: int):
    color: int = col_nft_mat // 2 ** 136
    has_token_id: bool = bool(col_nft_mat & (2**128))
    mat: int = col_nft_mat & 0xffffffffffffffff
    x: int = from_storage_form(x_y_z // 2 ** 128)
    y: int = from_storage_form((x_y_z // 2 ** 64) & 0xffffffffffffffff)
    z: int = from_storage_form(x_y_z & 0xffffffffffffffff)
    return color.to_bytes(7, 'big').decode('ascii'), mat, x, y, z, has_token_id
