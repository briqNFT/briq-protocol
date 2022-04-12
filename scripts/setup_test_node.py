from nile.nre import NileRuntimeEnvironment

def run(nre: NileRuntimeEnvironment):
    address, abi = nre.deploy("_proxy", alias="briq_backend")
    print(abi, address)
