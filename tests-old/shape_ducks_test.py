from collections import namedtuple
import os
from types import SimpleNamespace
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.business_logic.state.state_api_objects import BlockInfo

from .conftest import declare, declare_and_deploy, proxy_contract, compile

ADDRESS = 0xcafe
OTHER_ADDRESS = 0xfade
DISALLOWED_ADDRESS = 0xdead


@pytest_asyncio.fixture(scope="session")
async def factory_root():
    starknet = await Starknet.empty()

    [shapes, _] = await declare_and_deploy(starknet, "shape/shape_store_ducks.cairo")

    return (starknet, shapes)


@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, shapes] = factory_root
    state = Starknet(state=starknet.state.copy())
    return SimpleNamespace(
        starknet=state,
        shapes=proxy_contract(state, shapes),
    )


@pytest.mark.asyncio
async def test_bids(factory):
    assert (await factory.shapes.get_local_index_(2 * 2**192 + 3).call()).result.res == 0
