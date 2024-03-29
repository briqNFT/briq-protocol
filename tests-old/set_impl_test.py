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

from .conftest import declare_and_deploy, hash_token_id


FAKE_SET_PROXY_ADDRESS = 0xcafefade
ADMIN = 0x0  # No proxy so no admin
ADDRESS = 0x123456
OTHER_ADDRESS = 0x654321
THIRD_ADDRESS = 0x551155


@pytest_asyncio.fixture(scope="session")
async def factory_root():
    starknet = await Starknet.empty()
    [set_contract, _] = await declare_and_deploy(starknet, "set_nft.cairo")
    [briq_contract, _] = await declare_and_deploy(starknet, "briq.cairo")
    [attributes_registry_mock, _] = await declare_and_deploy(starknet, "mocks/attributes_registry_mock.cairo")
    await set_contract.setBriqAddress_(address=briq_contract.contract_address).execute(caller_address=ADMIN)
    await set_contract.setAttributesRegistryAddress_(address=attributes_registry_mock.contract_address).execute(caller_address=ADMIN)
    await briq_contract.setSetAddress_(address=set_contract.contract_address).execute(caller_address=ADMIN)
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
        deploy_call_info=sc.deploy_call_info,
    )

@pytest_asyncio.fixture
async def briq_contract(factory: Tuple[Starknet, StarknetContract, StarknetContract]):
    [starknet, sc, bc] = factory
    return StarknetContract(
        state=starknet.state,
        abi=bc.abi,
        contract_address=bc.contract_address,
        deploy_call_info=bc.deploy_call_info,
    )


@pytest_asyncio.fixture
async def starknet(factory: Tuple[Starknet, StarknetContract, StarknetContract]):
    [starknet, sc, bc] = factory
    return starknet

def invoke_set(call, addr=ADDRESS):
    return call.execute(caller_address=addr)

@pytest.mark.asyncio
async def disabled_test_minting_compactness(briq_contract, set_contract):
    res = await invoke_set(set_contract.assemble_(owner=ADDRESS, token_id_hint=50, name=[0x12], description=[0x34], fts=[(1, 25)], nfts=[], shape=[], attributes=[]))

    tok_id_50 = hash_token_id(ADDRESS, 50, uri=[])
    assert (await set_contract.balanceDetailsOf_(owner=ADDRESS).call()).result.token_ids == [tok_id_50]
    assert (await set_contract.tokenURI_(token_id=tok_id_50).call()).result.uri == [0x1234, 0x4321]

    # Now let's break stuff up.
    await invoke_set(set_contract.setTokenURI_(tok_id_50, [0xcafe]), ADMIN)
    assert (await set_contract.balanceDetailsOf_(owner=ADDRESS).call()).result.token_ids == [tok_id_50]
    assert (await set_contract.tokenURI_(token_id=tok_id_50).call()).result.uri == [0xcafe]

    await invoke_set(set_contract.setTokenURI_(tok_id_50, [0x1, 0x2, 0x3, 0x4]), ADMIN)
    assert (await set_contract.balanceDetailsOf_(owner=ADDRESS).call()).result.token_ids == [tok_id_50]
    assert (await set_contract.tokenURI_(token_id=tok_id_50).call()).result.uri == [0x1, 0x2, 0x3, 0x4]

    # This would write to the token_id initially, but not any more.
    await invoke_set(set_contract.setTokenURI_(tok_id_50, [0x1234, 0x4444]), ADMIN)
    assert (await set_contract.balanceDetailsOf_(owner=ADDRESS).call()).result.token_ids == [tok_id_50]
    assert (await set_contract.tokenURI_(token_id=tok_id_50).call()).result.uri == [0x1234, 0x4444]

