use array::ArrayTrait;
use array::SpanTrait;

use briq_protocol::briq_factory::BriqFactory;

use debug::PrintTrait;

const ADDRESS: felt252 = 0x1234;

#[test]
#[available_gas(999999)]
fn test_get_t() {
    BriqFactory::initialise(BriqFactory::decimals);

    assert(BriqFactory::get_current_t() == BriqFactory::decimals, 'bad T');

    BriqFactory::integrate(6478383, 1).print();
    BriqFactory::integrate(10000, 10).print();
    assert(BriqFactory::integrate(6478383, 1) == 647838450000000000000, 'bad T');
    assert(BriqFactory::integrate(6478383, 347174) == 230939137995400000000000000, 'bad T');
}
