# Source one of the setup scripts.

sozo build

sozo migrate --name test-0 --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD

export WORLD_ADDRESS=0x4c66c4619cb38939e508adca17d9697b460cc28e22a86829326c1eca54dbfc0
export EXECUTOR_ADDRESS=0x5c3494b21bc92d40abdc40cdc54af66f22fb92bf876665d982c765a2cc0e06a
export BRIQ_ADDR=0x444f8c5f1ed2a4a291b04e211123ed495e010ca1c195f243e8a2ce3dc8a5754
export SET_ADDR=0x3c8c5a1f01aa2e0608bf0c663b4de8f84edcc280b10429f4c181d764c192d44
export SETUP_WORLD_ADDR=0x1de23a504cc9d32771580a0798a75d744cad32905f8f5965f4a6e538314384e
export BRIQ_FACTORY_ADDR=0x36dcc86ee71c5e389737ec31efcacbb76ec47aac43ba945b1ff0be960df84b9
export ATTRIBUTE_GROUPS_ADDR=0x6acc9ee2e764fde5369525440a13701caf8585f5b6887c85680b3270cc5577a
export REGISTER_SHAPE_VALIDATOR_ADDR=0x551d45c5590bd19f77577937cc3e4a4b9c0c219a21512bd0c148525b4d561ec
export BOX_NFT_ADDR=0xcc95ee1addf7fe4db0d869597922c133e2047b5fa01f9d9de6fa392105acbd
export BOOKLET_DUCKS_ADDR=0x5688b6b04f1e6e9304870bf12c810844bad658eb60715277eed9351341d6ee1
export BOOKLET_STARKNET_PLANET_ADDR=0x44aab1e30326ff94263034e34953fd13c9e155939299031181bda7485c7b9ac
export SET_NFT_DUCKS_ADDR=0x204634c0b3e140517e5cb8f2a7c7e826c8a2ec44bedf7fe82337eff716b4a9e
export SET_NFT_1155_ADDR=0x5882fcc57a4d5cbcc25ded6db4036b7b05485743a5a020cc03f4d1365edbb21

echo "\n*************************************"
echo FEE_TOKEN_ADDR=$FEE_TOKEN_ADDR
echo BRIQ_ADDR=$BRIQ_ADDR
echo SET_ADDR=$SET_ADDR
echo FACTORY_ADDR=$FACTORY_ADDR
echo DUCKS_ADDR=$DUCKS_ADDR
echo DUCK_BOOKLET_ADDR=$DUCK_BOOKLET_ADDR
echo BOX_ADDR=$BOX_ADDR
echo "*************************************"

starkli invoke $BRIQ_ADDR init_world $WORLD_ADDRESS --keystore-password $KEYSTORE_PWD
starkli invoke $SET_ADDR init_world $WORLD_ADDRESS --keystore-password $KEYSTORE_PWD
starkli invoke $BRIQ_FACTORY_ADDR init_world $WORLD_ADDRESS --keystore-password $KEYSTORE_PWD
starkli invoke $BOX_NFT_ADDR init_world $WORLD_ADDRESS --keystore-password $KEYSTORE_PWD
starkli invoke $BOOKLET_DUCKS_ADDR init_world $WORLD_ADDRESS --keystore-password $KEYSTORE_PWD
starkli invoke $BOOKLET_STARKNET_PLANET_ADDR init_world $WORLD_ADDRESS --keystore-password $KEYSTORE_PWD
starkli invoke $SET_NFT_DUCKS_ADDR init_world $WORLD_ADDRESS --keystore-password $KEYSTORE_PWD
starkli invoke $SET_NFT_1155_ADDR init_world $WORLD_ADDRESS --keystore-password $KEYSTORE_PWD

## Setup World config
#sozo execute SetupWorld --world $WORLD_ADDRESS --calldata $TREASURY_ADDRESS,$BRIQ_ADDR,$SET_ADDR,$FACTORY_ADDR --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
starkli invoke $SETUP_WORLD_ADDR execute $WORLD_ADDRESS $TREASURY_ADDRESS $BRIQ_ADDR $SET_ADDR $FACTORY_ADDR --keystore-password $KEYSTORE_PWD

## Return World config
sozo component entity WorldConfig 1 --world $WORLD_ADDRESS
#starkli call $WORLD_ADDRESS entity str:WorldConfig 1 1 0 4 4 251 251 251 251

## Setup briq_factory
#sozo execute BriqFactoryInitialize --world $WORLD_ADDRESS --calldata 0,0,$FEE_TOKEN_ADDR --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
starkli invoke $BRIQ_FACTORY_ADDR initialize 0 0 $FEE_TOKEN_ADDR --keystore-password $KEYSTORE_PWD

## Return briq_factory config
sozo component entity BriqFactoryStore 1 --world $WORLD_ADDRESS

#### Setup authorizations

starkli invoke $SETUP_WORLD_ADDR register_set_contract $WORLD_ADDRESS $SET_ADDR 1 --keystore-password $KEYSTORE_PWD

sozo auth writer ERC1155Balance BriqFactoryMint --world $WORLD_ADDRESS --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
sozo auth writer BriqFactoryStore BriqFactoryMint --world $WORLD_ADDRESS --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD

sozo auth writer ERC721Balance set_nft_assembly --world $WORLD_ADDRESS --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
sozo auth writer ERC721Owner set_nft_assembly --world $WORLD_ADDRESS --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
sozo auth writer ERC1155Balance set_nft_assembly --world $WORLD_ADDRESS --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD

sozo auth writer ERC721Balance set_nft_disassembly --world $WORLD_ADDRESS --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
sozo auth writer ERC721Owner set_nft_disassembly --world $WORLD_ADDRESS --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
sozo auth writer ERC1155Balance set_nft_disassembly --world $WORLD_ADDRESS --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD



## approve EXECUTOR to spend 1eth FEE_TOKEN
starkli invoke $FEE_TOKEN_ADDR approve $FACTORY_ADDR u256:1000000000000000000 --keystore-password $KEYSTORE_PWD
starkli call $FEE_TOKEN_ADDR allowance $ACCOUNT_ADDRESS $FACTORY_ADDR

## Buy 1000 briqs with material_id=1 in briq_factory
# sozo execute BriqFactoryMint --world $WORLD_ADDRESS --calldata $ACCOUNT_ADDRESS,1,1000 --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
starkli invoke $FACTORY_ADDR buy 1 1000 --keystore-password $KEYSTORE_PWD

## ACCOUNT_ADDRESS balance : BRIQ
starkli call $BRIQ_ADDR balance_of $ACCOUNT_ADDRESS u256:1

starkli invoke $SET_ADDR assemble $ACCOUNT_ADDRESS 341987491384 1 str:toto 1 str:desc 1 1 1 1 1 1 0 --keystore-password $KEYSTORE_PWD

sozo execute set_nft_assembly --world $WORLD_ADDRESS \
    --calldata "8904,\
$ACCOUNT_ADDRESS,\
3417423384,\
1,23423,\
1,41343,\
1,1,1,\
1,1,1,\
0"\
    --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD

## Upgrade

starkli invoke $FACTORY_ADDR upgrade $FACTORY_HASH --keystore-password $KEYSTORE_PWD
starkli invoke $SET_ADDR upgrade $SET_HASH --keystore-password $KEYSTORE_PWD
