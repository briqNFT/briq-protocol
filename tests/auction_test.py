from collections import namedtuple
import os
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.starknet import StarknetContract
from starkware.starknet.testing.contract import StarknetContractFunctionInvocation
from starkware.starkware_utils.error_handling import StarkException
from starkware.cairo.common.hash_state import compute_hash_on_elements
from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.business_logic.state.state_api_objects import BlockInfo

from starkware.starknet.utils.api_utils import cast_to_felts
from starkware.starknet.compiler.compile import compile_starknet_files, compile_starknet_codes
from generators.generate_auction import generate_auction

from generators.shape_utils import to_shape_data, compress_shape_item

CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")
VENDOR_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts", "vendor")

ADDRESS = 0xcafe
OTHER_ADDRESS = 0xd00d
MOCK_SHAPE_TOKEN = 0xdeadfade

def compile(path):
    return compile_starknet_files(
        files=[os.path.join(CONTRACT_SRC, path)],
        cairo_path=[CONTRACT_SRC, VENDOR_SRC],
        debug_info=True,
        disable_hint_validation=True
    )


@pytest_asyncio.fixture(scope="module")
async def factory_root(tmp_path_factory):
    starknet = await Starknet.empty()
    
    # Set starting block time.
    starknet.state.state.update_block_info(
        BlockInfo.create_for_testing(
            block_number=3,
            block_timestamp=200
            )
    )

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

    box_code = compile("box_nft.cairo")
    await starknet.declare(contract_class=box_code)
    box_contract = await starknet.deploy(contract_class=box_code)

    auction_code = generate_auction(
        box_address=box_contract.contract_address,
        erc20_address=token_contract_eth.contract_address,
        auction_data = {
        1: {
            "box_token_id": 0x5,
            "quantity": 1,
            "auction_start": 134,
            "auction_duration": 80,
            "initial_price": 0,
        },
        2: {
            "box_token_id": 0x2,
            "quantity": 2,
            "auction_start": 198,
            "auction_duration": 50,
            "initial_price": 5500,
        }
    })
    folder = tmp_path_factory.mktemp('data')
    (folder / 'contracts' / 'auction').mkdir(parents=True, exist_ok=True)
    open(folder / 'contracts' / 'auction' / 'data.cairo', "w").write(auction_code)
    auction_code = compile_starknet_files(files=[os.path.join(CONTRACT_SRC, 'auction.cairo')], disable_hint_validation=True, debug_info=True, cairo_path=[str(folder)])

    auction_impl_hash = await starknet.declare(contract_class=auction_code)
    auction_contract = await starknet.deploy(contract_class=auction_code)

    await auction_contract.setBoxAddress_(box_contract.contract_address).execute()

    return [starknet, auction_contract, box_contract, token_contract_eth]


def proxy_contract(state, contract):
    return StarknetContract(
        state=state.state,
        abi=contract.abi,
        contract_address=contract.contract_address,
        deploy_call_info=contract.deploy_call_info,
    )

@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, auction_contract, box_contract, token_contract_eth] = factory_root
    state = Starknet(state=starknet.state.copy())
    return namedtuple('State', ['starknet', 'auction_contract', 'box_contract', 'token_contract_eth'])(
        starknet=state,
        auction_contract=proxy_contract(state, auction_contract),
        box_contract=proxy_contract(state, box_contract),
        token_contract_eth=proxy_contract(state, token_contract_eth),
    )

@pytest.mark.asyncio
async def test_view(factory):
    # Reversed order but that's OK
    assert (await factory.auction_contract.get_auction_data().call()).result.data == [
        factory.auction_contract.AuctionData(box_token_id=0x2, total_supply=2, auction_start=198, auction_duration=50, initial_price=5500),
        factory.auction_contract.AuctionData(box_token_id=0x5, total_supply=1, auction_start=134, auction_duration=80, initial_price=0)
    ]
    assert (await factory.auction_contract.get_price(0).call()).result.price == 0
    assert (await factory.auction_contract.get_price(1).call()).result.price == 5500

@pytest.mark.asyncio
async def test_bid(factory):
    with pytest.raises(StarkException, match="Bid greater than allowance"):
        await factory.auction_contract.make_bid(factory.auction_contract.BidData(
            bidder=ADDRESS,
            auction_index=0,
            box_token_id=0x5,
            bid_amount=300
        )).execute(ADDRESS)

    with pytest.raises(StarkException, match="Bid must be greater than 0"):
        await factory.auction_contract.make_bid(factory.auction_contract.BidData(
            bidder=ADDRESS,
            auction_index=0,
            box_token_id=0x5,
            bid_amount=0
        )).execute(ADDRESS)

    await factory.token_contract_eth.approve(factory.auction_contract.contract_address, (500, 0)).execute(ADDRESS)

    with pytest.raises(StarkException, match="Bid greater than allowance"):
        await factory.auction_contract.make_bid(factory.auction_contract.BidData(
            bidder=ADDRESS,
            auction_index=0,
            box_token_id=0x5,
            bid_amount=600
        )).execute(ADDRESS)

    with pytest.raises(StarkException, match="box_token_id does not match auction_index"):
        await factory.auction_contract.make_bid(factory.auction_contract.BidData(
            bidder=ADDRESS,
            auction_index=1,
            box_token_id=0x5,
            bid_amount=200
        )).execute(ADDRESS)

    await factory.auction_contract.make_bid(factory.auction_contract.BidData(
        bidder=ADDRESS,
        auction_index=0,
        box_token_id=0x5,
        bid_amount=500
    )).execute(ADDRESS)

    events = factory.starknet.state.events

    assert factory.auction_contract.event_manager._selector_to_name[events[3].keys[0]] == 'Bid'
    assert events[3].data == [
        ADDRESS,
        0x5,
        500,
    ]


