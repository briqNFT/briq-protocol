// This contract is only declared, and call via LibraryDispatcher & class_hash
#[starknet::contract]
mod test_shapes {
    use array::{SpanTrait, ArrayTrait};
    use option::OptionTrait;
    use briq_protocol::types::{PackedShapeItem, FTSpec};
    use briq_protocol::booklet::attribute::IShapeChecker;

    #[storage]
    struct Storage {}

    use debug::PrintTrait;

    #[external(v0)]
    impl ShapeChecker of IShapeChecker<ContractState> {
        fn verify_shape(
            self: @ContractState, attribute_id: u64, shape: Span<PackedShapeItem>, fts: Span<FTSpec>
        ) {
            if attribute_id == 0x1 {
                test_shape_1(shape, fts);
            } else if attribute_id == 0x2 {
                test_shape_2(shape, fts);
            } else if attribute_id == 0x3 {
                test_shape_3(shape, fts);
            } else {
                panic(array!['unhandled attribute_id'])
            }
        }
    }

    fn validate_shape_items_position(shape: Span<PackedShapeItem>, expected: Span<felt252>) {
        let mut i = 0;
        loop {
            if i == shape.len() {
                break;
            }

            let shape = *shape.at(i);
            assert(shape.x_y_z == *expected.at(i), 'bad shape item');

            i += 1;
        };
    }

    fn test_shape_1(shape: Span<PackedShapeItem>, fts: Span<FTSpec>) {
        assert(shape.len() == 4, 'bad shape length');
        assert(fts.len() == 1, 'bad ft spec');
        assert(fts.at(0).token_id == @1, 'bad ft spec');
        assert(fts.at(0).qty == @4, 'bad ft spec');

        validate_shape_items_position(
            shape,
            array![
                0x200000003fffffffe_felt252,
                0x300000003fffffffe,
                0x400000003fffffffe,
                0x500000003fffffffe
            ]
                .span()
        );
    }

    fn test_shape_2(shape: Span<PackedShapeItem>, fts: Span<FTSpec>) {
        assert(shape.len() == 3, 'bad shape length');
        assert(fts.len() == 1, 'bad ft spec');
        assert(fts.at(0).token_id == @1, 'bad ft spec');
        assert(fts.at(0).qty == @3, 'bad ft spec');

        validate_shape_items_position(
            shape,
            array![0x200000003fffffffe_felt252, 0x300000003fffffffe, 0x400000003fffffffe,].span()
        );
    }

    fn test_shape_3(shape: Span<PackedShapeItem>, fts: Span<FTSpec>) {
        assert(shape.len() == 2, 'bad shape length');
        assert(fts.len() == 1, 'bad ft spec');
        assert(fts.at(0).token_id == @1, 'bad ft spec');
        assert(fts.at(0).qty == @2, 'bad ft spec');

        validate_shape_items_position(
            shape, array![0x200000003fffffffe_felt252, 0x300000003fffffffe,].span()
        );
    }
}
