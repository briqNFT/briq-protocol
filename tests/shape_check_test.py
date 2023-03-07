from collections import namedtuple
import os
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.starknet import StarknetContract
from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.compiler.compile import compile_starknet_codes, compile_starknet_files

from briq_protocol.shape_utils import to_shape_data, compress_shape_item

from .conftest import deploy_shape

CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")

ADDRESS = 0xcafe
OTHER_ADDRESS = 0xd00d
MOCK_SHAPE_TOKEN = 0xdeadfade

# Offset in the shape
OFFSET = 3

@pytest_asyncio.fixture(scope="module")
async def factory_root():
    starknet = await Starknet.empty()
    return [starknet]

@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet] = factory_root
    state = Starknet(state=starknet.state.copy())
    return namedtuple('State', ['starknet'])(
        starknet=state,
    )

def to_shape_items(shape_contract, items):
    return [shape_contract.ShapeItem(*compress_shape_item(*i)) for i in items]


@pytest.mark.asyncio
async def test_simple(deploy_shape, factory):
    [starknet] = factory

    [_, shape] = await deploy_shape(starknet, [("#ffaaff", 0x1, 0, 4, -2)])
    with pytest.raises(StarkException):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=[], fts=[], nfts=[]).call()
    with pytest.raises(StarkException, match="Material not found in FT list"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, [("#ffaaff", 0x1, 0, 4, -2)]), fts=[], nfts=[]).call()
    with pytest.raises(StarkException, match="Material not found in FT list"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, [("#ffaaff", 0x1, 0, 4, -2)]), fts=[(0x2, 1)], nfts=[]).call()
    with pytest.raises(StarkException, match="Shapes do not match"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, [("#ffaaff", 0x1, 0, 4, -2, True)]), fts=[(0x2, 1)], nfts=[]).call()
    with pytest.raises(StarkException, match="Wrong number of NFTs"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, [("#ffaaff", 0x1, 0, 4, -2)]), fts=[(0x1, 1)], nfts=[0x1234]).call()
    await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, [("#ffaaff", 0x1, 0, 4, -2)]), fts=[(0x1, 1)], nfts=[]).call()


@pytest.mark.asyncio
async def test_any_color_any_material(deploy_shape, factory):
    [starknet] = factory

    proper_shape = [("#ffaaff", 0x1, 0, 4, -2), ("any_color_any_material", 0x1, 1, 4, -2), ("#ffaaff", 0x1, 2, 4, 0)]
    [_, shape] = await deploy_shape(starknet, proper_shape)
    with pytest.raises(StarkException):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=[], fts=[], nfts=[]).call()
    with pytest.raises(StarkException, match="Material not found in FT list"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, proper_shape), fts=[], nfts=[]).call()
    with pytest.raises(StarkException, match="Material not found in FT list"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, proper_shape), fts=[(0x2, 1)], nfts=[]).call()

    with pytest.raises(StarkException):
        # Fails cause material is 0
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, proper_shape), fts=[(0x1, 1)], nfts=[]).call()
    await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, [("#ffaaff", 0x1, 0, 4, -2), ("#ffaaff", 0x1, 1, 4, -2), ("#ffaaff", 0x1, 2, 4, 0)]), fts=[(0x1, 3)], nfts=[]).call()
    await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, [("#ffaaff", 0x1, 0, 4, -2), ("#aaffaa", 0x2, 1, 4, -2), ("#ffaaff", 0x1, 2, 4, 0)]), fts=[(0x1, 2), (0x2, 1)], nfts=[]).call()
    await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, [("#ffaaff", 0x1, 0, 4, -2), ("#00ff00", 0x54, 1, 4, -2), ("#ffaaff", 0x1, 2, 4, 0)]), fts=[(0x1, 2), (0x54, 1)], nfts=[]).call()
    await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, [("#ffaaff", 0x1, 0, 4, -2), ("#00ff00", 0x1, 1, 4, -2), ("#ffaaff", 0x1, 2, 4, 0)]), fts=[(0x1, 3)], nfts=[]).call()


@pytest.mark.asyncio
async def test_simple_nft(deploy_shape, factory):
    [starknet] = factory

    [_, shape] = await deploy_shape(starknet, [("#ffaaff", 0x1, 0, 4, -2, True)], [1234 * 2 ** 64 + 1])
    with pytest.raises(StarkException):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=[], fts=[], nfts=[]).call()
    with pytest.raises(StarkException, match="Wrong number of NFTs"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, [("#ffaaff", 0x1, 0, 4, -2, True)]), fts=[], nfts=[]).call()
    with pytest.raises(StarkException, match="Incorrect NFT"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, [("#ffaaff", 0x1, 0, 4, -2, True)]), fts=[], nfts=[123 * 2 ** 64 + 1]).call()
    with pytest.raises(StarkException, match="Incorrect NFT"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, [("#ffaaff", 0x1, 0, 4, -2, True)]), fts=[], nfts=[1234 * 2 ** 64 + 2]).call()
    with pytest.raises(StarkException, match="Wrong number of NFTs"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, [("#ffaaff", 0x1, 0, 4, -2, True)]), fts=[], nfts=[1234 * 2 ** 64 + 1, 1234 * 2 ** 64 + 2]).call()
    with pytest.raises(StarkException, match="Wrong number of briqs in shape"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, [("#ffaaff", 0x1, 0, 4, -2, True)]), fts=[(0x1, 1)], nfts=[1234 * 2 ** 64 + 1]).call()
    await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, [("#ffaaff", 0x1, 0, 4, -2, True)]), fts=[], nfts=[1234 * 2 ** 64 + 1]).call()


@pytest.mark.asyncio
async def test_both(deploy_shape, factory):
    [starknet] = factory

    shape_data = [
        ("#ffaaff", 0x1, 0, 4, -2,),
        ("#ffaaff", 0x1, 1, 4, -2, True),
        ("#ffaaff", 0x2, 2, 4, -2,),
        ("#ffaaff", 0x2, 3, 4, -2, True)
    ]
    [_, shape] = await deploy_shape(starknet, shape_data, [1234 * 2 ** 64 + 1, 4321 * 2 ** 64 + 2])

    with pytest.raises(StarkException):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=[], fts=[], nfts=[]).call()
    with pytest.raises(StarkException, match="Wrong number of NFTs"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, shape_data), fts=[], nfts=[]).call()
    with pytest.raises(StarkException, match="Wrong number of NFTs"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, shape_data), fts=[], nfts=[123 * 2 ** 64 + 1]).call()
    with pytest.raises(StarkException, match="Wrong number of NFTs"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, shape_data), fts=[], nfts=[1234 * 2 ** 64 + 1, 1234 * 2 ** 64 + 2, 1234 * 2 ** 64 + 4]).call()
    with pytest.raises(StarkException, match="Incorrect NFT"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, shape_data), fts=[(0x1, 1), (0x2, 1)], nfts=[1234 * 2 ** 64 + 1, 1234 * 2 ** 64 + 2]).call()
    with pytest.raises(StarkException, match="Incorrect NFT"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, shape_data), fts=[(0x1, 1), (0x2, 1)], nfts=[4321 * 2 ** 64 + 2, 1234 * 2 ** 64 + 1]).call()
    with pytest.raises(StarkException, match="Incorrect NFT"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, shape_data), fts=[(0x1, 1), (0x2, 1)], nfts=[1234 * 2 ** 64 + 2, 1234 * 2 ** 64 + 2]).call()
    with pytest.raises(StarkException, match="Wrong number of briqs in shape"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, shape_data), fts=[(0x1, 1), (0x2, 2)], nfts=[1234 * 2 ** 64 + 1, 4321 * 2 ** 64 + 2]).call()
    with pytest.raises(StarkException, match="Wrong number of briqs in shape"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, shape_data), fts=[(0x1, 2), (0x2, 1)], nfts=[1234 * 2 ** 64 + 1, 4321 * 2 ** 64 + 2]).call()
    with pytest.raises(StarkException, match="Material not found in FT list"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, shape_data), fts=[(0x1, 1)], nfts=[1234 * 2 ** 64 + 1, 4321 * 2 ** 64 + 2]).call()
    with pytest.raises(StarkException, match="Wrong number of briqs in shape"):
        await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, shape_data), fts=[(0x1, 1), (0x2, 1), (0x3, 1)], nfts=[1234 * 2 ** 64 + 1, 4321 * 2 ** 64 + 2]).call()
    await shape.check_shape_numbers_(global_index=OFFSET, shape=to_shape_items(shape, shape_data), fts=[(0x1, 1), (0x2, 1)], nfts=[1234 * 2 ** 64 + 1, 4321 * 2 ** 64 + 2]).call()
