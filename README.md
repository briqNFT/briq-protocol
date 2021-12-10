
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

export ADDRESS="0x01d6b126e22d2f805a64fa0ce53ddebcd37363d13ab89960bd2bf896dd2742d4"
export SET_ADDRESS="0x01618ffcb9f43bfd894eb4a176ce265323372bb4d833a77e20363180efca3a65"

starknet deploy --contract mint_proxy.json --network alpha --inputs $ADDRESS
export MINT_ADDRESS="0x03dbda16e85ad0d72cd54ffd2971b4e18e71a4f9d1d310cc8fd2deb564fc8a59"

starknet invoke --function initialize --network alpha --abi briq_abi.json --address $ADDRESS --inputs $SET_ADDRESS $MINT_ADDRESS
starknet invoke --function initialize --network alpha --abi set_abi.json --address $SET_ADDRESS --inputs $ADDRESS

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