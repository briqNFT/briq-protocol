# Run katana
# Configure for starkli
export STARKNET_RPC="http://localhost:5050/"

# password is katana
export STARKNET_KEYSTORE="scripts/katana_signer"
export KEYSTORE_PWD="katana"

export STARKNET_ACCOUNT="scripts/katana_account.json"

export ACCOUNT_ADDRESS=$(jq .deployment.address scripts/katana_account.json -r)

sozo build

echo "\nDeclaring class hashes ...\n"

export BRIQ_HASH=$(starkli declare  --compiler-version 2.1.0 target/dev/briq_protocol-BriqToken.json --keystore-password $KEYSTORE_PWD)
export SET_HASH=$(starkli declare  --compiler-version 2.1.0 target/dev/briq_protocol-SetNft.json --keystore-password $KEYSTORE_PWD)
export ERC1155_HASH=$(starkli declare  --compiler-version 2.1.0 target/dev/briq_protocol-GenericERC1155.json --keystore-password $KEYSTORE_PWD)

echo "\n*************************************"
echo BRIQ_HASH=$BRIQ_HASH
echo SET_HASH=$SET_HASH
echo ERC1155_HASH=$ERC1155_HASH
echo "*************************************"

sozo migrate

export WORLD_ADDRESS=0x23aa0e3ffa4663cca36a00577eb9c188aff648568c859735e6de463d41713ec

echo "\nDeploying contracts ...\n"

export BRIQ_ADDR=$(starkli deploy $BRIQ_HASH $WORLD_ADDRESS --keystore-password $KEYSTORE_PWD)
export BOOKLET_ADDR=$(starkli deploy $ERC1155_HASH $WORLD_ADDRESS --keystore-password $KEYSTORE_PWD)
export BOX_ADDR=$(starkli deploy $ERC1155_HASH $WORLD_ADDRESS --keystore-password $KEYSTORE_PWD)
export SET_ADDR=$(starkli deploy $SET_HASH $WORLD_ADDRESS --keystore-password $KEYSTORE_PWD)

echo "\n*************************************"
echo BRIQ_ADDR=$BRIQ_ADDR
echo BOOKLET_ADDR=$BOOKLET_ADDR
echo BOX_ADDR=$BOX_ADDR
echo SET_ADDR=$SET_ADDR
echo "*************************************"


## Setup Wold config
sozo execute SetupWorld --world $WORLD_ADDRESS --calldata $ACCOUNT_ADDRESS,$BRIQ_ADDR,$SET_ADDR,$BOOKLET_ADDR,$BOX_ADDR 

## Return wolrd config
sozo component entity WorldConfig 1 --world $WORLD_ADDRESS 

return

## Integration tests
# mint briqs for 
#sozo execute ERC1155MintBurn --calldata $WORLD_ADDRESS,$BRIQ_ADDR,0,$ACCOUNT_ADDRESS,1,1,1,100 --world $WORLD_ADDRESS 

# Doesnt' work at all --> should use entity instead of get
#sozo component get ERC1155Balance $BRIQ_ADDR, --world $WORLD_ADDRESS 

# starkli call $BRIQ_ADDR balance_of $ACCOUNT_ADDRESS u256:1
