import os
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.testing.starknet import StarknetContract

from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.public.abi import get_selector_from_name
from starkware.cairo.common.hash_state import compute_hash_on_elements

from .briq_impl_test import compiled_briq, invoke_briq
from .set_impl_test import hash_token_id, compiled_set

CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")
ADMIN = 0x123456
OTHER_ADDRESS = 0x654321

def compile(path):
    return compile_starknet_files(
        files=[os.path.join(CONTRACT_SRC, path)],
        debug_info=True
    )

import asyncio
@pytest.fixture(scope="session")
def event_loop():
    return asyncio.get_event_loop()


@pytest.fixture(scope="session")
def compiled_proxy():
    return compile("upgrades/proxy.cairo")

@pytest_asyncio.fixture(scope="module")
async def setup_proxies_initial(compiled_proxy, compiled_briq, compiled_set):
    starknet = await Starknet.empty()

    briq_impl = await starknet.deploy(contract_def=compiled_briq)
    set_impl = await starknet.deploy(contract_def=compiled_set)
    briq_proxy = await starknet.deploy(contract_def=compiled_proxy, constructor_calldata=[ADMIN, briq_impl.contract_address])
    set_proxy = await starknet.deploy(contract_def=compiled_proxy, constructor_calldata=[ADMIN, set_impl.contract_address])

    briq_proxy = briq_proxy.replace_abi(briq_impl.abi)
    set_proxy = set_proxy.replace_abi(set_impl.abi)

    box_mock = await starknet.deploy(contract_def=compile_starknet_files(files=[os.path.join(CONTRACT_SRC, "mocks/box_mock.cairo")]))

    await set_proxy.setBriqAddress_(briq_proxy.contract_address).invoke(ADMIN)
    await set_proxy.setBoxAddress_(box_mock.contract_address).invoke(ADMIN)
    await briq_proxy.setSetAddress_(set_proxy.contract_address).invoke(ADMIN)

    return starknet, briq_proxy, set_proxy

@pytest_asyncio.fixture
async def setup_proxies(setup_proxies_initial):
    [starknet, briq_proxy, set_proxy] = setup_proxies_initial
    starknet = Starknet(starknet.state.copy())
    briq_proxy = StarknetContract(
        state=starknet.state,
        abi=briq_proxy.abi,
        contract_address=briq_proxy.contract_address,
        deploy_execution_info=briq_proxy.deploy_execution_info,
    )
    set_proxy = StarknetContract(
        state=starknet.state,
        abi=set_proxy.abi,
        contract_address=set_proxy.contract_address,
        deploy_execution_info=set_proxy.deploy_execution_info,
    )
    return starknet, briq_proxy, set_proxy

@pytest.mark.asyncio
async def test_admin_failure_mode(setup_proxies):
    [starknet, briq_proxy, set_proxy] = setup_proxies

    assert (await briq_proxy.getAdmin_().call()).result.admin == ADMIN
    assert (await set_proxy.getAdmin_().call()).result.admin == ADMIN

    await briq_proxy.upgradeImplementation_(0xcafe).invoke(ADMIN)
    await set_proxy.upgradeImplementation_(0xcafe).invoke(ADMIN)

    # The new interface doesn't exist, everything dails.
    with pytest.raises(StarkException):
        assert (await briq_proxy.getImplementation_().call()).result.implementation == 0xcafe
    with pytest.raises(StarkException):
        assert (await set_proxy.getImplementation_().call()).result.implementation == 0xcafe

@pytest.mark.asyncio
async def test_admin(setup_proxies):
    [starknet, briq_proxy, set_proxy] = setup_proxies

    assert (await briq_proxy.getAdmin_().call()).result.admin == ADMIN
    assert (await set_proxy.getAdmin_().call()).result.admin == ADMIN

    await briq_proxy.setRootAdmin_(0xdead).invoke(ADMIN)
    await set_proxy.setRootAdmin_(0xdead).invoke(ADMIN)

    assert (await briq_proxy.getAdmin_().call()).result.admin == 0xdead
    assert (await set_proxy.getAdmin_().call()).result.admin == 0xdead

    with pytest.raises(StarkException):
        await briq_proxy.upgradeImplementation_(0xcafe).invoke(ADMIN)
    with pytest.raises(StarkException):
        await set_proxy.upgradeImplementation_(0xcafe).invoke(ADMIN)

    await briq_proxy.upgradeImplementation_(0xcafe).invoke(0xdead)
    await set_proxy.upgradeImplementation_(0xcafe).invoke(0xdead)


@pytest.mark.asyncio
async def test_call(setup_proxies):
    [starknet, briq_proxy, set_proxy] = setup_proxies

    await briq_proxy.mintFT(ADMIN, 1, 50).invoke(ADMIN)
    await set_proxy.assemble_(ADMIN, token_id_hint=0x1, fts=[(1, 5)], nfts=[], uri=[0xcafe]).invoke(ADMIN)
    with pytest.raises(StarkException):
        await set_proxy.assemble_(0x12, 0x2, [(1, 5)], [], [0xfade]).invoke(0xcafe)

@pytest.fixture(scope="session")
def compiled_mint():
    return compile("mint.cairo")


@pytest.mark.asyncio
async def test_mint(compiled_mint, compiled_proxy, setup_proxies):
    [starknet, briq_proxy, set_proxy] = setup_proxies

    mint = await starknet.deploy(contract_def=compiled_mint, constructor_calldata=[briq_proxy.contract_address, 100])

    await starknet.state.invoke_raw(contract_address=briq_proxy.contract_address,
        selector=get_selector_from_name("setMintContract_"),
        calldata=[mint.contract_address],
        caller_address=ADMIN,
        max_fee=0,
    )

    await starknet.state.invoke_raw(contract_address=mint.contract_address,
        selector=get_selector_from_name("mint"),
        calldata=[0xcafe],
        caller_address=0xcafe,
        max_fee=0,
    )

    with pytest.raises(StarkException):
        await starknet.state.invoke_raw(contract_address=mint.contract_address,
            selector=get_selector_from_name("mint"),
            calldata=[0xfade],
            caller_address=0xdead,
            max_fee=0,
        )


