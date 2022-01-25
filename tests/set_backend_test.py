import os
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from starkware.cairo.common.hash_state import compute_hash_on_elements

from starkware.starknet.compiler.compile import compile_starknet_files

from .briq_backend_test import FAKE_BRIQ_PROXY_ADDRESS, compiled_briq, briq_backend, invoke_briq

CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")

FAKE_SET_PROXY_ADDRESS = 0xcafefade


def compile(path):
    return compile_starknet_files(
        files=[os.path.join(CONTRACT_SRC, path)],
        debug_info=True
    )


@pytest.fixture(scope="session")
def compiled_set():
    return compile("set_backend.cairo")


@pytest_asyncio.fixture
async def starknet():
    # Create a new Starknet class that simulates the StarkNet
    return await Starknet.empty()


@pytest_asyncio.fixture
async def set_backend(starknet, compiled_set, briq_backend):
    set_backend = await starknet.deploy(contract_def=compiled_set, constructor_calldata=[FAKE_SET_PROXY_ADDRESS])
    await set_backend.setBriqBackendAddress(address=briq_backend.contract_address).invoke(caller_address=FAKE_SET_PROXY_ADDRESS)
    await briq_backend.setSetBackendAddress(address=set_backend.contract_address).invoke(caller_address=FAKE_BRIQ_PROXY_ADDRESS)
    return set_backend


def invoke_set(call):
    return call.invoke(caller_address=FAKE_SET_PROXY_ADDRESS)


@pytest.mark.asyncio
async def test_minting_and_querying(briq_backend, set_backend):
    await invoke_briq(briq_backend.mintFT(owner=0x11, material=1, qty=50))
    await invoke_briq(briq_backend.mintOneNFT(owner=0x11, material=1, uid=1))
    await invoke_briq(briq_backend.mintOneNFT(owner=0x11, material=1, uid=2))
    await invoke_briq(briq_backend.mintOneNFT(owner=0x11, material=1, uid=3))
    await invoke_briq(briq_backend.mintFT(owner=0x12, material=1, qty=50))
    await invoke_set(set_backend.assemble(owner=0x11, token_id_hint=50, fts=[(1, 25)], nfts=[1 * 2**64 + 1, 3 * 2**64 + 1]))
    tok_id_50 = compute_hash_on_elements([0x11, 50])

    assert (await set_backend.balanceOf(owner=0x11).call()).result.balance == 1
    assert (await set_backend.balanceDetailsOf(owner=0x11).call()).result.token_ids == [tok_id_50]
    assert (await briq_backend.balanceDetailsOf(owner=0x11, material=1).call()).result.nft_ids == [2 * 2**64 + 1]


    await invoke_set(set_backend.assemble(owner=0x11, token_id_hint=150, fts=[(1, 10)], nfts=[]))
    await invoke_set(set_backend.assemble(owner=0x12, token_id_hint=25, fts=[(1, 10)], nfts=[]))

    tok_id_150 = compute_hash_on_elements([0x11, 150])
    tok_id_25 = compute_hash_on_elements([0x12, 25])


    assert (await set_backend.balanceOf(owner=0x11).call()).result.balance == 2
    assert (await set_backend.balanceOf(owner=0x12).call()).result.balance == 1
    assert (await set_backend.ownerOf(token_id=tok_id_50).call()).result.owner == 0x11
    assert (await set_backend.ownerOf(token_id=tok_id_150).call()).result.owner == 0x11
    assert (await set_backend.ownerOf(token_id=tok_id_25).call()).result.owner == 0x12
    assert (await set_backend.balanceDetailsOf(owner=0x11).call()).result.token_ids == [tok_id_50, tok_id_150]
    assert (await set_backend.balanceDetailsOf(owner=0x12).call()).result.token_ids == [tok_id_25]

    assert (await briq_backend.balanceOf(owner=0x11, material=1).call()).result.balance == 16
    assert (await briq_backend.balanceOf(owner=0x12, material=1).call()).result.balance == 40

    assert (await briq_backend.balanceOf(owner=tok_id_50, material=1).call()).result.balance == 27
    assert (await briq_backend.balanceOf(owner=tok_id_150, material=1).call()).result.balance == 10
    assert (await briq_backend.balanceOf(owner=tok_id_25, material=1).call()).result.balance == 10
    assert (await briq_backend.balanceDetailsOf(owner=tok_id_50, material=1).call()).result.nft_ids == [3 * 2**64 + 1, 1 * 2**64 + 1]

    await invoke_set(set_backend.disassemble(owner=0x11, token_id=tok_id_150, fts=[(1, 10)], nfts=[]))
    assert (await set_backend.balanceOf(owner=0x11).call()).result.balance == 1

    await invoke_set(set_backend.disassemble(owner=0x11, token_id=tok_id_50, fts=[(1, 25)], nfts=[1 * 2**64 + 1, 3 * 2**64 + 1]))
    assert (await set_backend.balanceOf(owner=0x11).call()).result.balance == 0
    assert (await briq_backend.balanceOf(owner=tok_id_50, material=1).call()).result.balance == 0
    assert (await briq_backend.balanceOf(owner=tok_id_150, material=1).call()).result.balance == 0
    assert (await briq_backend.balanceOf(owner=tok_id_25, material=1).call()).result.balance == 10
    assert (await set_backend.ownerOf(token_id=tok_id_50).call()).result.owner == 0
    assert (await set_backend.ownerOf(token_id=tok_id_150).call()).result.owner == 0
    assert (await set_backend.ownerOf(token_id=tok_id_25).call()).result.owner == 0x12

    assert (await briq_backend.balanceOf(owner=0x11, material=1).call()).result.balance == 53

    with pytest.raises(StarkException):
        await invoke_set(set_backend.assemble(owner=0x12, token_id_hint=25, fts=[], nfts=[]))


