import os
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException

from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.public.abi import get_selector_from_name

from .briq_backend_test import compiled_briq, briq_backend
from .set_backend_test import compiled_set, set_backend

CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")


def compile(path):
    return compile_starknet_files(
        files=[os.path.join(CONTRACT_SRC, path)],
        debug_info=True
    )

@pytest.fixture(scope="session")
def compiled_set_proxy():
    return compile("backend_set_proxy.cairo")


@pytest_asyncio.fixture
async def starknet():
    # Create a new Starknet class that simulates the StarkNet
    return await Starknet.empty()


@pytest.mark.asyncio
async def test_call(starknet, compiled_set_proxy, compiled_set):
    proxy = await starknet.deploy(contract_def=compiled_set_proxy, constructor_calldata=[0x123456])
    set_backend = await starknet.deploy(contract_def=compiled_set, constructor_calldata=[proxy.contract_address])
    await proxy.setImplementation(set_backend.contract_address).invoke()

    await starknet.state.invoke_raw(contract_address=proxy.contract_address,
        selector=get_selector_from_name("assemble"),
        calldata=[0x11, 0x1, 0, 0],
        caller_address=0x123456,
    )
    with pytest.raises(StarkException):
        await starknet.state.invoke_raw(contract_address=proxy.contract_address,
            selector=get_selector_from_name("assemble"),
            calldata=[0x12, 0x2, 0, 0],
            caller_address=0xcafe,
        )
