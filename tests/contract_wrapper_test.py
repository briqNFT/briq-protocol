import pytest

from starknet_proxy.contract import ContractWrapper

abi = [
    {
        "inputs": [],
        "name": "initialize",
        "outputs": [],
        "type": "function"
    },
    {
        "inputs": [
            {
                "name": "owner",
                "type": "felt"
            }
        ],
        "name": "balance_of",
        "outputs": [
            {
                "name": "res",
                "type": "felt"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    }
]

from unittest.mock import patch

@patch('starknet_proxy.contract.feeder_client.call_contract', autospec=True)
@pytest.mark.asyncio
async def test_wrapper(MockFuncInvocation):
    MockFuncInvocation.return_value = { "result": ["0x5"] }
    contract = ContractWrapper(abi_json=abi, address="0x075157ee904c59f9b4f5a2f284284fed3c05e0cc6446fd6578e753554a7a638f")
    assert await contract.balance_of(owner=5).call() == 5

def test_wrapper_bad_call():
    contract = ContractWrapper(abi_json=abi, address="0x075157ee904c59f9b4f5a2f284284fed3c05e0cc6446fd6578e753554a7a638f")
    with pytest.raises(Exception):
        contract.balance_of(tata=5, toto=3)
    with pytest.raises(Exception):
        contract.balance_of(owner=[3])

def test_wrapper_not_exist():
    contract = ContractWrapper(abi_json=abi, address="0x075157ee904c59f9b4f5a2f284284fed3c05e0cc6446fd6578e753554a7a638f")
    with pytest.raises(Exception):
        contract.not_existent(5)

