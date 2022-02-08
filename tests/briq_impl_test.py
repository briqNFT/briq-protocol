import os
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException


from starkware.starknet.compiler.compile import compile_starknet_files

CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")

FAKE_BRIQ_PROXY_ADDRESS = 0xfadecafe
ADMIN = 0x0  # No proxy so no admin
ADDRESS = 0x123456
OTHER_ADDRESS = 0x654321

def compile(path):
    return compile_starknet_files(
        files=[os.path.join(CONTRACT_SRC, path)],
        debug_info=True
    )

@pytest.fixture(scope="session")
def compiled_briq():
    return compile("briq_impl.cairo")

@pytest_asyncio.fixture
async def starknet():
    # Create a new Starknet class that simulates the StarkNet
    return await Starknet.empty()

@pytest_asyncio.fixture
async def briq_contract(starknet, compiled_briq):
    briq_contract = await starknet.deploy(contract_def=compiled_briq)
    return briq_contract


def invoke_briq(call, addr=ADMIN):
    return call.invoke(caller_address=addr)


@pytest.mark.asyncio
async def test_minting_and_querying(briq_contract):
    await invoke_briq(briq_contract.mintFT(owner=ADDRESS, material=1, qty=50))
    assert (await briq_contract.balanceOf(owner=ADDRESS, material=1).call()).result.balance == 50
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.ft_balance == 50
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.nft_ids == []
    assert (await briq_contract.totalSupply(material=1).call()).result.supply == 50

    await invoke_briq(briq_contract.mintFT(owner=ADDRESS, material=1, qty=150))
    await invoke_briq(briq_contract.mintFT(owner=ADDRESS, material=2, qty=50))
    await invoke_briq(briq_contract.mintFT(owner=OTHER_ADDRESS, material=1, qty=50))

    assert (await briq_contract.balanceOf(owner=ADDRESS, material=1).call()).result.balance == 200
    assert (await briq_contract.balanceOf(owner=ADDRESS, material=2).call()).result.balance == 50
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.ft_balance == 200
    assert (await briq_contract.totalSupply(material=1).call()).result.supply == 250

    assert (await briq_contract.multiBalanceOf(owner=ADDRESS, materials=[1, 2]).call()).result.balances == [200, 50]

    assert (await briq_contract.balanceOf(owner=OTHER_ADDRESS, material=1).call()).result.balance == 50
    assert (await briq_contract.balanceDetailsOf(owner=OTHER_ADDRESS, material=1).call()).result.ft_balance == 50

    THIRD_ADDR = 0x13

    await invoke_briq(briq_contract.mintOneNFT(owner=THIRD_ADDR, material=3, uid=0x1))
    assert (await briq_contract.ownerOf(1 * 2**64 + 3).call()).result.owner == THIRD_ADDR
    assert (await briq_contract.balanceDetailsOf(owner=THIRD_ADDR, material=3).call()).result.nft_ids == [2**64 + 3]
    assert (await briq_contract.balanceOf(owner=THIRD_ADDR, material=3).call()).result.balance == 1
    assert (await briq_contract.totalSupply(material=3).call()).result.supply == 1

    await invoke_briq(briq_contract.mintOneNFT(owner=ADDRESS, material=1, uid=0x5))
    await invoke_briq(briq_contract.mintOneNFT(owner=ADDRESS, material=1, uid=0x2))
    assert (await briq_contract.balanceOf(owner=ADDRESS, material=1).call()).result.balance == 202
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.ft_balance == 200
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.nft_ids == [5 * 2**64 + 1, 2 * 2**64 + 1]
    assert (await briq_contract.totalSupply(material=1).call()).result.supply == 252
    assert (await briq_contract.ownerOf(5 * 2**64 + 1).call()).result.owner == ADDRESS
    assert (await briq_contract.ownerOf(2 * 2**64 + 1).call()).result.owner == ADDRESS

    with pytest.raises(StarkException):
        await invoke_briq(briq_contract.mintOneNFT(owner=ADDRESS, material=1, uid=0x2))
    with pytest.raises(StarkException):
        await invoke_briq(briq_contract.mintOneNFT(owner=OTHER_ADDRESS, material=1, uid=0x2), OTHER_ADDRESS)

