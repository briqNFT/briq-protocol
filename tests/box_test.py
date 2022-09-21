from collections import namedtuple
import os
from typing import Tuple
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.starknet import StarknetContract
from starkware.starkware_utils.error_handling import StarkException

from .conftest import declare_and_deploy, proxy_contract

@pytest_asyncio.fixture(scope="session")
async def factory_root():
    starknet = await Starknet.empty()
    [box_contract, _] = await declare_and_deploy(starknet, "box_nft.cairo")
    return (starknet, box_contract)

@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, box_contract] = factory_root
    state = Starknet(state=starknet.state.copy())
    return namedtuple('State', ['starknet', 'box_contract'])(
        starknet=state,
        box_contract=proxy_contract(state, box_contract),
    )

@pytest.mark.asyncio
async def test_view(factory):
    assert (await factory.box_contract.get_box_data(0x1).call()).result.data == factory.box_contract.BoxData(54, 0, 0, 0, 0, 0xcafe)
    assert (await factory.box_contract.get_box_data(0x2).call()).result.data == factory.box_contract.BoxData(20, 10, 0, 0, 0, 0xdead)
    #with pytest.raises(StarkException):
    # TODO: this now returns random garbage.
    #    await factory.box_contract.get_box_data(0x3).call()
