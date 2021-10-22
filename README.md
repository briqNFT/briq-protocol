
```pip3 install```

```source venv/bin/activate```


`pytest`


```sh
starknet-compile contracts/briq.cairo --output briq.json --abi briq_abi.json
```

export STARKNET_NETWORK=alpha

starknet-devnet --port 4999
export GATEWAY_URL=http://localhost:4999
export FEEDER_GATEWAY_URL=http://localhost:4999

First version: 0x032558a3801160d4fec8db90a143e225534a3a0de2fb791b370527b76bf18d16