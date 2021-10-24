
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

export ADDRESS="0x04aabebdf46043787c3da64aa2852a6e6062c1dbe5dcee51313c18cb2916fa89"
export SET_ADDRESS="0x01e419c44afff349e65848be339ad01fb62dd9ac56a3720a366f32de754ef8d5"

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