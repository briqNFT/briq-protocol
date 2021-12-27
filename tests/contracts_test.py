import os
import pytest

from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException

# The path to the contract source code.
CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "../contracts/briq.cairo")

SET_CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "../contracts/set.cairo")

MINT_CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "../contracts/mint_proxy.cairo")

@pytest.mark.asyncio
@pytest.fixture
async def starknet():
    # Create a new Starknet class that simulates the StarkNet
    return await Starknet.empty()

@pytest.mark.asyncio
@pytest.fixture
async def briq_contract(starknet):
    # Deploy the contract.
    return await starknet.deploy(CONTRACT_FILE)

@pytest.mark.asyncio
@pytest.fixture
async def set_contract(starknet):
    # Deploy the contract.
    return await starknet.deploy(SET_CONTRACT_FILE)

ADMIN_ADDR = 0x46fda85f6ff5b7303b71d632b842e950e354fa08225c4f62eee23a1abbec4eb
# fake address
ERC20_ADDR = 0x0011223344

@pytest.mark.asyncio
async def test_micro(briq_contract, set_contract):
    await briq_contract.initialize(set_contract.contract_address, 0, 0).invoke(caller_address=ADMIN_ADDR)
    await briq_contract.mint(owner=0x11, token_id=0x123, material=1).invoke(caller_address=ADMIN_ADDR)
    with pytest.raises(StarkException):
        await briq_contract.mint(owner=0x11, token_id=0x124, material=1).invoke(caller_address=0xdead)
    await briq_contract.mint(owner=0x11, token_id=0x124, material=2).invoke(caller_address=ADMIN_ADDR)
    await briq_contract.mint_multiple(owner=0x11, token_start=0x200, material=2, nb=5).invoke(caller_address=ADMIN_ADDR)
    assert (await briq_contract.get_all_tokens_for_owner(owner=0x11).call()).result[0] == [
        0x200, 2, 0,
        0x201, 2, 0,
        0x202, 2, 0,
        0x203, 2, 0,
        0x204, 2, 0,
        0x124, 2, 0,
        0x123, 1, 0,
    ]

    await set_contract.initialize(briq_contract.contract_address).invoke(caller_address=ADMIN_ADDR)
    await set_contract.mint(owner=0x11, token_id=0x100, bricks=[0x123, 0x124, 0x200, 0x202]).invoke(caller_address=0x11)

    assert (await briq_contract.get_all_tokens_for_owner(owner=0x11).call()).result[0] == [
        0x200, 2, 0x100,
        0x201, 2, 0,
        0x202, 2, 0x100,
        0x203, 2, 0,
        0x204, 2, 0,
        0x124, 2, 0x100,
        0x123, 1, 0x100,
    ]

    with pytest.raises(StarkException):
        await set_contract.mint(owner=0x11, token_id=0x102, bricks=[]).invoke(caller_address=0x11)

    await set_contract.mint(owner=0x11, token_id=0x101, bricks=[0x203]).invoke(caller_address=0x11)
    await set_contract.mint(owner=0x11, token_id=0x102, bricks=[0x204]).invoke(caller_address=0x11)

    assert (await set_contract.get_all_tokens_for_owner(owner=0x11).call()).result[0] == [
        0x102, 0x101, 0x100
    ]

    await set_contract.disassemble_hinted(owner=0x11, token_id=0x101, bricks=[0x203]).invoke(caller_address=0x11)
    assert (await set_contract.get_all_tokens_for_owner(owner=0x11).call()).result[0] == [
        0x102, 0x100
    ]

    with pytest.raises(StarkException):
        await set_contract.disassemble_hinted(owner=0x11, token_id=0xDeaD, bricks=[0x123, 0x201]).invoke(caller_address=0x11)
    with pytest.raises(StarkException):
        await set_contract.disassemble_hinted(owner=0x11, token_id=0x100, bricks=[0x123, 0x201]).invoke(caller_address=0x11)
    with pytest.raises(StarkException):
        await set_contract.disassemble_hinted(owner=0x11, token_id=0x100, bricks=[]).invoke(caller_address=0x11)
    await set_contract.disassemble(owner=0x11, token_id=0x100).invoke(caller_address=0x11)
    assert (await briq_contract.get_all_tokens_for_owner(owner=0x11).call()).result[0] == [
        0x200, 2, 0,
        0x201, 2, 0,
        0x202, 2, 0,
        0x203, 2, 0,
        0x204, 2, 0x102,
        0x124, 2, 0,
        0x123, 1, 0,
    ]

    assert (await set_contract.get_all_tokens_for_owner(owner=0x11).call()).result[0] == [
        0x102
    ]
    await set_contract.disassemble_hinted(owner=0x11, token_id=0x102, bricks=[0x204]).invoke(caller_address=0x11)
    assert (await set_contract.get_all_tokens_for_owner(owner=0x11).call()).result[0] == []
    assert (await briq_contract.get_all_tokens_for_owner(owner=0x11).call()).result[0] == [
        0x200, 2, 0,
        0x201, 2, 0,
        0x202, 2, 0,
        0x203, 2, 0,
        0x204, 2, 0,
        0x124, 2, 0,
        0x123, 1, 0,
    ]

    with pytest.raises(StarkException):
        await set_contract.mint(owner=0x11, token_id=0x100, bricks=[0x123, 0x124, 0x123, 0x124]).invoke(caller_address=0x11)


