import os

from nile.nre import NileRuntimeEnvironment


def run(nre: NileRuntimeEnvironment):

    if not os.getenv('KEEP'):
        # Assume we're dumping everything
        os.unlink('localhost.declarations.txt')

    if not os.getenv("ADMIN"):
        print("ADMIN env variable must be set to the address of the admin wallet")

    try:
        nre.declare("proxy", "proxy")
        nre.declare("set_interface", "set_interface")
        nre.declare("briq_interface", "briq_interface")
        nre.declare("booklet", "booklet")
        nre.declare("box", "box")
        nre.declare("auction", "auction")
    except Exception as ex:
        if 'already exists in' in str(ex):
            pass
        else:
            raise

    account = nre.get_or_deploy_account("ADMIN")
    print(account)
    args = account.deploy("proxy", ["1234"], alias="auction")
    print(args)    

    #addr="$(starknet deploy --contract artifacts/proxy.json --inputs $WALLET_ADDRESS $auction_hash --account test)"
    #addr="$(starknet deploy --contract artifacts/proxy.json --inputs $WALLET_ADDRESS $box_hash --account test)"
    #addr="$(starknet deploy --contract artifacts/proxy.json --inputs $WALLET_ADDRESS $booklet_hash --account test)"
    #addr="$(starknet deploy --contract artifacts/proxy.json --inputs $WALLET_ADDRESS $briq_hash --account test)"
    #addr="$(starknet deploy --contract artifacts/proxy.json --inputs $WALLET_ADDRESS $set_hash --account test)"

    #os.environ["toto"] = "123456"
    #account = nre.get_or_deploy_account("toto")
    #print(f"Deployed deploy account to {account.address}")

    #briq_interface_addr, abi = nre.deploy("briq_interface", arguments=[], alias="briq_interface")
    #set_interface_addr, abi = nre.deploy("set_interface", arguments=[], alias="set_interface")

    #briq_address, abi = nre.deploy("proxy", arguments=[os.getenv("ADMIN"), briq_interface_addr], alias="briq_proxy")
    #set_address, abi = nre.deploy("proxy", arguments=[os.getenv("ADMIN"), set_interface_addr], alias="set_proxy")

    #print(f"Deployed briq to {briq_address}")
    #print(f"Deployed set to {set_address}")

    #account.send(briq_address, "setSetAddress_", [int(set_address, 16)])
    #account.send(set_address, "setBriqAddress_", [int(briq_address, 16)])