@pytest.mark.asyncio
async def test_transfer_ft(briq_contract):
    await invoke_briq(briq_contract.mintOneNFT(owner=ADDRESS, material=1, uid=0x1))
    await invoke_briq(briq_contract.mintFT(owner=ADDRESS, material=1, qty=50))
    await invoke_briq(briq_contract.mintOneNFT(owner=ADDRESS, material=1, uid=0x2))
    await invoke_briq(briq_contract.transferFT(sender=ADDRESS, recipient=OTHER_ADDRESS, material=1, qty=25))
    assert (await briq_contract.balanceOf(owner=ADDRESS, material=1).call()).result.balance == 27
    assert (await briq_contract.balanceOf(owner=OTHER_ADDRESS, material=1).call()).result.balance == 25
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.nft_ids == [1 * 2**64 + 1, 2 * 2**64 + 1]
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.ft_balance == 25
    assert (await briq_contract.balanceDetailsOf(owner=OTHER_ADDRESS, material=1).call()).result.ft_balance == 25
    await invoke_briq(briq_contract.transferFT(sender=ADDRESS, recipient=OTHER_ADDRESS, material=1, qty=25))
    assert (await briq_contract.balanceOf(owner=ADDRESS, material=1).call()).result.balance == 2
    assert (await briq_contract.balanceOf(owner=OTHER_ADDRESS, material=1).call()).result.balance == 50
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.nft_ids == [1 * 2**64 + 1, 2 * 2**64 + 1]
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.ft_balance == 0
    assert (await briq_contract.balanceDetailsOf(owner=OTHER_ADDRESS, material=1).call()).result.ft_balance == 50

@pytest.mark.asyncio
async def test_transfer_nft(briq_contract):
    await invoke_briq(briq_contract.mintOneNFT(owner=ADDRESS, material=1, uid=0x1))
    await invoke_briq(briq_contract.mintOneNFT(owner=ADDRESS, material=1, uid=0x2))
    await invoke_briq(briq_contract.mintOneNFT(owner=ADDRESS, material=1, uid=0x3))
    assert (await briq_contract.totalSupply(material=1).call()).result.supply == 3

    await invoke_briq(briq_contract.transferOneNFT(sender=ADDRESS, recipient=OTHER_ADDRESS, material=1, briq_token_id=2 * 2**64 + 1))
    assert (await briq_contract.balanceOf(owner=ADDRESS, material=1).call()).result.balance == 2
    assert (await briq_contract.balanceOf(owner=OTHER_ADDRESS, material=1).call()).result.balance == 1
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.nft_ids == [1 * 2**64 + 1, 3 * 2**64 + 1]
    assert (await briq_contract.balanceDetailsOf(owner=OTHER_ADDRESS, material=1).call()).result.nft_ids == [2 * 2**64 + 1]
    assert (await briq_contract.ownerOf(1 * 2**64 + 1).call()).result.owner == ADDRESS
    assert (await briq_contract.ownerOf(2 * 2**64 + 1).call()).result.owner == OTHER_ADDRESS
    assert (await briq_contract.ownerOf(3 * 2**64 + 1).call()).result.owner == ADDRESS

    await invoke_briq(briq_contract.transferOneNFT(sender=ADDRESS, recipient=OTHER_ADDRESS, material=1, briq_token_id=3 * 2**64 + 1))
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.nft_ids == [1 * 2**64 + 1]
    assert (await briq_contract.balanceDetailsOf(owner=OTHER_ADDRESS, material=1).call()).result.nft_ids == [2 * 2**64 + 1, 3 * 2**64 + 1]
    await invoke_briq(briq_contract.transferOneNFT(sender=ADDRESS, recipient=OTHER_ADDRESS, material=1, briq_token_id=1 * 2**64 + 1))
    assert (await briq_contract.balanceOf(owner=ADDRESS, material=1).call()).result.balance == 0
    assert (await briq_contract.balanceOf(owner=OTHER_ADDRESS, material=1).call()).result.balance == 3
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.nft_ids == []
    assert (await briq_contract.balanceDetailsOf(owner=OTHER_ADDRESS, material=1).call()).result.nft_ids == [2 * 2**64 + 1, 3 * 2**64 + 1, 1 * 2**64 + 1]
    assert (await briq_contract.ownerOf(1 * 2**64 + 1).call()).result.owner == OTHER_ADDRESS
    assert (await briq_contract.ownerOf(2 * 2**64 + 1).call()).result.owner == OTHER_ADDRESS
    assert (await briq_contract.ownerOf(3 * 2**64 + 1).call()).result.owner == OTHER_ADDRESS

