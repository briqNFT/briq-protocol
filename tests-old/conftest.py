import asyncio
import os
import pytest
import pytest_asyncio
from typing import Any

from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.testing.starknet import StarknetContract
from starkware.cairo.common.hash_state import compute_hash_on_elements

from briq_protocol.generate_shape import generate_shape_code


CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")
VENDOR_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts", "vendor")


@pytest.fixture(scope="session")
def event_loop():
    return asyncio.get_event_loop()


def compile(path):
    return compile_starknet_files(
        files=[os.path.join(CONTRACT_SRC, path)],
        cairo_path=[CONTRACT_SRC, VENDOR_SRC],
        debug_info=True,
        disable_hint_validation=True
    )

async def declare(starknet, contract) -> str:
    code = compile(contract)
    return (await starknet.declare(contract_class=code)).class_hash

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

def proxy_contract(state, contract):
    return StarknetContract(
        state=state.state,
        abi=contract.abi,
        contract_address=contract.contract_address,
        deploy_call_info=contract.deploy_call_info,
    )

@pytest_asyncio.fixture
async def deploy_clean_shapes(tmp_path_factory):
    async def __(starknet, shapes, offset = 1):
        folder = tmp_path_factory.mktemp('data')
        (folder / 'contracts' / 'shape').mkdir(parents=True, exist_ok=True)
        open(folder / 'contracts' / 'shape' / 'data.cairo', "w").write(
            generate_shape_code(shapes, offset)
        )
        shape_code = compile_starknet_files(files=[os.path.join(CONTRACT_SRC, 'shape/shape_store.cairo')], disable_hint_validation=True, debug_info=True, cairo_path=[str(folder)])
        return [await starknet.declare(contract_class=shape_code), await starknet.deploy(contract_class=shape_code)]
    return __

# For testing, generate a shape contract with some random other things thrown in
# The interesting data is at offset 3 (2 + index_start of 1)
@pytest_asyncio.fixture
def deploy_shape(deploy_clean_shapes):
    async def __(starknet, items, nfts=[]):
        return await deploy_clean_shapes(starknet, [
                ([
                    ('#ffaaff', 1, 1, 2, 3, True),
                    ('#ffaaff', 1, 1, 2, 4, True),
                ], [
                    1 * 2 ** 64 + 1,
                    2 * 2 ** 64 + 1
                ]),
                ([
                    ('#ffaaff', 1, 1, 2, 3),
                ], []),
                (items, nfts),
                ([
                    ('#ffaaff', 1, 1, 2, 3),
                ], [])
            ]
        )
    return __
