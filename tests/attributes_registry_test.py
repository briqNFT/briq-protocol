from collections import namedtuple
from dis import COMPILER_FLAG_NAMES
import os
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.starknet import StarknetContract
from starkware.starknet.testing.contract import StarknetContractFunctionInvocation
from starkware.starkware_utils.error_handling import StarkException

from starkware.starknet.compiler.compile import compile_starknet_files, compile_starknet_codes
from generators.generate_auction import generate_auction

from generators.shape_utils import to_shape_data, compress_shape_item

from generators.generate_box import generate_box
from tests.booklet_test import MOCK_SHAPE_TOKEN
from tests.genesis_sale_test import OTHER_ADDRESS

from .conftest import declare_and_deploy, declare, proxy_contract

ADDRESS = 0xCAFE
OTHER_ADDRESS = 0xBABA
SET_ADDRESS = 0xD00D

@pytest_asyncio.fixture(scope="module")
async def factory_root():
    starknet = await Starknet.empty()

    [attributes_registry, _] = await declare_and_deploy(starknet, "attributes_registry.cairo")
    await attributes_registry.setSetAddress_(SET_ADDRESS).execute()

    return [starknet, attributes_registry]


@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, attributes_registry] = factory_root
    state = Starknet(state=starknet.state.copy())
    return namedtuple('State', ['starknet', 'attributes_registry'])(
        state,
        proxy_contract(state, attributes_registry),
    )

@pytest.mark.asyncio
async def test_simple_attributes(factory):
    TOKEN_ID = 0x1234
    COLLECTION_ID=0x4422
    ATTRIBUTE_1 = 0x1 * 2**192 + COLLECTION_ID
    ATTRIBUTE_2 = 0xfea3 * 2**192 + COLLECTION_ID

    with pytest.raises(StarkException, match="Insufficient balance"):
        await factory.attributes_registry.assign_attribute(
            ADDRESS,
            TOKEN_ID,
            ATTRIBUTE_1,
            [],[],[]
        ).execute(SET_ADDRESS)

    await factory.attributes_registry.create_collection_(COLLECTION_ID, 0, ADDRESS).execute()
    await factory.attributes_registry.increase_attribute_balance_(ATTRIBUTE_1, 500).execute(ADDRESS)
    await factory.attributes_registry.increase_attribute_balance_(ATTRIBUTE_1, 500).execute(ADDRESS)
    with pytest.raises(StarkException, match="not authorized"):
        await factory.attributes_registry.increase_attribute_balance_(ATTRIBUTE_1, 500).execute(OTHER_ADDRESS)

    assert (await factory.attributes_registry.has_attribute(TOKEN_ID, ATTRIBUTE_1).call()).result.has_attribute == 0
    await factory.attributes_registry.assign_attribute(
        ADDRESS,
        TOKEN_ID,
        ATTRIBUTE_1,
        [],[],[]
    ).execute(SET_ADDRESS)

    assert (await factory.attributes_registry.has_attribute(TOKEN_ID, ATTRIBUTE_1).call()).result.has_attribute == 1
    assert (await factory.attributes_registry.total_balance(TOKEN_ID).call()).result.total_balance == 1

    await factory.attributes_registry.increase_attribute_balance_(ATTRIBUTE_2, 500).execute(ADDRESS)

    assert (await factory.attributes_registry.has_attribute(TOKEN_ID, ATTRIBUTE_2).call()).result.has_attribute == 0
    await factory.attributes_registry.assign_attribute(
        ADDRESS,
        TOKEN_ID,
        ATTRIBUTE_2,
        [],[],[]
    ).execute(SET_ADDRESS)

    assert (await factory.attributes_registry.has_attribute(TOKEN_ID, ATTRIBUTE_2).call()).result.has_attribute == 1
    assert (await factory.attributes_registry.total_balance(TOKEN_ID).call()).result.total_balance == 2

    await factory.attributes_registry.remove_attribute(
        ADDRESS,
        TOKEN_ID,
        ATTRIBUTE_1,
    ).execute(SET_ADDRESS)

    assert (await factory.attributes_registry.has_attribute(TOKEN_ID, ATTRIBUTE_1).call()).result.has_attribute == 0
    assert (await factory.attributes_registry.has_attribute(TOKEN_ID, ATTRIBUTE_2).call()).result.has_attribute == 1
    assert (await factory.attributes_registry.total_balance(TOKEN_ID).call()).result.total_balance == 1

    await factory.attributes_registry.remove_attribute(
        ADDRESS,
        TOKEN_ID,
        ATTRIBUTE_2,
    ).execute(SET_ADDRESS)

    assert (await factory.attributes_registry.has_attribute(TOKEN_ID, ATTRIBUTE_1).call()).result.has_attribute == 0
    assert (await factory.attributes_registry.has_attribute(TOKEN_ID, ATTRIBUTE_2).call()).result.has_attribute == 0
    assert (await factory.attributes_registry.total_balance(TOKEN_ID).call()).result.total_balance == 0


@pytest.mark.asyncio
async def test_booklet_attributes(factory):
    TOKEN_ID = 0x1234
    COLLECTION_ID=0x4422
    ATTRIBUTE_1 = 0x1 * 2**192 + COLLECTION_ID
    ATTRIBUTE_2 = 0xfea3 * 2**192 + COLLECTION_ID

    with pytest.raises(StarkException, match="Insufficient balance"):
        await factory.attributes_registry.assign_attribute(
            ADDRESS,
            TOKEN_ID,
            ATTRIBUTE_1,
            [],[],[]
        ).execute(SET_ADDRESS)

    [booklet_contract, _] = await declare_and_deploy(factory.starknet, "booklet_nft.cairo")
    shape_class_hash = await declare(factory.starknet, "mocks/shape_mock.cairo")
    await booklet_contract.setAttributesRegistryAddress_(factory.attributes_registry.contract_address).execute()
    await booklet_contract.mint_(ADDRESS, ATTRIBUTE_1, shape_class_hash).execute()

    await factory.attributes_registry.create_collection_(COLLECTION_ID, 2, booklet_contract.contract_address).execute()

    with pytest.raises(StarkException, match="Balance can only be increased on non-delegating attributes"):
        await factory.attributes_registry.increase_attribute_balance_(ATTRIBUTE_1, 500).execute(OTHER_ADDRESS)

    assert (await factory.attributes_registry.has_attribute(TOKEN_ID, ATTRIBUTE_1).call()).result.has_attribute == 0
    await factory.attributes_registry.assign_attribute(
        ADDRESS,
        TOKEN_ID,
        ATTRIBUTE_1,
        [],[],[]
    ).execute(SET_ADDRESS)

    assert (await factory.attributes_registry.has_attribute(TOKEN_ID, ATTRIBUTE_1).call()).result.has_attribute == 1
    assert (await factory.attributes_registry.total_balance(TOKEN_ID).call()).result.total_balance == 1

    assert (await factory.attributes_registry.has_attribute(TOKEN_ID, ATTRIBUTE_2).call()).result.has_attribute == 0
    with pytest.raises(StarkException, match="Class with hash 0x0 is not declared"):
        await factory.attributes_registry.assign_attribute(
            ADDRESS,
            TOKEN_ID,
            ATTRIBUTE_2,
            [],[],[]
        ).execute(SET_ADDRESS)

    await booklet_contract.mint_(OTHER_ADDRESS, ATTRIBUTE_2, shape_class_hash).execute()
    with pytest.raises(StarkException, match="Insufficient balance"):
        await factory.attributes_registry.assign_attribute(
            ADDRESS,
            TOKEN_ID,
            ATTRIBUTE_2,
            [],[],[]
        ).execute(SET_ADDRESS)

    await booklet_contract.mint_(ADDRESS, ATTRIBUTE_2, shape_class_hash).execute()

    await factory.attributes_registry.assign_attribute(
        ADDRESS,
        TOKEN_ID,
        ATTRIBUTE_2,
        [],[],[]
    ).execute(SET_ADDRESS)
    assert (await factory.attributes_registry.has_attribute(TOKEN_ID, ATTRIBUTE_2).call()).result.has_attribute == 1
    assert (await factory.attributes_registry.total_balance(TOKEN_ID).call()).result.total_balance == 2

    await factory.attributes_registry.remove_attribute(
        ADDRESS,
        TOKEN_ID,
        ATTRIBUTE_1,
    ).execute(SET_ADDRESS)

    assert (await factory.attributes_registry.has_attribute(TOKEN_ID, ATTRIBUTE_1).call()).result.has_attribute == 0
    assert (await factory.attributes_registry.has_attribute(TOKEN_ID, ATTRIBUTE_2).call()).result.has_attribute == 1
    assert (await factory.attributes_registry.total_balance(TOKEN_ID).call()).result.total_balance == 1

    await factory.attributes_registry.remove_attribute(
        ADDRESS,
        TOKEN_ID,
        ATTRIBUTE_2,
    ).execute(SET_ADDRESS)

    assert (await factory.attributes_registry.has_attribute(TOKEN_ID, ATTRIBUTE_1).call()).result.has_attribute == 0
    assert (await factory.attributes_registry.has_attribute(TOKEN_ID, ATTRIBUTE_2).call()).result.has_attribute == 0
    assert (await factory.attributes_registry.total_balance(TOKEN_ID).call()).result.total_balance == 0