@pytest.mark.asyncio
async def test_minting_and_querying(briq_contract, set_contract):
    await invoke_briq(briq_contract.mintOneNFT(owner=ADDRESS, material=1, uid=1))
    await invoke_briq(briq_contract.mintOneNFT(owner=ADDRESS, material=1, uid=2))
    await invoke_briq(briq_contract.mintOneNFT(owner=ADDRESS, material=1, uid=3))
    await invoke_set(set_contract.assemble_(owner=ADDRESS, token_id_hint=50, name=[0x12], description=[0x34], fts=[(1, 25)], nfts=[1 * 2**64 + 1, 3 * 2**64 + 1], shape=[], attributes=[]))
    tok_id_50 = hash_token_id(ADDRESS, 50, uri=[])

    assert (await set_contract.balanceOf_(owner=ADDRESS).call()).result.balance == 1
    assert (await set_contract.balanceDetailsOf_(owner=ADDRESS).call()).result.token_ids == [tok_id_50]
    assert (await briq_contract.balanceDetailsOfMaterial_(owner=ADDRESS, material=1).call()).result.nft_ids == [2 * 2**64 + 1]

    await invoke_set(set_contract.assemble_(owner=ADDRESS, token_id_hint=150, name=[0x12], description=[0x34], fts=[(1, 10)], nfts=[], shape=[], attributes=[]))

    await invoke_briq(briq_contract.mintFT(owner=OTHER_ADDRESS, material=1, qty=50))
    await invoke_set(set_contract.assemble_(owner=OTHER_ADDRESS, token_id_hint=25, name=[0x12], description=[0x34], fts=[(1, 10)], nfts=[], shape=[], attributes=[]), OTHER_ADDRESS)

    tok_id_150 = hash_token_id(ADDRESS, 150, uri=[])
    tok_id_25 = hash_token_id(OTHER_ADDRESS, 25, uri=[])


    assert (await set_contract.balanceOf_(owner=ADDRESS).call()).result.balance == 2
    assert (await set_contract.balanceOf_(owner=OTHER_ADDRESS).call()).result.balance == 1
    assert (await set_contract.ownerOf_(token_id=tok_id_50).call()).result.owner == ADDRESS
    assert (await set_contract.ownerOf_(token_id=tok_id_150).call()).result.owner == ADDRESS
    assert (await set_contract.ownerOf_(token_id=tok_id_25).call()).result.owner == OTHER_ADDRESS
    assert (await set_contract.balanceDetailsOf_(owner=ADDRESS).call()).result.token_ids == [tok_id_50, tok_id_150]
    assert (await set_contract.balanceDetailsOf_(owner=OTHER_ADDRESS).call()).result.token_ids == [tok_id_25]

    assert (await briq_contract.balanceOfMaterial_(owner=ADDRESS, material=1).call()).result.balance == 16
    assert (await briq_contract.balanceOfMaterial_(owner=OTHER_ADDRESS, material=1).call()).result.balance == 40

    assert (await briq_contract.balanceOfMaterial_(owner=tok_id_50, material=1).call()).result.balance == 27
    assert (await briq_contract.balanceOfMaterial_(owner=tok_id_150, material=1).call()).result.balance == 10
    assert (await briq_contract.balanceOfMaterial_(owner=tok_id_25, material=1).call()).result.balance == 10
    assert (await briq_contract.balanceDetailsOfMaterial_(owner=tok_id_50, material=1).call()).result.nft_ids == [3 * 2**64 + 1, 1 * 2**64 + 1]

    await invoke_set(set_contract.disassemble_(owner=ADDRESS, token_id=tok_id_150, fts=[(1, 10)], nfts=[], attributes=[]))
    assert (await set_contract.balanceOf_(owner=ADDRESS).call()).result.balance == 1

    await invoke_set(set_contract.disassemble_(owner=ADDRESS, token_id=tok_id_50, fts=[(1, 25)], nfts=[1 * 2**64 + 1, 3 * 2**64 + 1], attributes=[]))
    assert (await set_contract.balanceOf_(owner=ADDRESS).call()).result.balance == 0
    assert (await briq_contract.balanceOfMaterial_(owner=tok_id_50, material=1).call()).result.balance == 0
    assert (await briq_contract.balanceOfMaterial_(owner=tok_id_150, material=1).call()).result.balance == 0
    assert (await briq_contract.balanceOfMaterial_(owner=tok_id_25, material=1).call()).result.balance == 10
    assert (await set_contract.ownerOf_(token_id=tok_id_50).call()).result.owner == 0
    assert (await set_contract.ownerOf_(token_id=tok_id_150).call()).result.owner == 0
    assert (await set_contract.ownerOf_(token_id=tok_id_25).call()).result.owner == OTHER_ADDRESS

    assert (await briq_contract.balanceOfMaterial_(owner=ADDRESS, material=1).call()).result.balance == 53

    with pytest.raises(StarkException):
        await invoke_set(set_contract.assemble_(owner=OTHER_ADDRESS, token_id_hint=25, name=[0x12], description=[0x34], fts=[], nfts=[], shape=[], attributes=[]), OTHER_ADDRESS)

