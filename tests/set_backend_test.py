import os
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from starkware.cairo.common.hash_state import compute_hash_on_elements

from starkware.starknet.compiler.compile import compile_starknet_files, compile_starknet_codes

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

def hash_token_id(owner: int, hint: int, uri):
    raw_tid = compute_hash_on_elements([owner, hint]) & ((2**251 - 1) - (2**59 - 1))
    if len(uri) == 2 and uri[1] < 2**59:
        raw_tid += uri[1]
    return raw_tid

@pytest.mark.asyncio
async def test_minting_compactness(briq_backend, set_backend):
    await invoke_briq(briq_backend.mintFT(owner=0x11, material=1, qty=50))
    res = await invoke_set(set_backend.assemble(owner=0x11, token_id_hint=50, fts=[(1, 25)], nfts=[], uri=[0x1234, 0x4321]))

    tok_id_50 = hash_token_id(0x11, 50, uri=[0x1234, 0x4321])
    assert (await set_backend.balanceDetailsOf(owner=0x11).call()).result.token_ids == [tok_id_50]
    assert (await set_backend.tokenUri(token_id=tok_id_50).call()).result.uri == [0x1234, 0x4321]

    # Now let's break stuff up.
    await invoke_set(set_backend.setTokenUri(tok_id_50, [0xcafe]))
    assert (await set_backend.balanceDetailsOf(owner=0x11).call()).result.token_ids == [tok_id_50]
    assert (await set_backend.tokenUri(token_id=tok_id_50).call()).result.uri == [0xcafe]

    await invoke_set(set_backend.setTokenUri(tok_id_50, [0x1, 0x2, 0x3, 0x4]))
    assert (await set_backend.balanceDetailsOf(owner=0x11).call()).result.token_ids == [tok_id_50]
    assert (await set_backend.tokenUri(token_id=tok_id_50).call()).result.uri == [0x1, 0x2, 0x3, 0x4]

    # This would write to the token_id initially, but not any more.
    await invoke_set(set_backend.setTokenUri(tok_id_50, [0x1234, 0x4444]))
    assert (await set_backend.balanceDetailsOf(owner=0x11).call()).result.token_ids == [tok_id_50]
    assert (await set_backend.tokenUri(token_id=tok_id_50).call()).result.uri == [0x1234, 0x4444]

@pytest.mark.asyncio
async def test_minting_and_querying(briq_backend, set_backend):
    await invoke_briq(briq_backend.mintFT(owner=0x11, material=1, qty=50))
    await invoke_briq(briq_backend.mintOneNFT(owner=0x11, material=1, uid=1))
    await invoke_briq(briq_backend.mintOneNFT(owner=0x11, material=1, uid=2))
    await invoke_briq(briq_backend.mintOneNFT(owner=0x11, material=1, uid=3))
    await invoke_briq(briq_backend.mintFT(owner=0x12, material=1, qty=50))
    await invoke_set(set_backend.assemble(owner=0x11, token_id_hint=50, fts=[(1, 25)], nfts=[1 * 2**64 + 1, 3 * 2**64 + 1], uri=[1234]))
    tok_id_50 = hash_token_id(0x11, 50, uri=[1234])

    assert (await set_backend.balanceOf(owner=0x11).call()).result.balance == 1
    assert (await set_backend.balanceDetailsOf(owner=0x11).call()).result.token_ids == [tok_id_50]
    assert (await briq_backend.balanceDetailsOf(owner=0x11, material=1).call()).result.nft_ids == [2 * 2**64 + 1]


    await invoke_set(set_backend.assemble(owner=0x11, token_id_hint=150, fts=[(1, 10)], nfts=[], uri=[1234]))
    await invoke_set(set_backend.assemble(owner=0x12, token_id_hint=25, fts=[(1, 10)], nfts=[], uri=[1234]))

    tok_id_150 = hash_token_id(0x11, 150, uri=[1234])
    tok_id_25 = hash_token_id(0x12, 25, uri=[1234])


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
        await invoke_set(set_backend.assemble(owner=0x12, token_id_hint=25, fts=[], nfts=[], uri=[1234]))


