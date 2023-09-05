use poseidon::poseidon_hash_span;
use array::{ArrayTrait, SpanTrait};
use serde::Serde;
use briq_protocol::types::{FTSpec, PackedShapeItem};

fn hash_shape(fts: Span<FTSpec>, shape: Span<PackedShapeItem>) -> felt252 {
    let mut serialized_fts: Array<felt252> = array![];
    fts.serialize(ref serialized_fts);

    let mut serialized_shape: Array<felt252> = array![];
    shape.serialize(ref serialized_shape);

    let hash_1 = poseidon_hash_span(serialized_shape.span());
    let hash_2 = poseidon_hash_span(serialized_fts.span());

    poseidon_hash_span(array![hash_1, hash_2].span())
}
