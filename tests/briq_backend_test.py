import os
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException


from starkware.starknet.compiler.compile import compile_starknet_files

CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")


def compile(path):
    return compile_starknet_files(
        files=[os.path.join(CONTRACT_SRC, path)],
        debug_info=True
    )

@pytest.fixture(scope="session")
def compiled_briq():
    return compile("briq_backend.cairo")

@pytest_asyncio.fixture
async def starknet():
    # Create a new Starknet class that simulates the StarkNet
    return await Starknet.empty()

@pytest_asyncio.fixture
async def briq_backend(starknet, compiled_briq):
    return await starknet.deploy(contract_def=compiled_briq)

@pytest.mark.asyncio
async def test_minting_and_querying(briq_backend):
    await briq_backend.mintFT(owner=0x11, material=1, qty=50).invoke()
    assert (await briq_backend.balanceOf(owner = 0x11, material = 1).call()).result.balance == 50
    assert (await briq_backend.balanceDetailsOf(owner = 0x11, material = 1).call()).result.ft_balance == 50
    assert (await briq_backend.balanceDetailsOf(owner = 0x11, material = 1).call()).result.nft_ids == []
    assert (await briq_backend.totalSupply(material = 1).call()).result.supply == 50

    await briq_backend.mintFT(owner=0x11, material=1, qty=150).invoke()
    await briq_backend.mintFT(owner=0x11, material=2, qty=50).invoke()
    await briq_backend.mintFT(owner=0x12, material=1, qty=50).invoke()

    assert (await briq_backend.balanceOf(owner = 0x11, material = 1).call()).result.balance == 200
    assert (await briq_backend.balanceOf(owner = 0x11, material = 2).call()).result.balance == 50
    assert (await briq_backend.balanceDetailsOf(owner = 0x11, material = 1).call()).result.ft_balance == 200
    assert (await briq_backend.totalSupply(material = 1).call()).result.supply == 250

    assert (await briq_backend.balanceOf(owner = 0x12, material = 1).call()).result.balance == 50
    assert (await briq_backend.balanceDetailsOf(owner = 0x12, material = 1).call()).result.ft_balance == 50

    await briq_backend.mintOneNFT(owner=0x13, material=3, uid=0x1).invoke()
    assert (await briq_backend.ownerOf(1 * 2**64 + 3).call()).result.owner == 0x13
    assert (await briq_backend.balanceDetailsOf(owner = 0x13, material = 3).call()).result.nft_ids == [2**64 + 3]
    assert (await briq_backend.balanceOf(owner = 0x13, material = 3).call()).result.balance == 1
    assert (await briq_backend.totalSupply(material = 3).call()).result.supply == 1

    await briq_backend.mintOneNFT(owner=0x11, material=1, uid=0x5).invoke()
    await briq_backend.mintOneNFT(owner=0x11, material=1, uid=0x2).invoke()
    assert (await briq_backend.balanceOf(owner=0x11, material=1).call()).result.balance == 202
    assert (await briq_backend.balanceDetailsOf(owner = 0x11, material = 1).call()).result.ft_balance == 200
    assert (await briq_backend.balanceDetailsOf(owner = 0x11, material = 1).call()).result.nft_ids == [5 * 2**64 + 1, 2 * 2**64 + 1]
    assert (await briq_backend.totalSupply(material = 1).call()).result.supply == 252
    assert (await briq_backend.ownerOf(5 * 2**64 + 1).call()).result.owner == 0x11
    assert (await briq_backend.ownerOf(2 * 2**64 + 1).call()).result.owner == 0x11

    with pytest.raises(StarkException):
        await briq_backend.mintOneNFT(owner=0x11, material=1, uid=0x2).invoke()
    with pytest.raises(StarkException):
        await briq_backend.mintOneNFT(owner=0x12, material=1, uid=0x2).invoke()

@pytest.mark.asyncio
async def test_transfer_ft(briq_backend):
    await briq_backend.mintOneNFT(owner=0x11, material=1, uid=0x1).invoke()
    await briq_backend.mintFT(owner=0x11, material=1, qty=50).invoke()
    await briq_backend.mintOneNFT(owner=0x11, material=1, uid=0x2).invoke()
    await briq_backend.transferFT(sender=0x11, recipient=0x12, material=1, qty=25).invoke()
    assert (await briq_backend.balanceOf(owner=0x11, material=1).call()).result.balance == 27
    assert (await briq_backend.balanceOf(owner=0x12, material=1).call()).result.balance == 25
    assert (await briq_backend.balanceDetailsOf(owner=0x11, material=1).call()).result.nft_ids == [1 * 2**64 + 1, 2 * 2**64 + 1]
    assert (await briq_backend.balanceDetailsOf(owner=0x11, material=1).call()).result.ft_balance == 25
    assert (await briq_backend.balanceDetailsOf(owner=0x12, material=1).call()).result.ft_balance == 25
    await briq_backend.transferFT(sender=0x11, recipient=0x12, material=1, qty=25).invoke()
    assert (await briq_backend.balanceOf(owner=0x11, material=1).call()).result.balance == 2
    assert (await briq_backend.balanceOf(owner=0x12, material=1).call()).result.balance == 50
    assert (await briq_backend.balanceDetailsOf(owner=0x11, material=1).call()).result.nft_ids == [1 * 2**64 + 1, 2 * 2**64 + 1]
    assert (await briq_backend.balanceDetailsOf(owner=0x11, material=1).call()).result.ft_balance == 0
    assert (await briq_backend.balanceDetailsOf(owner=0x12, material=1).call()).result.ft_balance == 50

@pytest.mark.asyncio
async def test_transfer_nft(briq_backend):
    await briq_backend.mintOneNFT(owner=0x11, material=1, uid=0x1).invoke()
    await briq_backend.mintOneNFT(owner=0x11, material=1, uid=0x2).invoke()
    await briq_backend.mintOneNFT(owner=0x11, material=1, uid=0x3).invoke()
    assert (await briq_backend.totalSupply(material=1).call()).result.supply == 3

    await briq_backend.transferOneNFT(sender=0x11, recipient=0x12, material=1, briq_token_id=2 * 2**64 + 1).invoke()
    assert (await briq_backend.balanceOf(owner=0x11, material=1).call()).result.balance == 2
    assert (await briq_backend.balanceOf(owner=0x12, material=1).call()).result.balance == 1
    assert (await briq_backend.balanceDetailsOf(owner=0x11, material=1).call()).result.nft_ids == [1 * 2**64 + 1, 3 * 2**64 + 1]
    assert (await briq_backend.balanceDetailsOf(owner=0x12, material=1).call()).result.nft_ids == [2 * 2**64 + 1]
    assert (await briq_backend.ownerOf(1 * 2**64 + 1).call()).result.owner == 0x11
    assert (await briq_backend.ownerOf(2 * 2**64 + 1).call()).result.owner == 0x12
    assert (await briq_backend.ownerOf(3 * 2**64 + 1).call()).result.owner == 0x11

    await briq_backend.transferOneNFT(sender=0x11, recipient=0x12, material=1, briq_token_id=3 * 2**64 + 1).invoke()
    assert (await briq_backend.balanceDetailsOf(owner=0x11, material=1).call()).result.nft_ids == [1 * 2**64 + 1]
    assert (await briq_backend.balanceDetailsOf(owner=0x12, material=1).call()).result.nft_ids == [2 * 2**64 + 1, 3 * 2**64 + 1]
    await briq_backend.transferOneNFT(sender=0x11, recipient=0x12, material=1, briq_token_id=1 * 2**64 + 1).invoke()
    assert (await briq_backend.balanceOf(owner=0x11, material=1).call()).result.balance == 0
    assert (await briq_backend.balanceOf(owner=0x12, material=1).call()).result.balance == 3
    assert (await briq_backend.balanceDetailsOf(owner=0x11, material=1).call()).result.nft_ids == []
    assert (await briq_backend.balanceDetailsOf(owner=0x12, material=1).call()).result.nft_ids == [2 * 2**64 + 1, 3 * 2**64 + 1, 1 * 2**64 + 1]
    assert (await briq_backend.ownerOf(1 * 2**64 + 1).call()).result.owner == 0x12
    assert (await briq_backend.ownerOf(2 * 2**64 + 1).call()).result.owner == 0x12
    assert (await briq_backend.ownerOf(3 * 2**64 + 1).call()).result.owner == 0x12

@pytest.mark.asyncio
async def test_mutate(briq_backend):
    await briq_backend.mintOneNFT(owner=0x11, material=1, uid=0x1).invoke()
    await briq_backend.mintOneNFT(owner=0x11, material=1, uid=0x2).invoke()
    await briq_backend.mintOneNFT(owner=0x11, material=1, uid=0x3).invoke()
    assert (await briq_backend.totalSupply(material=1).call()).result.supply == 3

    await briq_backend.mutateOneNFT(owner=0x11, source_material=1, target_material=2, uid=0x1, new_uid=0x1).invoke()
    assert (await briq_backend.totalSupply(material=1).call()).result.supply == 2
    assert (await briq_backend.totalSupply(material=2).call()).result.supply == 1
    assert (await briq_backend.balanceDetailsOf(owner=0x11, material=1).call()).result.nft_ids == [3 * 2**64 + 1, 2 * 2**64 + 1]
    assert (await briq_backend.balanceDetailsOf(owner=0x11, material=2).call()).result.nft_ids == [1 * 2**64 + 2]

    await briq_backend.mutateOneNFT(owner=0x11, source_material=1, target_material=2, uid=0x2, new_uid=0x5).invoke()
    await briq_backend.mutateOneNFT(owner=0x11, source_material=1, target_material=2, uid=0x3, new_uid=0x3).invoke()
    assert (await briq_backend.totalSupply(material=1).call()).result.supply == 0
    assert (await briq_backend.totalSupply(material=2).call()).result.supply == 3
    assert (await briq_backend.balanceDetailsOf(owner=0x11, material=1).call()).result.nft_ids == []
    assert (await briq_backend.balanceDetailsOf(owner=0x11, material=2).call()).result.nft_ids == [1 * 2**64 + 2, 5 * 2**64 + 2, 3 * 2**64 + 2]

    assert (await briq_backend.ownerOf(1 * 2**64 + 1).call()).result.owner == 0
    assert (await briq_backend.ownerOf(2 * 2**64 + 1).call()).result.owner == 0
    assert (await briq_backend.ownerOf(3 * 2**64 + 1).call()).result.owner == 0
    
    assert (await briq_backend.ownerOf(1 * 2**64 + 2).call()).result.owner == 0x11
    assert (await briq_backend.ownerOf(3 * 2**64 + 2).call()).result.owner == 0x11
    assert (await briq_backend.ownerOf(5 * 2**64 + 2).call()).result.owner == 0x11

    with pytest.raises(StarkException):
        await briq_backend.mutateOneNFT(owner=0x11, source_material=2, target_material=2, uid=0x3, new_uid=0x3).invoke()
    with pytest.raises(StarkException):
        await briq_backend.mutateOneNFT(owner=0x11, source_material=1, target_material=2, uid=0x3, new_uid=0x3).invoke()
    with pytest.raises(StarkException):
        await briq_backend.mutateOneNFT(owner=0x11, source_material=1, target_material=2, uid=0x34, new_uid=0x3).invoke()
    with pytest.raises(StarkException):
        await briq_backend.mutateOneNFT(owner=0x12, source_material=2, target_material=3, uid=0x3, new_uid=0x3).invoke()
    with pytest.raises(StarkException):
        await briq_backend.mutateOneNFT(owner=0x11, source_material=2, target_material=3, uid=0x3, new_uid=0x5).invoke()
        await briq_backend.mutateOneNFT(owner=0x11, source_material=2, target_material=3, uid=0x5, new_uid=0x5).invoke()

    await briq_backend.mintFT(owner=0x11, material=1, qty=100).invoke()
    assert (await briq_backend.totalSupply(material=1).call()).result.supply == 100
    await briq_backend.mutateFT(owner=0x11, source_material=1, target_material=2, qty=50).invoke()
    assert (await briq_backend.totalSupply(material=1).call()).result.supply == 50
    assert (await briq_backend.totalSupply(material=2).call()).result.supply == 52
    assert (await briq_backend.balanceOf(owner=0x11, material=1).call()).result.balance == 50
    assert (await briq_backend.balanceOf(owner=0x11, material=2).call()).result.balance == 52
    await briq_backend.mutateFT(owner=0x11, source_material=1, target_material=2, qty=50).invoke()
    assert (await briq_backend.totalSupply(material=1).call()).result.supply == 0
    assert (await briq_backend.totalSupply(material=2).call()).result.supply == 102
    assert (await briq_backend.balanceOf(owner=0x11, material=1).call()).result.balance == 0
    assert (await briq_backend.balanceOf(owner=0x11, material=2).call()).result.balance == 102

    with pytest.raises(StarkException):
        await briq_backend.mutateFT(owner=0x11, source_material=2, target_material=3, qty=0).invoke()
    with pytest.raises(StarkException):
        await briq_backend.mutateFT(owner=0x11, source_material=2, target_material=2, qty=5).invoke()
    with pytest.raises(StarkException):
        await briq_backend.mutateFT(owner=0x11, source_material=1, target_material=2, qty=5).invoke()
    with pytest.raises(StarkException):
        await briq_backend.mutateFT(owner=0x12, source_material=2, target_material=3, qty=5).invoke()
