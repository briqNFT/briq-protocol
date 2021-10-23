
```pip3 install```

```source venv/bin/activate```


`pytest`


```sh
export STARKNET_NETWORK=alpha
starknet-devnet --port 4999
export GATEWAY_URL="http://localhost:4999"
export FEEDER_GATEWAY_URL="http://localhost:4999"

starknet-compile contracts/briq.cairo --output briq.json --abi briq_abi.json
ADD=$(starknet deploy --contract briq.json --gateway_url $GATEWAY_URL --feeder_gateway_url $FEEDER_GATEWAY_URL | grep "Contract")
export ADDRESS=$(echo $ADD | sed "s/Contract address: //")
export ADDRESS=""

export FLASK_APP=starknet_proxy.proxy
flask run
```


First version: 0x032558a3801160d4fec8db90a143e225534a3a0de2fb791b370527b76bf18d16

curl --header "Content-Type: application/json" \
  --request POST \
  --data '{"inputs": { "owner": 17, "token_id": 100, "material": 1 }}' \
  http://localhost:5000/call_func/mint

  curl --header "Content-Type: application/json" \
  --request POST \
  --data '{"inputs": { "owner": 17, "token_id": 101, "material": 1 }}' \
  http://localhost:5000/call_func/mint

  curl --header "Content-Type: application/json" \
  --request POST \
  --data '{"inputs": { "owner": 17 }}' \
  http://localhost:5000/call_func/balance_of

    curl --header "Content-Type: application/json" \
  --request POST \
  --data '{"inputs": { "owner": 17 }}' \
  http://localhost:5000/get_bricks/17