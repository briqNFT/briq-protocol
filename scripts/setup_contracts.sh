
# Hashes

starknet_declare () {
    addr="$(starknet declare --contract $1 --account $ACCOUNT)"
    echo $addr
    comm=$(echo "$addr" | grep 'Contract class hash' | awk '{gsub("Contract class hash: ", "",$0); print $0}')
    printf -v $2 $comm
    echo "$2=$comm"
    echo "$2=$comm" >> "$STARKNET_NETWORK_ID.test_node.txt"
}

starknet_declare artifacts/proxy.json proxy_hash
starknet_declare artifacts/auction.json auction_hash
starknet_declare artifacts/box_nft.json box_hash
starknet_declare artifacts/booklet_nft.json booklet_hash
starknet_declare artifacts/attributes_registry.json attributes_registry_hash
starknet_declare artifacts/briq.json briq_hash
starknet_declare artifacts/set_nft.json set_hash


### Contracts

deploy_proxy() {
    addr="$(starknet deploy --class_hash $proxy_hash --inputs $WALLET_ADDRESS $1 --account $ACCOUNT)"
    echo $addr
    comm=$(echo "$addr" | grep "Contract address: " | awk '{gsub("Contract address: ", "",$0); print $0}')
    printf -v $2 $comm
    echo "$2=$comm"
    echo "$2=$comm" >> "$STARKNET_NETWORK_ID.test_node.txt"
}

# Nonces will fail in testet...
deploy_proxy $auction_hash auction_addr
deploy_proxy $box_hash box_addr
deploy_proxy $booklet_hash booklet_addr
deploy_proxy $attributes_registry_hash attributes_registry_addr
deploy_proxy $set_hash set_addr
deploy_proxy $briq_hash briq_addr

# Setup

invoke () {
    tx=$(starknet invoke --address $1 --abi artifacts/abis/$2.json --function $3 --inputs $4 $5 $6 $7 --account $ACCOUNT)
    export tx_hash=$(echo $tx | grep "Transaction hash:" | awk '{gsub("Transaction hash: ", "",$0); print $0}')
    echo "$2 $3 $tx_hash"
    ((nonce=$nonce+1))
}


# I have to specify max_fee or it tries to estimate_fee with a bad nonce.
invoke () {
    tx=$(starknet invoke --address $1 --abi artifacts/abis/$2.json --function $3 --inputs $4 $5 $6 $7 $8 --account $ACCOUNT --nonce $nonce --max_fee 100000000000000)
    export tx_hash=$(echo $tx | grep "Transaction hash:" | awk '{gsub("Transaction hash: ", "",$0); print $0}')
    echo "$2 $3 $tx_hash"
    ((nonce=$nonce+1))
}

nonce="$(starknet call --address $WALLET_ADDRESS --function get_nonce --no_wallet --abi venv/lib/python3.9/site-packages/starknet_devnet/accounts_artifacts/OpenZeppelin/0.2.1/Account.cairo/Account_abi.json)"
echo $nonce

invoke $box_addr box_nft setBookletAddress_ $booklet_addr
invoke $box_addr box_nft setBriqAddress_ $briq_addr

invoke $set_addr set_nft setAttributesRegistryAddress_ $attributes_registry_addr
invoke $set_addr set_nft setBriqAddress_ $briq_addr

invoke $briq_addr briq setSetAddress_ $set_addr
invoke $briq_addr briq setBoxAddress_ $box_addr

invoke $booklet_addr booklet_nft setAttributesRegistryAddress_ $attributes_registry_addr
invoke $booklet_addr booklet_nft setBoxAddress_ $box_addr

invoke $attributes_registry_addr attributes_registry setSetAddress_ $set_addr
invoke $attributes_registry_addr attributes_registry create_collection_ 1 3 $booklet_addr

# If you have to upgrade
# invoke $attributes_registry_addr attributes_registry upgradeImplementation_ $attributes_registry_hash