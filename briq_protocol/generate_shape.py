from typing import Tuple
from .shape_utils import to_shape_data

# Index_start is usually 1 because the token 0 generally doesn't exist and this makes things neater.
# Warning: shapes isn't sorted (because tests pass broken inputs on purpose)
def generate_shape_code(shapes: list[Tuple[list, list]], index_start: int = 1):
    newline = '\n'
    shape_offsets = ["dw 0;"]
    nft_offsets = ["dw 0;"]
    data_shapes = []
    data_nfts = []
    cum_shape = 0
    cum_nft = 0
    for shape in shapes:
        cum_shape += len(shape[0])
        cum_nft += len(shape[1])
        shape_offsets.append(f"dw {cum_shape};")
        nft_offsets.append(f"dw {cum_nft};")
        for shape_data in shape[0]:
            data_shapes.append(to_shape_data(*shape_data))
        for nft_data in shape[1]:
            data_nfts.append(f"dw {hex(nft_data)};")

    return f"""
%lang starknet

const INDEX_START = {index_start};

shape_offset_cumulative:
{newline.join(shape_offsets)}
shape_offset_cumulative_end:

shape_data:
{newline.join(data_shapes)}
shape_data_end:

nft_offset_cumulative:
{newline.join(nft_offsets)}
nft_offset_cumulative_end:

nft_data:
{newline.join(data_nfts)}
nft_data_end:
"""
