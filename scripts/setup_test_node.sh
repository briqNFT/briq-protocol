
# NB: for now, run the starknet devnet node manually using
# starknet-devnet --dump-path devnetstate --accounts 0 --lite-mode --dump-on exit
# then 
# starknet-devnet --dump-path devnetstate --accounts 0 --lite-mode --dump-on exit --load-path devnetstate

export STARKNET_GATEWAY_URL="http://127.0.0.1:5050"
export STARKNET_FEEDER_GATEWAY_URL="http://127.0.0.1:5050"
export STARKNET_NETWORK_ID="localhost"

# export STARKNET_NETWORK="alpha-goerli"
export STARKNET_CHAIN_ID=SN_GOERLI
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount

# NB: may need to be done manually changing ~/.starknet_accounts/starknet_open_zeppelin_accounts.json
starknet deploy_account --account test
WALLET_ADDRESS="0x0489fb007707f2afa97c40c268384c89298f35f88c4b8e77315a2c3ac951cf5b"

# --gateway_url "http://127.0.0.1:5000" --feeder_gateway_url "127.0.0.1:5000" --network_id localhost

# Hashes

starknet_declare () {
    addr="$(starknet declare --contract $1 --account test)"
    comm=$(echo "$addr" | grep 'Contract class hash' | awk '{gsub("Contract class hash: ", "",$0); print $0}')
    printf -v $2 $comm
    echo "$2=$comm"
    echo "$2=$comm" >> "$STARKNET_NETWORK_ID.test_node.txt"
}

starknet_declare artifacts/proxy.json proxy_hash
starknet_declare artifacts/auction.json auction_hash
starknet_declare artifacts/box.json box_hash
starknet_declare artifacts/booklet.json booklet_hash
starknet_declare artifacts/briq_interface.json briq_hash
starknet_declare artifacts/set_interface.json set_hash


# proxy_hash=0x1386b773ca65975b53d30e0ab68f5db05068e26f95641db50ab68abb44a3c2b
# auction_hash=0x4083bd66f88a7ca5d9c11bf1300babad06b330d4c4ba00cf5aac27656998324
# box_hash=0x23fa1847731968ca6d339ae1f96683dab2c0f0e18b8a1ead148f9df89f42885
# booklet_hash=0x70958c495afd76b01a6019b9ef462e619256bb74326038517c9d91deefb2a1e
# briq_hash=0x6aae5142b01646373e323d9bedba127217f425feef54d2db2890c358eeb9275
# set_hash=0x1a5964974c7b0dab5c370932c79c869f3671e9022199c3268f422bd06a99aa6

### Contracts

addr="$(starknet deploy --class_hash $proxy_hash --inputs $WALLET_ADDRESS $auction_hash --account test --max_fee 0)"
export auction_addr=$(echo "$addr" | grep "Contract address: " | awk '{gsub("Contract address: ", "",$0); print $0}')
echo "auction_addr=$auction_addr"
echo "auction_addr=$auction_addr" >> "$STARKNET_NETWORK_ID.test_node.txt"

addr="$(starknet deploy --class_hash $proxy_hash --inputs $WALLET_ADDRESS $box_hash --account test --max_fee 0)"
export box_addr=$(echo "$addr" | grep "Contract address: " | awk '{gsub("Contract address: ", "",$0); print $0}')
echo "box_addr=$box_addr"
echo "box_addr=$box_addr" >> "$STARKNET_NETWORK_ID.test_node.txt"

addr="$(starknet deploy --class_hash $proxy_hash --inputs $WALLET_ADDRESS $booklet_hash --account test --max_fee 0)"
export booklet_addr=$(echo "$addr" | grep "Contract address: " | awk '{gsub("Contract address: ", "",$0); print $0}')
echo "booklet_addr=$booklet_addr"
echo "booklet_addr=$booklet_addr" >> "$STARKNET_NETWORK_ID.test_node.txt"

addr="$(starknet deploy --class_hash $proxy_hash --inputs $WALLET_ADDRESS $briq_hash --account test --max_fee 0)"
export briq_addr=$(echo "$addr" | grep "Contract address: " | awk '{gsub("Contract address: ", "",$0); print $0}')
echo "briq_addr=$briq_addr"
echo "briq_addr=$briq_addr" >> "$STARKNET_NETWORK_ID.test_node.txt"

addr="$(starknet deploy --class_hash $proxy_hash --inputs $WALLET_ADDRESS $set_hash --account test --max_fee 0)"
export set_addr=$(echo "$addr" | grep "Contract address: " | awk '{gsub("Contract address: ", "",$0); print $0}')
echo "set_addr=$set_addr"
echo "set_addr=$set_addr" >> "$STARKNET_NETWORK_ID.test_node.txt"

# auction_addr=0x061f577a6317df31af6bcc1a55a4dfb2a066e7f8dac0685d17b7ea93dbb18330
# box_addr=0x01ef4ce33a6a31ce6d01cae3db43d0885e9cb3a51af5d3e28d147fac4a1986c4
# booklet_addr=0x008c36dfd159194f03315c7fcc8583bc1904ba6d9ebc836a35090231e0f43eba
# briq_addr=0x051d0fbee758c47d91dd1834e2a2128a6d562398b9b50a8ac72a22976e6f3cc9
# set_addr=0x068a270a4c2bbf1f1a7ae1f1aaf3de541e61fb99acd2dcd2ce585b7ead20b663

# Setup

invoke () {
    tx="$(starknet invoke --address $1 --abi artifacts/abis/$2.json --function $3 --inputs $4 --account test --max_fee 0)"
    export tx_hash=$(echo "$tx" | grep "Transaction hash:" | awk '{gsub("Transaction hash: ", "",$0); print $0}')
    echo $tx_hash
}

invoke $box_addr box setBookletAddress_ $booklet_addr
invoke $box_addr box setBriqAddress_ $briq_addr

invoke $set_addr set_interface setBookletAddress_ $booklet_addr
invoke $set_addr set_interface setBriqAddress_ $briq_addr

invoke $briq_addr briq_interface setSetAddress_ $set_addr
invoke $briq_addr briq_interface setBoxAddress_ $box_addr

invoke $booklet_addr booklet setSetAddress_ $set_addr
invoke $booklet_addr booklet setBoxAddress_ $box_addr
