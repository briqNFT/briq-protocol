
#[starknet::interface]
trait IERC1155Metadata<TState> {
    fn name(self: @TState) -> felt252;
    fn symbol(self: @TState) -> felt252;
    fn uri(self: @TState, token_id: u256) -> ByteArray;
}

use core::ByteArray;

impl Bytes31Serde of Serde<bytes31> {
    fn serialize(self: @bytes31, ref output: Array<felt252>) {
    }
    fn deserialize(ref serialized: Span<felt252>) -> Option<bytes31> {
        Option::None
    }
}

impl ByteArraySerde of Serde<ByteArray> {
    fn serialize(self: @ByteArray, ref output: Array<felt252>) {
        self.data.serialize(ref output);
        self.pending_word.serialize(ref output);
        self.pending_word_len.serialize(ref output);
    }
    fn deserialize(ref serialized: Span<felt252>) -> Option<ByteArray> {
        let data = Serde::<Array::<bytes31>>::deserialize(ref serialized)?;
        let pending_word = Serde::<felt252>::deserialize(ref serialized)?;
        let pending_word_len = Serde::<usize>::deserialize(ref serialized)?;
        Option::Some(ByteArray { data, pending_word, pending_word_len })
    }
}
