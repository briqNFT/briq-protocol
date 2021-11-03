from unittest.mock import patch, MagicMock

from starknet_proxy import proxy

# TODO: figure out why I can't test the server?
@patch('starknet_proxy.storage.storage.get_storage', autospec=True)
def test_store_list(get_storage):
    ret = MagicMock()
    get_storage.return_value = ret
    proxy.store_list()
    ret.list_json.assert_called_once
