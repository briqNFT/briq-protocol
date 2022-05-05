import os
from typing import Tuple
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.starknet import StarknetContract
from starkware.starkware_utils.error_handling import StarkException
from starkware.cairo.common.hash_state import compute_hash_on_elements

from starkware.starknet.compiler.compile import compile_starknet_files, compile_starknet_codes

from .briq_impl_test import FAKE_BRIQ_PROXY_ADDRESS, compiled_briq, invoke_briq

import asyncio
@pytest.fixture(scope="session")
def event_loop():
    return asyncio.get_event_loop()


CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")

FAKE_SET_PROXY_ADDRESS = 0xcafefade
ADMIN = 0x0  # No proxy so no admin
ADDRESS = 0x123456
OTHER_ADDRESS = 0x654321
THIRD_ADDRESS = 0x551155

def compile(path):
    return compile_starknet_files(
        files=[os.path.join(CONTRACT_SRC, path)],
        debug_info=True,
        disable_hint_validation=True
    )

@pytest.fixture(scope="session")
def compiled_set():
    return compile("set_interface.cairo")


@pytest_asyncio.fixture(scope="session")
async def factory_root(compiled_set, compiled_briq):
    starknet = await Starknet.empty()
    set_contract = await starknet.deploy(contract_def=compiled_set)
    briq_contract = await starknet.deploy(contract_def=compiled_briq)
    await set_contract.setBriqAddress_(address=briq_contract.contract_address).invoke(caller_address=ADMIN)
    await briq_contract.setSetAddress_(address=set_contract.contract_address).invoke(caller_address=ADMIN)
    await invoke_briq(briq_contract.mintFT(owner=ADDRESS, material=1, qty=100))
    return (starknet, set_contract, briq_contract)

@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, sc, bc] = factory_root
    state = Starknet(state=starknet.state.copy())
    return (state, sc, bc)

@pytest_asyncio.fixture
async def set_contract(factory: Tuple[Starknet, StarknetContract, StarknetContract]):
    [starknet, sc, bc] = factory
    return StarknetContract(
        state=starknet.state,
        abi=sc.abi,
        contract_address=sc.contract_address,
        deploy_execution_info=sc.deploy_execution_info,
    )

@pytest_asyncio.fixture
async def briq_contract(factory: Tuple[Starknet, StarknetContract, StarknetContract]):
    [starknet, sc, bc] = factory
    return StarknetContract(
        state=starknet.state,
        abi=bc.abi,
        contract_address=bc.contract_address,
        deploy_execution_info=bc.deploy_execution_info,
    )


@pytest_asyncio.fixture
async def starknet(factory: Tuple[Starknet, StarknetContract, StarknetContract]):
    [starknet, sc, bc] = factory
    return starknet

def invoke_set(call, addr=ADDRESS):
    return call.invoke(caller_address=addr)

def hash_token_id(owner: int, hint: int, uri):
    raw_tid = compute_hash_on_elements([owner, hint]) & ((2**251 - 1) - (2**59 - 1))
    if len(uri) == 2 and uri[1] < 2**59:
        raw_tid += uri[1]
    return raw_tid

from generators.shape_utils import compress_shape_item, compress_long_shape_item
from starkware.starknet.testing.objects import StarknetTransactionExecutionInfo

def report_performance(exc_info: StarknetTransactionExecutionInfo):
    gas_cost = exc_info.call_info.execution_resources
    print(gas_cost)
    print("Reminder: the gas cost is the maximum")
    print("Steps: ", gas_cost.n_steps, " gas cost: ", gas_cost.n_steps * 0.05)
    print("Range: ", gas_cost.builtin_instance_counter['range_check_builtin'], " gas cost: ", gas_cost.builtin_instance_counter['range_check_builtin'] * 0.4)
    print("Bitwise: ", gas_cost.builtin_instance_counter['bitwise_builtin'], " gas cost: ", gas_cost.builtin_instance_counter['bitwise_builtin'] * 12.8)

def shapeItem(set_contract, i, material):
    return set_contract.ShapeItem(*compress_shape_item(color="#ffaaff", material=material, x=i, y=4, z=-2))

# The purpose of this test is to compare the L2 gas costs
# On some simple shape-checking operations of 80 briqs. The material layout is different, resulting in different gas costs.
# In the current setup, gas costs are capped by bitwise comparisons (O(n) in # of briqs) for few materials,
# but with enough materials, the steps start to dominate because of the counter-incrementing logic.
# It's actually fairly well-balanced, so nice.

@pytest.mark.asyncio
async def test_performance_optimal(set_contract):
    ex_info = await set_contract.assemble_with_shape_(owner=ADDRESS, token_id_hint=0x1,
        fts=[(1, 80)], nfts=[], shape=[shapeItem(set_contract, i, material=1) for i in range(80)],
        target_shape_token_id=0, uri=[1234]).invoke(ADDRESS)
    report_performance(ex_info)

@pytest.mark.asyncio
async def test_performance_less_optimal(briq_contract, set_contract):
    await briq_contract.mintFT(ADDRESS, 2, 50).invoke()
    ex_info = await set_contract.assemble_with_shape_(owner=ADDRESS, token_id_hint=0x1,
        fts=[(1, 65), (2, 15)], nfts=[], shape=[shapeItem(set_contract, i, material=1) for i in range(65)
            ] + [shapeItem(set_contract, i + 51, material=2) for i in range(15)],
        target_shape_token_id=0, uri=[1234]).invoke(ADDRESS)
    report_performance(ex_info)


@pytest.mark.asyncio
async def test_performance_bad_case(briq_contract, set_contract):
    await briq_contract.mintFT(ADDRESS, 2, 50).invoke()
    await briq_contract.mintFT(ADDRESS, 3, 50).invoke()
    await briq_contract.mintFT(ADDRESS, 4, 50).invoke()
    await briq_contract.mintFT(ADDRESS, 5, 50).invoke()
    await briq_contract.mintFT(ADDRESS, 6, 50).invoke()
    await briq_contract.mintFT(ADDRESS, 7, 50).invoke()
    await briq_contract.mintFT(ADDRESS, 8, 50).invoke()
    ex_info = await set_contract.assemble_with_shape_(owner=ADDRESS, token_id_hint=0x1,
        fts=[(1, 10), (2, 10), (3, 10), (4, 10), (5, 10), (6, 10), (7, 10), (8, 10)], nfts=[], shape=[
            shapeItem(set_contract, i, material=1) for i in range(10)
            ] + [shapeItem(set_contract, i + 21, material=2) for i in range(10)
            ] + [shapeItem(set_contract, i + 41, material=3) for i in range(10)
            ] + [shapeItem(set_contract, i + 61, material=4) for i in range(10)
            ] + [shapeItem(set_contract, i + 81, material=5) for i in range(10)
            ] + [shapeItem(set_contract, i + 101, material=6) for i in range(10)
            ] + [shapeItem(set_contract, i + 121, material=7) for i in range(10)
            ] + [shapeItem(set_contract, i + 141, material=8) for i in range(10)
            ],
        target_shape_token_id=0, uri=[1234]).invoke(ADDRESS)
    report_performance(ex_info)