@pytest.mark.asyncio
async def test_transfer(briq_contract, set_contract):
    await briq_contract.initialize(set_contract.contract_address, 0).invoke(caller_address=0x46fda85f6ff5b7303b71d632b842e950e354fa08225c4f62eee23a1abbec4eb)
    await set_contract.initialize(briq_contract.contract_address).invoke(caller_address=0x46fda85f6ff5b7303b71d632b842e950e354fa08225c4f62eee23a1abbec4eb)

    await briq_contract.mint_multiple(owner=0x11, token_start=0x200, material=2, nb=5).invoke(caller_address=0x46fda85f6ff5b7303b71d632b842e950e354fa08225c4f62eee23a1abbec4eb)
    await set_contract.mint(owner=0x11, token_id=0x101, bricks=[0x201]).invoke(caller_address=0x11)
    await set_contract.mint(owner=0x11, token_id=0x100, bricks=[0x200, 0x202, 0x203]).invoke(caller_address=0x11)
    await set_contract.mint(owner=0x11, token_id=0x102, bricks=[0x204]).invoke(caller_address=0x11)

    assert (await briq_contract.get_all_tokens_for_owner(owner=0x11).call()).result[0] == [
        0x200, 2, 0x100,
        0x201, 2, 0x101,
        0x202, 2, 0x100,
        0x203, 2, 0x100,
        0x204, 2, 0x102,
    ]

    assert (await briq_contract.get_bricks_for_set(owner=0x11, set_id=0x100).call()).result[0] == [0x200, 0x202, 0x203]
    assert (await briq_contract.get_bricks_for_set(owner=0x11, set_id=0x101).call()).result[0] == [0x201]
    assert (await briq_contract.get_bricks_for_set(owner=0x11, set_id=0x103).call()).result[0] == []

    assert (await set_contract.get_all_tokens_for_owner(owner=0x11).call()).result[0] == [0x102, 0x100, 0x101]
    assert (await set_contract.token_at_index(owner=0x11, index=0).call()).result[0] == 0x101
    assert (await set_contract.token_at_index(owner=0x11, index=1).call()).result[0] == 0x100

    await set_contract.transfer_from_hinted(sender=0x11, recipient=0x12, token_id=0x100, bricks=[0x200, 0x202, 0x203]).invoke(caller_address=0x11)

    assert (await set_contract.balance_of(owner=0x11).call()).result[0] == 2
    assert (await set_contract.balance_of(owner=0x12).call()).result[0] == 1

    assert (await set_contract.get_all_tokens_for_owner(owner=0x11).call()).result[0] == [0x102, 0x101]
    assert (await set_contract.get_all_tokens_for_owner(owner=0x12).call()).result[0] == [0x100]
    assert (await set_contract.token_at_index(owner=0x11, index=0).call()).result[0] == 0x101
    assert (await set_contract.token_at_index(owner=0x11, index=1).call()).result[0] == 0x102
    with pytest.raises(StarkException):
        assert (await set_contract.token_at_index(owner=0x11, index=2).call()).result[0] == 0
    assert (await set_contract.token_at_index(owner=0x12, index=0).call()).result[0] == 0x100

    assert (await briq_contract.get_all_tokens_for_owner(owner=0x11).call()).result[0] == [
        0x201, 2, 0x101,
        0x204, 2, 0x102,
    ]
    assert (await briq_contract.get_all_tokens_for_owner(owner=0x12).call()).result[0] == [
        0x200, 2, 0x100,
        0x202, 2, 0x100,
        0x203, 2, 0x100,
    ]

    await set_contract.transfer_from(sender=0x12, recipient=0x11, token_id=0x100).invoke(caller_address=0x12)
   
    assert (await briq_contract.get_all_tokens_for_owner(owner=0x11).call()).result[0] == [
        0x200, 2, 0x100,
        0x202, 2, 0x100,
        0x203, 2, 0x100,
        0x201, 2, 0x101,
        0x204, 2, 0x102,
    ]
    assert (await briq_contract.get_all_tokens_for_owner(owner=0x12).call()).result[0] == [
    ]


@pytest.mark.asyncio
async def test_mint_proxy(starknet, briq_contract):
    NB_BRIQS = 50
    mint_contract = await starknet.deploy(MINT_CONTRACT_FILE, constructor_calldata=[briq_contract.contract_address, NB_BRIQS])
    await briq_contract.initialize(0, mint_contract.contract_address, 0).invoke(caller_address=ADMIN_ADDR)

    (await mint_contract.amount_minted(0x11).call()).result[0] == 0
    with pytest.raises(StarkException):
        await mint_contract.mint(0x11).invoke(caller_address=0x12)
    await mint_contract.mint(0x11).invoke(caller_address=0x11)
    (await mint_contract.amount_minted(0x11).call()).result[0] == NB_BRIQS
    with pytest.raises(StarkException):
        await mint_contract.mint(0x11).invoke(caller_address=0x11)
    with pytest.raises(StarkException):
        await mint_contract.mint_amount(0x11, 1).invoke(caller_address=0x11)

    res = []
    for i in range(50):
        res = res + [i + 1, 1, 0]
    assert (await briq_contract.get_all_tokens_for_owner(owner=0x11).call()).result[0] == res

    await mint_contract.mint(0x12).invoke(caller_address=0x12)
    res = []
    for i in range(50):
        res = res + [i + 51, 1, 0]
    assert (await briq_contract.get_all_tokens_for_owner(owner=0x12).call()).result[0] == res


@pytest.mark.asyncio
async def test_erc20_transfer(briq_contract):
    await briq_contract.initialize(0, 0, ERC20_ADDR).invoke(caller_address=ADMIN_ADDR)
    await briq_contract.mint_multiple(owner=0x11, token_start=0x200, material=1, nb=10).invoke(caller_address=ADMIN_ADDR)

    await briq_contract.ERC20_transfer(sender=0x11, recipient=0x12, amount=5).invoke(caller_address=ERC20_ADDR)    

    assert (await briq_contract.balance_of(owner=0x11).call()).result[0] == 5
    assert (await briq_contract.balance_of(owner=0x12).call()).result[0] == 5

