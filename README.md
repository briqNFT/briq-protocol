
```pip3 install```

```source venv/bin/activate```


`pytest`


```sh
export STARKNET_NETWORK=alpha
starknet-devnet --port 4999

scripts/compile.sh

export GATEWAY_URL="http://localhost:4999"
export FEEDER_GATEWAY_URL="http://localhost:4999"
ADD=$(starknet deploy --contract briq.json --gateway_url $GATEWAY_URL --feeder_gateway_url $FEEDER_GATEWAY_URL | grep "Contract")
export ADDRESS=$(echo $ADD | sed "s/Contract address: //")
ADD=$(starknet deploy --contract set.json --gateway_url $GATEWAY_URL --feeder_gateway_url $FEEDER_GATEWAY_URL | grep "Contract")
export SET_ADDRESS=$(echo $ADD | sed "s/Contract address: //")

export FLASK_APP=starknet_proxy.proxy
flask run

curl http://localhost:5000/init
```

export ADDRESS="0x01fe597234df2e00d784b9872493df0012b71256e90a3dc0276b67d1aa36dd5b"
export SET_ADDRESS="0x03989dafaa2d3dd2a08a56ce8f15dfc82e46fa1324e54a46940218a778567598"


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
  --data '{"inputs": { "sender": 17, "recipient": 18, "token_id": 101}}' \
  http://localhost:5000/call_func/transfer_from

    curl --header "Content-Type: application/json" \
  --request POST \
  --data '{"inputs": { "owner": 17 }}' \
  http://localhost:5000/get_bricks/17