@pytest.mark.asyncio
async def test_transfer_nft(briq_backend, set_backend):
    await invoke_briq(briq_backend.mintFT(owner=0x11, material=1, qty=50))
    await invoke_set(set_backend.assemble(owner=0x11, token_id_hint=0x2, fts=[(1, 10)], nfts=[]))
    await invoke_set(set_backend.assemble(owner=0x11, token_id_hint=0x3, fts=[(1, 10)], nfts=[]))
    await invoke_set(set_backend.assemble(owner=0x11, token_id_hint=0x1, fts=[(1, 10)], nfts=[]))

    tok_id_1 = compute_hash_on_elements([0x11, 0x1])
    tok_id_2 = compute_hash_on_elements([0x11, 0x2])
    tok_id_3 = compute_hash_on_elements([0x11, 0x3])

    await invoke_set(set_backend.transferOneNFT(sender=0x11, recipient=0x12, token_id=tok_id_2))
    assert (await set_backend.balanceOf(owner=0x11).call()).result.balance == 2
    assert (await set_backend.balanceOf(owner=0x12).call()).result.balance == 1
    assert (await set_backend.balanceDetailsOf(owner=0x11).call()).result.token_ids == [tok_id_1, tok_id_3]
    assert (await set_backend.balanceDetailsOf(owner=0x12).call()).result.token_ids == [tok_id_2]
    assert (await set_backend.ownerOf(tok_id_1).call()).result.owner == 0x11
    assert (await set_backend.ownerOf(tok_id_2).call()).result.owner == 0x12
    assert (await set_backend.ownerOf(tok_id_3).call()).result.owner == 0x11

    await invoke_set(set_backend.transferOneNFT(sender=0x11, recipient=0x12, token_id=tok_id_3))
    assert (await set_backend.balanceDetailsOf(owner=0x11).call()).result.token_ids == [tok_id_1]
    assert (await set_backend.balanceDetailsOf(owner=0x12).call()).result.token_ids == [tok_id_2, tok_id_3]
    await invoke_set(set_backend.transferOneNFT(sender=0x11, recipient=0x12, token_id=tok_id_1))
    assert (await set_backend.balanceOf(owner=0x11).call()).result.balance == 0
    assert (await set_backend.balanceOf(owner=0x12).call()).result.balance == 3
    assert (await set_backend.balanceDetailsOf(owner=0x11).call()).result.token_ids == []
    assert (await set_backend.balanceDetailsOf(owner=0x12).call()).result.token_ids == [tok_id_2, tok_id_3, tok_id_1]
    assert (await set_backend.ownerOf(tok_id_1).call()).result.owner == 0x12
    assert (await set_backend.ownerOf(tok_id_2).call()).result.owner == 0x12
    assert (await set_backend.ownerOf(tok_id_3).call()).result.owner == 0x12


