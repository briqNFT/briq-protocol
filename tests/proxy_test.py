import os
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException

from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.public.abi import get_selector_from_name
from starkware.cairo.common.hash_state import compute_hash_on_elements

from .briq_backend_test import compiled_briq, briq_backend, invoke_briq
from .set_backend_test import hash_token_id, compiled_set

CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")


def compile(path):
    return compile_starknet_files(
        files=[os.path.join(CONTRACT_SRC, path)],
        debug_info=True
    )

@pytest.fixture(scope="session")
def compiled_set_proxy():
    return compile("proxy_set_backend.cairo")


@pytest_asyncio.fixture
async def starknet():
    # Create a new Starknet class that simulates the StarkNet
    return await Starknet.empty()


@pytest.mark.asyncio
async def test_call(starknet, briq_backend, compiled_set_proxy, compiled_set):
    await invoke_briq(briq_backend.mintFT(owner=0x11, material=1, qty=50))
    proxy = await starknet.deploy(contract_def=compiled_set_proxy, constructor_calldata=[0x123456])
    set_backend = await starknet.deploy(contract_def=compiled_set, constructor_calldata=[proxy.contract_address])
    await proxy.setImplementation(set_backend.contract_address).invoke(caller_address=ADMIN)
    await proxy.setBriqBackendAddress(briq_backend.contract_address).invoke(caller_address=ADMIN)
    await invoke_briq(briq_backend.setSetBackendAddress(set_backend.contract_address))

    await starknet.state.invoke_raw(contract_address=proxy.contract_address,
        selector=get_selector_from_name("assemble"),
        calldata=[0x11, 0x1, 1, 1, 5, 0, 1, 0xcafe],
        caller_address=0x11,
    )
    with pytest.raises(StarkException):
        await starknet.state.invoke_raw(contract_address=proxy.contract_address,
            selector=get_selector_from_name("assemble"),
            calldata=[0x12, 0x2, 1, 1, 5, 0, 0xfade],
            caller_address=0xcafe,
        )

ADMIN = 0x123456

@pytest.mark.asyncio
async def test_transfer_approval(starknet, briq_backend, compiled_set_proxy, compiled_set):
    await invoke_briq(briq_backend.mintFT(owner=0x11, material=1, qty=50))
    proxy = await starknet.deploy(contract_def=compiled_set_proxy, constructor_calldata=[ADMIN])
    set_backend = await starknet.deploy(contract_def=compiled_set, constructor_calldata=[proxy.contract_address])
    await proxy.setImplementation(set_backend.contract_address).invoke(caller_address=ADMIN)
    await proxy.setBriqBackendAddress(briq_backend.contract_address).invoke(caller_address=ADMIN)
    await invoke_briq(briq_backend.setSetBackendAddress(set_backend.contract_address))

    tok_id_1 = hash_token_id(0x11, 1, [0xcafe])

    await starknet.state.invoke_raw(contract_address=proxy.contract_address,
        selector=get_selector_from_name("assemble"),
        calldata=[0x11, 0x1, 1, 1, 5, 0, 1, 0xcafe],
        caller_address=0x11,
    )

    #assert(await starknet.state.invoke_raw(contract_address=proxy.contract_address,
    #    selector=get_selector_from_name("ownerOf"),
    #    calldata=[tok_id_1],
    #    caller_address=0x57384,
    #)).result.owner == 0x11

    await starknet.state.invoke_raw(contract_address=proxy.contract_address,
        selector=get_selector_from_name("transferOneNFT"),
        calldata=[0x11, 0x12, tok_id_1],
        caller_address=0x11,
    )

    with pytest.raises(StarkException):
        await starknet.state.invoke_raw(contract_address=proxy.contract_address,
            selector=get_selector_from_name("transferOneNFT"),
            calldata=[0x12, 0x11, tok_id_1],
            caller_address=0x11,
        )

    await starknet.state.invoke_raw(contract_address=proxy.contract_address,
        selector=get_selector_from_name("approve"),
        calldata=[0x11, tok_id_1],
        caller_address=0x12,
    )

    await starknet.state.invoke_raw(contract_address=proxy.contract_address,
        selector=get_selector_from_name("transferOneNFT"),
        calldata=[0x12, 0x11, tok_id_1],
        caller_address=0x11,
    )

    # TODO check approve status

    with pytest.raises(StarkException):
        await starknet.state.invoke_raw(contract_address=proxy.contract_address,
            selector=get_selector_from_name("transferOneNFT"),
            calldata=[0x11, 0x12, tok_id_1],
            caller_address=0x12,
        )

    await starknet.state.invoke_raw(contract_address=proxy.contract_address,
        selector=get_selector_from_name("setApprovalForAll"),
        calldata=[0x12, 1],
        caller_address=0x11,
    )

    # Now transfer goes through, approved as operator
    await starknet.state.invoke_raw(contract_address=proxy.contract_address,
        selector=get_selector_from_name("transferOneNFT"),
        calldata=[0x11, 0x12, tok_id_1],
        caller_address=0x12,
    )

    # authorization was burned, this fails.
    with pytest.raises(StarkException):
        await starknet.state.invoke_raw(contract_address=proxy.contract_address,
            selector=get_selector_from_name("transferOneNFT"),
            calldata=[0x12, 0x11, tok_id_1],
            caller_address=0x11,
        )
