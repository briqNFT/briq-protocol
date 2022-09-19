import os
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.starknet import StarknetContract
from starkware.starkware_utils.error_handling import StarkException
from starkware.cairo.common.hash_state import compute_hash_on_elements

from starkware.starknet.compiler.compile import compile_starknet_files, compile_starknet_codes

from generators.shape_utils import to_shape_data, compress_shape_item

from .conftest import declare_and_deploy

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
    [booklet_contract, _] = await declare_and_deploy(starknet, "booklet.cairo")
    [set_mock, _] = await declare_and_deploy(starknet, "mocks/set_mock.cairo")
    [shape_mock, _] = await declare_and_deploy(starknet, "mocks/shape_mock.cairo")
    await booklet_contract.setSetAddress_(set_mock.contract_address).execute()
    await booklet_contract.mint_(MOCK_SHAPE_TOKEN, MOCK_SHAPE_TOKEN, shape_mock.contract_address).execute()
    return (starknet, booklet_contract, shape_mock, set_mock)

@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, a, b, set_mock] = factory_root
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
    return (state, a, b, set_mock)

@pytest.mark.asyncio
async def test_mint_transfer(factory):
    [_, booklet_contract, _, _] = factory
    TOKEN = 1
    await booklet_contract.mint_(ADDRESS, TOKEN, 2).execute()
    await booklet_contract.safeTransferFrom_(ADDRESS, OTHER_ADDRESS, TOKEN, 1, []).execute(ADDRESS)


@pytest.mark.asyncio
async def test_shape(factory):
    [starknet, booklet_contract, _, _] = factory

    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("// DEFINE_SHAPE", f"""
    const SHAPE_LEN = 3;

    shape_data:
    {to_shape_data('#ffaaff', 1, 4, -2, -6)}
    {to_shape_data('#ffaaff', 1, 4, 0, -6)}
    {to_shape_data('#ffaaff', 1, 4, 4, -6, True)}

    shape_data_end:
    nft_data:
    dw { 1 * 2 **64 + 1};
    nft_data_end:
""")
    test_code = compile_starknet_codes(codes=[(data, "test_code")])
    shape_hash = await starknet.declare(contract_class=test_code)
    shape_contract = await starknet.deploy(contract_class=test_code)

    TOKEN = 1
    await booklet_contract.mint_(ADDRESS, TOKEN, shape_hash.class_hash).execute()
    assert (await booklet_contract.get_shape_(TOKEN).call()).result.shape == [
        shape_contract.ShapeItem(*compress_shape_item(color='#ffaaff', material=1, x=4, y=-2, z=-6)),
        shape_contract.ShapeItem(*compress_shape_item(color='#ffaaff', material=1, x=4, y=0, z=-6)),
        shape_contract.ShapeItem(*compress_shape_item(color='#ffaaff', material=1, x=4, y=4, z=-6, has_token_id=True))
    ]
    assert (await booklet_contract.get_shape_(TOKEN).call()).result.nfts == [1 * 2 ** 64 + 1]