@pytest.mark.asyncio
async def test_minting_bad_duplicate_nft(briq_contract, set_contract):
    await invoke_briq(briq_contract.mintOneNFT(owner=ADDRESS, material=1, uid=1))
    with pytest.raises(StarkException):
        await invoke_set(set_contract.assemble_(owner=ADDRESS, token_id_hint=50, name=[0x12], description=[0x34], fts=[(1, 25)], nfts=[1 * 2**64 + 1, 1 * 2**64 + 1], shape=[], attributes=[]))

@pytest.mark.asyncio
async def test_minting_bad_disassembly(briq_contract, set_contract):
    tok_id = hash_token_id(ADDRESS, 150, uri=[])
    await invoke_set(set_contract.assemble_(owner=ADDRESS, token_id_hint=150, name=[0x12], description=[0x34], fts=[(1, 10)], nfts=[], shape=[], attributes=[]))
    with pytest.raises(StarkException):
        await invoke_set(set_contract.disassemble_(owner=ADDRESS, token_id=tok_id, fts=[], nfts=[], attributes=[]))
    with pytest.raises(StarkException):
        await invoke_set(set_contract.disassemble_(owner=ADDRESS, token_id=tok_id, fts=[(1, 15)], nfts=[], attributes=[]))
    with pytest.raises(StarkException):
        await invoke_set(set_contract.disassemble_(owner=ADDRESS, token_id=tok_id, fts=[(1, 5)], nfts=[], attributes=[]))
    with pytest.raises(StarkException):
        await invoke_set(set_contract.disassemble_(owner=ADDRESS, token_id=tok_id, fts=[(1, 10)], nfts=[2], attributes=[]))
    # Finally the correct variant.
    await invoke_set(set_contract.disassemble_(owner=ADDRESS, token_id=tok_id, fts=[(1, 10)], nfts=[], attributes=[]))

@pytest.mark.asyncio
async def test_transfer_nft(set_contract):
    await invoke_set(set_contract.assemble_(owner=ADDRESS, token_id_hint=0x2, name=[0x12], description=[0x34], fts=[(1, 10)], nfts=[], shape=[], attributes=[]))
    await invoke_set(set_contract.assemble_(owner=ADDRESS, token_id_hint=0x3, name=[0x12], description=[0x34], fts=[(1, 10)], nfts=[], shape=[], attributes=[]))
    await invoke_set(set_contract.assemble_(owner=ADDRESS, token_id_hint=0x1, name=[0x12], description=[0x34], fts=[(1, 10)], nfts=[], shape=[], attributes=[]))

    tok_id_1 = hash_token_id(ADDRESS, 0x1, uri=[])
    tok_id_2 = hash_token_id(ADDRESS, 0x2, uri=[])
    tok_id_3 = hash_token_id(ADDRESS, 0x3, uri=[])

    await invoke_set(set_contract.transferFrom_(sender=ADDRESS, recipient=OTHER_ADDRESS, token_id=tok_id_2))
    with pytest.raises(StarkException):
        await invoke_set(set_contract.transferFrom_(sender=ADDRESS, recipient=ADDRESS, token_id=tok_id_1))
    assert (await set_contract.balanceOf_(owner=ADDRESS).call()).result.balance == 2
    assert (await set_contract.balanceOf_(owner=OTHER_ADDRESS).call()).result.balance == 1
    assert (await set_contract.balanceDetailsOf_(owner=ADDRESS).call()).result.token_ids == [tok_id_1, tok_id_3]
    assert (await set_contract.balanceDetailsOf_(owner=OTHER_ADDRESS).call()).result.token_ids == [tok_id_2]
    assert (await set_contract.ownerOf_(tok_id_1).call()).result.owner == ADDRESS
    assert (await set_contract.ownerOf_(tok_id_2).call()).result.owner == OTHER_ADDRESS
    assert (await set_contract.ownerOf_(tok_id_3).call()).result.owner == ADDRESS

    await invoke_set(set_contract.transferFrom_(sender=ADDRESS, recipient=OTHER_ADDRESS, token_id=tok_id_3))
    assert (await set_contract.balanceDetailsOf_(owner=ADDRESS).call()).result.token_ids == [tok_id_1]
    assert (await set_contract.balanceDetailsOf_(owner=OTHER_ADDRESS).call()).result.token_ids == [tok_id_2, tok_id_3]
    await invoke_set(set_contract.transferFrom_(sender=ADDRESS, recipient=OTHER_ADDRESS, token_id=tok_id_1))
    assert (await set_contract.balanceOf_(owner=ADDRESS).call()).result.balance == 0
    assert (await set_contract.balanceOf_(owner=OTHER_ADDRESS).call()).result.balance == 3
    assert (await set_contract.balanceDetailsOf_(owner=ADDRESS).call()).result.token_ids == []
    assert (await set_contract.balanceDetailsOf_(owner=OTHER_ADDRESS).call()).result.token_ids == [tok_id_2, tok_id_3, tok_id_1]
    assert (await set_contract.ownerOf_(tok_id_1).call()).result.owner == OTHER_ADDRESS
    assert (await set_contract.ownerOf_(tok_id_2).call()).result.owner == OTHER_ADDRESS
    assert (await set_contract.ownerOf_(tok_id_3).call()).result.owner == OTHER_ADDRESS

