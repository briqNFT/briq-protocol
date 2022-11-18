from collections import namedtuple
import os
from typing import Tuple
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.starknet import StarknetContract
from starkware.starkware_utils.error_handling import StarkException
from starkware.cairo.lang.cairo_constants import DEFAULT_PRIME

from .conftest import declare_and_deploy, proxy_contract

@pytest_asyncio.fixture(scope="session")
async def factory_root():
    starknet = await Starknet.empty()
    [uint_contract, _] = await declare_and_deploy(starknet, "mocks/uint256.cairo")
    return (starknet, uint_contract)

@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, uint_contract] = factory_root
    state = Starknet(state=starknet.state.copy())
    return namedtuple('State', ['starknet', 'uint_contract'])(
        starknet=state,
        uint_contract=proxy_contract(state, uint_contract),
    )

@pytest.mark.asyncio
async def test_felt_to_uint(factory):
    assert (await factory.uint_contract.felt_to_uint(0).call()).result.value == (0, 0)
    assert (await factory.uint_contract.felt_to_uint(1).call()).result.value == (1, 0)
    assert (await factory.uint_contract.felt_to_uint(375982173598).call()).result.value == (375982173598, 0)
    assert (await factory.uint_contract.felt_to_uint(32543 * 2**128 + 8237958273).call()).result.value == (8237958273, 32543)
    assert (await factory.uint_contract.felt_to_uint(3950912359 * 2**128 + 3985109375).call()).result.value == (3985109375, 3950912359)
    assert (await factory.uint_contract.felt_to_uint(DEFAULT_PRIME - 1).call()).result.value == (0, 0x8000000000000110000000000000000)
    with pytest.raises(ValueError):
        assert (await factory.uint_contract.felt_to_uint(DEFAULT_PRIME).call()).result.value


@pytest.mark.asyncio
async def test_felts_to_uints(factory):
    assert (await factory.uint_contract.felts_to_uints([]).call()).result.value == []
    assert (await factory.uint_contract.felts_to_uints([123]).call()).result.value == [(123, 0)]
    assert (await factory.uint_contract.felts_to_uints([0, 1, 375982173598, 32543 * 2**128 + 8237958273, 3950912359 * 2**128 + 3985109375, DEFAULT_PRIME - 1]).call()
    ).result.value == [(0, 0), (1, 0), (375982173598, 0), (8237958273, 32543), (3985109375, 3950912359), (0, 0x8000000000000110000000000000000)]

    with pytest.raises(ValueError):
        await factory.uint_contract.felts_to_uints([0, 1, 375982173598, 32543 * 2**128 + 8237958273, 3950912359 * 2**128 + 3985109375, DEFAULT_PRIME]).call()


@pytest.mark.asyncio
async def test_uint_to_felt(factory):
    assert (await factory.uint_contract.uint_to_felt((0, 0)).call()).result.value == 0
    assert (await factory.uint_contract.uint_to_felt((1, 0)).call()).result.value == 1
    assert (await factory.uint_contract.uint_to_felt((375982173598, 0)).call()).result.value == 375982173598
    assert (await factory.uint_contract.uint_to_felt((8237958273, 32543)).call()).result.value == 32543 * 2**128 + 8237958273
    assert (await factory.uint_contract.uint_to_felt((3985109375, 3950912359)).call()).result.value == 3950912359 * 2**128 + 3985109375
    assert (await factory.uint_contract.uint_to_felt((0, 0x8000000000000110000000000000000)).call()).result.value == DEFAULT_PRIME - 1
    assert (await factory.uint_contract.uint_to_felt((2**128 - 1, 0x8000000000000110000000000000000 - 1)).call()).result.value == DEFAULT_PRIME - 2
    with pytest.raises(StarkException, match='_check_uint_fits_felt'):
        assert (await factory.uint_contract.uint_to_felt((1, 0x8000000000000110000000000000000)).call()).result.value == DEFAULT_PRIME 
    with pytest.raises(StarkException):
        assert (await factory.uint_contract.uint_to_felt((0, 0x9000000000000110000000000000000)).call()).result.value
    with pytest.raises(StarkException):
        assert (await factory.uint_contract.uint_to_felt((2**128, 0)).call()).result.value
    with pytest.raises(StarkException):
        assert (await factory.uint_contract.uint_to_felt((0, 2**128)).call()).result.value


@pytest.mark.asyncio
async def test_uints_to_feltS(factory):
    assert (await factory.uint_contract.uints_to_felts([]).call()).result.value == []
    assert (await factory.uint_contract.uints_to_felts([(1, 1)]).call()).result.value == [2**128 + 1]
    assert (await factory.uint_contract.uints_to_felts([(0, 0), (1, 0), (375982173598, 0), (8237958273, 32543), (3985109375, 3950912359), (0, 0x8000000000000110000000000000000), (2**128 - 1, 0x8000000000000110000000000000000 - 1)]).call()
    ).result.value == [0, 1, 375982173598, 32543 * 2**128 + 8237958273, 3950912359 * 2**128 + 3985109375, DEFAULT_PRIME - 1, DEFAULT_PRIME - 2]

    with pytest.raises(StarkException):
        await factory.uint_contract.uints_to_felts([(0, 0), (1, 0), (1, 0x8000000000000110000000000000000), (8237958273, 32543), (3985109375, 3950912359), (0, 0x8000000000000110000000000000000), (2**128 - 1, 0x8000000000000110000000000000000 - 1)]).call()
    