
# NB: for now, run the starknet devnet node manually using
# starknet-devnet --port 5000 --seed 4285634827
# Then use the wallet #0, private key: 0xaa50075de54918588d5c5347a5a46351

#export STARKNET_GATEWAY_URL="http://127.0.0.1:5000"
#export STARKNET_FEEDER_GATEWAY_URL="http://127.0.0.1:5000"
#export STARKNET_NETWORK_ID="localhost"

export STARKNET_NETWORK="alpha-goerli"

export STARKNET_CHAIN_ID=SN_GOERLI
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount

WALLET_ADDRESS="0x190f6fa63f7263541cd9c927a1664a579618544ccea309a4b6a1f48bd5bf161"

# --gateway_url "http://127.0.0.1:5000" --feeder_gateway_url "127.0.0.1:5000" --network_id localhost

# Hashes

addr="$(starknet declare --contract artifacts/proxy.json --account test)"
export proxy_hash=$(echo "$addr" | grep 'Contract class hash' | awk '{gsub("Contract class hash: ", "",$0); print $0}')
echo "proxy_hash=$proxy_hash"

addr="$(starknet declare --contract artifacts/auction.json --account test)"
export auction_hash=$(echo "$addr" | grep 'Contract class hash' | awk '{gsub("Contract class hash: ", "",$0); print $0}')
echo "auction_hash=$auction_hash"

addr="$(starknet declare --contract artifacts/box.json --account test)"
export box_hash=$(echo "$addr" | grep 'Contract class hash' | awk '{gsub("Contract class hash: ", "",$0); print $0}')
echo "box_hash=$box_hash"

addr="$(starknet declare --contract artifacts/booklet.json --account test)"
export booklet_hash=$(echo "$addr" | grep 'Contract class hash' | awk '{gsub("Contract class hash: ", "",$0); print $0}')
echo "booklet_hash=$booklet_hash"

addr="$(starknet declare --contract artifacts/briq_interface.json --account test)"
export briq_hash=$(echo "$addr" | grep 'Contract class hash' | awk '{gsub("Contract class hash: ", "",$0); print $0}')
echo "briq_hash=$briq_hash"

addr="$(starknet declare --contract artifacts/set_interface.json --account test)"
export set_hash=$(echo "$addr" | grep 'Contract class hash' | awk '{gsub("Contract class hash: ", "",$0); print $0}')
echo "set_hash=$set_hash"

### Contracts

addr="$(starknet deploy --contract artifacts/proxy.json --inputs $WALLET_ADDRESS $auction_hash --account test)"
export auction_addr=$(echo "$addr" | grep "Contract address: " | awk '{gsub("Contract address: ", "",$0); print $0}')
echo "auction_addr=$auction_addr"

addr="$(starknet deploy --contract artifacts/proxy.json --inputs $WALLET_ADDRESS $box_hash --account test)"
export box_addr=$(echo "$addr" | grep "Contract address: " | awk '{gsub("Contract address: ", "",$0); print $0}')
echo "box_addr=$box_addr"

addr="$(starknet deploy --contract artifacts/proxy.json --inputs $WALLET_ADDRESS $booklet_hash --account test)"
export booklet_addr=$(echo "$addr" | grep "Contract address: " | awk '{gsub("Contract address: ", "",$0); print $0}')
echo "booklet_addr=$booklet_addr"

addr="$(starknet deploy --contract artifacts/proxy.json --inputs $WALLET_ADDRESS $briq_hash --account test)"
export briq_addr=$(echo "$addr" | grep "Contract address: " | awk '{gsub("Contract address: ", "",$0); print $0}')
echo "briq_addr=$briq_addr"

addr="$(starknet deploy --contract artifacts/proxy.json --inputs $WALLET_ADDRESS $set_hash --account test)"
export set_addr=$(echo "$addr" | grep "Contract address: " | awk '{gsub("Contract address: ", "",$0); print $0}')
echo "set_addr=$set_addr"

## Setup

#starknet invoke --address $set_addr --abi artifacts/abis/set_interface.json --function setBriqAddress_ --inputs $briq_addr


#starknet invoke 

# await set_contract.setBriqAddress_(briq_contract.contract_address).invoke()
# await set_contract.setBookletAddress_(booklet_contract.contract_address).invoke()
# await briq_contract.setSetAddress_(set_contract.contract_address).invoke()
# await booklet_contract.setSetAddress_(set_contract.contract_address).invoke()