@pytest.mark.asyncio
async def test_redo_implementation(setup_proxies):
    [starknet, briq_proxy, set_proxy] = setup_proxies

    await starknet.state.invoke_raw(contract_address=briq_proxy.contract_address,
        selector=get_selector_from_name("mintFT"),
        calldata=[ADMIN, 1, 50],
        caller_address=ADMIN,
        max_fee=0,
    )

    await starknet.state.invoke_raw(contract_address=set_proxy.contract_address,
        selector=get_selector_from_name("assemble"),
        calldata=[ADMIN, 0x1, 1, 1, 5, 0, 1, 0xcafe],
        caller_address=ADMIN,
        max_fee=0,
    )

    bimp = (await briq_proxy.getImplementation_().call()).result.implementation
    simp = (await set_proxy.getImplementation_().call()).result.implementation

    await briq_proxy.upgradeImplementation_(simp).invoke(ADMIN)
    await set_proxy.upgradeImplementation_(bimp).invoke(ADMIN)

    with pytest.raises(StarkException):
        await starknet.state.invoke_raw(contract_address=set_proxy.contract_address,
            selector=get_selector_from_name("disassemble"),
            calldata=[ADMIN, 0x1, 1, 1, 5, 0],
            caller_address=0xdead,
            max_fee=0,
        )

    await briq_proxy.upgradeImplementation_(bimp).invoke(ADMIN)
    await set_proxy.upgradeImplementation_(simp).invoke(ADMIN)

    tok_id = hash_token_id(ADMIN, 1, uri=[0xcafe])
    await starknet.state.invoke_raw(contract_address=set_proxy.contract_address,
        selector=get_selector_from_name("disassemble"),
        calldata=[ADMIN, tok_id, 1, 1, 5, 0],
        caller_address=ADMIN,
        max_fee=0,
    )


@pytest.mark.asyncio
async def test_transfer_approval(setup_proxies):
    [starknet, briq_proxy, set_proxy] = setup_proxies

    await starknet.state.invoke_raw(contract_address=briq_proxy.contract_address,
        selector=get_selector_from_name("mintFT"),
        calldata=[ADMIN, 1, 50],
        caller_address=ADMIN,
        max_fee=0,
    )

    tok_id_1 = hash_token_id(ADMIN, 1, [0xcafe])

    await starknet.state.invoke_raw(contract_address=set_proxy.contract_address,
        selector=get_selector_from_name("assemble"),
        calldata=[ADMIN, 0x1, 1, 1, 5, 0, 1, 0xcafe],
        caller_address=ADMIN,
        max_fee=0,
    )

    #assert(await starknet.state.invoke_raw(contract_address=set_proxy.contract_address,
    #    selector=get_selector_from_name("ownerOf"),
    #    calldata=[tok_id_1],
    #    caller_address=0x57384,
    #)).result.owner == ADMIN

    await starknet.state.invoke_raw(contract_address=set_proxy.contract_address,
        selector=get_selector_from_name("transferOneNFT"),
        calldata=[ADMIN, OTHER_ADDRESS, tok_id_1],
        caller_address=ADMIN,
        max_fee=0,
    )

    with pytest.raises(StarkException):
        await starknet.state.invoke_raw(contract_address=set_proxy.contract_address,
            selector=get_selector_from_name("transferOneNFT"),
            calldata=[OTHER_ADDRESS, ADMIN, tok_id_1],
            caller_address=ADMIN,
            max_fee=0,
        )

    await starknet.state.invoke_raw(contract_address=set_proxy.contract_address,
        selector=get_selector_from_name("approve_"),
        calldata=[ADMIN, tok_id_1],
        caller_address=OTHER_ADDRESS,
        max_fee=0,
    )

    await starknet.state.invoke_raw(contract_address=set_proxy.contract_address,
        selector=get_selector_from_name("transferOneNFT"),
        calldata=[OTHER_ADDRESS, ADMIN, tok_id_1],
        caller_address=ADMIN,
        max_fee=0,
    )

    # TODO check approve status

    with pytest.raises(StarkException):
        await starknet.state.invoke_raw(contract_address=set_proxy.contract_address,
            selector=get_selector_from_name("transferOneNFT"),
            calldata=[ADMIN, OTHER_ADDRESS, tok_id_1],
            caller_address=OTHER_ADDRESS,
            max_fee=0,
        )

    await starknet.state.invoke_raw(contract_address=set_proxy.contract_address,
        selector=get_selector_from_name("setApprovalForAll_"),
        calldata=[OTHER_ADDRESS, 1],
        caller_address=ADMIN,
        max_fee=0,
    )

    # Now transfer goes through, approved as operator
    await starknet.state.invoke_raw(contract_address=set_proxy.contract_address,
        selector=get_selector_from_name("transferOneNFT"),
        calldata=[ADMIN, OTHER_ADDRESS, tok_id_1],
        caller_address=OTHER_ADDRESS,
        max_fee=0,
    )

    # authorization was burned, this fails.
    with pytest.raises(StarkException):
        await starknet.state.invoke_raw(contract_address=set_proxy.contract_address,
            selector=get_selector_from_name("transferOneNFT"),
            calldata=[OTHER_ADDRESS, ADMIN, tok_id_1],
            caller_address=ADMIN,
            max_fee=0,
        )