@pytest.mark.asyncio
async def test_transfer_nft(briq_backend, set_backend):
    await invoke_briq(briq_backend.mintFT(owner=0x11, material=1, qty=50))
    await invoke_set(set_backend.assemble(owner=0x11, token_id_hint=0x2, fts=[(1, 10)], nfts=[], uri=[1234]))
    await invoke_set(set_backend.assemble(owner=0x11, token_id_hint=0x3, fts=[(1, 10)], nfts=[], uri=[1234]))
    await invoke_set(set_backend.assemble(owner=0x11, token_id_hint=0x1, fts=[(1, 10)], nfts=[], uri=[1234]))

    tok_id_1 = hash_token_id(0x11, 0x1, uri=[1234])
    tok_id_2 = hash_token_id(0x11, 0x2, uri=[1234])
    tok_id_3 = hash_token_id(0x11, 0x3, uri=[1234])

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
    await invoke_set(set_backend.assemble(owner=0x11, token_id_hint=0x1, fts=[(1, 10)], nfts=[], uri=[1234]))
    token_id = hash_token_id(0x11, 0x1, uri=[1234])

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

    # Need to keep the two LSBs free.
    await invoke_set(set_backend.setTokenUri(token_id=token_id, uri=[2**248]))
    await invoke_set(set_backend.setTokenUri(token_id=token_id, uri=[2**249 - 1]))
    with pytest.raises(StarkException):
        await invoke_set(set_backend.setTokenUri(token_id=token_id, uri=[2**249]))
    with pytest.raises(StarkException):
        await invoke_set(set_backend.setTokenUri(token_id=token_id, uri=[1, 2, 3, 2**249, 4]))


@pytest.mark.asyncio
async def test_update_nft(briq_backend, set_backend):
    await invoke_briq(briq_backend.mintFT(owner=0x11, material=1, qty=50))
    await invoke_briq(briq_backend.mintFT(owner=0x11, material=2, qty=50))
    await invoke_briq(briq_backend.mintOneNFT(owner=0x11, material=1, uid=1))
    await invoke_briq(briq_backend.mintOneNFT(owner=0x11, material=2, uid=1))
    await invoke_set(set_backend.assemble(owner=0x11, token_id_hint=0x1, fts=[(1, 10)], nfts=[2**64 + 1], uri=[1234]))

    tok_id_1 = hash_token_id(0x11, 0x1, uri=[1234])

    assert (await briq_backend.balanceDetailsOf(tok_id_1, 1).call()).result.ft_balance == 10
    assert (await briq_backend.balanceDetailsOf(tok_id_1, 1).call()).result.nft_ids == [2**64 + 1]
    assert (await briq_backend.balanceOf(0x11, 1).call()).result.balance == 40

    await invoke_set(set_backend.updateBriqs(owner=0x11, token_id=tok_id_1,
        add_fts=[(2, 10)], add_nfts=[2**64 + 2],
        remove_fts=[(1, 10)], remove_nfts=[2**64 + 1],
        uri=[0x1234]
    ))

    assert (await briq_backend.balanceOf(0x11, 1).call()).result.balance == 51
    assert (await briq_backend.balanceOf(0x11, 2).call()).result.balance == 40
    assert (await briq_backend.balanceDetailsOf(tok_id_1, 1).call()).result.ft_balance == 0
    assert (await briq_backend.balanceDetailsOf(tok_id_1, 1).call()).result.nft_ids == []
    assert (await briq_backend.balanceDetailsOf(tok_id_1, 2).call()).result.ft_balance == 10
    assert (await briq_backend.balanceDetailsOf(tok_id_1, 2).call()).result.nft_ids == [2**64 + 2]


@pytest.mark.asyncio
async def test_events(starknet, briq_backend, set_backend):
    tok_id_1 = hash_token_id(0x11, 0x1, uri=[1234])

    await invoke_briq(briq_backend.mintFT(owner=0x11, material=1, qty=50))
    await invoke_set(set_backend.assemble(owner=0x11, token_id_hint=0x1, fts=[(1, 10)], nfts=[], uri=[1234]))
    await invoke_set(set_backend.updateBriqs(owner=0x11, token_id=tok_id_1,
        add_fts=[], add_nfts=[],
        remove_fts=[], remove_nfts=[],
        uri=[4321]
    ))
    await invoke_set(set_backend.transferOneNFT(sender=0x11, recipient=0x12, token_id=tok_id_1))
    await invoke_set(set_backend.disassemble(owner=0x12, token_id=tok_id_1, fts=[(1, 10)], nfts=[]))

    events = starknet.state.events

    #print(briq_backend.event_manager._selector_to_name)
    #print(set_backend.event_manager._selector_to_name)
    
    assert set_backend.event_manager._selector_to_name[events[2].keys[0]] == 'Transfer'
    assert events[2].data == [0, 0x11, tok_id_1]
    assert set_backend.event_manager._selector_to_name[events[3].keys[0]] == 'URI'
    assert events[3].data == [1, 1234, tok_id_1]
    assert set_backend.event_manager._selector_to_name[events[4].keys[0]] == 'URI'
    assert events[4].data == [1, 4321, tok_id_1]
    assert set_backend.event_manager._selector_to_name[events[5].keys[0]] == 'Transfer'
    assert events[5].data == [0x11, 0x12, tok_id_1]
    assert set_backend.event_manager._selector_to_name[events[7].keys[0]] == 'Transfer'
    assert events[7].data == [0x12, 0, tok_id_1]
