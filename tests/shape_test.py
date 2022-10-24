import os
from random import randrange
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from starkware.cairo.common.hash_state import compute_hash_on_elements

from starkware.starknet.utils.api_utils import cast_to_felts
from starkware.cairo.lang.compiler.test_utils import short_string_to_felt

from starkware.starknet.compiler.compile import compile_starknet_files, compile_starknet_codes

from .conftest import compile, deploy_shape

CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")

FAKE_SET_PROXY_ADDRESS = 0xcafefade
ADMIN = 0x0  # No proxy so no admin
ADDRESS = 0x123456
OTHER_ADDRESS = 0x654321

# Offset in the shape
OFFSET = 3

@pytest.fixture(scope="session")
def compiled_shape():
    return compile("shape/shape_store.cairo")

@pytest_asyncio.fixture(scope="session")
async def empty_starknet():
    return await Starknet.empty()

@pytest_asyncio.fixture
async def starknet(empty_starknet):
    return Starknet(state=empty_starknet.state.copy())


## Test compress
from generators.shape_utils import to_shape_data, compress_shape_item, uncompress_shape_item

def test_compression():
    col_nft_mat, xyz = compress_shape_item("#ffffff", 2, 5, -1, 4)
    assert col_nft_mat == 0x236666666666660000000000000000000000000000000002
    assert xyz == 0x80000000000000057fffffffffffffff8000000000000004
    col, mat, x, y, z, _ = uncompress_shape_item(col_nft_mat, xyz)
    assert col == "#ffffff"
    assert mat == 2
    assert x == 5
    assert y == -1
    assert z == 4

    col_nft_mat, xyz = compress_shape_item("#ffffff", 2, 2**63 - 1, -2**63 + 1, 4)
    col, mat, x, y, z, _ = uncompress_shape_item(col_nft_mat, xyz)
    assert x == 2**63 - 1
    assert y == -2**63 + 1
    assert z == 4

    col_nft_mat, xyz = compress_shape_item("#ffffff", 2, 2**63 - 1, -2**63 + 1, 0)
    col, mat, x, y, z, _ = uncompress_shape_item(col_nft_mat, xyz)
    assert x == 2**63 - 1
    assert y == -2**63 + 1
    assert z == 0


@pytest.mark.asyncio
async def test_onchain_decompression(starknet: Starknet, deploy_shape):
    [_, contract] = await deploy_shape(starknet, [('#ffaaff', 1, 4, 2, -6)])
    assert (await contract.decompress_data(contract.ShapeItem(*compress_shape_item(
        color='#ffaaff', material=1, x=4, y=2, z=-6)), OFFSET - 1).call()).result.data == contract.UncompressedShapeItem(
        color=short_string_to_felt('#ffaaff'), material=1, nft_token_id=0,
        x=cast_to_felts([4])[0], y=cast_to_felts([2])[0], z=cast_to_felts([-6])[0])


@pytest.mark.asyncio
async def test_nfts_onchain_decompression(starknet: Starknet, deploy_shape):
    [_, contract] = await deploy_shape(starknet, [
        ('#ffaaff', 1, 4, -2, -4),
        ('#ffaaff', 1, 4, 1, -4, True),
        ('#ffaaff', 2, 4, 2, -4),
        ('#ffaaff', 2, 4, 3, -4, True),
        ('#ffaaff', 1, 4, 4, -4),
    ], nfts=[
        1 * 2**64 + 1,
        2 * 2**64 + 2
    ])
    assert (await contract.decompress_data(contract.ShapeItem(*compress_shape_item(
        color='#ffaaff', material=1, x=4, y=1, z=-4, has_token_id=True)), OFFSET - 1).call()).result.data == contract.UncompressedShapeItem(
        color=short_string_to_felt('#ffaaff'), material=1, nft_token_id=1 * 2**64 + 1,
        x=cast_to_felts([4])[0], y=cast_to_felts([1])[0], z=cast_to_felts([-4])[0])

    assert (await contract.decompress_data(contract.ShapeItem(*compress_shape_item(
        color='#ffaaff', material=2, x=4, y=3, z=-4, has_token_id=True)), OFFSET - 1).call()).result.data == contract.UncompressedShapeItem(
        color=short_string_to_felt('#ffaaff'), material=2, nft_token_id=2 * 2**64 + 2,
        x=cast_to_felts([4])[0], y=cast_to_felts([3])[0], z=cast_to_felts([-4])[0])

@pytest.mark.asyncio
async def test_simple(starknet: Starknet, deploy_shape):
    [_, contract] = await deploy_shape(starknet, [('#ffaaff', 1, 4, 2, -6)])
    assert (await contract.shape_(OFFSET).call()).result.shape == [contract.ShapeItem(*compress_shape_item(color='#ffaaff', material=1, x=4, y=2, z=-6))]

@pytest.mark.asyncio
async def test_long(starknet: Starknet, deploy_shape):
    [_, contract] = await deploy_shape(starknet, [
        ('#ffaaff', 1, 4, -2, -6),
        ('#ffaaff', 1, 4, 2, -6),
        ('#ffaaff', 1, 5, 2, -4),
    ])
    assert (await contract.shape_(OFFSET).call()).result.shape == [
        contract.ShapeItem(*compress_shape_item('#ffaaff', 1, 4, -2, -6)),
        contract.ShapeItem(*compress_shape_item('#ffaaff', 1, 4, 2, -6)),
        contract.ShapeItem(*compress_shape_item('#ffaaff', 1, 5, 2, -4)),
    ]