@pytest.mark.asyncio
async def test_token_uri(briq_backend, set_backend):
    await invoke_briq(briq_backend.mintFT(owner=0x11, material=1, qty=50))
    await invoke_set(set_backend.assemble(owner=0x11, token_id_hint=0x1, fts=[(1, 10)], nfts=[]))
    token_id = compute_hash_on_elements([0x11, 0x1])

    assert (await set_backend.balanceOf(owner=0x11).call()).result.balance == 1
    assert (await set_backend.balanceDetailsOf(owner=0x11).call()).result.token_ids == [token_id]
    assert (await set_backend.ownerOf(token_id).call()).result.owner == 0x11

    with pytest.raises(StarkException):
        await invoke_set(set_backend.setTokenUri(token_id=0xdead, uri=[0xcafecafe]))

    await invoke_set(set_backend.setTokenUri(token_id=token_id, uri=[0xcafecafe]))
    assert (await set_backend.tokenUri(token_id=token_id).call()).result.uri == [0xcafecafe]

    await invoke_set(set_backend.setTokenUri(token_id=token_id, uri=[0xcafecafe, 0xfadefade]))
    assert (await set_backend.tokenUri(token_id=token_id).call()).result.uri == [0xcafecafe, 0xfadefade]
    await invoke_set(set_backend.setTokenUri(token_id=token_id, uri=[0xcafecafe, 0xfadefade, 0x1234, 0x5678]))
    assert (await set_backend.tokenUri(token_id=token_id).call()).result.uri == [0xcafecafe, 0xfadefade, 0x1234, 0x5678]
    await invoke_set(set_backend.setTokenUri(token_id=token_id, uri=[0xcafecafe]))
    assert (await set_backend.tokenUri(token_id=token_id).call()).result.uri == [0xcafecafe]
    # edge cases around 0-value items
    await invoke_set(set_backend.setTokenUri(token_id=token_id, uri=[0xcafecafe, 0xfadefade, 0, 0x1234, 0x5678]))
    assert (await set_backend.tokenUri(token_id=token_id).call()).result.uri == [0xcafecafe, 0xfadefade, 0, 0x1234, 0x5678]
    await invoke_set(set_backend.setTokenUri(token_id=token_id, uri=[0, 0xfadefade, 0, 0x1234, 0x5678]))
    assert (await set_backend.tokenUri(token_id=token_id).call()).result.uri == [0, 0xfadefade, 0, 0x1234, 0x5678]
    await invoke_set(set_backend.setTokenUri(token_id=token_id, uri=[0]))
    assert (await set_backend.tokenUri(token_id=token_id).call()).result.uri == [0]
    await invoke_set(set_backend.setTokenUri(token_id=token_id, uri=[0, 0, 0]))
    assert (await set_backend.tokenUri(token_id=token_id).call()).result.uri == [0, 0, 0]
    await invoke_set(set_backend.setTokenUri(token_id=token_id, uri=[0x1, 0]))
    assert (await set_backend.tokenUri(token_id=token_id).call()).result.uri == [0x1, 0]
    await invoke_set(set_backend.setTokenUri(token_id=token_id, uri=[0x1, 0, 0, 0]))
    assert (await set_backend.tokenUri(token_id=token_id).call()).result.uri == [0x1, 0, 0, 0]

    # Need to keep the LSB free.
    await invoke_set(set_backend.setTokenUri(token_id=token_id, uri=[2**249]))
    await invoke_set(set_backend.setTokenUri(token_id=token_id, uri=[2**250 - 1]))
    with pytest.raises(StarkException):
        await invoke_set(set_backend.setTokenUri(token_id=token_id, uri=[2**250]))
    with pytest.raises(StarkException):
        await invoke_set(set_backend.setTokenUri(token_id=token_id, uri=[1, 2, 3, 2**250, 4]))