@pytest.mark.asyncio
async def test_mutate(briq_contract):
    await invoke_briq(briq_contract.mintOneNFT(owner=ADDRESS, material=1, uid=0x1))
    await invoke_briq(briq_contract.mintOneNFT(owner=ADDRESS, material=1, uid=0x2))
    await invoke_briq(briq_contract.mintOneNFT(owner=ADDRESS, material=1, uid=0x3))
    assert (await briq_contract.totalSupply(material=1).call()).result.supply == 3

    await invoke_briq(briq_contract.mutateOneNFT(owner=ADDRESS, source_material=1, target_material=2, uid=0x1, new_uid=0x1), ADMIN)
    assert (await briq_contract.totalSupply(material=1).call()).result.supply == 2
    assert (await briq_contract.totalSupply(material=2).call()).result.supply == 1
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.nft_ids == [3 * 2**64 + 1, 2 * 2**64 + 1]
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=2).call()).result.nft_ids == [1 * 2**64 + 2]

    await invoke_briq(briq_contract.mutateOneNFT(owner=ADDRESS, source_material=1, target_material=2, uid=0x2, new_uid=0x5), ADMIN)
    await invoke_briq(briq_contract.mutateOneNFT(owner=ADDRESS, source_material=1, target_material=2, uid=0x3, new_uid=0x3), ADMIN)
    assert (await briq_contract.totalSupply(material=1).call()).result.supply == 0
    assert (await briq_contract.totalSupply(material=2).call()).result.supply == 3
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.nft_ids == []
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=2).call()).result.nft_ids == [1 * 2**64 + 2, 5 * 2**64 + 2, 3 * 2**64 + 2]

    assert (await briq_contract.ownerOf(1 * 2**64 + 1).call()).result.owner == 0
    assert (await briq_contract.ownerOf(2 * 2**64 + 1).call()).result.owner == 0
    assert (await briq_contract.ownerOf(3 * 2**64 + 1).call()).result.owner == 0
    
    assert (await briq_contract.ownerOf(1 * 2**64 + 2).call()).result.owner == ADDRESS
    assert (await briq_contract.ownerOf(3 * 2**64 + 2).call()).result.owner == ADDRESS
    assert (await briq_contract.ownerOf(5 * 2**64 + 2).call()).result.owner == ADDRESS

    with pytest.raises(StarkException):
        await invoke_briq(briq_contract.mutateOneNFT(owner=ADDRESS, source_material=2, target_material=2, uid=0x3, new_uid=0x3), ADMIN)
    with pytest.raises(StarkException):
        await invoke_briq(briq_contract.mutateOneNFT(owner=ADDRESS, source_material=1, target_material=2, uid=0x3, new_uid=0x3), ADMIN)
    with pytest.raises(StarkException):
        await invoke_briq(briq_contract.mutateOneNFT(owner=ADDRESS, source_material=1, target_material=2, uid=0x34, new_uid=0x3), ADMIN)
    with pytest.raises(StarkException):
        await invoke_briq(briq_contract.mutateOneNFT(owner=OTHER_ADDRESS, source_material=2, target_material=3, uid=0x3, new_uid=0x3), OTHER_ADDRESS)
    with pytest.raises(StarkException):
        await invoke_briq(briq_contract.mutateOneNFT(owner=ADDRESS, source_material=2, target_material=3, uid=0x3, new_uid=0x5), ADMIN)
        await invoke_briq(briq_contract.mutateOneNFT(owner=ADDRESS, source_material=2, target_material=3, uid=0x5, new_uid=0x5), ADMIN)

    await invoke_briq(briq_contract.mintFT(owner=ADDRESS, material=1, qty=100))
    assert (await briq_contract.totalSupply(material=1).call()).result.supply == 100
    await invoke_briq(briq_contract.mutateFT(owner=ADDRESS, source_material=1, target_material=2, qty=50), ADMIN)
    assert (await briq_contract.totalSupply(material=1).call()).result.supply == 50
    assert (await briq_contract.totalSupply(material=2).call()).result.supply == 52
    assert (await briq_contract.balanceOf(owner=ADDRESS, material=1).call()).result.balance == 50
    assert (await briq_contract.balanceOf(owner=ADDRESS, material=2).call()).result.balance == 52
    await invoke_briq(briq_contract.mutateFT(owner=ADDRESS, source_material=1, target_material=2, qty=50), ADMIN)
    assert (await briq_contract.totalSupply(material=1).call()).result.supply == 0
    assert (await briq_contract.totalSupply(material=2).call()).result.supply == 102
    assert (await briq_contract.balanceOf(owner=ADDRESS, material=1).call()).result.balance == 0
    assert (await briq_contract.balanceOf(owner=ADDRESS, material=2).call()).result.balance == 102

    with pytest.raises(StarkException):
        await invoke_briq(briq_contract.mutateFT(owner=ADDRESS, source_material=2, target_material=3, qty=0), ADMIN)
    with pytest.raises(StarkException):
        await invoke_briq(briq_contract.mutateFT(owner=ADDRESS, source_material=2, target_material=2, qty=5), ADMIN)
    with pytest.raises(StarkException):
        await invoke_briq(briq_contract.mutateFT(owner=ADDRESS, source_material=1, target_material=2, qty=5), ADMIN)
    with pytest.raises(StarkException):
        await invoke_briq(briq_contract.mutateFT(owner=OTHER_ADDRESS, source_material=2, target_material=3, qty=5), OTHER_ADDRESS)