@pytest.mark.asyncio
async def test_bad_sort_0(starknet: Starknet, deploy_shape):
    with pytest.raises(StarkException, match="Shape items are not properly sorted"):
        [_, contract] = await deploy_shape(starknet, [
            ('#ffaaff', 1, 4, -2, -6),
            ('#ffaaff', 1, 2, -2, -6)
        ])

@pytest.mark.asyncio
async def test_bad_sort_1(starknet: Starknet, deploy_shape):
    with pytest.raises(StarkException, match="Shape items are not properly sorted"):
        [_, contract] = await deploy_shape(starknet, [
            ('#ffaaff', 1, 4, -2, -6),
            ('#ffaaff', 1, 4, -4, -6)
        ])

@pytest.mark.asyncio
async def test_bad_sort_2(starknet: Starknet, deploy_shape):
    with pytest.raises(StarkException, match="Shape items are not properly sorted"):
        [_, contract] = await deploy_shape(starknet, [
            ('#ffaaff', 1, 4, -2, 4),
            ('#ffaaff', 1, 4, -2, 2),
        ])
@pytest.mark.asyncio
async def test_bad_ident(starknet: Starknet, deploy_shape):
    with pytest.raises(StarkException, match="Shape items contains duplicate position"):
        [_, contract] = await deploy_shape(starknet, [
            ('#ffaaff', 1, 4, -2, 4),
            ('#ffaaff', 1, 4, -2, 4),
        ])

@pytest.mark.asyncio
async def test_bad_nft_too_few_0(starknet: Starknet, deploy_shape):
    with pytest.raises(StarkException, match="Shape does not have the right number of NFTs"):
        [_, contract] = await deploy_shape(starknet, [
            ('#ffaaff', 1, 4, -2, 4),
            ('#ffaaff', 1, 5, -2, 4),
        ], [
            1 * 2 **64 + 1
        ])

@pytest.mark.asyncio
async def test_bad_nft_too_few_1(starknet: Starknet, deploy_shape):
    with pytest.raises(StarkException, match="Shape does not have the right number of NFTs"):
        [_, contract] = await deploy_shape(starknet, [
            ('#ffaaff', 1, 4, -2, 4),
            ('#ffaaff', 1, 5, -2, 4, True),
        ], [
            1 * 2 **64 + 1,
            2 * 2 **64 + 1,
        ])

@pytest.mark.asyncio
async def test_bad_nft_too_many_0(starknet: Starknet, deploy_shape):
    with pytest.raises(StarkException, match="Shape does not have the right number of NFTs"):
        [_, contract] = await deploy_shape(starknet, [
            ('#ffaaff', 1, 4, -2, 4, True),
            ('#ffaaff', 1, 5, -2, 4),
        ])
    
@pytest.mark.asyncio
async def test_bad_nft_too_many_1(starknet: Starknet, deploy_shape):
    with pytest.raises(StarkException, match="Shape does not have the right number of NFTs"):
        [_, contract] = await deploy_shape(starknet, [
            ('#ffaaff', 1, 4, -2, 4, True),
            ('#ffaaff', 1, 5, -2, 4, True),
        ], [
            1 * 2 **64 + 1
        ])

@pytest.mark.asyncio
async def test_bad_nft_repetition(starknet: Starknet, deploy_shape):
    with pytest.raises(StarkException, match="Shape items contains duplicate position"):
        [_, contract] = await deploy_shape(starknet, [
            ('#ffaaff', 1, 4, -2, 4, True),
            ('#ffaaff', 1, 5, -2, 4, True),
            ('#ffaaff', 1, 6, -2, 4, True),
        ], [
            1 * 2 **64 + 1,
            1 * 2 **64 + 2,
            1 * 2 **64 + 1
        ])


@pytest.mark.asyncio
async def test_bad_nft_bad_material(starknet: Starknet, deploy_shape):
    with pytest.raises(StarkException, match="NFT does not have the right material"):
        [_, contract] = await deploy_shape(starknet, [
            ('#ffaaff', 1, 4, -2, 4, True),
            ('#ffaaff', 1, 5, -2, 4, True),
        ], [
            1 * 2 **64 + 1,
            1 * 2 **64 + 2
        ])


@pytest.mark.asyncio
async def test_good_nft_random_order(starknet: Starknet, deploy_shape):
    # NFTs don't actually have to be in any particular sorting, all they have to do is match the shape positions.
    [_, contract] = await deploy_shape(starknet, [
        ('#ffaaff', 1, 4, -2, 4, True),
        ('#ffaaff', 1, 6, -2, 4, True),
        ('#ffaaff', 1, 7, -2, 4, True),
        ('#ffaaff', 2, 8, -2, 4, True),
    ], [
        5 * 2**64 + 1,
        2 * 2**64 + 1,
        1 * 2**64 + 1,
        1 * 2**64 + 2,
    ])



def to_shape_items(shape_contract, items):
    return [shape_contract.ShapeItem(*compress_shape_item(*i)) for i in items]
