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

from starkware.starknet.utils.api_utils import cast_to_felts
from starkware.starknet.compiler.compile import compile_starknet_files, compile_starknet_codes

from generators.shape_utils import to_shape_data, compress_shape_item

from .conftest import declare_and_deploy, hash_token_id, proxy_contract, deploy_clean_shapes


CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "..", "contracts")

ADDRESS = 0xcafe
OTHER_ADDRESS = 0xd00d
MOCK_SHAPE_TOKEN = 0xdeadfade

BOX_ADDRESS = 0x1234

# ! Hardcoded in cairo
COLLECTION_ID = 0x1

@pytest_asyncio.fixture(scope="module")
async def factory_root():
    starknet = await Starknet.empty()
    [briq_contract, _] = await declare_and_deploy(starknet, "briq.cairo")
    [set_contract, _] = await declare_and_deploy(starknet, "set_nft.cairo")
    [attributes_registry_contract, _] = await declare_and_deploy(starknet, "attributes_registry.cairo")
    [booklet_contract, _] = await declare_and_deploy(starknet, "booklet_nft.cairo")
    await briq_contract.setSetAddress_(set_contract.contract_address).execute()
    await set_contract.setBriqAddress_(briq_contract.contract_address).execute()
    await set_contract.setAttributesRegistryAddress_(attributes_registry_contract.contract_address).execute()
    await attributes_registry_contract.setSetAddress_(set_contract.contract_address).execute()
    await booklet_contract.setBoxAddress_(BOX_ADDRESS).execute()
    await booklet_contract.setAttributesRegistryAddress_(attributes_registry_contract.contract_address).execute()
    
    await briq_contract.mintFT_(ADDRESS, 0x1, 50).execute()
    await attributes_registry_contract.create_collection_(COLLECTION_ID, 2, booklet_contract.contract_address).execute()
    
    return [starknet, set_contract, briq_contract, attributes_registry_contract, booklet_contract]

@pytest_asyncio.fixture
async def factory(factory_root):
    [starknet, set_contract, briq_contract, attributes_registry_contract, booklet_contract] = factory_root
    state = Starknet(state=starknet.state.copy())
    return namedtuple('State', ['starknet', 'set_contract', 'briq_contract', 'attributes_registry_contract', 'booklet_contract'])(
        state,
        proxy_contract(state, set_contract),
        proxy_contract(state, briq_contract),
        proxy_contract(state, attributes_registry_contract),
        proxy_contract(state, booklet_contract),
    )

@pytest.mark.asyncio
async def test_working(tmp_path, factory, deploy_clean_shapes):
    state = factory
    TOKEN_HINT = 1234
    TOKEN_URI = [1234]
    BOOKLET_ID = 1234 * 2**192 + COLLECTION_ID
    SET_TOKEN_ID = hash_token_id(ADDRESS, TOKEN_HINT, TOKEN_URI)

    [shape_hash, _] = await deploy_clean_shapes(factory.starknet, shapes=[(
        [('#ffaaff', 1, 2, -2, -6),
        ('#aaffaa', 1, 4, -2, -6),
        ('#aaffaa', 1, 5, -2, -6),
        ('#aaffaa', 1, 6, -2, -6)],
        []
    )], offset = 1234)
    await state.booklet_contract.mint_(ADDRESS, BOOKLET_ID, shape_hash.class_hash).execute(BOX_ADDRESS)

    assert (await state.booklet_contract.balanceOf_(ADDRESS, BOOKLET_ID).call()).result.balance == 1
    assert (await state.booklet_contract.balanceOf_(SET_TOKEN_ID, BOOKLET_ID).call()).result.balance == 0

    await state.set_contract.assemble_with_attribute_(
        owner=ADDRESS,
        token_id_hint=TOKEN_HINT,
        uri=TOKEN_URI,
        fts=[(0x1, 4)],
        nfts=[],
        attribute_id=BOOKLET_ID,
        shape=[
            compress_shape_item('#ffaaff', 0x1, 2, -2, -6, False),
            compress_shape_item('#aaffaa', 0x1, 4, -2, -6, False),
            compress_shape_item('#aaffaa', 0x1, 5, -2, -6, False),
            compress_shape_item('#aaffaa', 0x1, 6, -2, -6, False),
        ],
    ).execute(ADDRESS)

    assert (await state.set_contract.ownerOf_(SET_TOKEN_ID).call()).result.owner == ADDRESS
    assert (await state.briq_contract.balanceOfMaterial_(ADDRESS, 0x1).call()).result.balance == 46
    assert (await state.booklet_contract.balanceOf_(ADDRESS, BOOKLET_ID).call()).result.balance == 0
    assert (await state.booklet_contract.balanceOf_(SET_TOKEN_ID, BOOKLET_ID).call()).result.balance == 1


    with pytest.raises(StarkException):
        await state.set_contract.disassemble_(
            owner=ADDRESS,
            token_id=SET_TOKEN_ID,
            fts=[(0x1, 4)],
            nfts=[],
        ).execute(ADDRESS)
    await state.set_contract.disassemble_with_attribute_(
        owner=ADDRESS,
        token_id=SET_TOKEN_ID,
        fts=[(0x1, 4)],
        nfts=[],
        attribute_id=BOOKLET_ID
    ).execute(ADDRESS)
    assert (await state.set_contract.ownerOf_(SET_TOKEN_ID).call()).result.owner == 0
    assert (await state.briq_contract.balanceOfMaterial_(ADDRESS, 0x1).call()).result.balance == 50
    assert (await state.booklet_contract.balanceOf_(ADDRESS, BOOKLET_ID).call()).result.balance == 1
    assert (await state.booklet_contract.balanceOf_(SET_TOKEN_ID, BOOKLET_ID).call()).result.balance == 0


