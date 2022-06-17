from collections import namedtuple
import os
from typing import Tuple
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.starknet import StarknetContract
from starkware.starkware_utils.error_handling import StarkException
from starkware.cairo.common.hash_state import compute_hash_on_elements

from starkware.starknet.compiler.compile import compile_starknet_files, compile_starknet_codes

from starkware.starknet.public.abi import get_selector_from_name

from generators.shape_utils import to_shape_data, compress_shape_item

from .briq_impl_test import FAKE_BRIQ_PROXY_ADDRESS, compiled_briq, invoke_briq
from starkware.starknet.testing.objects import StarknetTransactionExecutionInfo

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
    [briq_contract, _] = await declare_and_deploy(starknet, "briq_impl.cairo")
    [set_contract, _] = await declare_and_deploy(starknet, "set_impl.cairo")
    [booklet_contract, _] = await declare_and_deploy(starknet, "booklet.cairo")
    await set_contract.setBriqAddress_(briq_contract.contract_address).invoke()
    await set_contract.setBookletAddress_(booklet_contract.contract_address).invoke()
    await briq_contract.setSetAddress_(set_contract.contract_address).invoke()
    await booklet_contract.setSetAddress_(set_contract.contract_address).invoke()
    await briq_contract.mintFT_(ADDRESS, 0x1, 100).invoke()
    return [starknet, set_contract, briq_contract, booklet_contract]


def copy_contract(state, contract):
    return StarknetContract(
        state=state.state,
        abi=contract.abi,
        contract_address=contract.contract_address,
        deploy_execution_info=contract.deploy_execution_info,
    )

@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, set_contract, briq_contract, booklet_contract] = factory_root
    state = Starknet(state=starknet.state.copy())
    return namedtuple('State', ['starknet', 'set_contract', 'briq_contract', 'booklet_contract'])(
        starknet=state,
        set_contract=copy_contract(state, set_contract),
        briq_contract=copy_contract(state, briq_contract),
        booklet_contract=copy_contract(state, booklet_contract),
    )

def report_performance(exc_info: StarknetTransactionExecutionInfo):
    gas_cost = exc_info.call_info.execution_resources
    print(gas_cost)
    print("Reminder: the gas cost is the maximum")
    print("Steps: ", gas_cost.n_steps, " gas cost: ", gas_cost.n_steps * 0.05)
    print("Range: ", gas_cost.builtin_instance_counter['range_check_builtin'], " gas cost: ", gas_cost.builtin_instance_counter['range_check_builtin'] * 0.4)
    print("Bitwise: ", gas_cost.builtin_instance_counter['bitwise_builtin'], " gas cost: ", gas_cost.builtin_instance_counter['bitwise_builtin'] * 12.8)

# The purpose of this test is to compare the L2 gas costs
# On some simple shape-checking operations of 100 briqs. The material layout is different, resulting in different gas costs.
# In the current setup, gas costs are capped by bitwise comparisons (O(n) in # of briqs) for few materials,
# but with enough materials, the steps start to dominate because of the counter-incrementing logic.
# It's actually fairly well-balanced, so nice.

@pytest.mark.asyncio
async def test_performance_optimal(factory):
    state = factory
    TOKEN_HINT = 1234
    TOKEN_URI = [1234]
    BOOKLET_TOKEN_ID = 1234
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 100

    shape_data:
    {' '.join([to_shape_data('#ffaaff', 1, i, 0, 2) for i in range(100)])}
    shape_data_end:
    nft_data:
    nft_data_end:
""")
    # write to a file so we can get error messages.
    test_code = compile_starknet_codes(codes=[(data, "test_code")], disable_hint_validation=True, debug_info=True)
    shape_contract = await state.starknet.deploy(contract_class=test_code)

    await state.booklet_contract.mint_(ADDRESS, BOOKLET_TOKEN_ID, shape_contract.contract_address).invoke(ADDRESS)

    tx_info = await state.set_contract.assemble_with_booklet_(
        owner=ADDRESS,
        token_id_hint=TOKEN_HINT,
        uri=TOKEN_URI,
        fts=[(0x1, 100)],
        nfts=[],
        booklet_token_id=BOOKLET_TOKEN_ID,
        shape=[compress_shape_item('#ffaaff', 0x1, i, 0, 2, False) for i in range(100)],
    ).invoke(ADDRESS)
    report_performance(tx_info)


@pytest.mark.asyncio
async def test_performance_less_optimal(factory):
    state = factory
    await state.briq_contract.mintFT_(ADDRESS, 0x2, 100).invoke()
    TOKEN_HINT = 1234
    TOKEN_URI = [1234]
    BOOKLET_TOKEN_ID = 1234
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 100

    shape_data:
    {' '.join([to_shape_data('#ffaaff', 1, 0, i, 2) for i in range(80)])}
    {' '.join([to_shape_data('#ffaaff', 2, 1, i, 2) for i in range(20)])}
    shape_data_end:
    nft_data:
    nft_data_end:
""")
    # write to a file so we can get error messages.
    test_code = compile_starknet_codes(codes=[(data, "test_code")], disable_hint_validation=True, debug_info=True)
    shape_contract = await state.starknet.deploy(contract_class=test_code)

    await state.booklet_contract.mint_(ADDRESS, BOOKLET_TOKEN_ID, shape_contract.contract_address).invoke(ADDRESS)

    tx_info = await state.set_contract.assemble_with_booklet_(
        owner=ADDRESS,
        token_id_hint=TOKEN_HINT,
        uri=TOKEN_URI,
        fts=[(0x1, 80), (0x2, 20)],
        nfts=[],
        booklet_token_id=BOOKLET_TOKEN_ID,
        shape=[compress_shape_item('#ffaaff', 0x1, 0, i, 2, False) for i in range(80)] + [
            compress_shape_item('#ffaaff', 0x2, 1, i, 2, False) for i in range(20)
        ],
    ).invoke(ADDRESS)
    report_performance(tx_info)

@pytest.mark.asyncio
async def test_performance_bad(factory):
    state = factory
    await state.briq_contract.mintFT_(ADDRESS, 0x2, 10).invoke()
    await state.briq_contract.mintFT_(ADDRESS, 0x3, 10).invoke()
    await state.briq_contract.mintFT_(ADDRESS, 0x4, 10).invoke()
    await state.briq_contract.mintFT_(ADDRESS, 0x5, 10).invoke()
    await state.briq_contract.mintFT_(ADDRESS, 0x6, 10).invoke()
    await state.briq_contract.mintFT_(ADDRESS, 0x7, 10).invoke()
    await state.briq_contract.mintFT_(ADDRESS, 0x8, 10).invoke()
    await state.briq_contract.mintFT_(ADDRESS, 0x9, 10).invoke()
    await state.briq_contract.mintFT_(ADDRESS, 0xA, 10).invoke()
    TOKEN_HINT = 1234
    TOKEN_URI = [1234]
    BOOKLET_TOKEN_ID = 1234
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = 100

    shape_data:
    {' '.join([to_shape_data('#ffaaff', j+1, j, i, 2) for j in range(10) for i in range(10)])}
    shape_data_end:
    nft_data:
    nft_data_end:
""")
    # write to a file so we can get error messages.
    test_code = compile_starknet_codes(codes=[(data, "test_code")], disable_hint_validation=True, debug_info=True)
    shape_contract = await state.starknet.deploy(contract_class=test_code)

    await state.booklet_contract.mint_(ADDRESS, BOOKLET_TOKEN_ID, shape_contract.contract_address).invoke(ADDRESS)

    tx_info = await state.set_contract.assemble_with_booklet_(
        owner=ADDRESS,
        token_id_hint=TOKEN_HINT,
        uri=TOKEN_URI,
        fts=[(i + 1, 10) for i in range(10)],
        nfts=[],
        booklet_token_id=BOOKLET_TOKEN_ID,
        shape=[
            compress_shape_item('#ffaaff', j+1, j, i, 2, False) for j in range(10) for i in range(10)
        ],
    ).invoke(ADDRESS)
    report_performance(tx_info)
