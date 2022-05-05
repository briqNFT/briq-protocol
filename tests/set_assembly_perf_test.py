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
    await invoke_briq(briq_contract.mintFT(owner=ADDRESS, material=1, qty=50))
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

@pytest.mark.asyncio
async def test_performance_long(set_contract):
    ex_info: StarknetTransactionExecutionInfo = await set_contract.assemble_with_shape_long_(owner=ADDRESS, token_id_hint=0x1,
        fts=[(1, 50)], nfts=[], shape=[set_contract.LongShapeItem(*compress_long_shape_item(color="#ffaaff", material=1, x=i, y=4, z=-2)) for i in range(50)], target_shape_token_id=0, uri=[1234]).invoke(ADDRESS)
    print("Steps:", ex_info.call_info.execution_resources.n_steps * 0.05)
    print("Bitwise",ex_info.call_info.execution_resources.builtin_instance_counter['bitwise_builtin'] * 12.8)


@pytest.mark.asyncio
async def test_performance(set_contract):
    ex_info: StarknetTransactionExecutionInfo = await set_contract.assemble_with_shape_(owner=ADDRESS, token_id_hint=0x1,
        fts=[(1, 50)], nfts=[], shape=[set_contract.ShapeItem(*compress_shape_item(color="#ffaaff", material=1, x=i, y=4, z=-2)) for i in range(50)], target_shape_token_id=0, uri=[1234]).invoke(ADDRESS)
    print("Steps:", ex_info.call_info.execution_resources.n_steps * 0.05)
    print("Bitwise",ex_info.call_info.execution_resources.builtin_instance_counter['bitwise_builtin'] * 12.8)
