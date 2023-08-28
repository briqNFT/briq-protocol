# NB: for now, run the starknet devnet node manually using
# starknet-devnet --dump-path devnetstate --dump-on exit
# then 
# starknet-devnet --dump-path devnetstate --dump-on exit --load-path devnetstate

export STARKNET_GATEWAY_URL="http://127.0.0.1:5050"
export STARKNET_FEEDER_GATEWAY_URL="http://127.0.0.1:5050"
export STARKNET_NETWORK_ID="localhost"

# export STARKNET_NETWORK="alpha-goerli"
export STARKNET_CHAIN_ID=SN_GOERLI
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount

# NB: may need to be done manually changing
# rm ~/.starknet_accounts/starknet_open_zeppelin_accounts.json
export ACCOUNT="test"
# info stored in ~/.starknet_accounts/starknet_open_zeppelin_accounts.json
comm=$(starknet deploy_account --account $ACCOUNT)
comm=$(echo "$comm" | grep 'Contract address' | awk '{gsub("Contract address: ", "",$0); print $0}')
export WALLET_ADDRESS=$comm
# Mint some tokens to be able to deploy stuff
curl -H "Content-Type: application/json"  -d "{ \"address\": \"$WALLET_ADDRESS\", \"amount\": 5000000000000000000, \"lite\": 1 }" -X POST localhost:5050/mint
