from collections import namedtuple
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

from .conftest import compile, VENDOR_SRC, declare_and_deploy, declare_and_deploy_proxied, hash_token_id, proxy_contract, deploy_clean_shapes


CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")

ADMIN_ADDRESS=0xf00d

ADDRESS = 0xcafe
OTHER_ADDRESS = 0xd00d
THIRD_ADDRESS = 0xfade

# ! Hardcoded in Cairo
COLLECTION_ID = 0x1

def to_booklet_id(id):
    return id * 2**192 + COLLECTION_ID

@pytest_asyncio.fixture(scope="module")
async def factory_root():
    starknet = await Starknet.empty()

    compiled_proxy = compile("upgrades/proxy.cairo")
    await starknet.declare(contract_class=compiled_proxy)
    
    [token_contract_eth, _] = await declare_and_deploy(starknet, "vendor/openzeppelin/token/erc20/presets/ERC20Mintable.cairo", constructor_calldata=[
        0x1,  # name: felt,
        0x1,  # symbol: felt,
        18,  # decimals: felt,
        2 ** 64, 0,  # initial_supply: Uint256,
        ADDRESS,  # recipient: felt,
        ADDRESS  # owner: felt
    ])

    [auction_contract, _] = await declare_and_deploy_proxied(starknet, compiled_proxy, "auction.cairo", ADMIN_ADDRESS)
    [box_contract, _] = await declare_and_deploy_proxied(starknet, compiled_proxy, "box_nft.cairo", ADMIN_ADDRESS)
    [booklet_contract, _] = await declare_and_deploy_proxied(starknet, compiled_proxy, "booklet_nft.cairo", ADMIN_ADDRESS)
    [set_contract, _] = await declare_and_deploy_proxied(starknet, compiled_proxy, "set_nft.cairo", ADMIN_ADDRESS)
    [briq_contract, _] = await declare_and_deploy_proxied(starknet, compiled_proxy, "briq.cairo", ADMIN_ADDRESS)
    [attributes_registry_contract, _] = await declare_and_deploy_proxied(starknet, compiled_proxy, "attributes_registry.cairo", ADMIN_ADDRESS)

    await box_contract.setBookletAddress_(booklet_contract.contract_address).execute(ADMIN_ADDRESS)
    await box_contract.setBriqAddress_(briq_contract.contract_address).execute(ADMIN_ADDRESS)

    await booklet_contract.setAttributesRegistryAddress_(attributes_registry_contract.contract_address).execute(ADMIN_ADDRESS)
    await booklet_contract.setBoxAddress_(box_contract.contract_address).execute(ADMIN_ADDRESS)

    await set_contract.setBriqAddress_(briq_contract.contract_address).execute(ADMIN_ADDRESS)
    await set_contract.setAttributesRegistryAddress_(attributes_registry_contract.contract_address).execute(ADMIN_ADDRESS)

    await briq_contract.setSetAddress_(set_contract.contract_address).execute(ADMIN_ADDRESS)
    await briq_contract.setBoxAddress_(box_contract.contract_address).execute(ADMIN_ADDRESS)

    await attributes_registry_contract.setSetAddress_(set_contract.contract_address).execute(ADMIN_ADDRESS)
    await attributes_registry_contract.create_collection_(COLLECTION_ID, 2, booklet_contract.contract_address).execute(ADMIN_ADDRESS)

    return [starknet, auction_contract, box_contract, booklet_contract, attributes_registry_contract, token_contract_eth, set_contract, briq_contract]


@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, auction_contract, box_contract, booklet_contract, attributes_registry_contract, token_contract_eth, set_contract, briq_contract] = factory_root
    state = Starknet(state=starknet.state.copy())
    return namedtuple('State', ['starknet', 'auction_contract', 'box_contract', 'booklet_contract', 'attributes_registry_contract', 'token_contract_eth', 'set_contract', 'briq_contract'])(
        state,
        proxy_contract(state, auction_contract),
        proxy_contract(state, box_contract),
        proxy_contract(state, booklet_contract),
        proxy_contract(state, attributes_registry_contract),
        proxy_contract(state, token_contract_eth),
        proxy_contract(state, set_contract),
        proxy_contract(state, briq_contract),
    )

@pytest.mark.asyncio
async def test_everything(tmp_path, factory, deploy_clean_shapes):
    # Declare the auction ready by upgrading the auction contract.
    auction_code = generate_auction(auction_data = {
        1: {
            "box_token_id": 0x1,
            "quantity": 1,
            "auction_start": 134,
            "auction_duration": 24 * 60 * 60,
            "initial_price": 10,
        },
        2: {
            "box_token_id": 0x2,
            "quantity": 1,
            "auction_start": 198,
            "auction_duration": 24 * 60 * 60,
            "initial_price": 10,
        }
    }, box_address=factory.box_contract.contract_address, erc20_address=factory.token_contract_eth.contract_address)
    (tmp_path / 'contracts' / 'auction').mkdir(parents=True, exist_ok=True)
    open(tmp_path / 'contracts' / 'auction' / 'data.cairo', "w").write(auction_code)
    auction_code = compile_starknet_files(files=[os.path.join(CONTRACT_SRC, 'auction.cairo')], disable_hint_validation=True, debug_info=True, cairo_path=[str(tmp_path), VENDOR_SRC])

    auction_impl_hash = await factory.starknet.declare(contract_class=auction_code)
    await factory.auction_contract.upgradeImplementation_(auction_impl_hash.class_hash).execute(ADMIN_ADDRESS)

    # At this point, we need to match the box token IDs with some box identifiers (e.g. 'starknet_planet/spaceman')
    # and reveal the data.

    ################
    ################

    # Make a bid on the auction
    await factory.token_contract_eth.approve(factory.auction_contract.contract_address, (5000, 0)).execute(ADDRESS)
    bid_box_1 = factory.auction_contract.BidData(
        bidder=ADDRESS,
        auction_index=0,
        box_token_id=0x1,
        bid_amount=100
    )
    bid_box_2 = factory.auction_contract.BidData(
        bidder=ADDRESS,
        auction_index=1,
        box_token_id=0x2,
        bid_amount=200
    )
    await factory.auction_contract.make_bid(bid_box_1).execute(ADDRESS)
    await factory.auction_contract.make_bid(bid_box_2).execute(ADDRESS)

    ################
    ################

    # In the meantime, deploy two shape contracts
    [shape_basic, _] = await deploy_clean_shapes(factory.starknet, [
        ([
            ('#ffaaff', 0x1, -2, 0, 2),
            ('#ffaaff', 0x1, -1, 0, 2),
            ('#ffaaff', 0x1, 0, 0, 2),
        ], [])
    ], offset = 1)
    [shape_bimat, _] = await deploy_clean_shapes(factory.starknet, [
        ([
            ('#ffaaff', 0x1, -2, 1, 2),
            ('#ffaaff', 0x4, -1, 1, 2),
            ('#ffaaff', 0x1, 0, 1, 2),
        ], [])
    ], offset = 2)

    # Upgrade the box contract before the auction starts.
    box_code = generate_box(
        briq_data={
            1: {
                0x1: 3
            },
            2: {
                0x1: 2,
                0x4: 1
            }
        }, shape_data={
            0x1: shape_basic.class_hash,
            0x2: shape_bimat.class_hash,
        },
    )
    (tmp_path / 'contracts' / 'box_nft').mkdir(parents=True, exist_ok=True)
    open(tmp_path / 'contracts' / 'box_nft' / 'data.cairo', "w").write(box_code)
    box_code = compile_starknet_files(files=[os.path.join(CONTRACT_SRC, 'box_nft.cairo')], disable_hint_validation=True, debug_info=True, cairo_path=[str(tmp_path), VENDOR_SRC])

    box_impl_hash = await factory.starknet.declare(contract_class=box_code)
    await factory.box_contract.upgradeImplementation_(box_impl_hash.class_hash).execute(ADMIN_ADDRESS)

    # Mint the matching boxes (this can actually be done earlier)
    await factory.box_contract.mint_(factory.auction_contract.contract_address, 0x1, 10).execute(ADMIN_ADDRESS)
    await factory.box_contract.mint_(factory.auction_contract.contract_address, 0x2, 4).execute(ADMIN_ADDRESS)
    with pytest.raises(StarkException):
        await factory.box_contract.mint_(factory.auction_contract.contract_address, 0x3, 1).execute(ADMIN_ADDRESS)

    # Now end the auction, transferring stuff

    await factory.auction_contract.close_auction([bid_box_1]).execute(ADMIN_ADDRESS)
    await factory.auction_contract.close_auction([bid_box_2]).execute(ADMIN_ADDRESS)

    # GOOD TO GO
    await factory.box_contract.safeTransferFrom_(ADDRESS, OTHER_ADDRESS, 0x1, 1, []).execute(ADDRESS)
    await factory.box_contract.safeTransferFrom_(ADDRESS, OTHER_ADDRESS, 0x2, 1, []).execute(ADDRESS)

    assert (await factory.briq_contract.balanceOfMaterial_(OTHER_ADDRESS, 0x1).call()).result.balance == 0

    await factory.box_contract.unbox_(OTHER_ADDRESS, 0x1).execute(OTHER_ADDRESS)

    assert (await factory.booklet_contract.balanceOf_(OTHER_ADDRESS, to_booklet_id(0x1)).call()).result.balance == 1
    assert (await factory.briq_contract.balanceOfMaterial_(OTHER_ADDRESS, 0x1).call()).result.balance == 3

    await factory.box_contract.unbox_(OTHER_ADDRESS, 0x2).execute(OTHER_ADDRESS)
    assert (await factory.booklet_contract.balanceOf_(OTHER_ADDRESS, to_booklet_id(0x2)).call()).result.balance == 1
    assert (await factory.briq_contract.balanceOfMaterial_(OTHER_ADDRESS, 0x1).call()).result.balance == 5
    assert (await factory.briq_contract.balanceOfMaterial_(OTHER_ADDRESS, 0x4).call()).result.balance == 1

    set_token_id_a = hash_token_id(OTHER_ADDRESS, 0x1234, [1234])

    await factory.set_contract.assemble_(
        owner=OTHER_ADDRESS,
        token_id_hint=0x1234,
        name=[0x12], description=[0x34],
        fts=[(0x1, 3)],
        nfts=[],
        attributes=[to_booklet_id(0x1)],
        shape=[
            compress_shape_item('#ffaaff', 0x1, -2, 0, 2, False),
            compress_shape_item('#ffaaff', 0x1, -1, 0, 2, False),
            compress_shape_item('#ffaaff', 0x1, 0, 0, 2, False),
        ]
    ).execute(OTHER_ADDRESS)

    assert (await factory.booklet_contract.balanceOf_(OTHER_ADDRESS, to_booklet_id(0x1)).call()).result.balance == 0
    assert (await factory.briq_contract.balanceOfMaterial_(OTHER_ADDRESS, 0x1).call()).result.balance == 2
    assert (await factory.briq_contract.balanceOfMaterial_(OTHER_ADDRESS, 0x4).call()).result.balance == 1

    assert (await factory.booklet_contract.balanceOf_(set_token_id_a, to_booklet_id(0x1)).call()).result.balance == 1
    assert (await factory.briq_contract.balanceOfMaterial_(set_token_id_a, 0x1).call()).result.balance == 3