import math

@pytest.mark.asyncio
async def disabled_test_token_uri(set_contract):
    await invoke_set(set_contract.assemble_(owner=ADDRESS, token_id_hint=0x1, name=[0x12], description=[0x34], fts=[(1, 10)], nfts=[]))
    token_id = hash_token_id(ADDRESS, 0x1, uri=[])

    assert (await set_contract.balanceOf_(owner=ADDRESS).call()).result.balance == 1
    assert (await set_contract.balanceDetailsOf_(owner=ADDRESS).call()).result.token_ids == [token_id]
    assert (await set_contract.ownerOf_(token_id).call()).result.owner == ADDRESS

    with pytest.raises(StarkException):
        await invoke_set(set_contract.setTokenURI_(token_id=0xdead, uri=[0xcafecafe]), ADMIN)

    await invoke_set(set_contract.setTokenURI_(token_id=token_id, uri=[int.from_bytes('0xcafecafe'.encode('ascii'), 'big')]), ADMIN)
    res = (await set_contract.tokenURIData_(token_id=token_id).call()).result.uri
    assert ''.join(
            [x.to_bytes(math.ceil(x.bit_length() / 8), 'big').decode('ascii') for x in res]
        ) == 'data:application/json,{ "metadata": "0xcafecafe", "attributes": [{"trait_type": "Realms", "value": "no"}]}'

    await invoke_set(set_contract.setTokenURI_(token_id=token_id, uri=[0xcafecafe, 0xfadefade]), ADMIN)
    assert (await set_contract.tokenURI_(token_id=token_id).call()).result.uri == [0xcafecafe, 0xfadefade]
    await invoke_set(set_contract.setTokenURI_(token_id=token_id, uri=[0xcafecafe, 0xfadefade, 0x1234, 0x5678]), ADMIN)
    assert (await set_contract.tokenURI_(token_id=token_id).call()).result.uri == [0xcafecafe, 0xfadefade, 0x1234, 0x5678]
    await invoke_set(set_contract.setTokenURI_(token_id=token_id, uri=[0xcafecafe]), ADMIN)
    assert (await set_contract.tokenURI_(token_id=token_id).call()).result.uri == [0xcafecafe]
    # edge cases around 0-value items
    await invoke_set(set_contract.setTokenURI_(token_id=token_id, uri=[0xcafecafe, 0xfadefade, 0, 0x1234, 0x5678]), ADMIN)
    assert (await set_contract.tokenURI_(token_id=token_id).call()).result.uri == [0xcafecafe, 0xfadefade, 0, 0x1234, 0x5678]
    await invoke_set(set_contract.setTokenURI_(token_id=token_id, uri=[0, 0xfadefade, 0, 0x1234, 0x5678]), ADMIN)
    assert (await set_contract.tokenURI_(token_id=token_id).call()).result.uri == [0, 0xfadefade, 0, 0x1234, 0x5678]
    await invoke_set(set_contract.setTokenURI_(token_id=token_id, uri=[0]), ADMIN)
    assert (await set_contract.tokenURI_(token_id=token_id).call()).result.uri == [0]
    await invoke_set(set_contract.setTokenURI_(token_id=token_id, uri=[0, 0, 0]), ADMIN)
    assert (await set_contract.tokenURI_(token_id=token_id).call()).result.uri == [0, 0, 0]
    await invoke_set(set_contract.setTokenURI_(token_id=token_id, uri=[0x1, 0]), ADMIN)
    assert (await set_contract.tokenURI_(token_id=token_id).call()).result.uri == [0x1, 0]
    await invoke_set(set_contract.setTokenURI_(token_id=token_id, uri=[0x1, 0, 0, 0]), ADMIN)
    assert (await set_contract.tokenURI_(token_id=token_id).call()).result.uri == [0x1, 0, 0, 0]

    # Need to keep the two LSBs free.
    await invoke_set(set_contract.setTokenURI_(token_id=token_id, uri=[2**248]), ADMIN)
    await invoke_set(set_contract.setTokenURI_(token_id=token_id, uri=[2**249 - 1]), ADMIN)
    with pytest.raises(StarkException):
        await invoke_set(set_contract.setTokenURI_(token_id=token_id, uri=[2**249]), ADMIN)
    with pytest.raises(StarkException):
        await invoke_set(set_contract.setTokenURI_(token_id=token_id, uri=[1, 2, 3, 2**249, 4]), ADMIN)

