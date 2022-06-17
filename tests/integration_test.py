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

from .conftest import declare_and_deploy, declare_and_deploy_proxied, hash_token_id


CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")

ADMIN_ADDRESS=0xf00d

ADDRESS = 0xcafe
OTHER_ADDRESS = 0xd00d
THIRD_ADDRESS = 0xfade

def compile(path):
    return compile_starknet_files(
        files=[os.path.join(CONTRACT_SRC, path)],
        debug_info=True,
        disable_hint_validation=True
    )


@pytest_asyncio.fixture(scope="module")
async def factory_root():
    starknet = await Starknet.empty()

    compiled_proxy = compile("upgrades/proxy.cairo")
    await starknet.declare(contract_class=compiled_proxy)
    
    [token_contract_eth, _] = await declare_and_deploy(starknet, "OZ/token/erc20/ERC20_Mintable.cairo", constructor_calldata=[
        0x1,  # name: felt,
        0x1,  # symbol: felt,
        18,  # decimals: felt,
        2 ** 64, 0,  # initial_supply: Uint256,
        ADDRESS,  # recipient: felt,
        ADDRESS  # owner: felt
    ])

    [auction_contract, _] = await declare_and_deploy_proxied(starknet, compiled_proxy, "auction.cairo", ADMIN_ADDRESS)
    [box_contract, _] = await declare_and_deploy_proxied(starknet, compiled_proxy, "box.cairo", ADMIN_ADDRESS)
    [booklet_contract, _] = await declare_and_deploy_proxied(starknet, compiled_proxy, "booklet.cairo", ADMIN_ADDRESS)
    [set_contract, _] = await declare_and_deploy_proxied(starknet, compiled_proxy, "set_interface.cairo", ADMIN_ADDRESS)
    [briq_contract, _] = await declare_and_deploy_proxied(starknet, compiled_proxy, "briq_interface.cairo", ADMIN_ADDRESS)

    await box_contract.setBookletAddress_(booklet_contract.contract_address).invoke(ADMIN_ADDRESS)
    await box_contract.setBriqAddress_(briq_contract.contract_address).invoke(ADMIN_ADDRESS)

    await set_contract.setBriqAddress_(briq_contract.contract_address).invoke(ADMIN_ADDRESS)
    await set_contract.setBookletAddress_(booklet_contract.contract_address).invoke(ADMIN_ADDRESS)

    await briq_contract.setSetAddress_(set_contract.contract_address).invoke(ADMIN_ADDRESS)
    await briq_contract.setBoxAddress_(box_contract.contract_address).invoke(ADMIN_ADDRESS)

    await booklet_contract.setSetAddress_(set_contract.contract_address).invoke(ADMIN_ADDRESS)
    await booklet_contract.setBoxAddress_(box_contract.contract_address).invoke(ADMIN_ADDRESS)

    return [starknet, auction_contract, box_contract, booklet_contract, token_contract_eth, set_contract, briq_contract]


def proxy_contract(state, contract):
    return StarknetContract(
        state=state.state,
        abi=contract.abi,
        contract_address=contract.contract_address,
        deploy_execution_info=contract.deploy_execution_info,
    )

@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, auction_contract, box_contract, booklet_contract, token_contract_eth, set_contract, briq_contract] = factory_root
    state = Starknet(state=starknet.state.copy())
    return namedtuple('State', ['starknet', 'auction_contract', 'box_contract', 'booklet_contract', 'token_contract_eth', 'set_contract', 'briq_contract'])(
        starknet=state,
        auction_contract=proxy_contract(state, auction_contract),
        box_contract=proxy_contract(state, box_contract),
        booklet_contract=proxy_contract(state, booklet_contract),
        token_contract_eth=proxy_contract(state, token_contract_eth),
        set_contract=proxy_contract(state, set_contract),
        briq_contract=proxy_contract(state, briq_contract),
    )


async def deploy_shape(starknet, shape_data):
    data = open(os.path.join(CONTRACT_SRC, "shape/shape_store.cairo"), "r").read() + '\n'
    shape_data_str = '\n'.join(shape_data)
    shape = data.replace("#DEFINE_SHAPE", f"""
    const SHAPE_LEN = {len(shape_data)}

    shape_data:
    {shape_data_str}
    shape_data_end:
    nft_data:
    nft_data_end:
""")
    test_code = compile_starknet_codes(codes=[(shape, "shape_code")], disable_hint_validation=True)
    return await starknet.deploy(contract_class=test_code)


