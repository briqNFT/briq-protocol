%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.cairo.common.math import (
    assert_le_felt,
    assert_not_zero,
)

from starkware.cairo.common.registers import get_label_location

from contracts.auction_onchain.data_link import AuctionData

from contracts.auction_onchain.allowlist_test import _onlyAllowed

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
dw 0x20431ff348589bd51d035db2fd27c1f3de48839e0339d290000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// AdventurerDuck.json
dw 0x4904c8a1e0e2a9cbe86a2db3fe735064208b927fd1864fa1000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// AirplaneDuck.json
dw 0x26d5aae9a6176a10a969db14fa1741549c36e41c851ff994000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// AltruisticDuck.json
dw 0x5fd064cd0020087f6122e6567d4b5383c19c9d653913ad4f800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// AmericanFootballDuck.json
dw 0x1c1be1ef314d5a859d14c39d727c4b31f8194d17cb13960e000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// AngelDuck.json
dw 0x4e025ebb16e05d862b43de0f40286342864d7e3afc640ad4000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// AsylumDuck.json
dw 0x44e37f1563e0184d32e285d0e2163c02edfc2a1763e7efe9000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// AthenaDuck.json
dw 0xfa00c1d3d55669e33782a8ac959898577859523378f6ae1800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// AuctioneerDuck.json
dw 0x161e62a342d51964868553c0875e3cd47d0b368699442580800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// BDSMDuck.json
dw 0x54d3cca9380ca58eeaa025c1a15edecee5abaab96040c3ce800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// BalletDancerDuck.json
dw 0x7247418bf1a46965906d4309d6738f75543d39d9e9706615000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// BananaDuck.json
dw 0x1e229d5db1eaa86a07ac79f0c1722719eb95f7256c9085e9800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// BaoziDuck.json
dw 0x52747a19c6e8387fab66f3d48101319f45c924dac37b69e6000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// BarberDuck.json
dw 0x2c125da0dc68519f56e5d352ac258593d1d64302f9bd7fb9000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// BeeDuck.json
dw 0x75ee79f861fcf8351f74b63a4a16e748d4aac1f7820337000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// BeekeeperDuck.json
dw 0x4da9a25e87dee6da87f4154a0b742c96abd29e4986f44503800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// BikerDuck.json
dw 0x66003d26dbaa0897cbb53545b735cf6652a956e47d140579800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// BloodsDuck.json
dw 0x37e8f46442e5be83b7eb065f232c12f2cecd5d250c527042800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// BrazilianDuck.json
dw 0x3d295d9dc712e5084b8cd81a9d84b6dd9f135f5f6b18a154800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// BriqsDuck.json
dw 0x9f4f8c58be2ad474cba518d29044fe7d2e118dcc8a20c10000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// BuffoonDuck.json
dw 0x18b1a3cf0df77c98841bf4bc880b2a535c350e6c7bc3d16800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ButcherDuck.json
dw 0x638b52a0ea9c5057ec0b8b92f0b8769d74b6ff9e40d3022e800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// CR7Duck.json
dw 0x3a4bcf9c2bc908664b29416098c6768443a9965b6fc54045800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// CactusDucks.json
dw 0x24c289ac0886e2d9b7bfffaa114b97677809ada001a6b177800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// CaesarDuck.json
dw 0x361f165883e26b80b1519cc2b785c62eada6e544fd703011800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// CarrotDuck.json
dw 0x70c3f34a501fb68b8d5310cb15684fbb57b1f67bf9892aa1800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ChaplinDuck.json
dw 0x151a63997c3969c295764a60989d36bf22572a36f5f81e8c800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ChemistDuck.json
dw 0x2e0fc5c40a31d182d77b33c332e9ed82bf0c3f45f680c838800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ChimeraDuck.json
dw 0x12305d5356f27a21426e652f08b53a031f05b464e8b7364c800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ClayTennisDuck.json
dw 0x69f7ce9eef3f5a13e4ebf855266b888256080240232c31bd800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// CleaningDuck.json
dw 0x2b392fa2a92736555fd234dda72e320eeb0cbfec547fe9b5000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// CleopatraDuck.json
dw 0x73209f7c5b19bfdc11d85d904eeeaa564a44bfb284547a2e000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// CoffeeWaiterDuck.json
dw 0x338a5344fa22e9b156d2409b611e9cd70d255c8b49b0e000000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ColaCanDuck.json
dw 0x1909482b73a5fdc7a454ac23a3ea169eb51f94f0200afa03800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ColdDuck.json
dw 0x354d18d84689c2bf84ea0e559800e5278d6f43e585d12b42000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ColvertDuck.json
dw 0x612b47a282c413c4272c9174420100c09e85f5958f2bbdcc800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// CosplayDuck.json
dw 0x5737ee331632e53e3c84018488274e86130780f846176c9a000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// CowboyDuck.json
dw 0x498f3cb496a78cc109a4aadf5953094d6b2ce4eda42a4953800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// CreepyClownDuck.json
dw 0x323004fea0c220311007495476058ce457dce0673770e73e000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// CripsDuck.json
dw 0x4505b9074197eaef07202a4438d1640d30bf09a71bbc8f0b000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// CruyffOfTheBalkansDuck.json
dw 0x58565fd931ec73bab8cd6880e600c149ee51d58417e5b688800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// DeliveryDuck.json
dw 0x79e044aee3ece241c72ceedef98eceebf14d1bf7abbe39ad800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// DevilDuck.json
dw 0x2ca3eb8f0f3bcea5303fd9c726b65e6a61fc20cd02a682ad800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// DiscoDuck.json
dw 0x28046e946948363aaea7d7f1127113ab07f287b20d2be377000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// DjDuck.json
dw 0x46c4a61f549397afaf972fdfb6e4e30617012df9a3a0dd6a000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// DonutDuck.json
dw 0x5e9416ab30289378b95d6dbc296101d6b9669d0bb5078664000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// DriverDuck.json
dw 0x58de274a8d86f60567be0ef2a91b49a02a6bce483f318050800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// DruidDuck.json
dw 0x49abbfe483cf93a9855c388ad7b03e494f197f13ef294d22800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// DrumstickDuck.json
dw 0x5cacd735b6137b45ba11036dde616898ccda14feafa759e6800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// DrunkDuck.json
dw 0x7f01ef771e5c74ff1ad23341107fc5d7518f530872de7f8b800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// DuckjovicDuck.json
dw 0x6c712f57ddf66ab72bba68ad20b24e88af3212018ec286cb000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// DuckmanDuck.json
dw 0x4ab19e8dcba88b1a1c20e349a2102597fef5882e959e49ef800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// DucksInBlackDuck.json
dw 0x599938dafac2c03b4dd82b9706b699bef0f5a2a974f47c05000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// DwarfDuck.json
dw 0x743e7545aabb0b95a50589645cfac697f895d7744930871e800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// EagleDuck.json
dw 0x2c19214f19f35eb59d7fe6529889a0370ae06efdc37ae275000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// EctoplasmDuck.json
dw 0x29c6de383e2539ae867e24f8f3b7477b2557530db741cb01800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// EggDuck.json
dw 0x2a5ef6d348cb39ddaf05853f1003e7f848b5a8bfec1dad36800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// EgyptianDuck.json
dw 0x22223fddd235d545c8efe939da603f428087b866427cce01000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ElFenomenoDuck.json
dw 0x77656b0727f3ad0478d185b057077f4ac7df14b25eaa0905800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ElPibeDeOroDuck.json
dw 0x62261c4cc6b5f84480f800ed7780c1dc22a333bc1c4e969e800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ElfDuck.json
dw 0x10b0a667324304023afb64c164bf1566e76a3d0dee3f927f000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// FarmerDuck.json
dw 0x5bda925546382885e7b826a56018884d2674d1083f18eba1800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// FencilDuck.json
dw 0x481fa788b86bb33901a1e1f5b0d6994d27069bd3a08c0649800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// FireDuck.json
dw 0x45a7c8282e66be2a65c11a699fa8e7023a0adc89ebe930ec000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// FirefighterDuck.json
dw 0x7834e678ca0f6be43bd57880624278452e4482daaff9cee5800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// FirstMatePirate.json
dw 0x657fc615c24c94fc7090e0874e07b0388a2a4d8509f07dcc000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// FishermanDuck.json
dw 0x3e5a9070dd5136055eab22f731104fa47c5eca37fa26d07a000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// FlamingoDuck.json
dw 0x7c2b5575a30a6b7861caec0fd1dbdaae43cbbb6e2e1a752f800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// FlyingLadyDuck.json
dw 0x3d828e89849768b00dd4bddb8a36ee9d9a8a1ef178c9e31b800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// FoolDuck.json
dw 0x109961c28c1c765309b042f6f0a1663dad1c8fa4708df1f5000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// FrankensteinDuck.json
dw 0x323bd4f3a0fd62111ec85cb4a81ad39e35c5d4c3e683ff45000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// FrenchDuck.json
dw 0x698dcc17e0b322deb694c01fedb6947c51e335c7b8a7e546800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// FrenchMayorDuck.json
dw 0x58691267b149a4463caef39ef36c2810010aa6502e09fd60800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// FrenchPoliceDuck.json
dw 0x54e386395d98fae312e9180063fa7fdcb6ce76a2e68f44dd000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// FunDuck.json
dw 0x75dfe8a36f708126f2313edbf3bf0d163e0f083854e794f2800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// FunnyClownDuck.json
dw 0x20d2c738725218f058755fa3bf5e5b92073519ba5acb194e000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// GardenerDuck.json
dw 0x7603e03083cffbdd61a36ad88e1076d4ff4287a307a66245000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// GasMaskDuck.json
dw 0x36632d462b9845646475691c9c6c177840c1d927c6266c3e800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// GaulChefDuck.json
dw 0x743ecb69dbb9cdb795353f94caf7ccaa07642d2988f8bb0800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// GaulChefessDuck.json
dw 0x133583159f011a51db2200440260e819974b0c8a97c3b08e000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// GhostDuck.json
dw 0xa80c784011351af8d66f4bb6262425d8870fa18096ff697800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// GnomeDuck.json
dw 0xdec4d627aa6e8db94c8f84b7b5fc138e00369f89d8384d2800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// GondolierDuck.json
dw 0x7a894304f470dae958e06e5affb360e8eeb43df87c195a7a800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// GraduatedDuck.json
dw 0x2b786f6f5c566b883d74137e4213db9dbd19cd8f7d713c0a000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// GrandpaDuck.json
dw 0x5b0c6ba7dfd2273fdb723cbb455c0bded6d341362394a5a4800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// HeadKnifeDuck.json
dw 0x36cd8716cf52326c7c6afa52eb7255438b1ab133fbed9525000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// HeartDressedDuck.json
dw 0x7e934e256a66f1405baccb049a4ce9850a77a735dd4c187b800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// HidingDuck.json
dw 0x6da80fe7736e8fc0d9898ce3e22b12ab4cda58519de3a4a8800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// HighlighterDuck.json
dw 0x239606460d252a88c59e7a71520845eccffad48843af278b800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// HonduranDuck.json
dw 0x3262b1df298fb4385e6018bb2a7d19ae3be78908048fc092800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// HorseRidingDuck.json
dw 0xcbebe8650e02b8ad6646b6ca272e7a3c4703a13510e321e000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// HotDuck.json
dw 0x67e890bf718a8fba598fbd53a2f8d52c6e2096f72563610b800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// HunterDuck.json
dw 0x19a0afec34e603e7f4ff07b242d043ae4658457e9d90dea8000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// IceCreamDuck.json
dw 0x607b955cd4d39814dfb55e07644e06d46aeacb0af0710b6f800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// IncaDuck.json
dw 0x6c40d249e0c61cb561d95ff83da9f6df844ab32d83444d9a800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// InvisibleDuck.json
dw 0x39dd86aaabf2643c1316f2edeb7323cf1395dceaaf952ec9800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// IrishDuck.json
dw 0x2a27bbad84b4441fbe177a6f7e07843dc13a691293331578000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ItalianDuck.json
dw 0x1feef858b9355ada0202cf93a3aa1c4daa963ed6e17b97ef800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// JediDuck.json
dw 0x5bf25a56ae2c9ad3716caf210a8f1925e37607f74478504e000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// JesusDuck.json
dw 0x4fea57b7b779bf320c230f9fffd901d5b42261419f04b85e800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// KarateDuck.json
dw 0x1400ee758abb7a281de5936aa4833ac5304bfb1b0a4a4565000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// KingArthurDuck.json
dw 0x452ce557fbca406933b54af9abb81748147cfacbee77c3c7000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// KnightDuck.json
dw 0x656a79b361e87c6559e91e852fb5d92a41bd7d99a9ea8c13800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// LadyOfTheNightDuck.json
dw 0x1778f27253f9161ef648361b0fad922d67237ed64c9b7c87000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// LaserEyesDuck.json
dw 0x1e9386bf0b88bee256995a964b35b7f387e5404fceb938c8800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// LeprechaunDuck.json
dw 0x63dfb54e7baab0fd9a8ffe9eaf4174a386adcfe869e9b31e000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// LittleRedDuck.json
dw 0x4717e0008905d29bf45ca5fdaee469ed956bdff5827ba0bb800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// LouisXIVDuck.json
dw 0x3b7e9aec1ae27c976b06fdb430bdc2a8eed4f387c18283c6000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// LumberjackDuck.json
dw 0x504398f388e5a5edfeffa71389fcd7583c38ee40fea968ee800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// MagicianDuck.json
dw 0x155c296d795effa8f2a0b7f25e5a7ac7771df37cc8c50a3f800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// MailmanDuck.json
dw 0x45b1e5cbe43a2cae290be639b9b94fc4bf4d8ebf82a3f0ef000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// MangosteenDuck.json
dw 0x2693dc7a765cf61f7b889888f1abe9844a0e426b00a3ea43800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// MergedDuck.json
dw 0x418be4895de7e3347269611f128a6047643f2438a83b20ed800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// MermaidDuck.json
dw 0x40bafb2c9ea7cceffd3cf5cc0b8a2f34ae6e44585d9c802f800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// MillipedeDuck.json
dw 0x24a7fea1a0948effdcd2bd41887a88bb27521c5b3f07708b000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// MimeDuck.json
dw 0x5d6c1deb2d804e3c106051b7924b7b77c9cfde1acb37ab5e800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// MinerDuck.json
dw 0x77eabf3e6a42cd43402490060f8830cba5e68acccbd685e8800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// MissDuck.json
dw 0x328bbf167f01ced484e6f5c5add4d068f8196f1f3a4d85b8800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// MonkDuck.json
dw 0x5f232221899e3976db76d44ac1cd1a73bc49b680a24702ed000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// NapoleonDuck.json
dw 0x452a03d99e21704aec6618c4710f1df934e2e920b6a74868800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// NunDuck.json
dw 0xe51b05345fca8c336b345126a52d999c92c096c2ca78c68000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// NurseDuck.json
dw 0x131df1ab1589f63651b58256b429874cfab27f3a9ff75db2800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// NyanDuck.json
dw 0x642abebce0f3f549a1b43637d06a6762412628ba90a9a668800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// PartyDuck.json
dw 0x60f4e511d6d3bbb89c48571efdf9803142645bf77d06e606000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// PastryChefDuck.json
dw 0x3f4dd64d3dba20d58ef7c6849ad60c9996689b59f7e61984000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// PenguinDuck.json
dw 0x4691985eb33e968eabd42b8353c402d6f56ed510dfba6051800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// PharmacistDuck.json
dw 0x6f818c766fce3abade6960ba853c0375b8f0f54c9eb80cac000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// PianoDuck.json
dw 0x3ce04c64d36087d65718c4d04e937350de5fc88d6e408456800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// PigeonDuck.json
dw 0x2f288b165181115fe531bc41af8e8a7fda0465ca640a4091000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// PineTreeDuck.json
dw 0x310cdcf20d954c90f5861d0ea91a94502edd5bebfd42ec65000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// PirateDuck.json
dw 0x5b65fab79ff53b77337416672bf2e14537d4f4de332eb9ae800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// PizzaDuck.json
dw 0x417367f8fcf8dd3ff7b535e74fb48fd90b00e31d491cfb8b800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// PlagueDoctorDuck.json
dw 0x25b3778308323285ffc25cc30aa5af49f8221b55c11d9851800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// PlantDressedDuck.json
dw 0x5b8b4c2ed2221d3314c55eb9f5aa426b50a131c825924bc8000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// PlungerDuck.json
dw 0x4868b542aa4a047b660047dfa9b5bbb8c342e71d426d0f4a000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// PopeDuck.json
dw 0x17323eec4ba3bf6d4130c212759ddde50764b28a89541ac7000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// PoseidonDuck.json
dw 0x68cb4e68b87c31af9bbd74f81132003ed723254ce7a5928f800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// PrehistoricDuck.json
dw 0x3ca03060b3949f76ceaa574ad1adfd8a3474e1ad3e8283ef800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// PrinceDuck.json
dw 0xd2750af6e2c9366dc005195d081fbf90fc6153d3f33d384000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// PrincessDuck.json
dw 0x72212ba766d5dc267bbfa887bc1a5786d89bd919043ab49800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// PrisonerDuck.json
dw 0x513a4c14373df0bfefd29c93c0cd641be47a91eacf26ac21800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// PumpkinDuck.json
dw 0x647fa924763498149b6b87f4364c0517acf11bb8f1165788800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// QueensGuardDuck.json
dw 0x316d15c37a1c7823095d7a24326732fa92a99ac09ed64243000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// RailroaderDuck.json
dw 0x569ac9e51d60971667a18e0dcaed8744a7888fdde08e76f4800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ReaperDuck.json
dw 0x25a99133d9143323112ff0aae3da4b645ce8ab315b3159b800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// RedTelephoneBoxDuck.json
dw 0x67aef28e1c1bac80fb055ee1416d29125ed9184fe0766631000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ReindeerDressedDuck.json
dw 0x2d5cec634253e2dde80e509c247bea063b34741e6ae75159800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// RepairManDuck.json
dw 0x18cc7d4ecdfd4d37ab678611ce263b0e064e67baa637f694800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// RoadSafetyDuck.json
dw 0x9b58157c1b99d299bd72a72c6ca20eaeab9075141e298ae000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// RobinHoodDuck.json
dw 0x68b703d611d2cc89ddea818fece6e66c8c8f14935d4016f4800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// RocketShipDuck.json
dw 0x2b25b5c1166a9fc20118312f12f2e62dd48891cbcd046206800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// RollerDuck.json
dw 0x37071a74c041c9bbf30e9120109a8f5fb317b1b98ee78bf7000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// RomanDuck.json
dw 0x74eeecc590bcea4c6280ccc8fbf0b3f0e1b2f0fc83c62f72000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// RunningDuck.json
dw 0xe793253b66faf4f178d12ad8b088a229eb6933c19fe6376800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// SailorDuck.json
dw 0x5050c7debbbc346081aebd2781d56cb158aceaa4f8f0465c000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// SaintPatrickDuck.json
dw 0x10370fc9a0dfd258209880d45c0e5f5a52a4166c82382985800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// SandCastleDuck.json
dw 0xd5f374ce16696294538504db76502efc32bee6b36443624000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ScarecrowDuck.json
dw 0xc89b24e96e3adda975c7ec2cb644a402afbc0b216822bf1800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ScoutDuck.json
dw 0x238a3f7f03adf5a91b3d642cbb4007764d3298e947566bd7800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// SerialKillerDuck.json
dw 0x471bae63eb7b31c2b1cdc9b9a2632499f049ffb8f4922178000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// SheriffDuck.json
dw 0x8417d0f183653bbc3338a0acc9d0b9f38092ddb49b71e29800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// SherlockDuck.json
dw 0x954e88f61247c8353f2f37a73c797b3f27b93d5a1549835000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// SiamesesDuck.json
dw 0x2e2d9533b486395800a0cc26d296e1bab2532e9e56b55963000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// SickDuck.json
dw 0x46529a63fe79cbc4a1f9f4cf517a66e8d44ffe0182997995000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// SnailDuck.json
dw 0x2285acb827e9cba931ded25082881e9f5c30675b510dc8ab800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// SnowboardDuck.json
dw 0x63eab38a5c985ae42b266b0f1861b109c8e8a7e48788cd14800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// SpacemanDuck.json
dw 0x5b4bab3a4b1a5fece447ad7af9b20216e9c14236d8ecbd9e000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// SpanishDuck.json
dw 0x7ab040826a900f4a484c6c40e957e52829ef3edc143f9f1d800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// SpecialForcesDuck.json
dw 0x91902c6f1f41ce73f8be595414720289c43d015ffc21e1c000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// SpeleologistDuck.json
dw 0x32f076113fde04ee3947daae757ac940ff89baa4e9e2a9ed000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// StarkNetCCDuck.json
dw 0x25afd0d107291e873c2139e7910d75155e86b1d50f0ac32a800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// StewardessDuck.json
dw 0x1eb9d4fdbcdf05d83f8236aaf77a98d6954b5a58edc46edf800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// Stopduck.json
dw 0x781350eaac855c3be4b03b510d5bb05fc64d2d834944f119000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// SumoDuck.json
dw 0x5069701919d340c79df5be6232a3cc1cc5fd60773fac748a800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// SurgeonDuck.json
dw 0xe9d28f5aa0e73e8d559061ebb3a3ce0f120d5ba0a12eff4800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// SwagDuck.json
dw 0x6949e78b137ac26afe1f22d960ab778ad8f8e554ab1d5f6e800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// SwimmerDuck.json
dw 0x2ba95461e3cc110fe13e03c96acf6ba91bcc0f3d8ef00b67000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// TaekwenDuck.json
dw 0x1dbf50687f5d32d5e5b9f76b63888265defcd388597d38ac000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ThaiDuck.json
dw 0x3c6e87ce723c02fddc6b3e2f1855c944934a9a8d21056e64000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ToucanDuck.json
dw 0x4ef4294a2ca065f827c760255cdc89ee597d41e2bd86bebd800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// TrickOrTreatDuck.json
dw 0x53ddb02d9b4a7c9ddedc5b16cdf0fcd7c45c66ed509bd5b5000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// TurkishDuck.json
dw 0x32ead81eed1f90785a96d4fb10b6330741f7035582ec5da8800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// TwirlerDuck.json
dw 0x7eae386f36780dbc6a1c7097816b4f6f25c45efe516810bc800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// UFODuck.json
dw 0xdfcfa6b14de714b4156356e89f6b21197e2bfb79ea924cb800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// USADuck.json
dw 0x2039aa07add24dff555d79b96bdf5219049a5311b2539745800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// UnicycleDuck.json
dw 0x3ccaa6be5014aa3acb6b409321ddb8147010070c5d40dc3a000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// UpperClassDuck.json
dw 0x35a7ffcd25a06984b744d85673cec691e34ad736edce2316800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// UpsideDownDuck.json
dw 0x612aea3a1708d78812edc57c125f0c26cc96b3d143bf5dc7800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// VRDuck.json
dw 0x575ffc18a461aea55c7daf3ccb411ce322181a91edbcd69000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// VampireDuck.json
dw 0x390da0f37dfa1ee606349afe9c715285ddeea40053fce5bd800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// VeteranDuck.json
dw 0x14332ae29b44688e330edb1fd017dd4a95b070d995a54de7000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// VietDuck.json
dw 0x6ea88a30eb4cff666dc92d31fd115573407ac5cbe2c94f37800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// WarriorDuck.json
dw 0x11ef6771c92cacd2a08cb8da606dbe31517037c0ad5573a4000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// WaterJetDuck.json
dw 0xa91451830916cf510a296765e97878b1d8916e341761f7d000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// WetDuck.json
dw 0x1050a80450005f160886f816fec663551b2eb4beb7a44e1c000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// WitchDuck.json
dw 0x51b70f3c7470353b9eb7845bc6af325aa11574ac90f7fd19800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// WorkerDuck.json
dw 0x9e3f2a3fc7c4d169adfd16db3bc95076ce1b87715698098000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// YoungDuck.json
dw 0x449b18ed3936e3cbd451556b5c49a59fd4ce74090296e528800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ZombieDuck.json
dw 0x4a2553d6e33c66d9187604cbce9159bbe8038c0c0162f3b2800000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

// ZorroDuck.json
dw 0x1d9a3261e467c6396b408ee4e66c6e6cd3222d320f8af89f000000000000000; // token ID
dw 10000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1674483098; // start date
dw 864000; // duration

auction_data_end:
