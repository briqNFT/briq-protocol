# Run katana
# Configure for starkli
export STARKNET_RPC="http://localhost:5050/"

# password is katana
export STARKNET_KEYSTORE="scripts/katana_signer"
export KEYSTORE_PWD="katana"

export STARKNET_ACCOUNT="scripts/katana_account.json"
export ACCOUNT_ADDRESS=$(jq .deployment.address scripts/katana_account.json -r)
export TREASURY_ADDRESS="0x33c627a3e5213790e246a917770ce23d7e562baa5b4d2917c23b1be6d91961c"

# https://github.com/dojoengine/dojo/blob/main/crates/katana/core/src/constants.rs
# katana predeployed fee_token_address (uses transferFrom..)
export FEE_TOKEN_ADDR="0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"

sozo build

echo "\nDeclaring class hashes ...\n"

export BRIQ_HASH=$(starkli declare --compiler-version 2.1.0 target/dev/briq_protocol-BriqToken.json --keystore-password $KEYSTORE_PWD)
export SET_HASH=$(starkli declare --compiler-version 2.1.0 target/dev/briq_protocol-SetNft.json --keystore-password $KEYSTORE_PWD)
export ERC1155_HASH=$(starkli declare --compiler-version 2.1.0 target/dev/briq_protocol-GenericERC1155.json --keystore-password $KEYSTORE_PWD)

echo "\n*************************************"
echo BRIQ_HASH=$BRIQ_HASH
echo SET_HASH=$SET_HASH
echo ERC1155_HASH=$ERC1155_HASH
echo "*************************************"

sozo migrate

export WORLD_ADDRESS=0x23aa0e3ffa4663cca36a00577eb9c188aff648568c859735e6de463d41713ec
export EXECUTOR_ADDRESS=0x461be0e8caa002e9fa011760f4412fdad3579afc58cc120f22c794a888bfb6b


echo "\nDeploying contracts ...\n"

export BRIQ_ADDR=$(starkli deploy $BRIQ_HASH $WORLD_ADDRESS --keystore-password $KEYSTORE_PWD)
export BOOKLET_ADDR=$(starkli deploy $ERC1155_HASH $WORLD_ADDRESS --keystore-password $KEYSTORE_PWD)
export BOX_ADDR=$(starkli deploy $ERC1155_HASH $WORLD_ADDRESS --keystore-password $KEYSTORE_PWD)
export SET_ADDR=$(starkli deploy $SET_HASH $WORLD_ADDRESS --keystore-password $KEYSTORE_PWD)

echo "\n*************************************"
echo FEE_TOKEN_ADDR=$FEE_TOKEN_ADDR
echo BRIQ_ADDR=$BRIQ_ADDR
echo BOOKLET_ADDR=$BOOKLET_ADDR
echo BOX_ADDR=$BOX_ADDR
echo SET_ADDR=$SET_ADDR
echo "*************************************"


## Setup World config
sozo execute SetupWorld --world $WORLD_ADDRESS --calldata $ACCOUNT_ADDRESS,$TREASURY_ADDRESS,$BRIQ_ADDR,$SET_ADDR,$BOOKLET_ADDR,$BOX_ADDR 

## Return World config
sozo component entity WorldConfig 1 --world $WORLD_ADDRESS 

## Setup briq_factory
sozo execute BriqFactoryInitialize --world $WORLD_ADDRESS --calldata 0,0,$FEE_TOKEN_ADDR

## Return briq_factory config
sozo component entity BriqFactoryStore 1 --world $WORLD_ADDRESS 

## approve EXECUTOR to spend 1eth FEE_TOKEN
starkli invoke $FEE_TOKEN_ADDR approve $EXECUTOR_ADDRESS u256:1000000000000000000 --keystore-password $KEYSTORE_PWD --watch
starkli call $FEE_TOKEN_ADDR allowance $ACCOUNT_ADDRESS $EXECUTOR_ADDRESS

## Buy 10000 briqs with material_id=1 in briq_factory
sozo execute BriqFactoryMint --world $WORLD_ADDRESS --calldata 1,10000

return


## ACCOUNT_ADDRESS balance : BRIQ
# starkli call $BRIQ_ADDR balance_of $ACCOUNT_ADDRESS u256:1

## ACCOUNT_ADDRESS balance : ETH
# starkli balance $ACCOUNT_ADDRESS