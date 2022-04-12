import os
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException

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

@pytest.fixture(scope="session")
def compiled_proxy():
    return compile("proxy/_proxy.cairo")


@pytest_asyncio.fixture
async def starknet():
    # Create a new Starknet class that simulates the StarkNet
    return await Starknet.empty()


@pytest_asyncio.fixture
async def setup_proxies(starknet: Starknet, compiled_proxy, compiled_briq, compiled_set):
    briq_impl = await starknet.deploy(contract_def=compiled_briq)
    set_impl = await starknet.deploy(contract_def=compiled_set)
    briq_proxy = await starknet.deploy(contract_def=compiled_proxy, constructor_calldata=[ADMIN, briq_impl.contract_address])
    set_proxy = await starknet.deploy(contract_def=compiled_proxy, constructor_calldata=[ADMIN, set_impl.contract_address])

    await starknet.state.invoke_raw(contract_address=set_proxy.contract_address,
        selector=get_selector_from_name("setBriqAddress"),
        calldata=[briq_proxy.contract_address],
        caller_address=ADMIN,
        max_fee=0,
    )

    await starknet.state.invoke_raw(contract_address=briq_proxy.contract_address,
        selector=get_selector_from_name("setSetAddress"),
        calldata=[set_proxy.contract_address],
        caller_address=ADMIN,
        max_fee=0,
    )
    return briq_proxy, set_proxy

@pytest.mark.asyncio
async def test_admin(starknet, setup_proxies):
    briq_proxy = setup_proxies[0]
    set_proxy = setup_proxies[1]

    assert (await briq_proxy.getAdmin().call()).result.address == ADMIN
    assert (await set_proxy.getAdmin().call()).result.address == ADMIN

    await briq_proxy.setImplementation(0xcafe).invoke(ADMIN)
    await set_proxy.setImplementation(0xcafe).invoke(ADMIN)

    assert (await briq_proxy.getImplementation().call()).result.address == 0xcafe
    assert (await set_proxy.getImplementation().call()).result.address == 0xcafe

    with pytest.raises(StarkException):
        await briq_proxy.setImplementation(0xcafe).invoke(0xdead)
    with pytest.raises(StarkException):
        await set_proxy.setImplementation(0xcafe).invoke(0xdead)

    await briq_proxy.setAdmin(0xdead).invoke(ADMIN)
    await set_proxy.setAdmin(0xdead).invoke(ADMIN)

    assert (await briq_proxy.getAdmin().call()).result.address == 0xdead
    assert (await set_proxy.getAdmin().call()).result.address == 0xdead

    with pytest.raises(StarkException):
        await briq_proxy.setImplementation(0xcafe).invoke(ADMIN)
    with pytest.raises(StarkException):
        await set_proxy.setImplementation(0xcafe).invoke(ADMIN)

    await briq_proxy.setImplementation(0xcafe).invoke(0xdead)
    await set_proxy.setImplementation(0xcafe).invoke(0xdead)


@pytest.mark.asyncio
async def test_call(starknet, setup_proxies):
    briq_proxy = setup_proxies[0]
    set_proxy = setup_proxies[1]

    # await invoke_briq(briq_backendbriq_impl.mintFT(owner=ADMIN, material=1, qty=50), ADMIN)
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
    with pytest.raises(StarkException):
        await starknet.state.invoke_raw(contract_address=set_proxy.contract_address,
            selector=get_selector_from_name("assemble"),
            calldata=[0x12, 0x2, 1, 1, 5, 0, 0xfade],
            caller_address=0xcafe,
            max_fee=0,
        )



@pytest.mark.asyncio
async def test_admin_evolution(starknet, setup_proxies):
    briq_proxy = setup_proxies[0]

    # Check that admin auth depends on implementation.
    await invoke_briq(briq_proxy.setImplementation(0xcafe), 0x03e46c8abcd73a10cb59c249592a30c489eeab55f76b3496fd9e0250825afe03)
    with pytest.raises(StarkException):
        await invoke_briq(briq_proxy.setImplementation(0xcafe), 0x03e46c8abcd73a10cb59c249592a30c489eeab55f76b3496fd9e0250825afe03)
    await invoke_briq(briq_proxy.setImplementation(0xbabe), ADMIN)


@pytest.fixture(scope="session")
def compiled_mint():
    return compile("mint.cairo")


@pytest.mark.asyncio
async def test_mint(starknet, compiled_mint, compiled_proxy, setup_proxies):
    briq_proxy = setup_proxies[0]
    set_proxy = setup_proxies[1]

    mint = await starknet.deploy(contract_def=compiled_mint, constructor_calldata=[briq_proxy.contract_address, 100])

    await starknet.state.invoke_raw(contract_address=briq_proxy.contract_address,
        selector=get_selector_from_name("setMintContract"),
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
async def test_redo_implementation(starknet, setup_proxies):
    briq_proxy = setup_proxies[0]
    set_proxy = setup_proxies[1]

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

    bimp = (await briq_proxy.getImplementation().call()).result.address
    simp = (await set_proxy.getImplementation().call()).result.address

    await briq_proxy.setImplementation(0xcafe).invoke(ADMIN)
    await set_proxy.setImplementation(0xcafe).invoke(ADMIN)

    with pytest.raises(StarkException):
        await starknet.state.invoke_raw(contract_address=set_proxy.contract_address,
            selector=get_selector_from_name("disassemble"),
            calldata=[ADMIN, 0x1, 1, 1, 5, 0],
            caller_address=0xdead,
            max_fee=0,
        )

    await briq_proxy.setImplementation(bimp).invoke(ADMIN)
    await set_proxy.setImplementation(simp).invoke(ADMIN)

    tok_id = hash_token_id(ADMIN, 1, uri=[0xcafe])
    await starknet.state.invoke_raw(contract_address=set_proxy.contract_address,
        selector=get_selector_from_name("disassemble"),
        calldata=[ADMIN, tok_id, 1, 1, 5, 0],
        caller_address=ADMIN,
        max_fee=0,
    )


@pytest.mark.asyncio
async def test_transfer_approval(starknet, setup_proxies):
    briq_proxy = setup_proxies[0]
    set_proxy = setup_proxies[1]

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