@pytest.mark.asyncio
async def disabled_test_token_uri_realms(briq_contract, set_contract):
    await invoke_briq(briq_contract.mintFT(owner=ADDRESS, material=2, qty=50))
    await invoke_set(set_contract.assemble_(owner=ADDRESS, token_id_hint=0x1, name=[0x12], description=[0x34], fts=[(1, 10)], nfts=[], uri=[int.from_bytes('1234'.encode('ascii'), 'big')]))
    await invoke_set(set_contract.assemble_(owner=ADDRESS, token_id_hint=0x2, name=[0x12], description=[0x34], fts=[(2, 10)], nfts=[], uri=[int.from_bytes('1234'.encode('ascii'), 'big')]))
    await invoke_set(set_contract.assemble_(owner=ADDRESS, token_id_hint=0x3, name=[0x12], description=[0x34], fts=[(1, 5), (2, 10)], nfts=[], uri=[int.from_bytes('1234'.encode('ascii'), 'big')]))
    token_id_1 = hash_token_id(ADDRESS, 0x1, uri=[1234])
    token_id_2 = hash_token_id(ADDRESS, 0x2, uri=[1234])
    token_id_3 = hash_token_id(ADDRESS, 0x3, uri=[1234])

    res = (await set_contract.tokenURIData_(token_id=token_id_1).call()).result.uri
    assert ''.join([x.to_bytes(math.ceil(x.bit_length() / 8), 'big').decode('ascii') for x in res]
        ) == 'data:application/json,{ "metadata": "1234", "attributes": [{"trait_type": "Realms", "value": "no"}]}'

    res = (await set_contract.tokenURIData_(token_id=token_id_2).call()).result.uri
    assert ''.join([x.to_bytes(math.ceil(x.bit_length() / 8), 'big').decode('ascii') for x in res]
        ) == 'data:application/json,{ "metadata": "1234", "attributes": [{"trait_type": "Realms", "value": "yes"}]}'

    res = (await set_contract.tokenURIData_(token_id=token_id_3).call()).result.uri
    assert ''.join([x.to_bytes(math.ceil(x.bit_length() / 8), 'big').decode('ascii') for x in res]
        ) == 'data:application/json,{ "metadata": "1234", "attributes": [{"trait_type": "Realms", "value": "no"}]}'