@pytest.mark.asyncio
async def test_convert(briq_contract):
    await invoke_briq(briq_contract.mintOneNFT(owner=ADDRESS, material=1, uid=0x1))
    await invoke_briq(briq_contract.mintOneNFT(owner=ADDRESS, material=1, uid=0x2))
    await invoke_briq(briq_contract.mintOneNFT(owner=ADDRESS, material=1, uid=0x3))
    assert (await briq_contract.totalSupply(material=1).call()).result.supply == 3

    await invoke_briq(briq_contract.convertOneToFT(owner=ADDRESS, material=1, token_id=1 * 2**64 + 1), ADMIN)
    assert (await briq_contract.totalSupply(material=1).call()).result.supply == 3
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.nft_ids == [3 * 2**64 + 1, 2 * 2**64 + 1]
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.ft_balance == 1

    await invoke_briq(briq_contract.convertOneToFT(owner=ADDRESS, material=1, token_id=2 * 2**64 + 1), ADMIN)
    await invoke_briq(briq_contract.convertOneToFT(owner=ADDRESS, material=1, token_id=3 * 2**64 + 1), ADMIN)
    assert (await briq_contract.totalSupply(material=1).call()).result.supply == 3
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.nft_ids == []
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.ft_balance == 3

    await invoke_briq(briq_contract.convertOneToNFT(owner=ADDRESS, material=1, uid=45), ADMIN)
    await invoke_briq(briq_contract.convertOneToNFT(owner=ADDRESS, material=1, uid=1), ADMIN)
    assert (await briq_contract.totalSupply(material=1).call()).result.supply == 3
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.nft_ids == [45 * 2**64 + 1, 1 * 2**64 + 1]
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.ft_balance == 1

    assert (await briq_contract.ownerOf(token_id=45 * 2**64 + 1).call()).result.owner == ADDRESS

    #await invoke_briq(briq_contract.convertOneToFT(owner=ADDRESS, material=1, token_id=1 * 2**64 + 1))
    #await invoke_briq(briq_contract.convertOneToFT(owner=ADDRESS, material=1, token_id=45 * 2**64 + 1))

    await invoke_briq(briq_contract.convertToFT(owner=ADDRESS, token_ids=[(1, 45 * 2**64 + 1), (1, 1 * 2**64 + 1)]), ADMIN)
    assert (await briq_contract.totalSupply(material=1).call()).result.supply == 3
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.nft_ids == []
    assert (await briq_contract.balanceDetailsOf(owner=ADDRESS, material=1).call()).result.ft_balance == 3