@pytest.mark.asyncio
async def test_direct_bid(factory):

    # Setup: mint two boxes
    await factory.box_contract.mint_(factory.auction_contract.contract_address, 0x2, 2).execute(0)

    # Failure on the ERC20 side
    with pytest.raises(StarkException, match="ERC20: insufficient allowance"):
        await factory.auction_contract.make_bid(factory.auction_contract.BidData(
            bidder=ADDRESS,
            auction_index=1,
            box_token_id=0x2,
            bid_amount=6000
        )).execute(ADDRESS)

    await factory.token_contract_eth.approve(factory.auction_contract.contract_address, (13000, 0)).execute(ADDRESS)

    #assert (await factory.token_contract_eth.allowance(ADDRESS, factory.auction_contract.contract_address).call()).result.remaining == factory.token_contract_eth.Uint256(high=0, low=13000)

    with pytest.raises(StarkException, match="Bid lower than price"):
        await factory.auction_contract.make_bid(factory.auction_contract.BidData(
            bidder=ADDRESS,
            auction_index=1,
            box_token_id=0x2,
            bid_amount=4000
        )).execute(ADDRESS)

    with pytest.raises(StarkException, match="Bid lower than price"):
        await factory.auction_contract.make_bid(factory.auction_contract.BidData(
            bidder=ADDRESS,
            auction_index=1,
            box_token_id=0x2,
            bid_amount=0
        )).execute(ADDRESS)

    with pytest.raises(StarkException, match="box_token_id does not match auction_index"):
        await factory.auction_contract.make_bid(factory.auction_contract.BidData(
            bidder=ADDRESS,
            auction_index=0,
            box_token_id=0x2,
            bid_amount=200
        )).execute(ADDRESS)

    assert (await factory.token_contract_eth.balanceOf(ADDRESS).call()).result.balance == factory.token_contract_eth.Uint256(high=128, low=0)
    assert (await factory.box_contract.balanceOf_(ADDRESS, 0x2).call()).result.balance == 0
    assert (await factory.box_contract.balanceOf_(factory.auction_contract.contract_address, 0x2).call()).result.balance == 2

    # Actually through, we are only taken the price.
    await factory.auction_contract.make_bid(factory.auction_contract.BidData(
        bidder=ADDRESS,
        auction_index=1,
        box_token_id=0x2,
        bid_amount=8000
    )).execute(ADDRESS)

    assert (await factory.token_contract_eth.balanceOf(ADDRESS).call()).result.balance == factory.token_contract_eth.Uint256(high=127, low=2**128-5500)
    assert (await factory.box_contract.balanceOf_(ADDRESS, 0x2).call()).result.balance == 1
    assert (await factory.box_contract.balanceOf_(factory.auction_contract.contract_address, 0x2).call()).result.balance == 1


    ### Now some time-related failures
    factory.starknet.state.state.update_block_info(
        BlockInfo.create_for_testing(
            block_number=3,
            block_timestamp=100
            )
    )
    with pytest.raises(StarkException, match="Bid is too early"):
        await factory.auction_contract.make_bid(factory.auction_contract.BidData(
            bidder=ADDRESS,
            auction_index=1,
            box_token_id=0x2,
            bid_amount=8000
        )).execute(ADDRESS)

    factory.starknet.state.state.update_block_info(
        BlockInfo.create_for_testing(
            block_number=3,
            block_timestamp=500
            )
    )
    with pytest.raises(StarkException, match="Bid is too late"):
        await factory.auction_contract.make_bid(factory.auction_contract.BidData(
            bidder=ADDRESS,
            auction_index=1,
            box_token_id=0x2,
            bid_amount=8000
        )).execute(ADDRESS)

    factory.starknet.state.state.update_block_info(
        BlockInfo.create_for_testing(
            block_number=3,
            block_timestamp=200
            )
    )
    
    await factory.auction_contract.make_bid(factory.auction_contract.BidData(
        bidder=ADDRESS,
        auction_index=1,
        box_token_id=0x2,
        bid_amount=8000
    )).execute(ADDRESS)

    assert (await factory.token_contract_eth.balanceOf(ADDRESS).call()).result.balance == factory.token_contract_eth.Uint256(high=127, low=2**128-5500*2)
    assert (await factory.box_contract.balanceOf_(ADDRESS, 0x2).call()).result.balance == 2
    assert (await factory.box_contract.balanceOf_(factory.auction_contract.contract_address, 0x2).call()).result.balance == 0

    # This one fails because the auction contract no longer has any such box.
    with pytest.raises(StarkException, match=""):
        await factory.auction_contract.make_bid(factory.auction_contract.BidData(
            bidder=ADDRESS,
            auction_index=1,
            box_token_id=0x2,
            bid_amount=100
        )).execute(ADDRESS)
