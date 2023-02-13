%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.cairo.common.math import (
    assert_le_felt,
    assert_not_zero,
)

from starkware.cairo.common.registers import get_label_location

from contracts.auction_onchain.data_link import AuctionData

from contracts.auction_onchain.allowlist_testnet import _onlyAllowed

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
dw 0x8c03f1eba81afa437bcb45027aaf2ecbfa6e02a1f3bcc64800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// AdventurerDuck.json
dw 0x476b634e1b2b2f1358c54e174a023c0d9ac8e93d6702cafc000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// AirplaneDuck.json
dw 0x5e351d3c56af402b041131199c5ebf85e711fa6006169231000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// AltruisticDuck.json
dw 0x711e7621e6f12873b4be1d3bc4dedae813c1908321485f70000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// AmericanFootballDuck.json
dw 0x7951f12e483e89e08ec146c9842900c2df5a0bf1f39fbf75000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// AngelDuck.json
dw 0x69977e5bb5ca7055e739e32431b52c99c35ea303af87851b800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// AsylumDuck.json
dw 0x332c1cf0dcd8627645158f01675a00f11b7fbd0f23fab536800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// AthenaDuck.json
dw 0x41a4b3e4f5dc4dc499887653b477fd67860b8a4ae9c455df000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// AuctioneerDuck.json
dw 0x3ce4b7670940c19e6dac0b49aa2f834b92664a9b9e9e81c1000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// BDSMDuck.json
dw 0x1c2ed67db5b4d2e399a790d08ed7a6bea0fc80a4eaf8e23b000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// BalletDancerDuck.json
dw 0x56f04a789084ddfb70d1bcac1b65619c8018bc9bbd88d1b4000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// BananaDuck.json
dw 0x4ad5bee0faede9d885cb66f22cfdf2092d477ac766e72139800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// BaoziDuck.json
dw 0x6062933c8e64a55fee7f5f43769cf1cf150df2ae6279cda9000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// BarberDuck.json
dw 0x74824799da877375f863380952fefb4e4dcf0f7ebedd1df0800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// BeeDuck.json
dw 0x77e166e45c0eddf3c7fff4bf273780c40b53b39513578cfa800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// BeeKeeperDuck.json
dw 0x655b66e9bf86a026b9123376813cc3cde5845516fa9d10d2000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// BikerDuck.json
dw 0x75ce12bc8fa572172e9faff249e56b992b19b555f42ca07b000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// BloodsDuck.json
dw 0x2edd6cf2801b05c442cbec70f2a849d8a17fd5c625914f42000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// BrazilianDuck.json
dw 0x2c0569ca4a577328acedf3db463ec1757aa60e7c21ae29f9800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// BriqsDuck.json
dw 0x5aedfc4286badce5fa6833463c836f1dbccce244034be121000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// BuffoonDuck.json
dw 0x22807c32fb8707e3548e5566b65d8691fb78062d6925bd7d000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// ButcherDuck.json
dw 0x1e064ea1607a60cfa09b050799cb2e4948a4121204037818000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// CR7Duck.json
dw 0x42999d674932d13216da8ed2d101ae582c866964cb9700c6000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// CactusDucks.json
dw 0x69b24a7c740fe8593bbbe40604b1ea2ebf567fcfd057d6ed000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// CaesarDuck.json
dw 0x4ca44a49b4ba5752f5f685be67c6181429730ff528b7a33e800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// CarrotDuck.json
dw 0x6132b9fa02f80457d84b785ed6044ebf3249ebf6cec36a69000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// ChaplinDuck.json
dw 0x290ab92837509a90738567be476cca31a5af502c2950aa32800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// ChemistDuck.json
dw 0x52f53d372c6a702edc5b4a0e963af17b8696654ddc59104000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// ChimeraDuck.json
dw 0x58b170da1a7ced3998fbee1c212a8a872f759ff8e1f0c450800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// ClayTennisDuck.json
dw 0x2d828a8d2efe00d8148a0311da72443f9989452351c34850000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// CleaningDuck.json
dw 0x61b3c56725aab9f26f453c04a3327dad2535e0eb37dc61e8000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// CleopatraDuck.json
dw 0x5d5d843270391e6d3bc0c1a9207dd7fb2a9432cec137c5f1800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// CoffeeWaiterDuck.json
dw 0xbedbf79175e209c39fc49cf56e2b842985db28a4baa22eb000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// ColaCanDuck.json
dw 0x28b3a0c208da5b11226272a169436882287e1e87ae710f73000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// ColdDuck.json
dw 0x43476cd40435fe6973de4ce7dc5b197720379d715d3a159f800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// ColvertDuck.json
dw 0x1ed31461b8320205e535f3ea7981c52de4d840b9b3d9947f800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// CosplayDuck.json
dw 0x57a9aef0a3afbf1aa08245a1c707c0a0272e397abf2d0a80000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// CowboyDuck.json
dw 0x273a12d308fb76d7fd82fb153bfe4c5f28c09b6e9e009445000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// CreepyClownDuck.json
dw 0x67bc8f050e8db3cfbae88e5774b312c56279e70cc06352b8000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// CripsDuck.json
dw 0x445047900f2a10ece5471e40fa56775b9065540ae0d59fed800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// CruyffOfTheBalkansDuck.json
dw 0x4d54638ac6e7278cde1899923f223f38fd06cabcc2633cb1000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// DeliveryDuck.json
dw 0x32e8d3d17fd408432e888326c1fb3d54b71f43e96fe29880800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// DevilDuck.json
dw 0x60e152d682be23e7afd2e9bd74f596a034271e1353f981f2000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// DiscoDuck.json
dw 0x1b4ac023f216ca45736b561ed57e399467be04bac9695994800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// DjDuck.json
dw 0x5a048bb9597ec8dcb077ed311725060da0b139a3f8c91509000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// DonutDuck.json
dw 0x489abbc11c41daab631f3169f806356fd3d8efa41f218950800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// DriverDuck.json
dw 0x1cd427e2f365ecd795f790fc91090e1ac3126de5aea7e4f6000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// DruidDuck.json
dw 0x3740af51ed70fc0edf675837558c4dd2d693fef9ff1c042e000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// DrumstickDuck.json
dw 0x560472269e4a3033470676c80345c77a55c98f297988af3a000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// DrunkDuck.json
dw 0x2723d856faffeedbecb39e9a344e2041ef01adc49caf9756800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// DuckjovicDuck.json
dw 0x46b2dab80757e4bfc5579a5f427be8537244025bcb2429fe800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// DuckmanDuck.json
dw 0x58430274bd1840bbfa9832c9d53a1ac7fd195b81e45527d3800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// DucksInBlackDuck.json
dw 0x2217c9e630e96b243e9597e9fe4c50876467f0db5342856e800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// DwarfDuck.json
dw 0x62796fef89fc638562ce1923801e9d3a4026302551ff369c800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// EagleDuck.json
dw 0x5ae41ccaa6311de8febc980d579958a1b6499e22dfd78df4000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// EctoplasmDuck.json
dw 0x438cfc63731ce505b94d4c217c0ae663137191fdd650f9d6000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// EggDuck.json
dw 0x50de198e49ed7e941fc6cf6796841d53b1ef7e5f238a1585000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// EgyptianDuck.json
dw 0x4c18be56db7c6c54629615240927531b65b2fb79b85a9979000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// ElFenomenoDuck.json
dw 0x385e70ba8a81cb2b4c4b66622d1c3c78ca8ac95f2002562f000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// ElPibeDeOroDuck.json
dw 0x4a821b6abbe415add886625a56a27436db3b7c591a6358a3000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// ElfDuck.json
dw 0x4bf2c78940950eec1866f9daf1a62de109072e220eb606fd000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// FarmerDuck.json
dw 0x2b5e16a7eb2629de92f8bdcbd14160bf9fa50b759554614c800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// FencilDuck.json
dw 0x7676c7a9d7292042f30fbaeee6f030a11094a19e1a265e0d800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// FireDuck.json
dw 0x5f83d73c6df3d33033b00481871ebfaf62c36a50c1b659b1000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// FirefighterDuck.json
dw 0x601136471b3debbea2b36d70eb0a720a2c039a7499d72850000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// FirstMatePirate.json
dw 0x1744f54e63532c09f67ee7e283feecb76438d928e54afc11000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// FishermanDuck.json
dw 0x4d80e763b5af55821b7587235acaf680820b0b399f213ded000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// FlamingoDuck.json
dw 0x5b54850da0dff05a8be584471915167dff95c6fea4a0d142800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// FlyingLadyDuck.json
dw 0x2ba130d96187ad29c256259acc47a84ccf14629b8af3a5ff000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// FoolDuck.json
dw 0xf6479f77ad089b6bc425557ec67acaf8e7c1f2c3be041a0800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// FrankensteinDuck.json
dw 0x26db66b8e1156d59f2361c024cfd1050871488459ea08d3e800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// FrenchDuck.json
dw 0x63c9bdce61b17afcb13904fdd6c5dd1b022c660936574a9e000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// FrenchMayorDuck.json
dw 0x51836e42c4562d5a04e4cd35594051fb6b6bf3a0c72232c3800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// FrenchPoliceDuck.json
dw 0x41117a77d25e64c410ab06987d8ea4290816952c94534d2e000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// FunDuck.json
dw 0x28960db6b9eda9273db7653574c26ed07d896feb317d5c5f800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// FunnyClownDuck.json
dw 0x335d3d089e2e77e2275ac68e8eb7af03ddbb7b8e631c6808000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// GardenerDuck.json
dw 0x1ed8c421a32df151f0a9757f181cb46a1b72935d1e58166800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// GasMaskDuck.json
dw 0x6fb65fda28d8992661216b368f875a4b81ed6732696f6a7c800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// GaulChefDuck.json
dw 0x22f99365e4e8c4b60b4cbe2ec9efb3c246f9f910c6fb356800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// GaulChefessDuck.json
dw 0x1f4bf3aa33524969b99321d0cd6bd81c13e94c498a3dc279800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// GhostDuck.json
dw 0x6bcc619b12b222b7ada4b542fd1367c89cea6cd14ba87810000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// GnomeDuck.json
dw 0x2bd163965963f414ad9f6e1491ba85b78a6ab122bdc1c2e1000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// GondolierDuck.json
dw 0xbf778377be6b81a5ebaf70114877c612357d937d3a372be000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// GraduatedDuck.json
dw 0x31949b9d95c1ceb86b2ab46885667a1a4583cc5d1c0dc731800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// GrandpaDuck.json
dw 0x76be0c84a767df1613d3632c3aa7a9c35520b8f3d0df3c0e800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// HeadKnifeDuck.json
dw 0x47af166c2da3648461219f75f39a1d26e015500e8597fbc1800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// HeartDressedDuck.json
dw 0x788d845cbf0fefb3d58ed19aec4fee2bfc743dcd70bda90d000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// HidingDuck.json
dw 0x532ca41e46863c98d71c85deb6429b1e12cff59fbdf4476b800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// HighlighterDuck.json
dw 0x51788c6d0c9bd15a173c8931197c9d75a1b4ebec3c85238f000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// HonduranDuck.json
dw 0x5e55aa6ceab4d5751f46a8ee9a640db2cc38b495009f132f000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// HorseRidingDuck.json
dw 0x64190f65c3565521dd1babe1c6795a8bfc9abf9dbc407281000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// HotDuck.json
dw 0x4c5293e7e522c94feb138d1c445208758a122567d4bc070e800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// HunterDuck.json
dw 0x522b74e149d94ec189f947819b1de1c79f3bda88dbe04d3000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// IceCreamDuck.json
dw 0x71a4421898b3845c58a191950c8c1359ab9e4cbcfbcec6a1000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// IncaDuck.json
dw 0x2967fe366281ee5fdb31ef9e4aa1cb6d806e6be29dddcd9d000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// InvisibleDuck.json
dw 0x548ace1ee625f62b9d4a108bbe989d7a9d97c15820bd14ba800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// IrishDuck.json
dw 0x47fc7069fae27326d34347d379c1f6ede45089e5d6db0fb8800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// ItalianDuck.json
dw 0x2e877f4ba19e5d8dfb5c9cd618003a18ba6e2af0afbd113000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// JediDuck.json
dw 0x110fe925a1642272e2f63cdbba0c9a24ab64f6ce73cfd55a800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// JesusDuck.json
dw 0x54c5236fd550b8ae7ea4487f9eb842b8434e1ba336d9fb72000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// KarateDuck.json
dw 0x799fdafe616f59df963f36ab5cd05df7c0d2d96c2abaa59a800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// KingArthurDuck.json
dw 0x59a2585c32a91d8d74503c2282bd1b24ef55626d85a74f12800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// KnightDuck.json
dw 0x6a1f35717990e1a35f49b16a22a463da5f04fca2d9fb490b000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// LadyOfTheNightDuck.json
dw 0x14ee924125be6bd9eeb9ea07443667b8dd854b3d264db43e000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// LaserEyesDuck.json
dw 0xa8d317769960a0011efaacbfc985df9c61db14b53288936800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// LeprechaunDuck.json
dw 0x21dbe16dc6dd38318f81085d6ec9f2054c3058f18641e961000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// LittleRedDuck.json
dw 0xb75dca83f1160ebed084bb4d1c450d06990d8d5f05c5224800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// LouisXIVDuck.json
dw 0x79073c93968a11bd243b324a1f433140e884f8427a204716800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// LumberjackDuck.json
dw 0x5208f096cdf65d3f0e7db5bd0c6a0e10659ffb864b7edffa800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// MagicianDuck.json
dw 0xc25ea2b4c57e99e8ce2845e43555177fdb11667be3bcaaa000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// MailmanDuck.json
dw 0x6e00ac28ded63f9bbde943f6994ec6d7f14f235650544d94000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// MangosteenDuck.json
dw 0xbbb17d2def4fba90605ec3b04a5d652ef87a86ceee9e801800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// MergedDuck.json
dw 0x1e54efbeb776332e0139ed5dc7d0bc02e482716c2813c06c800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// MermaidDuck.json
dw 0x41610a8b095ccf815d095e7ba602ab7437dc9c7677a931e8800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// MillipedeDuck.json
dw 0x17a840b5484ad375e229115d45399612ff55a271f0cdf02b000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// MimeDuck.json
dw 0x676373043412a7368cca1ede5117082fd87d64d72cdf896c000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// MinerDuck.json
dw 0x23a4f60346d4c2a8a408ae5e09cfe586720f7b481f91b4ed800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// MissDuck.json
dw 0x40d80a8375c122275b408aa227f0e6b7117c8ceec46f1091800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// MonkDuck.json
dw 0x3beab9597f9b5310195a15328a33b783239c276ea0c093e3800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// NapoleonDuck.json
dw 0x1f3a8f13df0ddb743741ffe0da7be6aa49c18b7ae47cfdc7000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// NunDuck.json
dw 0x76742ced02128685ca38f830be1d463dd204469824a90024800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// NurseDuck.json
dw 0x1153884fa1d48fc8556e0bcd19ce9f22c984ade6ab95f648800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// NyanDuck.json
dw 0x172e79f26cf7b6e8dd6ba60d12ecf36b3b3765fd79abc9af800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// PartyDuck.json
dw 0x470d04f921936d80ab695084149f9647a3a2bcd9ac25fe94000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// PastryChefDuck.json
dw 0x2a54a76872d5e8886d4d8d8b68f4efcc26ae31dd34703fa9000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// PenguinDuck.json
dw 0x3b3fe710f29b95f76d1ec097675a96d0eec89b3402124f3d000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// PharmacistDuck.json
dw 0x119265800f67fbd182845b7e28fa4636c88ddc3a3c17b643800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// PianoDuck.json
dw 0x557198c6f402026a165bc8ce4c205aa0ac5972980a2cde5b000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// PigeonDuck.json
dw 0x6d0bd48de59b3916c4dc3288ce58724d0a61cb2df1661a22800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// PineTreeDuck.json
dw 0x22b19b16c601a1b4c35d10e99761d35c7a2c0863ccf574a7800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// PirateDuck.json
dw 0x3b80e96123204f966e661364cc4cd9664069a33a4ca19bab000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// PizzaDuck.json
dw 0x270864d1c2553ab7713897505467a3d7219cf0275f49bfc4800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// PlagueDoctorDuck.json
dw 0x161440197fd60da2da2751ad2a19bb7a70d57ed0271264da800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// PlantDressedDuck.json
dw 0x6ce520fb787cd26db5962db816f1cef5b3a6aff601e6a373000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// PlungerDuck.json
dw 0x334cef7aff02495265ef5a938e16532ef92e9b4c1ea42ad8000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// PopeDuck.json
dw 0x65e692bcc856010ca079171ee9ea8b0f5cf6fe6e7306d7f0000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// PoseidonDuck.json
dw 0x3a19772b776b2e9a74016d867ecb9d0a7ff51e1135606fb4800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// PrehistoricDuck.json
dw 0x3d3130048e8cbac5c90bbf619efc9d62dab521101443e638000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// PrinceDuck.json
dw 0x5708263ccb7e2e8451dee61b331182bafc9f36997eed4757000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// PrincessDuck.json
dw 0x2f7425371647c77ab3d24f484fe01f2f311b8e4b0c1dfbb8800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// PrisonerDuck.json
dw 0x5215693578c139c568faedd63f214da3a059a302ba20c258800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// PumpkinDuck.json
dw 0x1bd4015caf88a405644b25939064f2772076bf36f47d08a0000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// QueensGuardDuck.json
dw 0x1c45aed2586cbd909bf11835be74a52c82535c9ea3d7e7b5000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// RailroaderDuck.json
dw 0x9d0e05f08c822b95d0dca8ca27e2117a64be1dd015ed3c0800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// ReaperDuck.json
dw 0x617c203c6a9232cf20308a1d3c651cc895b3b409a56169b4000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// RedTelephoneBoxDuck.json
dw 0x5778a145ce69ceb7111078056bdda70b212cb382b8ca194c800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// ReindeerDressedDuck.json
dw 0x20e27815e9b25dcb84d4ba64eb72edcc594180ff32580edd000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// RepairManDuck.json
dw 0x691787dd0144ff4d3aca32d6dd4015d2b44df914ef8ff04d000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// RoadSafetyDuck.json
dw 0x767850b6791ff09def36860f3a196a07f759aeb7736456fe800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// RobinHoodDuck.json
dw 0x7eb8ce1238156c526fdfde486de12f983a3faba344bf305000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// RocketShipDuck.json
dw 0x4bfebef6d1ea7337425651ff998209852469283434433757000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// RollerDuck.json
dw 0x32155d67852347aa56551fa1db92cf9c18066ad522e9f955800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// RomanDuck.json
dw 0x329f4a59bfbbd1d867794e8752d56ae0c15540c0ef60cc76000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// RunningDuck.json
dw 0x568247b4584725248317a3ef307b40ca19efc0b8625895cb000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// SailorDuck.json
dw 0x142b24d4afc2dee27923398b829de8db7726063ed582f09a000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// SaintPatrickDuck.json
dw 0x11f78453cc8967ec2d0d9b6948e12040513b45f90ec10cc1800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// SandCastleDuck.json
dw 0x25850deb362e4fa57acb02afaebe000a849c4d3813e60640000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// ScarecrowDuck.json
dw 0x6e9fe49f1368c0e26bec51715c557fb9afde9c50eff9626d800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// ScoutDuck.json
dw 0x3574fe15d1b32bd8cba02de852b7a7023d6e1427a208c544800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// SerialKillerDuck.json
dw 0x60835d0824f72579407f1b4e272af500fa38640634d9001b800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// SheriffDuck.json
dw 0x124781a7cb9a13c7cbf56642681e84bef6876fe26d8a722b000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// SherlockDuck.json
dw 0xe5f7decc4a14f996cce54c753581b4b7ec4c92600b0385e800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// SiamesesDuck.json
dw 0x4c6776975179f727451541c236f65e5f23abd6b20d4d5aa7800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// SickDuck.json
dw 0x67664071a9a65347202f5ff2b4ad63457d68002882ba1c8d800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// SnailDuck.json
dw 0x5e9d6ad75e5890f5aff39821e71756651a23690291228404000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// SnowboardDuck.json
dw 0x25737fed7fb3e911dbf13d81de16a6941d69675093ac41ed000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// SpacemanDuck.json
dw 0x2066301b713809fce599830e5e8ff549a2820bcb41cf2f8d000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// SpanishDuck.json
dw 0x2385e55f8541d7ee8bdd836c7f0f0e0a63a92382aa4b2b2b800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// SpecialForcesDuck.json
dw 0x237ccea67384b8c5e99e21855617b721ed0d04ec774045a000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// SpeleologistDuck.json
dw 0x51d0cb7c1fd916d1d383dc358cc8c0b2522ad96027fbfe9e800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// StarkNetCCDuck.json
dw 0x20cfa42d172b318801dcfd83a41ae39cb688fd6fff0ffa8d000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// StewardessDuck.json
dw 0x4eff9ec234d1fa52b6d31f2a5b7145de744a802a099316ee000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// Stopduck.json
dw 0x4bbea36c0ae4f3e26f870972f35eb1ea30fa5d15e8b0b56c800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// SumoDuck.json
dw 0xd484556cb1db261ff029ff862e47127aa1444f3d881e4bc800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// SurgeonDuck.json
dw 0x1440df99f9c753a798994dacbcef22629735d9229ec6d7f0800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// SwagDuck.json
dw 0x31751a83c1863d522358cbd65264776e4c5edc3d9478e739800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// SwimmerDuck.json
dw 0x4ca9909102d7a1bff3ca6a080f72a8bfb233d6056ae2c4d9000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// TaekwenDuck.json
dw 0x47e8ed1843e854ee508f17b42280ab4850a8dc60812bdf7e000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// ThaiDuck.json
dw 0x56031bc5c61aa673376e1e93b135407e2cafcc3595192f71000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// ToucanDuck.json
dw 0x1408d60893ffc0db4a2544ad97c09f34ac537e079ef2ba5e800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// TrickOrTreatDuck.json
dw 0x896abf16f174275e17c7579fa0879dd685dcc9bd8d16f3c000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// TurkishDuck.json
dw 0x31560aba0fd5add99f14887c5b1a35f65f7f3b0e73be58cb000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// TwirlerDuck.json
dw 0x21af93240486f0e4d830bea0b8dae421ddda86a81aec9e19000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// UFODuck.json
dw 0x3635bc46e39b15e59ed7576f1a48bb11f7db7de797c49aea800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// USADuck.json
dw 0x5787a25d2a026a421065dbf445c23ee105bc71c2001daed1800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// UnicycleDuck.json
dw 0x533a450035823dc1db5cf9dc382c4ad73d7a6c8411042442800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// UpperClassDuck.json
dw 0x1f43c2ff3867fa52b8e47dc3b95aea7a08f0062df3373586800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// UpsideDownDuck.json
dw 0x2e25cc31e3f325082e5f36c18fe5ca85904792581fb2dd8d000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// VRDuck.json
dw 0x15b72a5dc4edfaee458587a93f941ad5a8e800f000c2aa78000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// VampireDuck.json
dw 0x7ee1369e4620134f712dc4357899dc5be016a0522d24c860800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// VeteranDuck.json
dw 0x46fad4f575367a3a5cceef3f983fbb2e693580e07fb32506800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// VietDuck.json
dw 0x162fad70804c9dc35117a1b7d3469c540e9e3a49c591cd78000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// WarriorDuck.json
dw 0xf4fbaf04f0e78b498c8e84aa42d3054172be224614a866e800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// WaterJetDuck.json
dw 0xd852f2964f2266d55852e35a20c933a591885a417f7cbbb800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// WetDuck.json
dw 0x6404efad2e195bafa59560016c65baf4214703948eec82de000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// WitchDuck.json
dw 0x301b9f75e01637a5275e330500364f6f74a2a15fe71d22bd000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// WorkerDuck.json
dw 0x6e5eb1871c4f5173e531ccc0638300270eeea88c90758839000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// YoungDuck.json
dw 0x167447cde14f9df583c5038266401d60fbd1e72c5a4757a5800000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

// ZombieDuck.json
dw 0x40419fb6722b3676c5c738b96477f09b1c6d53a95b8bcc95000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676116600; // start date
dw 86400; // duration

// ZorroDuck.json
dw 0x4696201940cd6cbe8c160def469f0f8cda157c8f5d0cfdd3000000000000000; // token ID
dw 50000000000000000; // minimum bid (wei)
dw 50; // growth factor (in per mil)
dw 1676023000; // start date
dw 86400; // duration

auction_data_end:
