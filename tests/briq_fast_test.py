import os
import pytest

from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "../contracts/briq.cairo")

SET_CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "../contracts/set.cairo")

@pytest.mark.asyncio
@pytest.fixture
async def contract():
    # Create a new Starknet class that simulates the StarkNet
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(CONTRACT_FILE)

@pytest.mark.asyncio
async def test_micro(contract):
    await contract.mint(owner=0x11, token_id=0x123, material=1).invoke()
    assert await contract.tokens_at_index(owner=0x11, index=0).call() == ()