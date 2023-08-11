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

    [auction_contract, _] = await declare_and_deploy(starknet, "auction_onchain.cairo")
    data_hash = await declare(starknet, "auction_onchain/data_test.cairo")
    await auction_contract.setDataHash_(data_hash).execute()

    erc20 = compile("vendor/openzeppelin/token/erc20/presets/ERC20Mintable.cairo")
    await starknet.declare(contract_class=erc20)
    token_contract_eth = await starknet.deploy(contract_class=erc20, constructor_calldata=[
        0x1,  # name: felt,
        0x1,  # symbol: felt,
        18,  # decimals: felt,
        0, 2 * 64,  # initial_supply: Uint256,
        ADDRESS,  # recipient: felt,
        ADDRESS  # owner: felt
    ])
    await token_contract_eth.transfer(OTHER_ADDRESS, (100000, 0)).execute(ADDRESS)

    await auction_contract.setPaymentAddress_(token_contract_eth.contract_address).execute()

    starknet.state.state.update_block_info(
        BlockInfo.create_for_testing(
            block_number=3,
            block_timestamp=150
        )
    )

    return (starknet, auction_contract, token_contract_eth)


@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, auction_contract, token_contract_eth] = factory_root
    state = Starknet(state=starknet.state.copy())
    return SimpleNamespace(
        starknet=state,
        auction_contract=proxy_contract(state, auction_contract),
        token_contract_eth=proxy_contract(state, token_contract_eth),
    )


@pytest.mark.asyncio
async def test_bids(factory):
    await factory.token_contract_eth.approve(factory.auction_contract.contract_address, (50000, 0)).execute(ADDRESS)

    await factory.auction_contract.make_bids([2, 3, 6], [2000, 2000, 2000]).execute(ADDRESS)
    await factory.auction_contract.make_bids([4, 5], [2000, 2000]).execute(ADDRESS)
    await factory.auction_contract.make_bids([2, 3, 6, 4, 5], [2050, 2050, 2050, 2050, 2050]).execute(ADDRESS)

    await factory.auction_contract.make_bids([1], [6464]).execute(ADDRESS)

    with pytest.raises(StarkException):
        await factory.auction_contract.make_bids([], []).execute(ADDRESS)

    with pytest.raises(StarkException):
        await factory.auction_contract.make_bids([1, 2], [432]).execute(ADDRESS)
    with pytest.raises(StarkException):
        await factory.auction_contract.make_bids([1, 2], [432, 742, 924]).execute(ADDRESS)
    with pytest.raises(StarkException):
        await factory.auction_contract.make_bids([1], []).execute(ADDRESS)

    with pytest.raises(StarkException):
        await factory.auction_contract.make_bids([2], [1000]).execute(ADDRESS)
    with pytest.raises(StarkException):
        await factory.auction_contract.make_bids([2, 20], [3000, 3000]).execute(ADDRESS)


@pytest.mark.asyncio
async def test_self_overbid(factory):
    await factory.token_contract_eth.approve(factory.auction_contract.contract_address, (500000, 0)).execute(OTHER_ADDRESS)

    await factory.auction_contract.make_bids([1], [20000]).execute(OTHER_ADDRESS)
    # Re-bid higher
    await factory.auction_contract.make_bids([1], [70000]).execute(OTHER_ADDRESS)
    # Here you'll re-bid more than you have in your balance ATM.
    await factory.auction_contract.make_bids([1], [90000]).execute(OTHER_ADDRESS)


@pytest.mark.asyncio
async def test_whitelist(factory):
    await factory.token_contract_eth.approve(factory.auction_contract.contract_address, (50000, 0)).execute(ADDRESS)
    await factory.token_contract_eth.approve(factory.auction_contract.contract_address, (50000, 0)).execute(DISALLOWED_ADDRESS)

    await factory.auction_contract.make_bids([1], [20000]).execute(ADDRESS)
    with pytest.raises(StarkException, match="Caller is not in the allow list"):
        await factory.auction_contract.make_bids([1], [20000]).execute(DISALLOWED_ADDRESS)


@pytest.mark.asyncio
async def test_single_bids_1(factory):
    await factory.token_contract_eth.approve(factory.auction_contract.contract_address, (50000, 0)).execute(ADDRESS)
    await factory.auction_contract.make_bids([2, 3, 6], [2000, 2000, 2000]).execute(ADDRESS)

    await factory.auction_contract.make_bid(4, 2500).execute(ADDRESS)
    await factory.auction_contract.make_bid(5, 2500).execute(ADDRESS)

    # Fails: too low
    with pytest.raises(StarkException):
        await factory.auction_contract.make_bid(6, 1500).execute(ADDRESS)
    await factory.auction_contract.make_bid(6, 2500).execute(ADDRESS)