@pytest.mark.asyncio
async def test_events(starknet, briq_contract):
    await invoke_briq(briq_contract.mintFT(owner=ADDRESS, material=1, qty=50))
    await invoke_briq(briq_contract.mintOneNFT(owner=ADDRESS, material=1, uid=1))
    await invoke_briq(briq_contract.transferFT(sender=ADDRESS, recipient=OTHER_ADDRESS, material=1, qty=10))
    await invoke_briq(briq_contract.transferNFT(sender=ADDRESS, recipient=OTHER_ADDRESS, material=1, token_ids=[2**64 + 1]))
    await invoke_briq(briq_contract.mutateFT(owner=OTHER_ADDRESS, source_material=1, target_material=2, qty=5), ADMIN)
    await invoke_briq(briq_contract.mutateOneNFT(owner=OTHER_ADDRESS, source_material=1, target_material=2, uid=1, new_uid=1), ADMIN)
    await invoke_briq(briq_contract.convertOneToFT(owner=OTHER_ADDRESS, material=2, token_id=2**64 + 2), ADMIN)
    await invoke_briq(briq_contract.convertOneToNFT(owner=OTHER_ADDRESS, material=2, uid=1), ADMIN)

    events = starknet.state.events

    assert briq_contract.event_manager._selector_to_name[events[0].keys[0]] == 'TransferSingle'
    assert events[0].data == [briq_contract.contract_address, 0, ADDRESS, 1, 50]
    assert briq_contract.event_manager._selector_to_name[events[1].keys[0]] == 'TransferSingle'
    assert events[1].data == [briq_contract.contract_address, 0, ADDRESS, 1 * 2**64 + 1, 1]

    assert briq_contract.event_manager._selector_to_name[events[2].keys[0]] == 'TransferSingle'
    assert events[2].data == [briq_contract.contract_address, ADDRESS, OTHER_ADDRESS, 1, 10]
    assert briq_contract.event_manager._selector_to_name[events[3].keys[0]] == 'TransferSingle'
    assert events[3].data == [briq_contract.contract_address, ADDRESS, OTHER_ADDRESS, 1 * 2**64 + 1, 1]

    assert briq_contract.event_manager._selector_to_name[events[4].keys[0]] == 'TransferSingle'
    assert events[4].data == [briq_contract.contract_address, OTHER_ADDRESS, 0, 1, 5]
    assert briq_contract.event_manager._selector_to_name[events[5].keys[0]] == 'TransferSingle'
    assert events[5].data == [briq_contract.contract_address, 0, OTHER_ADDRESS, 2, 5]

    assert briq_contract.event_manager._selector_to_name[events[6].keys[0]] == 'TransferSingle'
    assert events[6].data == [briq_contract.contract_address, OTHER_ADDRESS, 0, 2**64 + 1, 1]
    assert briq_contract.event_manager._selector_to_name[events[7].keys[0]] == 'TransferSingle'
    assert events[7].data == [briq_contract.contract_address, 0, OTHER_ADDRESS, 2**64 + 2, 1]
    assert briq_contract.event_manager._selector_to_name[events[8].keys[0]] == 'Mutate'
    assert events[8].data == [OTHER_ADDRESS, 2**64 + 1, 2**64 + 2, 1, 2]

    assert briq_contract.event_manager._selector_to_name[events[9].keys[0]] == 'TransferSingle'
    assert events[9].data == [briq_contract.contract_address, OTHER_ADDRESS, 0, 2**64 + 2, 1]
    assert briq_contract.event_manager._selector_to_name[events[10].keys[0]] == 'TransferSingle'
    assert events[10].data == [briq_contract.contract_address, 0, OTHER_ADDRESS, 2, 1]
    assert briq_contract.event_manager._selector_to_name[events[11].keys[0]] == 'ConvertToFT'
    assert events[11].data == [OTHER_ADDRESS, 2, 2**64 + 2]

    assert briq_contract.event_manager._selector_to_name[events[12].keys[0]] == 'TransferSingle'
    assert events[12].data == [briq_contract.contract_address, OTHER_ADDRESS, 0, 2, 1]
    assert briq_contract.event_manager._selector_to_name[events[13].keys[0]] == 'TransferSingle'
    assert events[13].data == [briq_contract.contract_address, 0, OTHER_ADDRESS, 2**64 + 2, 1]
    assert briq_contract.event_manager._selector_to_name[events[14].keys[0]] == 'ConvertToNFT'
    assert events[14].data == [OTHER_ADDRESS, 2, 2**64 + 2]
