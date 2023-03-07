import math
import os
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.starknet import StarknetContract
from starkware.starkware_utils.error_handling import StarkException
from starkware.cairo.common.hash_state import compute_hash_on_elements
from starkware.crypto.signature.signature import FIELD_PRIME

from starkware.starknet.compiler.compile import compile_starknet_files, compile_starknet_codes

from briq_protocol.shape_utils import to_shape_data, compress_shape_item

from .conftest import declare_and_deploy, deploy_shape

CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")

ADDRESS = 0xcafe
OTHER_ADDRESS = 0xd00d
MOCK_SHAPE_TOKEN = 0xdeadfade

def compile(path):
    return compile_starknet_files(
        files=[os.path.join(CONTRACT_SRC, path)],
        debug_info=True,
        disable_hint_validation=True
    )

@pytest_asyncio.fixture(scope="module")
async def factory_root():
    starknet = await Starknet.empty()
    [booklet_contract, _] = await declare_and_deploy(starknet, "booklet_nft.cairo")
    [shape_mock, _] = await declare_and_deploy(starknet, "mocks/shape_mock.cairo")
    await booklet_contract.mint_(MOCK_SHAPE_TOKEN, MOCK_SHAPE_TOKEN, shape_mock.contract_address).execute()
    return (starknet, booklet_contract, shape_mock)

@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, a, b] = factory_root
    state = Starknet(state=starknet.state.copy())
    a = StarknetContract(
        state=state.state,
        abi=a.abi,
        contract_address=a.contract_address,
        deploy_call_info=a.deploy_call_info,
    )
    b = StarknetContract(
        state=state.state,
        abi=b.abi,
        contract_address=b.contract_address,
        deploy_call_info=b.deploy_call_info,
    )
    return (state, a, b)

@pytest.mark.asyncio
async def test_mint_transfer(factory):
    [_, booklet_contract, _] = factory
    TOKEN = 1
    await booklet_contract.mint_(ADDRESS, TOKEN, 2).execute()
    await booklet_contract.safeTransferFrom_(ADDRESS, OTHER_ADDRESS, TOKEN, 1, []).execute(ADDRESS)


@pytest.mark.asyncio
async def test_shape(factory, deploy_shape):
    [starknet, booklet_contract, _] = factory
    [shape_hash, shape_contract] = await deploy_shape(starknet, [
        ('#ffaaff', 1, 4, -2, -6),
        ('#ffaaff', 1, 4, 0, -6),
        ('#ffaaff', 1, 4, 4, -6, True),
    ], [
        1 * 2 **64 + 1
    ])

    TOKEN = 3 * 2**192 + 1
    await booklet_contract.mint_(ADDRESS, TOKEN, shape_hash.class_hash).execute()
    assert (await booklet_contract.get_shape_(TOKEN).call()).result.shape == [
        shape_contract.ShapeItem(*compress_shape_item(color='#ffaaff', material=1, x=4, y=-2, z=-6)),
        shape_contract.ShapeItem(*compress_shape_item(color='#ffaaff', material=1, x=4, y=0, z=-6)),
        shape_contract.ShapeItem(*compress_shape_item(color='#ffaaff', material=1, x=4, y=4, z=-6, has_token_id=True))
    ]
    assert (await booklet_contract.get_shape_(TOKEN).call()).result.nfts == [1 * 2 ** 64 + 1]

@pytest.mark.asyncio
async def test_uri(factory):
    [_, booklet_contract, _] = factory

    uri_data = (await booklet_contract.tokenURI_(1245).call()).result.uri
    assert ''.join([x.to_bytes(math.ceil(x.bit_length() / 8), 'big').decode('ascii') for x in uri_data]) == "https://api.briq.construction/v1/uri/booklet/starknet-mainnet/1245.json"
    for i in range(2, 255, 16):
        uri_data = (await booklet_contract.tokenURI_(2**i).call()).result.uri
        print(''.join([x.to_bytes(math.ceil(x.bit_length() / 8), 'big').decode('ascii') for x in uri_data]), f"https://api.briq.construction/v1/uri/booklet/starknet-mainnet/{2**i}.json")
        assert ''.join([x.to_bytes(math.ceil(x.bit_length() / 8), 'big').decode('ascii') for x in uri_data]) == f"https://api.briq.construction/v1/uri/booklet/starknet-mainnet/{2**i}.json"
        uri_data = (await booklet_contract.tokenURI_(2**i - 1).call()).result.uri
        print(''.join([x.to_bytes(math.ceil(x.bit_length() / 8), 'big').decode('ascii') for x in uri_data]), f"https://api.briq.construction/v1/uri/booklet/starknet-mainnet/{2**i-1}.json")
        assert ''.join([x.to_bytes(math.ceil(x.bit_length() / 8), 'big').decode('ascii') for x in uri_data]) == f"https://api.briq.construction/v1/uri/booklet/starknet-mainnet/{2**i-1}.json"

    for i in range(2, 60, 2):
        uri_data = (await booklet_contract.tokenURI_(int(10**i + 10** (i-30))).call()).result.uri
        print(''.join([x.to_bytes(math.ceil(x.bit_length() / 8), 'big').decode('ascii') for x in uri_data]), f"https://api.briq.construction/v1/uri/booklet/starknet-mainnet/{int(10**i + 10** (i-30))}.json")
        assert ''.join([x.to_bytes(math.ceil(x.bit_length() / 8), 'big').decode('ascii') for x in uri_data]) == f"https://api.briq.construction/v1/uri/booklet/starknet-mainnet/{int(10**i + 10** (i-30))}.json"
        uri_data = (await booklet_contract.tokenURI_(10**i - 1).call()).result.uri
        print(''.join([x.to_bytes(math.ceil(x.bit_length() / 8), 'big').decode('ascii') for x in uri_data]), f"https://api.briq.construction/v1/uri/booklet/starknet-mainnet/{10**i - 1}.json")
        assert ''.join([x.to_bytes(math.ceil(x.bit_length() / 8), 'big').decode('ascii') for x in uri_data]) == f"https://api.briq.construction/v1/uri/booklet/starknet-mainnet/{10**i - 1}.json"

    uri_data = (await booklet_contract.tokenURI_(FIELD_PRIME - 1).call()).result.uri
    assert ''.join([x.to_bytes(math.ceil(x.bit_length() / 8), 'big').decode('ascii') for x in uri_data]) == f"https://api.briq.construction/v1/uri/booklet/starknet-mainnet/{FIELD_PRIME - 1}.json"