@pytest.mark.asyncio
async def test_everything(tmp_path, factory):
    # Declare the auction ready by upgrading the auction contract.
    auction_code = generate_auction(auction_data = {
        1: {
            "box_token_id": 0x1,
            "quantity": 10,
            "auction_start": 134,
            "auction_duration": 24 * 60 * 60,
        },
        2: {
            "box_token_id": 0x2,
            "quantity": 20,
            "auction_start": 198,
            "auction_duration": 24 * 60 * 60,
        }
    }, box_address=factory.box_contract.contract_address)
    (tmp_path / 'contracts' / 'auction').mkdir(parents=True, exist_ok=True)
    open(tmp_path / 'contracts' / 'auction' / 'data.cairo', "w").write(auction_code)
    auction_code = compile_starknet_files(files=[os.path.join(CONTRACT_SRC, 'auction.cairo')], disable_hint_validation=True, debug_info=True, cairo_path=[str(tmp_path)])

    auction_impl_hash = await factory.starknet.declare(contract_class=auction_code)
    await factory.auction_contract.upgradeImplementation_(auction_impl_hash.class_hash).invoke(ADMIN_ADDRESS)

    ################
    ################

    # Make a bid on the auction
    await factory.token_contract_eth.approve(factory.auction_contract.contract_address, (5000, 0)).invoke(ADDRESS)
    bid_box_1 = factory.auction_contract.BidData(
        payer=ADDRESS,
        payer_erc20_contract=factory.token_contract_eth.contract_address,
        box_token_id=0x1,
        bid_amount=100
    )
    bid_box_2 = factory.auction_contract.BidData(
        payer=ADDRESS,
        payer_erc20_contract=factory.token_contract_eth.contract_address,
        box_token_id=0x2,
        bid_amount=200
    )
    await factory.auction_contract.make_bid(bid_box_1).invoke(ADDRESS)
    await factory.auction_contract.make_bid(bid_box_2).invoke(ADDRESS)

    ################
    ################

    # In the meantime, deploy two shape contracts
    shape_basic = await deploy_shape(factory.starknet, [
        to_shape_data('#ffaaff', 0x1, -2, 0, 2),
        to_shape_data('#ffaaff', 0x1, -1, 0, 2),
        to_shape_data('#ffaaff', 0x1, 0, 0, 2),
    ])
    shape_bimat = await deploy_shape(factory.starknet, [
        to_shape_data('#ffaaff', 0x1, -2, 1, 2),
        to_shape_data('#ffaaff', 0x4, -1, 1, 2),
        to_shape_data('#ffaaff', 0x1, 0, 1, 2),
    ])

    # Upgrade the box contract before the auction ends.
    box_code = generate_box(briq_data={
        1: {
            0x1: 3
        },
        2: {
            0x1: 2,
            0x4: 1
        }
    }, shape_data={
        0x1: shape_basic.contract_address,
        0x2: shape_bimat.contract_address,
    }, booklet_address=factory.booklet_contract.contract_address, briq_address=factory.briq_contract.contract_address)
    (tmp_path / 'contracts' / 'box_erc1155').mkdir(parents=True, exist_ok=True)
    open(tmp_path / 'contracts' / 'box_erc1155' / 'data.cairo', "w").write(box_code)
    box_code = compile_starknet_files(files=[os.path.join(CONTRACT_SRC, 'box.cairo')], disable_hint_validation=True, debug_info=True, cairo_path=[str(tmp_path)])

    box_impl_hash = await factory.starknet.declare(contract_class=box_code)
    await factory.box_contract.upgradeImplementation_(box_impl_hash.class_hash).invoke(ADMIN_ADDRESS)

    # Mint the matching boxes (this can actually be done earlier)
    await factory.box_contract.mint_(factory.auction_contract.contract_address, 0x1, 10).invoke(ADMIN_ADDRESS)
    await factory.box_contract.mint_(factory.auction_contract.contract_address, 0x2, 4).invoke(ADMIN_ADDRESS)
    with pytest.raises(StarkException):
        await factory.box_contract.mint_(factory.auction_contract.contract_address, 0x3, 1).invoke(ADMIN_ADDRESS)

    # Now end the auction, transferring stuff

    await factory.auction_contract.close_auction([bid_box_1]).invoke(ADMIN_ADDRESS)
    await factory.auction_contract.close_auction([bid_box_2]).invoke(ADMIN_ADDRESS)

    # GOOD TO GO
    await factory.box_contract.safeTransferFrom_(ADDRESS, OTHER_ADDRESS, 0x1, 1, []).invoke(ADDRESS)
    await factory.box_contract.safeTransferFrom_(ADDRESS, OTHER_ADDRESS, 0x2, 1, []).invoke(ADDRESS)

    assert (await factory.briq_contract.balanceOfMaterial_(OTHER_ADDRESS, 0x1).call()).result.balance == 0

    await factory.box_contract.unbox_(OTHER_ADDRESS, 0x1).invoke(OTHER_ADDRESS)

    assert (await factory.booklet_contract.balanceOf_(OTHER_ADDRESS, 0x1).call()).result.balance == 1
    assert (await factory.briq_contract.balanceOfMaterial_(OTHER_ADDRESS, 0x1).call()).result.balance == 3

    await factory.box_contract.unbox_(OTHER_ADDRESS, 0x2).invoke(OTHER_ADDRESS)
    assert (await factory.booklet_contract.balanceOf_(OTHER_ADDRESS, 0x2).call()).result.balance == 1
    assert (await factory.briq_contract.balanceOfMaterial_(OTHER_ADDRESS, 0x1).call()).result.balance == 5
    assert (await factory.briq_contract.balanceOfMaterial_(OTHER_ADDRESS, 0x4).call()).result.balance == 1

    set_token_id_a = hash_token_id(OTHER_ADDRESS, 0x1234, [1234])

    await factory.set_contract.assemble_with_booklet_(
        owner=OTHER_ADDRESS,
        token_id_hint=0x1234,
        uri=[1234],
        fts=[(0x1, 3)],
        nfts=[],
        booklet_token_id=0x1,
        shape=[
            compress_shape_item('#ffaaff', 0x1, -2, 0, 2, False),
            compress_shape_item('#ffaaff', 0x1, -1, 0, 2, False),
            compress_shape_item('#ffaaff', 0x1, 0, 0, 2, False),
        ]
    ).invoke(OTHER_ADDRESS)

    assert (await factory.booklet_contract.balanceOf_(OTHER_ADDRESS, 0x1).call()).result.balance == 0
    assert (await factory.briq_contract.balanceOfMaterial_(OTHER_ADDRESS, 0x1).call()).result.balance == 2
    assert (await factory.briq_contract.balanceOfMaterial_(OTHER_ADDRESS, 0x4).call()).result.balance == 1

    assert (await factory.booklet_contract.balanceOf_(set_token_id_a, 0x1).call()).result.balance == 1
    assert (await factory.briq_contract.balanceOfMaterial_(set_token_id_a, 0x1).call()).result.balance == 3