@pytest.mark.asyncio
async def test_bad_shape(tmp_path, factory, deploy_clean_shapes):
    state = factory
    TOKEN_HINT = 1234
    BOOKLET_ID = 1234 * 2**192 + COLLECTION_ID

    [shape_hash, _] = await deploy_clean_shapes(factory.starknet, shapes=[(
        [('#ffaaff', 1, 2, -2, -6),
        ('#aaffaa', 1, 4, -2, -6),
        ('#aaffaa', 1, 5, -2, -6),
        ('#aaffaa', 1, 6, -2, -6)],
        []
    )], offset = 1234)
    await state.booklet_contract.mint_(ADDRESS, BOOKLET_ID, shape_hash.class_hash).execute(BOX_ADDRESS)

    with pytest.raises(StarkException, match="Shapes do not match"):
        await state.set_contract.assemble_with_attribute_(
            owner=ADDRESS,
            token_id_hint=TOKEN_HINT,
            uri=[1234],
            fts=[(0x1, 4)],
            nfts=[],
            attribute_id=BOOKLET_ID,
            shape=[
                compress_shape_item('#ffaaff', 0x1, 2, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 5, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 4, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 6, -2, -6, False),
            ],
        ).execute(ADDRESS)


@pytest.mark.asyncio
async def test_bad_number(tmp_path, factory, deploy_clean_shapes):
    state = factory
    TOKEN_HINT = 1234
    BOOKLET_ID = 1234 * 2**192 + COLLECTION_ID

    [shape_hash, _] = await deploy_clean_shapes(factory.starknet, shapes=[(
        [('#ffaaff', 1, 2, -2, -6),
        ('#aaffaa', 1, 4, -2, -6),
        ('#aaffaa', 1, 5, -2, -6),
        ('#aaffaa', 1, 6, -2, -6)],
        []
    )], offset = 1234)
    await state.booklet_contract.mint_(ADDRESS, BOOKLET_ID, shape_hash.class_hash).execute(BOX_ADDRESS)

    with pytest.raises(StarkException, match="Wrong number of briqs in shape"):
        await state.set_contract.assemble_with_attribute_(
            owner=ADDRESS,
            token_id_hint=TOKEN_HINT,
            uri=[1234],
            fts=[(0x1, 3)],
            nfts=[],
            attribute_id=BOOKLET_ID,
            shape=[
                compress_shape_item('#ffaaff', 0x1, 2, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 4, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 5, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 6, -2, -6, False),
            ],
        ).execute(ADDRESS)

    with pytest.raises(StarkException, match="Wrong number of briqs in shape"):
        await state.set_contract.assemble_with_attribute_(
            owner=ADDRESS,
            token_id_hint=TOKEN_HINT,
            uri=[1234],
            fts=[(0x1, 5)],
            nfts=[],
            attribute_id=BOOKLET_ID,
            shape=[
                compress_shape_item('#ffaaff', 0x1, 2, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 4, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 5, -2, -6, False),
                compress_shape_item('#aaffaa', 0x1, 6, -2, -6, False),
            ],
        ).execute(ADDRESS)
