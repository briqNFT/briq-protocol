use array::ArrayTrait;
use array::SpanTrait;
use briq_protocol::utilities::authorization::Auth;

#[test]
#[available_gas(999999)]
fn test_increase_amount() {
    assert( 2 == 25, 'Balance aint 25' );
}