@pytest.mark.asyncio
async def test_single_bids_2(factory):
    await factory.token_contract_eth.approve(factory.auction_contract.contract_address, (50000, 0)).execute(ADDRESS)
    await factory.auction_contract.make_bid(4, 2500).execute(ADDRESS)
    await factory.auction_contract.make_bid(5, 2500).execute(ADDRESS)
    await factory.auction_contract.make_bid(4, 4000).execute(ADDRESS)


@pytest.mark.asyncio
async def test_bids_amounts(factory):
    await factory.token_contract_eth.approve(factory.auction_contract.contract_address, (50000, 0)).execute(ADDRESS)
    await factory.token_contract_eth.approve(factory.auction_contract.contract_address, (50000, 0)).execute(OTHER_ADDRESS)

    assert (await factory.token_contract_eth.balanceOf(ADDRESS).call()).result.balance == (2**128-100000, 127)
    assert (await factory.token_contract_eth.balanceOf(OTHER_ADDRESS).call()).result.balance == (100000, 0)

    # Fail: bid too low compared to minimum
    with pytest.raises(StarkException):
        await factory.auction_contract.make_bids([1], [1000]).execute(ADDRESS)

    await factory.auction_contract.make_bids([1, 2, 3], [2000, 1500, 2000]).execute(ADDRESS)

    # Warning -> order is different on purpose
    await factory.auction_contract.make_bids([4, 1, 2], [3000, 3000, 2000]).execute(OTHER_ADDRESS)

    await factory.auction_contract.make_bids([4, 1, 2], [3500, 3500, 2500]).execute(OTHER_ADDRESS)

    await factory.auction_contract.make_bids([2], [5000]).execute(ADDRESS)

    # Doesn't exist in test, fails
    with pytest.raises(StarkException):
        await factory.auction_contract.make_bids([20], [5000]).execute(ADDRESS)

    # Fail: bid too low compared to existing
    with pytest.raises(StarkException):
        await factory.auction_contract.make_bids([2], [4000]).execute(OTHER_ADDRESS)
    with pytest.raises(StarkException):
        await factory.auction_contract.make_bids([2], [5001]).execute(OTHER_ADDRESS)
    await factory.auction_contract.make_bids([2], [5050]).execute(OTHER_ADDRESS)

    # For Address, only the bid for token 3 remains.
    assert (await factory.token_contract_eth.balanceOf(ADDRESS).call()).result.balance == (2**128 - 100000 - 2000, 127)
    # For other, bids for 1-2-4
    assert (await factory.token_contract_eth.balanceOf(OTHER_ADDRESS).call()).result.balance == (100000 - 5050 - 3500 - 3500, 0)


@pytest.mark.asyncio
async def test_settlement(factory):
    await factory.token_contract_eth.approve(factory.auction_contract.contract_address, (50000, 0)).execute(ADDRESS)
    await factory.token_contract_eth.approve(factory.auction_contract.contract_address, (50000, 0)).execute(OTHER_ADDRESS)

    await factory.auction_contract.make_bids([1, 2], [2000, 2000]).execute(ADDRESS)
    await factory.auction_contract.make_bids([3, 2], [2000, 2500]).execute(OTHER_ADDRESS)

    [set_mock, _] = await declare_and_deploy(factory.starknet, "mocks/set_mock.cairo")
    await factory.auction_contract.setSetAddress_(set_mock.contract_address).execute()

    # mint
    await set_mock.transferFrom_(0, factory.auction_contract.contract_address, 1).execute()
    await set_mock.transferFrom_(0, factory.auction_contract.contract_address, 2).execute()

    # Fails, auction isn't done.
    with pytest.raises(StarkException):
        await factory.auction_contract.settle_auctions([1, 2, 3]).execute()

    factory.starknet.state.state.update_block_info(
        BlockInfo.create_for_testing(
            block_number=4,
            block_timestamp=250
        )
    )

    # Fails, 3 isn't minted
    with pytest.raises(StarkException):
        await factory.auction_contract.settle_auctions([1, 2, 3]).execute()

    await set_mock.transferFrom_(0, factory.auction_contract.contract_address, 3).execute()
    await set_mock.transferFrom_(0, factory.auction_contract.contract_address, 4).execute()

    await factory.auction_contract.settle_auctions([1, 2, 3]).execute()

    assert (await set_mock.ownerOf_(1).call()).result.owner == ADDRESS
    assert (await set_mock.ownerOf_(2).call()).result.owner == OTHER_ADDRESS
    assert (await set_mock.ownerOf_(3).call()).result.owner == OTHER_ADDRESS
    assert (await set_mock.ownerOf_(4).call()).result.owner == factory.auction_contract.contract_address
