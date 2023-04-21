use array::ArrayTrait;
use array::SpanTrait;

use debug::PrintTrait;

const ADDRESS: felt252 = 0x1234;
const TOKEN_ID: felt252 = 0x1234;

use briq_protocol::utilities::token_uri;

const uri_part_1: felt252 = 'toto';
const uri_part_2: felt252 = 'toto';
const uri_part_3: felt252 = 'toto';
const uri_part_4: felt252 = 'toto';


#[test]
#[available_gas(99999999)]
fn test_uri_string() {
    let tb = token_uri::_getUrl(
        0x987755332CAFEBABE123456789809,
        uri_part_1,
        uri_part_2,
        uri_part_3,
        uri_part_4,
    );
    //tb.print();
    // Matches 49478092466981316202625096608159753
    assert(*tb[0] == 'toto', '0]Bad conversion');
    assert(*tb[1] == 'toto', '1]Bad conversion');
    assert(*tb[2] == 'toto', '2]Bad conversion'); // 49478092466981316202625096608159753
    assert(*tb[3] == '4', 'Bad conversion3]'); // 9478092466981316202625096608159753
    assert(*tb[4] == '9', 'Bad conversion4]'); // 478092466981316202625096608159753
    assert(*tb[5] == '4', 'Bad conversion5]'); // 78092466981316202625096608159753
    assert(*tb[6] == '7', 'Bad conversion6]'); // 8092466981316202625096608159753
    assert(*tb[7] == '8', 'Bad conversion7]'); // 092466981316202625096608159753
    assert(*tb[8] == '0', 'Bad conversion8]'); // 92466981316202625096608159753
    assert(*tb[9] == '9', 'Bad conversion9]'); // 2466981316202625096608159753
    assert(*tb[10] == '2', 'Bad conversion10'); // 466981316202625096608159753
    assert(*tb[11] == '4', 'Bad conversion11'); // 66981316202625096608159753
    assert(*tb[12] == '6', 'Bad conversion12'); // 6981316202625096608159753
    assert(*tb[13] == '6', 'Bad conversion13'); // 981316202625096608159753
    assert(*tb[14] == '9', 'Bad conversion14'); // 81316202625096608159753
    assert(*tb[15] == '8', 'Bad conversion15'); // 1316202625096608159753
    assert(*tb[16] == '1', 'Bad conversion16'); // 316202625096608159753
    assert(*tb[17] == '3', 'Bad conversion17'); // 16202625096608159753
    assert(*tb[18] == '1', 'Bad conversion18'); // 6202625096608159753
    assert(*tb[19] == '6', 'Bad conversion19'); // 202625096608159753
    assert(*tb[20] == '2', 'Bad conversion20'); // 02625096608159753
    assert(*tb[21] == '0', 'Bad conversion21'); // 2625096608159753
    assert(*tb[22] == '2', 'Bad conversion22'); // 625096608159753
    assert(*tb[23] == '6', 'Bad conversion23'); // 25096608159753
    assert(*tb[24] == '2', 'Bad conversion24'); // 5096608159753
    assert(*tb[25] == '5', 'Bad conversion25'); // 096608159753
    assert(*tb[26] == '0', 'Bad conversion26'); // 96608159753
    assert(*tb[27] == '9', 'Bad conversion27'); // 6608159753
    assert(*tb[28] == '6', 'Bad conversion28'); // 608159753
    assert(*tb[29] == '6', 'Bad conversion29'); // 08159753
    assert(*tb[30] == '0', 'Bad conversion30'); // 8159753
    assert(*tb[31] == '8', 'Bad conversion31'); // 159753
    assert(*tb[32] == '1', 'Bad conversion32'); // 59753
    assert(*tb[33] == '5', 'Bad conversion33'); // 9753
    assert(*tb[34] == '9', 'Bad conversion34'); // 753
    assert(*tb[35] == '7', 'Bad conversion35'); // 53
    assert(*tb[36] == '5', 'Bad conversion36'); // 3
    assert(*tb[37] == '3', 'Bad conversion37');
    assert(*tb[38] == 'toto', 'Bad conversion38');



    let tb = token_uri::_getUrl(
        0xCAFE0000000000000000000000000000000000000,
        uri_part_1,
        uri_part_2,
        uri_part_3,
        uri_part_4,
    );
    //tb.print();
    // Matches 18542088399789477794768722172103116064316452765696
    assert(*tb[0] == 'toto', '0]Bad conversion'); 
    assert(*tb[1] == 'toto', '1]Bad conversion');
    assert(*tb[2] == 'toto', '2]Bad conversion');
    assert(*tb[3] == '1', 'Bad conversion3]'); // 8542088399789477794768722172103116064316452765696
    assert(*tb[4] == '8', 'Bad conversion4]'); // 542088399789477794768722172103116064316452765696
    assert(*tb[5] == '5', 'Bad conversion5]'); // 42088399789477794768722172103116064316452765696
    assert(*tb[6] == '4', 'Bad conversion6]'); // 2088399789477794768722172103116064316452765696
    assert(*tb[7] == '2', 'Bad conversion7]'); // 088399789477794768722172103116064316452765696
    assert(*tb[8] == '0', 'Bad conversion8]'); // 88399789477794768722172103116064316452765696
    assert(*tb[9] == '8', 'Bad conversion9]'); // 8399789477794768722172103116064316452765696
    assert(*tb[10] == '8', 'Bad conversion10'); // 399789477794768722172103116064316452765696
    assert(*tb[11] == '3', 'Bad conversion11'); // 99789477794768722172103116064316452765696
    assert(*tb[12] == '9', 'Bad conversion12'); // 9789477794768722172103116064316452765696
    assert(*tb[13] == '9', 'Bad conversion13'); // 789477794768722172103116064316452765696
    assert(*tb[14] == '7', 'Bad conversion14'); // 89477794768722172103116064316452765696
    assert(*tb[15] == '8', 'Bad conversion15'); // 9477794768722172103116064316452765696
    assert(*tb[16] == '9', 'Bad conversion16'); // 477794768722172103116064316452765696
    assert(*tb[17] == '4', 'Bad conversion17'); // 77794768722172103116064316452765696
    assert(*tb[18] == '7', 'Bad conversion18'); // 7794768722172103116064316452765696
    assert(*tb[19] == '7', 'Bad conversion19'); // 794768722172103116064316452765696
    assert(*tb[20] == '7', 'Bad conversion20'); // 94768722172103116064316452765696
    assert(*tb[21] == '9', 'Bad conversion21'); // 4768722172103116064316452765696
    assert(*tb[22] == '4', 'Bad conversion22'); // 768722172103116064316452765696
    assert(*tb[23] == '7', 'Bad conversion23'); // 68722172103116064316452765696
    assert(*tb[24] == '6', 'Bad conversion24'); // 8722172103116064316452765696
    assert(*tb[25] == '8', 'Bad conversion25'); // 722172103116064316452765696
    assert(*tb[26] == '7', 'Bad conversion26'); // 22172103116064316452765696
    assert(*tb[27] == '2', 'Bad conversion27'); // 2172103116064316452765696
    assert(*tb[28] == '2', 'Bad conversion28'); // 172103116064316452765696
    assert(*tb[29] == '1', 'Bad conversion29'); // 72103116064316452765696
    assert(*tb[30] == '7', 'Bad conversion29'); // 2103116064316452765696
    assert(*tb[31] == '2', 'Bad conversion30'); // 103116064316452765696
    assert(*tb[32] == '1', 'Bad conversion30'); // 03116064316452765696
    assert(*tb[33] == '0', 'Bad conversion31'); // 3116064316452765696
    assert(*tb[34] == '3', 'Bad conversion32'); // 116064316452765696
    assert(*tb[35] == '1', 'Bad conversion33'); // 16064316452765696
    assert(*tb[36] == '1', 'Bad conversion34'); // 6064316452765696
    assert(*tb[37] == '6', 'Bad conversion35'); // 064316452765696
    assert(*tb[38] == '0', 'Bad conversion36'); // 64316452765696
    assert(*tb[39] == '6', 'Bad conversion37'); // 4316452765696
    assert(*tb[40] == '4', 'Bad conversion38'); // 316452765696
    assert(*tb[41] == '3', 'Bad conversion39'); // 16452765696
    assert(*tb[42] == '1', 'Bad conversion40'); // 6452765696
    assert(*tb[43] == '6', 'Bad conversion41'); // 452765696
    assert(*tb[44] == '4', 'Bad conversion42'); // 52765696
    assert(*tb[45] == '5', 'Bad conversion43'); // 2765696
    assert(*tb[46] == '2', 'Bad conversion44'); // 765696
    assert(*tb[47] == '7', 'Bad conversion45'); // 65696
    assert(*tb[48] == '6', 'Bad conversion46'); // 5696
    assert(*tb[49] == '5', 'Bad conversion47'); // 696
    assert(*tb[50] == '6', 'Bad conversion48'); // 96
    assert(*tb[51] == '9', 'Bad conversion49'); // 6
    assert(*tb[52] == '6', '49Bad conversion');
    assert(*tb[53] == 'toto', 'Bad conversion end');
}
