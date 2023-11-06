# Hashes
source "$STARKNET_NETWORK_ID.test_node.txt"

starknet_declare () {
    addr="$(starknet declare --contract $1 --nonce $nonce --deprecated)"
    echo $addr
    comm=$(echo "$addr" | grep 'Contract class hash' | awk '{gsub("Contract class hash: ", "",$0); print $0}')
    printf -v $2 $comm
    echo "$2=$comm"
    echo "$2=$comm" >> "$STARKNET_NETWORK_ID.test_node.txt"
    ((nonce=$nonce+1))
}

nonce=$(starknet get_nonce --contract_address $WALLET_ADDRESS)


starknet_declare artifacts/proxy.json proxy_hash
starknet_declare artifacts/booklet_nft.json booklet_hash
starknet_declare artifacts/attributes_registry.json attributes_registry_hash
starknet_declare artifacts/briq.json briq_hash
starknet_declare artifacts/set_nft.json set_hash
starknet_declare artifacts/shape_attribute.json shape_attribute_hash
starknet_declare artifacts/box_nft.json box_hash
starknet_declare artifacts/briq_factory.json briq_factory_hash

starknet_declare artifacts/shape_store.json shape_store_hash
starknet_declare artifacts/shape_store_ducks.json shape_store_ducks_hash

starknet_declare artifacts/auction.json auction_hash
starknet_declare artifacts/auction_onchain.json auction_onchain_hash
starknet_declare "artifacts/auction_onchain_data_${STARKNET_NETWORK_ID}.json" auction_onchain_data_hash

starknet_declare artifacts/shape_store_zenducks.json shape_store_zenducks_hash


### Contracts

deploy_proxy() {
    addr="$(starknet deploy --class_hash $proxy_hash --inputs $WALLET_ADDRESS $1 --nonce $nonce --max_fee 2220277007180367)"
    echo $addr
    comm=$(echo "$addr" | grep "Contract address: " | awk '{gsub("Contract address: ", "",$0); print $0}')
    printf -v $2 $comm
    echo "$2=$comm"
    echo "$2=$comm" >> "$STARKNET_NETWORK_ID.test_node.txt"
    ((nonce=$nonce+1))
}

# In testnet, nonces will fail to deploy several at one time
nonce=$(starknet get_nonce --contract_address $WALLET_ADDRESS)

deploy_proxy $box_hash box_addr
deploy_proxy $booklet_hash booklet_addr
deploy_proxy $attributes_registry_hash attributes_registry_addr
deploy_proxy $set_hash set_addr
deploy_proxy $briq_hash briq_addr
deploy_proxy $briq_factory_hash briq_factory_addr

deploy_proxy $shape_attribute_hash shape_attribute_addr
deploy_proxy $auction_onchain_hash auction_onchain_addr
deploy_proxy $auction_hash auction_addr
# Setup

invoke () {
    tx=$(starknet invoke --address $1 --abi artifacts/abis/$2.json --function $3 --inputs $4 $5 $6 $7  --nonce $nonce --max_fee 12618293576158800)
    export tx_hash=$(echo $tx | grep "Transaction hash:" | awk '{gsub("Transaction hash: ", "",$0); print $0}')
    echo "$2 $3"
    echo "starknet get_transaction --hash $tx_hash"
    ((nonce=$nonce+1))
}

call () {
    tx=$(starknet call --address $1 --abi artifacts/abis/$2.json --function $3 --inputs $4 $5 $6 $7)
    echo $tx
}


# I have to specify max_fee or it tries to estimate_fee with a bad nonce.
#invoke () {
#    tx=$(starknet invoke --address $1 --abi artifacts/abis/$2.json --function $3 --inputs $4 $5 $6 $7 $8 --account $ACCOUNT --nonce $nonce --max_fee 100000000000000)
#    export tx_hash=$(echo $tx | grep "Transaction hash:" | awk '{gsub("Transaction hash: ", "",$0); print $0}')
#    echo "$2 $3 $tx_hash"
#    ((nonce=$nonce+1))
#}

#nonce="$(starknet call --address $WALLET_ADDRESS --function get_nonce --no_wallet --abi venv/lib/python3.9/site-packages/starknet_devnet/accounts_artifacts/OpenZeppelin/0.2.1/Account.cairo/Account_abi.json)"
#echo $nonce

call $auction_addr box_nft getImplementation_
call $box_addr box_nft getImplementation_
call $booklet_addr box_nft getImplementation_
call $attributes_registry_addr box_nft getImplementation_
call $set_addr box_nft getImplementation_
call $briq_addr box_nft getImplementation_
call $shape_attribute_addr box_nft getImplementation_
call $auction_onchain_addr box_nft getImplementation_

nonce=$(starknet get_nonce --contract_address $WALLET_ADDRESS)

invoke $auction_addr auction setBoxAddress_ $box_addr

