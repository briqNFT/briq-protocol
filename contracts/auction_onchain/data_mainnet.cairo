%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.cairo.common.math import (
    assert_le_felt,
    assert_not_zero,
)

from starkware.cairo.common.registers import get_label_location

from contracts.auction_onchain.data_link import AuctionData

from contracts.auction_onchain.allowlist_mainnet import _onlyAllowed

@view
func get_auction_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    auction_id: felt,
) -> (
    data: AuctionData,
){
    // For convenience, the whitelist check is done here.
    // This makes it easier to change on a per-network basis, and it's called as part of making bids anyways.
    _onlyAllowed();

    let (start) = get_label_location(auction_data_start);
    let (end) = get_label_location(auction_data_end);
    
    with_attr error_message("Invalid auction_id") {
        assert_not_zero(auction_id);
        assert_le_felt(auction_id, (end - start) / AuctionData.SIZE);
    }

    let data = cast(start + AuctionData.SIZE * (auction_id - 1), AuctionData*)[0];
    return (data,);
}


auction_data_start:
// 80sGymDuck.json
dw 0x7792645181f044a28d6e74f905930986e30960adc478bd7c000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// AdventurerDuck.json
dw 0x38adbc427dcab2fbca475c88e628d6bef53ecd02af95c0d3800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// AirplaneDuck.json
dw 0x1b605d64f69897898d16e3f33937d11f3b87aafd6299fc7a800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// AltruisticDuck.json
dw 0x610580ff3a8c130781115af4f543a161e16ddb4215cd72ac000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// AmericanFootballDuck.json
dw 0x46401cd7c0fdc41b47ee78494f1cd0ba3e9cdeb3fbefbc2e800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// AngelDuck.json
dw 0x3a77a4308c1433cfacc3d243df65661014cff0620f4df9f2000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// AsylumDuck.json
dw 0x4ea587475854b589254a0c5fc660a407b6eeea8db1dd1571000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// AthenaDuck.json
dw 0x61d20a06cb0c3111d2ea79aa9dc7246caad729441997378a000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// AuctioneerDuck.json
dw 0x18206bf8e62b622b42185a40756baeb73b912b092e3b1368000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// BDSMDuck.json
dw 0x70b3523b419acbeaf0e99bf454b42100d3b8d9e1227f23b0800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// BalletDancerDuck.json
dw 0x5b5047ffd085a0a38b341879c2cb53acfe310de04089ac54800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// BananaDuck.json
dw 0x652cbe0f4417dedc108e635463165c278734e087cb423f4a000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// BaoziDuck.json
dw 0x18fd8cdab353be74df24ffad1b22c63d5de0b1d3cafd95c800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// BarberDuck.json
dw 0x3bd8f0c44a7a10bbc82a4ab688c6674fc2794564e0a68cfd000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// BeeDuck.json
dw 0x5e811ff5b14e3ff4ff15c5e09c6e61e814cd60f1b88858cc800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// BeeKeeperDuck.json
dw 0x12542110e7e53cfc48f0aebc9e038fa0eb77798615649ef1800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// BikerDuck.json
dw 0x4a045cb49063a841c74d7aeea73b15062d33d8d57541f184800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// BloodsDuck.json
dw 0x2c48c83c3e03771c8d27f6763230dfa1e7fe140dab9eea27000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// BrazilianDuck.json
dw 0x19b9f2dcdb6b30d3d47adda3573399f4bd2f93e4ea9862fb000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// BriqsDuck.json
dw 0x42f5fc1f7b1845b307807fa05672177c9c5483cd4b7cb847000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// BuffoonDuck.json
dw 0x5438d2e11dfd8ec3315ead84bd95992ee85d5627ec042f4e800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// ButcherDuck.json
dw 0x4d248c1a6026af05e62f4c14e32d9dc17051249cf413e344000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// CR7Duck.json
dw 0x7794e02e2f041dce7129cf75398f0dd044a76c5f828e894a800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// CactusDucks.json
dw 0x16b12b7803bb4e9356e6b6e68c4f4d88f71375491f271321800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// CaesarDuck.json
dw 0x267283846cd745ca6bf8c525fa2fc3d0e088180280636652800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// CarrotDuck.json
dw 0x40a4b89f134aa7be0e549b236f62611f12c4e71fbbe21ec4800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// ChaplinDuck.json
dw 0x22f95d4cb078aaa02fba9a63adfade4080c6666c3be470d9800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// ChemistDuck.json
dw 0x2cb7f3301560331b0115a798f4e7df3030e26be859b28885800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// ChimeraDuck.json
dw 0x556f4a3d8818d531d4a7f52ba6633fb902f9cb2ce8e884bd000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// ClayTennisDuck.json
dw 0x698bbc63686d1c0aa7275c3057ec1869b26578b4b1920a0f000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// CleaningDuck.json
dw 0x2af73d78cf63877e80b5e368c94427ed59a65f4adbe9e413800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// CleopatraDuck.json
dw 0x3c4f84ca2267be0ab3f6637aecd74d3c24f0a67b798ea9c000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// CoffeeWaiterDuck.json
dw 0x3976315f79eec9346d2ecc8c9e891681c8fa85209c016613000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// ColaCanDuck.json
dw 0xf7360b65a8047dbcccdc3165b604f76d3673e7759747597800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// ColdDuck.json
dw 0x3e43b4a8938d1cdb4c965cc28684f3049f4632fc9fb27493800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// ColvertDuck.json
dw 0xc29761463c2748dcabd87e5dbe4062a9bfaa32017ca2b84800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// CosplayDuck.json
dw 0x4c92e211268cecd3df4bae97dca82f78ac81cb867d9f2725000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// CowboyDuck.json
dw 0x7978414605f365b1de24fcd45e68a157644391b1826b86b8000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// CreepyClownDuck.json
dw 0x5e6616479f9a2b2216dac7ecda6549f07f4c03cec5c0c4eb800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// CripsDuck.json
dw 0x343dc05a38e51e61b7bc3c2728bb54f24e5723ed2de06c06000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// CruyffOfTheBalkansDuck.json
dw 0x68eee3e090c14a56401c6615ea9f0baaf8a89d84e1f67f57000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// DeliveryDuck.json
dw 0x36d3bdcd85feaf725262b4950ba48ee5187ec699f4bb016d800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// DevilDuck.json
dw 0x74cf5cee3493acfa0609c0018669a27e57ecf7f93516f97d800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// DiscoDuck.json
dw 0x1845e9ad4f6a1671b180794a5110b80f8ae02db2717cf16a800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// DjDuck.json
dw 0x377109b748bf669fe7d66eb73d3173607995a844622fa2f1000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// DonutDuck.json
dw 0x380d14dbaaa5cca41f254c285a34b632c2f951c8baab1a5a000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// DriverDuck.json
dw 0x224b3016361b7545d6bcbabc13df5bf69f4f9b00cb2237ac800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// DruidDuck.json
dw 0x6b970f12a80019c01b87aff88841f0e3420067496bc4eaf9000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// DrumstickDuck.json
dw 0x18f4779a683d2cf9deb7d335f6a75d66de1b7516366bb3f5000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// DrunkDuck.json
dw 0x56d7b5da922358c134953321e76200804cd6fa816a371ba7800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// DuckjovicDuck.json
dw 0x8b297e075232896729cab4a9b2ee09fee056fbdab1ed7dc000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// DuckmanDuck.json
dw 0x27f5ce1b7b6e86e610dbbeff721771272177453ea06053a8800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// DucksInBlackDuck.json
dw 0x117806922c938639329d7436ab15245c0d9c13579cb5f74d000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// DwarfDuck.json
dw 0x5b2d970c2e081ad52f63ec8b451689514b24024397fb4b93800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// EagleDuck.json
dw 0x51f09183c7e1d3a5cae98a5b3dec93b7727abfed4494268b800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// EctoplasmDuck.json
dw 0x3c1268a6871cd7a7a60dd3158933d91aca61f4808b7d8b5b000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// EggDuck.json
dw 0x7a63d90cdf8b1306ca112b50f9e971a231e0497512553087000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// EgyptianDuck.json
dw 0x68c2af2a9cb9cb73f883cc6333f271772ec076b898ba0d0a000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// ElFenomenoDuck.json
dw 0x3957c81991e9b1b2d44fa197cbcf4bfbf52355061a7c8792800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// ElPibeDeOroDuck.json
dw 0x2bec982ebf9bd3e7b51ff5327ca8f5bdb0e77ff9b20dd139800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// ElfDuck.json
dw 0x79c794c827e932b6b81f7612d8de0011a8799009313d6864000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// FarmerDuck.json
dw 0xeb7258b313d42bf9621f692bdf9e8060e47a030b3790d94000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// FencilDuck.json
dw 0x45c549f9f592f7c86d32b9d39b2531bab1f044a356ac6b99000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// FireDuck.json
dw 0x7fdac3281f4d335900020eb179261fdca4385c2f50d30c1e800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// FirefighterDuck.json
dw 0x4b2260c9e06f14a11dc99f69eab0596f3858193d4a4ca34c800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// FirstMatePirate.json
dw 0x58b043211f8be0e74b1a5f09a233363cab62185ad449b10e000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// FishermanDuck.json
dw 0x2de22c2f8b51eb84fb584bc4716fdcabf36f510750d76de8000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// FlamingoDuck.json
dw 0x45a29bbbb551d122c6e34b45df3ace1ca59db8f74307f04f800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// FlyingLadyDuck.json
dw 0x3c6e852a79a4b83614413c4a26905c63747a81ff2fe8dbca800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// FoolDuck.json
dw 0x252f275eb2555decdd8d33cf8583df1ed7a66c0d986146c800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// FrankensteinDuck.json
dw 0x1963e528d792c6312268140dd2c99516295584204211792c800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// FrenchDuck.json
dw 0x279e0a752229604eb69ce152279bcc0fc790c7e69b992a47000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// FrenchMayorDuck.json
dw 0x4696098b34be0fb2b07201ac0ab2ea0cfa32860242ba7d8000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// FrenchPoliceDuck.json
dw 0x3313b74e8c33189b99f46eacd390eda0587f088f560cb067800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// FunDuck.json
dw 0x6871669d7bbe5b52eb98bf531c4f3c7422009b1f28e6d6c6800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// FunnyClownDuck.json
dw 0x7feccc90f8bd181b03a322e09fda57ca2c39373c45f3d62a800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// GardenerDuck.json
dw 0x20470269ec6252df0188e1b4fe541f9fedfc236acfc8ac92000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// GasMaskDuck.json
dw 0x3a2b0669eb95d962b077311fbbe9008bbb4544b38dbde207800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// GaulChefDuck.json
dw 0x1842c484277f5bb157c0f1ff2886ce71ee96cdeedb25cea3800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// GaulChefessDuck.json
dw 0x51c621318d4935e1606e97354697b914bc80d480abcf7aa8000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// GhostDuck.json
dw 0x1aecb1887e3a949d96fa90254c38a56fba392f992f9fe301000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// GnomeDuck.json
dw 0x282024a953947e5c2794cb8268abe682e0ad7d852f2bfa8a800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// GondolierDuck.json
dw 0x448254631d2618dc8e1de05a09e9d1620e8882c4ec0f6538800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// GraduatedDuck.json
dw 0x613702651a04c51dbd95403eb9b2f615b2d92678464d6789000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// GrandpaDuck.json
dw 0x42c951e8050aa26c8a9a9d97129eac8b206c34d7b0528cab000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// HeadKnifeDuck.json
dw 0x49b56bdb84a28ea6ec7b9862771ade93f59488851efb9c72800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// HeartDressedDuck.json
dw 0x4da6e8d0b5c83b60c08cb85b003c0752f334c165d5733a49000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// HidingDuck.json
dw 0x7761b924ab9984989864b8b557d2339f1b79c71617367063000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// HighlighterDuck.json
dw 0x2312ec9fe5fe6ce72e5adb820b304047a1cb3d9be03433b8000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// HonduranDuck.json
dw 0x7b9115821a0c522939d67857e659be4aa593e79cfe8eb89f000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// HorseRidingDuck.json
dw 0x5cb1a1236ea8f287603109c7664199722f87c501213fbac8800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// HotDuck.json
dw 0x2f0a29ddebcebcb7a7bc5957ee492969bdbe5e9c2f0edd1000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// HunterDuck.json
dw 0x738098d262da5b86d9e66fcc9adfda66878d2b77f8b55169000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// IceCreamDuck.json
dw 0x22a4cf704bc496ff924625da64cb6f2436eda2275c89b2ff800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// IncaDuck.json
dw 0x676798f62a9f11ee25afd4ed4e3961a1463d54802fd6c80b000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// InvisibleDuck.json
dw 0x1b4e5f868591f07100f83be559c14bbbe4232f9acbc67e6d000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// IrishDuck.json
dw 0x3b2ac4b251519320629822be589506d0ebb07e584379825c800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// ItalianDuck.json
dw 0x333f224de3769817c673d7b67528f3e894dbaf13c2f36aba800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// JediDuck.json
dw 0x26fd297bb1bc60c3ab06d25ab6dbe60fb547079fe4253c8d000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// JesusDuck.json
dw 0x39c7082e141e8dc4ad5c89d2e840e0601bb1390b20a199b8000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// KarateDuck.json
dw 0x62af4c1b1f5fb0eca5a7494daa5ebf03c6f48c03ae38960d800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// KingArthurDuck.json
dw 0x53da2b27d06723f29f7e34fb02b3ae50ccf50e5d26e7797d800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// KnightDuck.json
dw 0x2db6ac20fcf79e01407df904ba44732f613726096c2c6cd1000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// LadyOfTheNightDuck.json
dw 0x84dbfcd85ff1b239042b586746f575ddaa4f70c63db7719800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// LaserEyesDuck.json
dw 0x314003dccb3b8d67cd1cae101aec564c3c2267ad55e5b66e000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// LeprechaunDuck.json
dw 0x291646d2138d13ff1b96bd309c46a80ad4c8b072fc151c71000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// LittleRedDuck.json
dw 0x452524b070488f4441cc22626bc26432009801d5278e19a2800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// LouisXIVDuck.json
dw 0x3025c863786baf69003ac44fbb90705d4df544dc8e176e2a000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// LumberjackDuck.json
dw 0x56483a892a02067b4c36d652550a6c4cf381bb4594d24223000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// MagicianDuck.json
dw 0x2c0c1fe12795c83b84065ef059fa274b58f9a742fe7382b6800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// MailmanDuck.json
dw 0x16b812b9963f275cb59c507ac270103b950aa096fc8e12af000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// MangosteenDuck.json
dw 0x1869a255cbb198d72bcc54cfa9f593598cd06b323b25a60e000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// MergedDuck.json
dw 0x63a377c06eb4432133cccaadd5f548f48ebd52b29d20998f000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// MermaidDuck.json
dw 0x304597a68f87126b02d0b7bcd02138d35f3561266a0516b7800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// MillipedeDuck.json
dw 0x3c34146760757b7a0a9605469c5af41fadbbc6f60eabc62f000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// MimeDuck.json
dw 0x24cbc0cef73e239e08398b2f998be4484dda6dd5a6bcb950800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// MinerDuck.json
dw 0x2ca885f9692b6d9205bc4345337c5bf7dc729ba805b04801000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// MissDuck.json
dw 0x5b741007578d8552cd67ae04e646f753991552b2ec52387f000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// MonkDuck.json
dw 0x74297a8711f5a98c8a1199038c810013cc5e11e45b443b08000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// NapoleonDuck.json
dw 0x2cfc5dbd15e395fd598f35bae2300322d0227760be5e9621000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// NunDuck.json
dw 0x450797afa5d9649b9c146038b0d484e6491f67db55aa640d800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// NurseDuck.json
dw 0x9e4613859f9533fa82147e949eb049793c84cdd9b613fe4800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// NyanDuck.json
dw 0x2a76dbdd10246c60d61044902b80a9a3ae3614d304244f60000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// PartyDuck.json
dw 0x61d59415424ab4224e8122a27ef0ffb16a9a025299f9b84c800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// PastryChefDuck.json
dw 0x4e256eb0ef7110fa10a63bdd52a9f3b56a615b0f4a4b5875000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// PenguinDuck.json
dw 0x49e4d038c90f3fa9f74d2cc41d3ff790f32bef7901db4d3b800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// PharmacistDuck.json
dw 0x3ad76f31138a90940aa91f0aa0ae20734ea41170a8c99a3d000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// PianoDuck.json
dw 0x3eb3344fa1eb6b0f9a67b5bb36d6e795c173138d46e3fb7e000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// PigeonDuck.json
dw 0xa388c09ba3435597b496bbb3acbb5f4aab50bd6f752b4fb800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// PineTreeDuck.json
dw 0x615a72272d035d538f968f8be004e9a78297e0cf55bfbf48000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// PirateDuck.json
dw 0xba25b04e23460b5e212ca2ee213fd9aa3fc742a3ebf9680800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// PizzaDuck.json
dw 0x1368ba90d24fd2f527430ed3d93cbd39995031530ef3421e800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// PlagueDoctorDuck.json
dw 0x596913e4bc0ca81da06a540e276a63629fb6f71094496dd4800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// PlantDressedDuck.json
dw 0x5f59271e3f7ce05f6d3361e56abf5cdbf783969f873e6bf800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// PlungerDuck.json
dw 0x76cd3a8780131a5bf77966a4043867908d1e943e0dfee737000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// PopeDuck.json
dw 0x3e57df7873b334bf0ccdc953dd250cd7e8dfad88ffbe9929000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// PoseidonDuck.json
dw 0xfb419fc8591c8e3578867d779f95b5fe4cc2d94fca24446800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// PrehistoricDuck.json
dw 0x2f8a11ced12b0c3c8b6ea05f9453a959efc9fa10902ae249800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// PrinceDuck.json
dw 0x405757dcbf1ad06a0c547179d191c36905021b4409d3611c800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// PrincessDuck.json
dw 0x6803d1425cc820091d6162d5ffe835cfd529d0a8c56a9bd5800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// PrisonerDuck.json
dw 0x18210f774f8371e9a024a81f1e6ac60d13821d0351236b14000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// PumpkinDuck.json
dw 0x3b0ac44ab7f62a08af0fafbda66b61b0e970d0cf3acb5205000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// QueensGuardDuck.json
dw 0x38a7c21caf9c725d7c76f79d4a3d935392bff8b0a5a2cf12000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// RailroaderDuck.json
dw 0x263aa92011e12afdd2d4f116a4d8708af95e19d7ae924986000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// ReaperDuck.json
dw 0x6bbbe2f57ee75b6646c7a7005d3be8f110e4a68bb37bc4dc800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// RedTelephoneBoxDuck.json
dw 0x526e3dbf0da6cebb19a719c80859e51243237065c85e5ddc000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// ReindeerDressedDuck.json
dw 0x1c43a2e781165a2fc328568ebca9dda4fac139bc874c6f66800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// RepairManDuck.json
dw 0x493792761692740b595dce921add6bc35e3f110f127e7652000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// RoadSafetyDuck.json
dw 0x38ced76696ada64b3f5877f63a5cf5e4422aa3bfdc37dc92800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// RobinHoodDuck.json
dw 0x74a14b1cac7815ab6c518845e917354712e7975e57ea0caf000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// RocketShipDuck.json
dw 0x491a3785562086f31ebce50ec056223b9e3e787170211fb4000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// RollerDuck.json
dw 0x5ebb39bd7cd7f8768348e17fec1720e0bde102fd5711e067800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// RomanDuck.json
dw 0x17105d54a33fffdde35c3e3eba4f8f783515778620fef2ed800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// RunningDuck.json
dw 0x464ac6ff2c8ddf8d59acb626cb1cff8612541d834c808eb2000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// SailorDuck.json
dw 0x31aa24948189a48b67a6ec0f100b7d6e494ebf949bd886cf000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// SaintPatrickDuck.json
dw 0x3c0e53c9422d9d765475e4e81c2828d950f78a8759f8c782000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// SandCastleDuck.json
dw 0x6c7d56d2cd9c3960b4d2ec0676b9cd05728d97ba833eac4d000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// ScarecrowDuck.json
dw 0x40163d21ce21456837239b77386b36097f8ef3e69640103b000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// ScoutDuck.json
dw 0x62eb31e8f8449aab5502d0a3a28c8f10223435910b89f8a6000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// SerialKillerDuck.json
dw 0x3db3bc08afbea5165485c7df0d3c4cdf476dfc82001319af000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// SheriffDuck.json
dw 0x79317d7a9747de95040c5d044f06b69d1e9172daaeb0edb5800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// SherlockDuck.json
dw 0x4a11f6a8378b2840fc0017f2c353a2ab85d1213f359b6654000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// SiamesesDuck.json
dw 0x574f1c8e5eb95704a56ecca36142b1cb19d5140d776c3155800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// SickDuck.json
dw 0x20605275e01588555aa64413af2880bc88a19e68d2cb03d000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// SnailDuck.json
dw 0x14e0b042da18eef84df4b2b1914594deed479f11ec7daea4800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// SnowboardDuck.json
dw 0xe67477bb2d314d82625bb0dcae4f5c8555ea5b1b8b800f3800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// SpacemanDuck.json
dw 0x5ef099f5a89b797e5067209eec5c6aefe73de7007f865114800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// SpanishDuck.json
dw 0x292f6be1e3c489a249dcc45d537d05636a7ed5cfaa386305800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// SpecialForcesDuck.json
dw 0x42684ceff87376a0d7311647b7117ad49c8f6b9ed3b32cc5000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// SpeleologistDuck.json
dw 0x1d6d9f3a5e80c32d1bbfd59ddc30b0a0aafebdb6dc3c8000000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// StarkNetCCDuck.json
dw 0x4c1b17450194d894c6586fd73545bb316715cb3f5f69854a000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// StewardessDuck.json
dw 0x29c399a3ce14598cf609a92461809cff3350a5198791341f800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// Stopduck.json
dw 0x19ef2ac7767204a0f24345b1ae97a469fd9c7ba19f89a466800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// SumoDuck.json
dw 0x34a868f7d2dffe0e3cda45fea95d259904c57ed9d5bffe4d800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// SurgeonDuck.json
dw 0x45fbe2f1f58662f0c2794e8e78f9a7a4c50fcc9ad0680f83800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// SwagDuck.json
dw 0x69003279a0fc4bdea78af530a5d41a59238bb6ba8178f3b8000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// SwimmerDuck.json
dw 0x71ea1afe78ecc64e0c7b4e9d743fecb8d5197fcaee517c3b800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// TaekwenDuck.json
dw 0x623cd8fc9e0b8d2d6fb60f9de1e89bab6d0c04eb0bfa695a000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// ThaiDuck.json
dw 0x2e5d4f1386596df3257c47a651a6a81aaf8a9925196c95e7000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// ToucanDuck.json
dw 0x38403215e766a61186d41e070ebb418f344289b8ca7fb085800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// TrickOrTreatDuck.json
dw 0x9820992b7672b2a8fb6c51b4afbb7a9c92c1ce2a370106b800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// TurkishDuck.json
dw 0x1d20bc97c74ca3b31e056106f070816c25f688718816c95b800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// TwirlerDuck.json
dw 0x55c518ecfb7261c39cb23aa15eb9fda259e67541d825c348000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// UFODuck.json
dw 0x6c2836a790f564c0b35f06337a4d78974d2157e97cff3f81000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// USADuck.json
dw 0x3cefb8bb9db073a0d5cdba9585e22a416c6226b9e61c2027800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// UnicycleDuck.json
dw 0x1b50c7931d2f521ba29eba47efb6b1626806e2cb3c8e1a4a000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// UpperClassDuck.json
dw 0x40e963f2ce24330714dc668e8c29b83ce6a118bfc6d66106000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// UpsideDownDuck.json
dw 0x9a6ed4ceca2db72ad62a380f056cd6d2499fef2e3c2d20d000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// VRDuck.json
dw 0x7358d2fd66c72feb9813914d0eb8dd02e98dc536f19890c3800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// VampireDuck.json
dw 0x3b39dc02185d794c6a62369650c9d498cd790431f93997a7800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// VeteranDuck.json
dw 0xcb6538aa4c1b737ae425575bffeb60d184bba2828bf0764800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// VietDuck.json
dw 0x63100a601760514df36a3c0f5930587b80265c0408e09299800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// WarriorDuck.json
dw 0x464bac6988d1f4458d867008794381690a4e8a658dc2b8a3000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// WaterJetDuck.json
dw 0x607b29c1c66d5b2a82b02919d14921bd11305593a3b35956000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// WetDuck.json
dw 0x1a1e64bc17e82f1b10282a2f9695cad73a41b09e341f24e6800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// WitchDuck.json
dw 0x4b0e71e477486ea15edb9e364ff54e342d9de0273ed00b0a000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// WorkerDuck.json
dw 0x350db6ba64201e490e535f6c5b8aa4f645a9682c43bbbcdc000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// YoungDuck.json
dw 0x4904f75e2a5e4141ef01223213d526613d339fdd71847aa800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

// ZombieDuck.json
dw 0x2d2956da0c2887cc4e0ea14c7aca4768912ce4f6f269b989000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676383200; // start date
dw 86400; // duration

// ZorroDuck.json
dw 0x2e5008278cf89cb4362c7038480d9e1cbe3034a749255bb2800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676289600; // start date
dw 10; // duration

auction_data_end:
