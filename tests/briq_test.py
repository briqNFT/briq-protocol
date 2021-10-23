import os
import pytest

from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "../contracts/briq.cairo")

@pytest.mark.asyncio
async def test_tokens():
    # Create a new Starknet class that simulates the StarkNet
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(CONTRACT_FILE)

    await contract.mint(owner=0x11, token_id=0x123, material=1).invoke()

    # Check the result of get_balance().
    assert await contract.owner_of(token_id=0x123).call() == (0x11,)

    await contract.mint(owner=0x11, token_id=0x124, material=1).invoke()
    assert await contract.owner_of(token_id=0x124).call() == (0x11,)
    await contract.mint(owner=0x11, token_id=0x125, material=1).invoke()
    assert await contract.owner_of(token_id=0x125).call() == (0x11,)
    assert await contract.balance_of(owner=0x11).call() == (3,)
    with pytest.raises(Exception):
        await contract.mint(owner=0x11, token_id=0x123, material=1).invoke()

    assert await contract.token_at_index(owner=0x11, index=0).call() == (0x123,)
    assert await contract.token_at_index(owner=0x11, index=1).call() == (0x124,)
    assert await contract.token_at_index(owner=0x11, index=2).call() == (0x125,)
    with pytest.raises(Exception):
        await contract.token_at_index(owner=0x11, index=3).call() 
    with pytest.raises(Exception):
        await contract.token_at_index(owner=0x73, index=0).call()
    
    assert await contract.tokens_at_index(owner=0x11, index=0).call() == ()


@pytest.mark.asyncio
async def test_illegal_material():
    # Create a new Starknet class that simulates the StarkNet
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(CONTRACT_FILE)

    with pytest.raises(Exception):
        await contract.mint(owner=0x73, token_id=0x85, material=0).invoke() 