@pytest.mark.asyncio
async def test_events(starknet, set_contract):
    tok_id_1 = hash_token_id(ADDRESS, 0x1, uri=[])

    tok_id_1_as_uint = [tok_id_1 & (2**128 - 1), tok_id_1 >> 128]

    await invoke_set(set_contract.assemble_(owner=ADDRESS, token_id_hint=0x1, name=[0x12], description=[0x34], fts=[(1, 10)], nfts=[], shape=[], attributes=[]))
    #await invoke_set(set_contract.setTokenURI_(token_id=tok_id_1, uri=[4321]), ADMIN)
    await invoke_set(set_contract.transferFrom_(sender=ADDRESS, recipient=OTHER_ADDRESS, token_id=tok_id_1))
    await invoke_set(set_contract.disassemble_(owner=OTHER_ADDRESS, token_id=tok_id_1, fts=[(1, 10)], nfts=[], attributes=[]), OTHER_ADDRESS)

    events = starknet.state.events

    assert set_contract.event_manager._selector_to_name[events[1].keys[0]] == 'Transfer'
    assert events[1].data == [0, ADDRESS, *tok_id_1_as_uint]
    assert set_contract.event_manager._selector_to_name[events[2].keys[0]] == 'URI'
    assert (''.join([x.to_bytes(math.ceil(x.bit_length() / 8), 'big').decode('ascii') for x in events[2].data[1:-2]])) == f"https://api.briq.construction/v1/uri/set/starknet-mainnet/{int(tok_id_1)}.json"
    assert events[2].data[-2:] == tok_id_1_as_uint
    assert set_contract.event_manager._selector_to_name[events[4].keys[0]] == 'Transfer'
    assert events[4].data == [ADDRESS, OTHER_ADDRESS, *tok_id_1_as_uint]
    assert set_contract.event_manager._selector_to_name[events[5].keys[0]] == 'Transfer'
    assert events[5].data == [OTHER_ADDRESS, 0, *tok_id_1_as_uint]


@pytest.mark.asyncio
async def test_approval(set_contract):
    tok_id_1 = hash_token_id(ADDRESS, 0x1, uri=[])
    await set_contract.assemble_(owner=ADDRESS, token_id_hint=0x1, name=[0x12], description=[0x34], fts=[(1, 10)], nfts=[], shape=[], attributes=[]).execute(ADDRESS)
    await set_contract.setApprovalForAll_(OTHER_ADDRESS, 1).execute(ADDRESS)
    await set_contract.approve_(THIRD_ADDRESS, tok_id_1).execute(OTHER_ADDRESS)
    assert (await set_contract.isApprovedForAll_(ADDRESS, OTHER_ADDRESS).call()).result.is_approved == 1
    assert (await set_contract.getApproved_(tok_id_1).call()).result.approved == THIRD_ADDRESS

    await set_contract.transferFrom_(sender=ADDRESS, recipient=OTHER_ADDRESS, token_id=tok_id_1).execute(THIRD_ADDRESS)
    assert (await set_contract.isApprovedForAll_(ADDRESS, OTHER_ADDRESS).call()).result.is_approved == 1
    assert (await set_contract.getApproved_(tok_id_1).call()).result.approved == 0

    await set_contract.transferFrom_(sender=OTHER_ADDRESS, recipient=ADDRESS, token_id=tok_id_1).execute(OTHER_ADDRESS)
    assert (await set_contract.isApprovedForAll_(ADDRESS, OTHER_ADDRESS).call()).result.is_approved == 1

    with pytest.raises(StarkException):
        await set_contract.transferFrom_(sender=OTHER_ADDRESS, recipient=ADDRESS, token_id=tok_id_1).execute(THIRD_ADDRESS)

    await set_contract.transferFrom_(sender=ADDRESS, recipient=OTHER_ADDRESS, token_id=tok_id_1).execute(OTHER_ADDRESS)
    assert (await set_contract.isApprovedForAll_(ADDRESS, OTHER_ADDRESS).call()).result.is_approved == 1

    with pytest.raises(StarkException):
        await set_contract.transferFrom_(sender=OTHER_ADDRESS, recipient=ADDRESS, token_id=tok_id_1).execute(ADDRESS)
