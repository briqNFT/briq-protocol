
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

starknet deploy --contract briq.json --network alpha
starknet deploy --contract set.json --network alpha

export FLASK_APP=starknet_proxy.proxy
flask run

curl http://localhost:5000/init
curl http://localhost:5000/set_contract
```

export ADDRESS="0x003673b845ed7583de3f2cc8cc3bc281c807808ca46e694d385eeb623f2a6cd4"
export SET_ADDRESS="0x0410361304c4a754e9dc87b43a816c731624eb1409d90e72e93ab798b2d4e164"

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