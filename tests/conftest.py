import asyncio
import os
import pytest
from typing import Any

from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.testing.starknet import StarknetContract
from starkware.cairo.common.hash_state import compute_hash_on_elements

CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")


@pytest.fixture(scope="session")
def event_loop():
    return asyncio.get_event_loop()


def compile(path):
    return compile_starknet_files(
        files=[os.path.join(CONTRACT_SRC, path)],
        debug_info=True,
        disable_hint_validation=True
    )

async def declare_and_deploy(starknet, contract, constructor_calldata=[]) -> tuple[StarknetContract, Any]:
    code = compile(contract)
    class_hash = await starknet.declare(contract_class=code)
    return (await starknet.deploy(contract_class=code, constructor_calldata=constructor_calldata), class_hash)


async def declare_and_deploy_proxied(starknet, compiled_proxy, contract, admin) -> tuple[StarknetContract, Any]:
    code = compile(contract)
    class_data = await starknet.declare(contract_class=code)
    proxy = await starknet.deploy(contract_class=compiled_proxy, constructor_calldata=[admin, class_data.class_hash])
    return (proxy.replace_abi(class_data.abi), class_data)


def hash_token_id(owner: int, hint: int, uri):
    raw_tid = compute_hash_on_elements([owner, hint]) & ((2**251 - 1) - (2**59 - 1))
    if len(uri) == 2 and uri[1] < 2**59:
        raw_tid += uri[1]
    return raw_tid
