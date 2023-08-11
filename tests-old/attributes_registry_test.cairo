use array::ArrayTrait;
use array::SpanTrait;

use briq_protocol::attributes_registry::AttributesRegistry;

use debug::PrintTrait;

const ADDRESS: felt252 = 0x1234;

#[test]
#[available_gas(999999)]
fn test_assign_attribute() {
    let mut calldata = ArrayTrait::new();
    calldata.append(ADDRESS);
    
    let tb = AttributesRegistry::__external::total_balance(calldata.span());
    assert (*tb.at(0_u32) == 0, 'tb == 0');

    let mut calldata = ArrayTrait::new();
    calldata.append(ADDRESS);
    calldata.append(1234);
    calldata.append(88);
    calldata.append(0);
    calldata.append(0);
    calldata.append(0);
    
    AttributesRegistry::__external::assign_attribute(calldata.span());

    let mut calldata = ArrayTrait::new();
    calldata.append(ADDRESS);
    let tb = AttributesRegistry::__external::total_balance(calldata.span());
    (*tb.at(0_u32)).print();
    assert (*tb.at(0_u32) == 1, 'tb == 1');
}

#[test]
#[available_gas(999999)]
fn test_bad_address() {
    let mut calldata = ArrayTrait::new();
    calldata.append(ADDRESS);
    
    let tb = AttributesRegistry::__external::total_balance(calldata.span());
    assert (*tb.at(0_u32) == 0, 'tb == 0');

    let mut calldata = ArrayTrait::new();
    calldata.append(0);
    calldata.append(1234);
    calldata.append(88);
    calldata.append(0);
    calldata.append(0);
    calldata.append(0);
    
    AttributesRegistry::__external::assign_attribute(calldata.span());
}
