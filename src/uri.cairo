use to_byte_array::{FormatAsByteArray, AppendFormattedToByteArray};

use starknet::info::get_tx_info;

fn get_api_url() -> ByteArray {
    let chain_id = get_tx_info().unbox().chain_id;
    if chain_id == 'SN_MAIN' {
        return "https://api.briq.construction/v1/";
    } else if chain_id == 'SN_GOERLI' {
        return "https://api.test.sltech.company/v1/";
    } else {
        return "https://api.briq.construction/v1/";
    }
}

fn get_url(path: ByteArray, token_id: u256) -> Array<felt252> {
    (get_api_url() + path + "/" + token_id.format_as_byte_array(10_u256.try_into().unwrap()) + ".json").into()
}

impl ByteArrayToArrayFelt of Into<ByteArray, Array<felt252>> {
    fn into(self: ByteArray) -> Array<felt252> {
        let mut result: Array<felt252> = array![];
        let mut span = self.data.span();
        loop {
            if span.len() == 0 {
                break;
            }
            let word = *(span.pop_front().unwrap());
            result.append(word.into());
        };
        if self.pending_word_len > 0 {
            result.append(self.pending_word.into());
        }
        result
    }
}
