use array::ArrayTrait;
use array::SpanTrait;

use briq_protocol::attributes_registry::AttributesRegistry;

use debug::PrintTrait;

const ADDRESS: felt252 = 0x1234;
const TOKEN_ID: felt252 = 0x1234;

use briq_protocol::utilities::token_uri;


#[test]
#[available_gas(99999999)]
fn test_uri_string() {
    let tb = token_uri::_getUrl(
        0x987755332CAFEBABE123456789809,
        token_uri::uri_part_1,
        token_uri::uri_part_2,
        token_uri::uri_part_3,
        token_uri::uri_part_4,
    );
    //tb.print();

    let tb = token_uri::_getUrl(
        0xCAFE0000000000000000000000000000000000000,
        token_uri::uri_part_1,
        token_uri::uri_part_2,
        token_uri::uri_part_3,
        token_uri::uri_part_4,
    );
    //tb.print();
}