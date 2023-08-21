# Run katana
# Configure for starkli
export STARKNET_RPC="http://localhost:5050/"

# password is katana
export STARKNET_KEYSTORE="scripts/katana_signer"

export STARKNET_ACCOUNT="scripts/katana_account.json"

export ACCOUNT_ADDRESS=$(jq .deployment.address scripts/katana_account.json -r)


starkli declare  --compiler-version 2.1.0 target/dev/briq_protocol-BriqToken.json
starkli declare  --compiler-version 2.1.0 target/dev/briq_protocol-SetNft.json
starkli declare  --compiler-version 2.1.0 target/dev/briq_protocol-GenericERC1155.json

BRIQ_HASH=0x021ea5ff87eb7faee063659417bb201918a2ef99a0208ac1acdf29c0e8fbbdbe
ERC1155_HASH=0x05ae1b827310a48a5d03d095ab70a61ad957191c06a738c00be43716f4488412
SET_HASH=0x0198e67b9d8705ba90de0f9b95a7f4e3fc71b1406e0527a8c6f1fdb59cebf9cb

sozo migrate

WORLD_ADDRESS=0x23aa0e3ffa4663cca36a00577eb9c188aff648568c859735e6de463d41713ec

starkli deploy $BRIQ_HASH $WORLD_ADDRESS
starkli deploy $ERC1155_HASH $WORLD_ADDRESS
starkli deploy $ERC1155_HASH $WORLD_ADDRESS
starkli deploy $SET_HASH $WORLD_ADDRESS

BRIQ_ADDR=0x007d2829b6a5c7c0eac8885ca95c338543423cffd8e33c52a92f7be8926f6f61
BOOKLET_ADDR=0x0039dc86205ffde13227be280c630a50a37965e2d7f320ee6c61cc9e0d14e493
BOX_ADDR=0x059e9566317c6177e26fb8fec87d1f5d541cf285d1c195ecd6b0bbd60a432aea
SET_ADDR=0x063dc9cd853bf1ab8015f2aa447958900b18d458a7df61b4279c8512e9801a72

sozo execute SetupWorld --world $WORLD_ADDRESS --calldata $ACCOUNT_ADDRESS,$BRIQ_ADDR,$SET_ADDR,$BOOKLET_ADDR,$BOX_ADDR


## Integration tests
sozo execute ERC1155MintBurn --calldata $WORLD_ADDRESS,$BRIQ_ADDR,0,$ACCOUNT_ADDRESS,1,1,1,100 --world $WORLD_ADDRESS 

# Doesnt' work at all
sozo component get ERC1155Balance --world $WORLD_ADDRESS 

starkli call $BRIQ_ADDR balance_of $ACCOUNT_ADDRESS u256:1
