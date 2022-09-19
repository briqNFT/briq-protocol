
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
starknet_declare artifacts/box.json box_hash
starknet_declare artifacts/booklet.json booklet_hash
starknet_declare artifacts/briq.json briq_hash
starknet_declare artifacts/set.json set_hash


# proxy_hash=0x1386b773ca65975b53d30e0ab68f5db05068e26f95641db50ab68abb44a3c2b
# auction_hash=0x4083bd66f88a7ca5d9c11bf1300babad06b330d4c4ba00cf5aac27656998324
# box_hash=0x23fa1847731968ca6d339ae1f96683dab2c0f0e18b8a1ead148f9df89f42885
# booklet_hash=0x70958c495afd76b01a6019b9ef462e619256bb74326038517c9d91deefb2a1e
# briq_hash=0x6aae5142b01646373e323d9bedba127217f425feef54d2db2890c358eeb9275
# set_hash=0x1a5964974c7b0dab5c370932c79c869f3671e9022199c3268f422bd06a99aa6

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
deploy_proxy $set_hash set_addr
deploy_proxy $briq_hash briq_addr

# auction_addr=0x061f577a6317df31af6bcc1a55a4dfb2a066e7f8dac0685d17b7ea93dbb18330
# box_addr=0x01ef4ce33a6a31ce6d01cae3db43d0885e9cb3a51af5d3e28d147fac4a1986c4
# booklet_addr=0x008c36dfd159194f03315c7fcc8583bc1904ba6d9ebc836a35090231e0f43eba
# briq_addr=0x051d0fbee758c47d91dd1834e2a2128a6d562398b9b50a8ac72a22976e6f3cc9
# set_addr=0x068a270a4c2bbf1f1a7ae1f1aaf3de541e61fb99acd2dcd2ce585b7ead20b663

# Setup

# I have to specify max_fee or it tries to estimate_fee with a bad nonce.
invoke () {
    tx=$(starknet invoke --address $1 --abi artifacts/abis/$2.json --function $3 --inputs $4 --account $ACCOUNT --nonce $nonce --max_fee 100000000000000)
    export tx_hash=$(echo $tx | grep "Transaction hash:" | awk '{gsub("Transaction hash: ", "",$0); print $0}')
    echo "$2 $3 $tx_hash"
    ((nonce=$nonce+1))
}

nonce="$(starknet call --address $WALLET_ADDRESS --function get_nonce --no_wallet --abi venv/lib/python3.9/site-packages/starknet_devnet/accounts_artifacts/OpenZeppelin/0.2.1/Account.cairo/Account_abi.json)"
echo $nonce

invoke $box_addr box setBookletAddress_ $booklet_addr
invoke $box_addr box setBriqAddress_ $briq_addr

invoke $set_addr set setBookletAddress_ $booklet_addr
invoke $set_addr set setBriqAddress_ $briq_addr

invoke $briq_addr briq setSetAddress_ $set_addr
invoke $briq_addr briq setBoxAddress_ $box_addr

invoke $booklet_addr booklet setSetAddress_ $set_addr
invoke $booklet_addr booklet setBoxAddress_ $box_addr


# If you have to upgrade
invoke $booklet_addr booklet upgradeImplementation_ $booklet_hash