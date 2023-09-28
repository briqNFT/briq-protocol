use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use dojo_erc::token::erc1155::interface::IERC1155DispatcherTrait;

use briq_protocol::tests::test_utils::{
    WORLD_ADMIN, DEFAULT_OWNER, DefaultWorld, spawn_briq_test_world, mint_briqs, impersonate
};

use debug::PrintTrait;

#[test]
#[available_gas(30000000)]
// The error is an unwrap failed as we use u256 parameters, but then when storing it should fail to convert back.
#[should_panic(
    expected: ('Option::unwrap failed.', 'ENTRYPOINT_FAILED')
)]
fn test_balance_overflow() {
    let DefaultWorld{world, briq_token, .. } = spawn_briq_test_world();

    let two_power_128: u256 = 340282366920938463463374607431768211456;
    let two_power_128_minus_one = 340282366920938463463374607431768211455;
    assert(two_power_128 == two_power_128_minus_one.into() + 1, 'ok');
    mint_briqs(world, DEFAULT_OWNER(), 1, two_power_128_minus_one);
    mint_briqs(world, DEFAULT_OWNER(), 1, 1);
}
