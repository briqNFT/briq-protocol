import os
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from starkware.cairo.common.hash_state import compute_hash_on_elements

from starkware.starknet.utils.api_utils import cast_to_felts
from starkware.cairo.lang.compiler.test_utils import short_string_to_felt

from starkware.starknet.compiler.compile import compile_starknet_files, compile_starknet_codes

CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")

FAKE_SET_PROXY_ADDRESS = 0xcafefade
ADMIN = 0x0  # No proxy so no admin
ADDRESS = 0x123456
OTHER_ADDRESS = 0x654321

def compile(path):
    return compile_starknet_files(
        files=[os.path.join(CONTRACT_SRC, path)],
        debug_info=True
    )

import asyncio
@pytest.fixture(scope="session")
def event_loop():
    return asyncio.get_event_loop()

@pytest.fixture(scope="session")
def compiled_shape():
    return compile("shape/shape_store.cairo")

@pytest_asyncio.fixture(scope="session")
async def empty_starknet():
    # Create a new Starknet class that simulates the StarkNet
    return await Starknet.empty()

@pytest_asyncio.fixture
async def starknet(empty_starknet):
    # Create a new Starknet class that simulates the StarkNet
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
async def test_onchain_decompression(starknet: Starknet):
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    shape = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 1

    shape_data:
    {to_shape_data('#ffaaff', 1, 4, 2, -6)}
    shape_data_end:
    nft_data:
    nft_data_end:
""")
    test_code = compile_starknet_codes(codes=[(shape, "test_code")])
    contract = await starknet.deploy(contract_def=test_code)
    assert (await contract.decompress_data(contract.ShapeItem(*compress_shape_item(
        color='#ffaaff', material=1, x=4, y=2, z=-6))).call()).result.data == contract.UncompressedShapeItem(
        color=short_string_to_felt('#ffaaff'), material=1, nft_token_id=0,
        x=cast_to_felts([4])[0], y=cast_to_felts([2])[0], z=cast_to_felts([-6])[0])


@pytest.mark.asyncio
async def test_nfts_onchain_decompression(starknet: Starknet):
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    shape = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 5

    shape_data:
    {to_shape_data('#ffaaff', 1, 4, -2, -4)}
    {to_shape_data('#ffaaff', 1, 4, 1, -4, True)}
    {to_shape_data('#ffaaff', 2, 4, 2, -4)}
    {to_shape_data('#ffaaff', 2, 4, 3, -4, True)}
    {to_shape_data('#ffaaff', 1, 4, 4, -4)}
    shape_data_end:
    nft_data:
    dw {1 * 2**64 + 1}
    dw {2 * 2**64 + 2}
    nft_data_end:
""")
    test_code = compile_starknet_codes(codes=[(shape, "test_code")], disable_hint_validation=True)
    contract = await starknet.deploy(contract_def=test_code)
    assert (await contract.decompress_data(contract.ShapeItem(*compress_shape_item(
        color='#ffaaff', material=1, x=4, y=1, z=-4, has_token_id=True))).call()).result.data == contract.UncompressedShapeItem(
        color=short_string_to_felt('#ffaaff'), material=1, nft_token_id=1 * 2**64 + 1,
        x=cast_to_felts([4])[0], y=cast_to_felts([1])[0], z=cast_to_felts([-4])[0])

    assert (await contract.decompress_data(contract.ShapeItem(*compress_shape_item(
        color='#ffaaff', material=2, x=4, y=3, z=-4, has_token_id=True))).call()).result.data == contract.UncompressedShapeItem(
        color=short_string_to_felt('#ffaaff'), material=2, nft_token_id=2 * 2**64 + 2,
        x=cast_to_felts([4])[0], y=cast_to_felts([3])[0], z=cast_to_felts([-4])[0])

@pytest.mark.asyncio
async def test_simple(starknet: Starknet):
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    shape = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 1

    shape_data:
    {to_shape_data('#ffaaff', 1, 4, 2, -6)}
    shape_data_end:
    nft_data:
    nft_data_end:
""")
    test_code = compile_starknet_codes(codes=[(shape, "test_code")])
    contract = await starknet.deploy(contract_def=test_code)
    assert (await contract._shape().call()).result.shape == [contract.ShapeItem(*compress_shape_item(color='#ffaaff', material=1, x=4, y=2, z=-6))]

@pytest.mark.asyncio
async def test_long(starknet: Starknet):
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    shape = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 3

    shape_data:
    {to_shape_data('#ffaaff', 1, 4, -2, -6)}
    {to_shape_data('#ffaaff', 1, 4, 2, -6)}
    {to_shape_data('#ffaaff', 1, 5, 2, -4)}
    shape_data_end:
    nft_data:
    nft_data_end:
""")
    test_code = compile_starknet_codes(codes=[(shape, "test_code")])
    contract = await starknet.deploy(contract_def=test_code)
    assert (await contract._shape().call()).result.shape == [
        contract.ShapeItem(*compress_shape_item('#ffaaff', 1, 4, -2, -6)),
        contract.ShapeItem(*compress_shape_item('#ffaaff', 1, 4, 2, -6)),
        contract.ShapeItem(*compress_shape_item('#ffaaff', 1, 5, 2, -4)),
    ]

@pytest.mark.asyncio
async def test_bad_sort_0(starknet: Starknet):
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 2

    shape_data:
    {to_shape_data('#ffaaff', 1, 4, -2, -6)}
    {to_shape_data('#ffaaff', 1, 2, -2, -6)}
    shape_data_end:
    nft_data:
    nft_data_end:
""")
    test_code = compile_starknet_codes(codes=[(data, "test_code")])
    with pytest.raises(StarkException, match="Shape items are not properly sorted"):
        await starknet.deploy(contract_def=test_code)

@pytest.mark.asyncio
async def test_bad_sort_1(starknet: Starknet):
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 2

    shape_data:
    {to_shape_data('#ffaaff', 1, 4, -2, -6)}
    {to_shape_data('#ffaaff', 1, 4, -4, -6)}

    shape_data_end:
    nft_data:
    nft_data_end:
""")
    test_code = compile_starknet_codes(codes=[(data, "test_code")])
    with pytest.raises(StarkException, match="Shape items are not properly sorted"):
        await starknet.deploy(contract_def=test_code)

@pytest.mark.asyncio
async def test_bad_sort_2(starknet: Starknet):
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 2

    shape_data:
    {to_shape_data('#ffaaff', 1, 4, -2, 4)}
    {to_shape_data('#ffaaff', 1, 4, -2, 2)}
    shape_data_end:
    nft_data:
    nft_data_end:
""")
    test_code = compile_starknet_codes(codes=[(data, "test_code")])
    with pytest.raises(StarkException, match="Shape items are not properly sorted"):
        await starknet.deploy(contract_def=test_code)

@pytest.mark.asyncio
async def test_bad_ident(starknet: Starknet):
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 2

    shape_data:
    {to_shape_data('#ffaaff', 1, 4, -2, 4)}
    {to_shape_data('#ffaaff', 1, 4, -2, 4)}
    shape_data_end:
    nft_data:
    nft_data_end:
""")
    test_code = compile_starknet_codes(codes=[(data, "test_code")])
    with pytest.raises(StarkException, match="Shape items contains duplicate position"):
        await starknet.deploy(contract_def=test_code)

@pytest.mark.asyncio
async def test_bad_nft_too_few_0(starknet: Starknet):
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 2

    shape_data:
    {to_shape_data('#ffaaff', 1, 4, -2, 4)}
    {to_shape_data('#ffaaff', 1, 5, -2, 4)}
    shape_data_end:
    nft_data:
    dw {1 * 2 **64 + 1}
    nft_data_end:
""")
    test_code = compile_starknet_codes(codes=[(data, "test_code")])
    with pytest.raises(StarkException, match="Shape does not have the right number of NFTs"):
        await starknet.deploy(contract_def=test_code)

@pytest.mark.asyncio
async def test_bad_nft_too_few_1(starknet: Starknet):
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 2

    shape_data:
    {to_shape_data('#ffaaff', 1, 4, -2, 4)}
    {to_shape_data('#ffaaff', 1, 5, -2, 4, True)}
    shape_data_end:
    nft_data:
    dw {1 * 2 **64 + 1}
    dw {2 * 2 **64 + 1}
    nft_data_end:
""")
    test_code = compile_starknet_codes(codes=[(data, "test_code")])
    with pytest.raises(StarkException, match="Shape does not have the right number of NFTs"):
        await starknet.deploy(contract_def=test_code)

@pytest.mark.asyncio
async def test_bad_nft_too_many_0(starknet: Starknet):
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 2

    shape_data:
    {to_shape_data('#ffaaff', 1, 4, -2, 4, True)}
    {to_shape_data('#ffaaff', 1, 5, -2, 4)}
    shape_data_end:
    nft_data:
    nft_data_end:
""")
    test_code = compile_starknet_codes(codes=[(data, "test_code")])
    with pytest.raises(StarkException, match="Shape does not have the right number of NFTs"):
        await starknet.deploy(contract_def=test_code)
    
@pytest.mark.asyncio
async def test_bad_nft_too_many_1(starknet: Starknet):
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 2

    shape_data:
    {to_shape_data('#ffaaff', 1, 4, -2, 4, True)}
    {to_shape_data('#ffaaff', 1, 5, -2, 4, True)}
    shape_data_end:
    nft_data:
    dw {1 * 2 **64 + 1}
    nft_data_end:
""")
    test_code = compile_starknet_codes(codes=[(data, "test_code")])
    with pytest.raises(StarkException, match="Shape does not have the right number of NFTs"):
        await starknet.deploy(contract_def=test_code)

@pytest.mark.asyncio
async def test_bad_nft_repetition(starknet: Starknet):
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 2

    shape_data:
    {to_shape_data('#ffaaff', 1, 4, -2, 4, True)}
    {to_shape_data('#ffaaff', 1, 5, -2, 4, True)}
    shape_data_end:
    nft_data:
    dw {1 * 2 **64 + 1}
    dw {1 * 2 **64 + 1}
    nft_data_end:
""")
    test_code = compile_starknet_codes(codes=[(data, "test_code")])
    with pytest.raises(StarkException, match="Shape items contains duplicate position"):
        await starknet.deploy(contract_def=test_code)


@pytest.mark.asyncio
async def test_bad_nft_bad_material(starknet: Starknet):
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 2

    shape_data:
    {to_shape_data('#ffaaff', 1, 4, -2, 4, True)}
    {to_shape_data('#ffaaff', 1, 5, -2, 4, True)}
    shape_data_end:
    nft_data:
    dw {1 * 2 **64 + 1}
    dw {1 * 2 **64 + 2}
    nft_data_end:
""")
    test_code = compile_starknet_codes(codes=[(data, "test_code")])
    with pytest.raises(StarkException, match="NFT does not have the right material"):
        await starknet.deploy(contract_def=test_code)