invoke $box_addr box_nft setBookletAddress_ $booklet_addr
invoke $box_addr box_nft setBriqAddress_ $briq_addr

invoke $set_addr set_nft setAttributesRegistryAddress_ $attributes_registry_addr
invoke $set_addr set_nft setBriqAddress_ $briq_addr

invoke $briq_addr briq setSetAddress_ $set_addr
invoke $briq_addr briq setBoxAddress_ $box_addr
invoke $briq_addr briq setFactoryAddress_ $briq_factory_addr

invoke $booklet_addr booklet_nft setAttributesRegistryAddress_ $attributes_registry_addr
invoke $booklet_addr booklet_nft setBoxAddress_ $box_addr

invoke $briq_factory_addr briq_factory setBriqAddress_ $briq_addr
# Start at 300000
invoke $briq_factory_addr briq_factory initialise 300000000000000000000000 0 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7

invoke $auction_onchain_addr auction_onchain setPaymentAddress_ 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
invoke $auction_onchain_addr auction_onchain setSetAddress_ $set_addr
invoke $auction_onchain_addr auction_onchain setDataHash_ $auction_onchain_data_hash

invoke $shape_attribute_addr shape_attribute setAttributesRegistryAddress_ $attributes_registry_addr

##
invoke $attributes_registry_addr attributes_registry setSetAddress_ $set_addr
# Collection 1 is GENESIS, supported by contract (thus params = 2) - also briqmas.
invoke $attributes_registry_addr attributes_registry create_collection_ 1 2 $booklet_addr
# Collection 2 is shape hashes, supported by contract (thus params = 2)
invoke $attributes_registry_addr attributes_registry create_collection_ 2 2 $shape_attribute_addr
# Collection 3 is ducks everywhere, same booklet as the genesis collection.
invoke $attributes_registry_addr attributes_registry create_collection_ 3 2 $booklet_addr
# Collection 4 is zenducks, idem
invoke $attributes_registry_addr attributes_registry create_collection_ 4 2 $booklet_addr
# Collection 5 is Ducks x Unframed, this is a non-contract-collection for now.
invoke $attributes_registry_addr attributes_registry create_collection_ 5 0 0x533e327451f538c64a70c08935177435e3d8d8177c4edd0f8a29a88a41e02f5
invoke $attributes_registry_addr attributes_registry increase_attribute_balance_ 0x1000000000000000000000000000000000000000000000005 10
invoke $attributes_registry_addr attributes_registry increase_attribute_balance_ 0x2000000000000000000000000000000000000000000000005 10
invoke $attributes_registry_addr attributes_registry increase_attribute_balance_ 0x3000000000000000000000000000000000000000000000005 10
invoke $attributes_registry_addr attributes_registry increase_attribute_balance_ 0x4000000000000000000000000000000000000000000000005 10
invoke $attributes_registry_addr attributes_registry increase_attribute_balance_ 0x5000000000000000000000000000000000000000000000005 10
invoke $attributes_registry_addr attributes_registry increase_attribute_balance_ 0x6000000000000000000000000000000000000000000000005 10
invoke $attributes_registry_addr attributes_registry increase_attribute_balance_ 0x7000000000000000000000000000000000000000000000005 10
invoke $attributes_registry_addr attributes_registry increase_attribute_balance_ 0x8000000000000000000000000000000000000000000000005 10
invoke $attributes_registry_addr attributes_registry increase_attribute_balance_ 0x9000000000000000000000000000000000000000000000005 10
invoke $attributes_registry_addr attributes_registry increase_attribute_balance_ 0xa000000000000000000000000000000000000000000000005 10

# If you have to upgrade
# invoke $attributes_registry_addr attributes_registry upgradeImplementation_ $attributes_registry_hash

invoke $auction_addr box_nft upgradeImplementation_ $auction_hash
invoke $box_addr box_nft upgradeImplementation_ $box_hash
invoke $booklet_addr box_nft upgradeImplementation_ $booklet_hash
invoke $attributes_registry_addr box_nft upgradeImplementation_ $attributes_registry_hash
invoke $set_addr box_nft upgradeImplementation_ $set_hash
invoke $briq_addr box_nft upgradeImplementation_ $briq_hash
invoke $auction_onchain_addr box_nft upgradeImplementation_ $auction_onchain_hash
invoke $briq_factory_addr briq_factory upgradeImplementation_ $briq_factory_hash

# Don't forget data hash

call $booklet_addr booklet_nft get_shape_ 0x13000000000000000000000000000000000000000000000001

call $auction_onchain_addr auction_onchain get_auction_data 1
call $briq_factory_addr briq_factory get_price 100

#### migration
# on testnet
nonce=$(starknet get_nonce --contract_address $WALLET_ADDRESS)
invoke $briq_addr box_nft upgradeImplementation_ $briq_hash
invoke $briq_addr briq setMigrationAddress_ 0x30e53c44983f6998732095bd61fa998e9008cd479ccc08ea553dfcae86f4880
