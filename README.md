
```source venv/bin/activate```

```pip3 install -r requirements```
```pip3 install flask_async```



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
curl http://localhost:5000/set_contract
```

export ADDRESS="0x038d7dcf276620757d268ef2505bc06ea3e8d8c1d601abacbccb0acb5786a6ff"
export SET_ADDRESS="0x0282b3b0ae1241b909fddeaf75a65fb5fc70a935c704105c7bb4edbd1054da2d"

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