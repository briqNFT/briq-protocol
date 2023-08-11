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

from briq_protocol.shape_utils import to_shape_data, compress_shape_item

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
    [briq_contract, _] = await declare_and_deploy(starknet, "briq.cairo")
    [set_contract, _] = await declare_and_deploy(starknet, "set_nft.cairo")
    [attributes_registry_contract, _] = await declare_and_deploy(starknet, "attributes_registry.cairo")
    await set_contract.setBriqAddress_(briq_contract.contract_address).execute()
    await set_contract.setAttributesRegistryAddress_(attributes_registry_contract.contract_address).execute()
    await briq_contract.setSetAddress_(set_contract.contract_address).execute()
    await attributes_registry_contract.setSetAddress_(set_contract.contract_address).execute()
    await briq_contract.mintFT_(ADDRESS, 0x1, 100).execute()
    return [starknet, set_contract, briq_contract, attributes_registry_contract]


def copy_contract(state, contract):
    return StarknetContract(
        state=state.state,
        abi=contract.abi,
        contract_address=contract.contract_address,
        deploy_call_info=contract.deploy_call_info,
    )

@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, set_contract, briq_contract, attributes_registry_contract] = factory_root
    state = Starknet(state=starknet.state.copy())
    return namedtuple('State', ['starknet', 'set_contract', 'briq_contract', 'attributes_registry_contract'])(
        starknet=state,
        set_contract=copy_contract(state, set_contract),
        briq_contract=copy_contract(state, briq_contract),
        attributes_registry_contract=copy_contract(state, attributes_registry_contract),
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
    ATTRIBUTES_REGISTRY_TOKEN_ID = 1234
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("// DEFINE_SHAPE", f"""
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

    await state.attributes_registry_contract.mint_(ADDRESS, ATTRIBUTES_REGISTRY_TOKEN_ID, shape_contract.contract_address).execute(ADDRESS)

    tx_info = await state.set_contract.assemble_with_attributes_registry_(
        owner=ADDRESS,
        token_id_hint=TOKEN_HINT,
        uri=TOKEN_URI,
        fts=[(0x1, 100)],
        nfts=[],
        attributes_registry_token_id=ATTRIBUTES_REGISTRY_TOKEN_ID,
        shape=[compress_shape_item('#ffaaff', 0x1, i, 0, 2, False) for i in range(100)],
    ).execute(ADDRESS)
    report_performance(tx_info)


@pytest.mark.asyncio
async def test_performance_less_optimal(factory):
    state = factory
    await state.briq_contract.mintFT_(ADDRESS, 0x2, 100).execute()
    TOKEN_HINT = 1234
    TOKEN_URI = [1234]
    ATTRIBUTES_REGISTRY_TOKEN_ID = 1234
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("// DEFINE_SHAPE", f"""
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

    await state.attributes_registry_contract.mint_(ADDRESS, ATTRIBUTES_REGISTRY_TOKEN_ID, shape_contract.contract_address).execute(ADDRESS)

    tx_info = await state.set_contract.assemble_with_attributes_registry_(
        owner=ADDRESS,
        token_id_hint=TOKEN_HINT,
        uri=TOKEN_URI,
        fts=[(0x1, 80), (0x2, 20)],
        nfts=[],
        attributes_registry_token_id=ATTRIBUTES_REGISTRY_TOKEN_ID,
        shape=[compress_shape_item('#ffaaff', 0x1, 0, i, 2, False) for i in range(80)] + [
            compress_shape_item('#ffaaff', 0x2, 1, i, 2, False) for i in range(20)
        ],
    ).execute(ADDRESS)
    report_performance(tx_info)

@pytest.mark.asyncio
async def test_performance_bad(factory):
    state = factory
    await state.briq_contract.mintFT_(ADDRESS, 0x2, 10).execute()
    await state.briq_contract.mintFT_(ADDRESS, 0x3, 10).execute()
    await state.briq_contract.mintFT_(ADDRESS, 0x4, 10).execute()
    await state.briq_contract.mintFT_(ADDRESS, 0x5, 10).execute()
    await state.briq_contract.mintFT_(ADDRESS, 0x6, 10).execute()
    await state.briq_contract.mintFT_(ADDRESS, 0x7, 10).execute()
    await state.briq_contract.mintFT_(ADDRESS, 0x8, 10).execute()
    await state.briq_contract.mintFT_(ADDRESS, 0x9, 10).execute()
    await state.briq_contract.mintFT_(ADDRESS, 0xA, 10).execute()
    TOKEN_HINT = 1234
    TOKEN_URI = [1234]
    ATTRIBUTES_REGISTRY_TOKEN_ID = 1234
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    data = data.replace("// DEFINE_SHAPE", f"""
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

    await state.attributes_registry_contract.mint_(ADDRESS, ATTRIBUTES_REGISTRY_TOKEN_ID, shape_contract.contract_address).execute(ADDRESS)

    tx_info = await state.set_contract.assemble_with_attributes_registry_(
        owner=ADDRESS,
        token_id_hint=TOKEN_HINT,
        uri=TOKEN_URI,
        fts=[(i + 1, 10) for i in range(10)],
        nfts=[],
        attributes_registry_token_id=ATTRIBUTES_REGISTRY_TOKEN_ID,
        shape=[
            compress_shape_item('#ffaaff', j+1, j, i, 2, False) for j in range(10) for i in range(10)
        ],
    ).execute(ADDRESS)
    report_performance(tx_info)
