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

MOCK_SHAPE_TOKEN=555

def compile(path):
    return compile_starknet_files(
        files=[os.path.join(CONTRACT_SRC, path)],
        debug_info=True,
        disable_hint_validation=True
    )

@pytest.fixture(scope="session")
def compiled_set():
    return compile("set_impl.cairo")


@pytest.fixture(scope="session")
def compiled_box():
    return compile("box.cairo")


@pytest_asyncio.fixture(scope="session")
async def factory_root(compiled_set, compiled_briq, compiled_box):
    starknet = await Starknet.empty()
    set_contract = await starknet.deploy(contract_def=compiled_set)
    briq_contract = await starknet.deploy(contract_def=compiled_briq)
    box_contract = await starknet.deploy(contract_def=compiled_box)
    await set_contract.setBriqAddress_(address=briq_contract.contract_address).invoke(caller_address=ADMIN)
    await briq_contract.setSetAddress_(address=set_contract.contract_address).invoke(caller_address=ADMIN)
    await invoke_briq(briq_contract.mintFT(owner=ADDRESS, material=1, qty=100))
    await box_contract.setSetAddress_(address=set_contract.contract_address).invoke(caller_address=ADMIN)

    shape_mock = await starknet.deploy(contract_def=compile("mocks/shape_mock.cairo"))
    await box_contract.mint_(MOCK_SHAPE_TOKEN, MOCK_SHAPE_TOKEN, shape_mock.contract_address).invoke()
    return (starknet, set_contract, briq_contract, box_contract)

@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, sc, bc, box] = factory_root
    state = Starknet(state=starknet.state.copy())
    sc = StarknetContract(
        state=state.state,
        abi=sc.abi,
        contract_address=sc.contract_address,
        deploy_execution_info=sc.deploy_execution_info,
    )
    bc = StarknetContract(
        state=state.state,
        abi=bc.abi,
        contract_address=bc.contract_address,
        deploy_execution_info=bc.deploy_execution_info,
    )
    box = StarknetContract(
        state=state.state,
        abi=box.abi,
        contract_address=box.contract_address,
        deploy_execution_info=box.deploy_execution_info,
    )
    return (state, sc, bc, box)

@pytest_asyncio.fixture
async def set_contract(factory):
    [starknet, sc, _, _] = factory
    return sc

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

def shapeItem(contract, i, material):
    return contract.ShapeItem(*compress_shape_item(color="#ffaaff", material=material, x=i, y=4, z=-2))

# The purpose of this test is to compare the L2 gas costs
# On some simple shape-checking operations of 80 briqs. The material layout is different, resulting in different gas costs.
# In the current setup, gas costs are capped by bitwise comparisons (O(n) in # of briqs) for few materials,
# but with enough materials, the steps start to dominate because of the counter-incrementing logic.
# It's actually fairly well-balanced, so nice.

@pytest.mark.asyncio
async def test_performance_optimal(set_contract: StarknetContract, factory):
    [_, _, _, box] = factory
    call = set_contract.assemble_(owner=ADDRESS, token_id_hint=0x1,
        fts=[(1, 80)], nfts=[], uri=[1234])
    call.name = 'assemble_and_proxy_'
    call.calldata += [box.contract_address, get_selector_from_name("on_set_assembly_")]
    shape_data = [compress_shape_item(color="#ffaaff", material=1, x=i, y=4, z=-2) for i in range(80)]
    call.calldata += [len(shape_data)] + [z for shape_item in shape_data for z in shape_item]
    call.calldata += [MOCK_SHAPE_TOKEN]
    ex_info = await call.invoke(ADDRESS)
    report_performance(ex_info)

@pytest.mark.asyncio
async def test_performance_less_optimal(set_contract: StarknetContract, factory):
    [_, _, briq_contract, box] = factory
    await briq_contract.mintFT(ADDRESS, 2, 50).invoke()
    call = set_contract.assemble_(owner=ADDRESS, token_id_hint=0x1,
        fts=[(1, 65), (2, 15)], nfts=[], uri=[1234])
    call.name = 'assemble_and_proxy_'
    call.calldata += [box.contract_address, get_selector_from_name("on_set_assembly_")]
    shape_data = [compress_shape_item(color="#ffaaff", material=1, x=i, y=4, z=-2) for i in range(65)
        ] + [compress_shape_item(color="#ffaaff", material=2, x=i, y=4, z=0) for i in range(15)]
    call.calldata += [len(shape_data)] + [z for shape_item in shape_data for z in shape_item]
    call.calldata += [MOCK_SHAPE_TOKEN]
    ex_info = await call.invoke(ADDRESS)
    report_performance(ex_info)


@pytest.mark.asyncio
async def test_performance_bad_case(set_contract: StarknetContract, factory):
    [_, _, briq_contract, box] = factory
    await briq_contract.mintFT(ADDRESS, 2, 50).invoke()
    await briq_contract.mintFT(ADDRESS, 3, 50).invoke()
    await briq_contract.mintFT(ADDRESS, 4, 50).invoke()
    await briq_contract.mintFT(ADDRESS, 5, 50).invoke()
    await briq_contract.mintFT(ADDRESS, 6, 50).invoke()
    await briq_contract.mintFT(ADDRESS, 7, 50).invoke()
    await briq_contract.mintFT(ADDRESS, 8, 50).invoke()
    call = set_contract.assemble_(owner=ADDRESS, token_id_hint=0x1,
        fts=[(1, 10), (2, 10), (3, 10), (4, 10), (5, 10), (6, 10), (7, 10), (8, 10)], nfts=[], uri=[1234])
    call.name = 'assemble_and_proxy_'
    call.calldata += [box.contract_address, get_selector_from_name("on_set_assembly_")]
    shape_data = [
        compress_shape_item(color="#ffaaff", material=1, x=i, y=4, z=-2) for i in range(10)] + [
        compress_shape_item(color="#ffaaff", material=2, x=i, y=4, z=-1) for i in range(10)] + [
        compress_shape_item(color="#ffaaff", material=3, x=i, y=4, z=0) for i in range(10)] + [
        compress_shape_item(color="#ffaaff", material=4, x=i, y=4, z=1) for i in range(10)] + [
        compress_shape_item(color="#ffaaff", material=5, x=i, y=4, z=2) for i in range(10)] + [
        compress_shape_item(color="#ffaaff", material=6, x=i, y=4, z=3) for i in range(10)] + [
        compress_shape_item(color="#ffaaff", material=7, x=i, y=4, z=4) for i in range(10)] + [
        compress_shape_item(color="#ffaaff", material=8, x=i, y=4, z=5) for i in range(10)]
    call.calldata += [len(shape_data)] + [z for shape_item in shape_data for z in shape_item]
    call.calldata += [MOCK_SHAPE_TOKEN]
    ex_info = await call.invoke(ADDRESS)
    report_performance(ex_info)
