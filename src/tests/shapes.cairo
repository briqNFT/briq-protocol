#[starknet::contract]
mod test_shape_1 {
    use array::{SpanTrait, ArrayTrait};
    use option::OptionTrait;
    use briq_protocol::types::{PackedShapeItem, FTSpec};
    use briq_protocol::shape_verifier::IShapeChecker;

    #[storage]
    struct Storage {}

    use debug::PrintTrait;

    #[external(v0)]
    impl ShapeChecker of IShapeChecker<ContractState> {
        fn verify_shape(
            self: @ContractState, attribute_id: u64, shape: Span<PackedShapeItem>, fts: Span<FTSpec>
        ) {
            if attribute_id == 0x69 {
                basic_test_shape(shape, fts);
            }
        }
    }

    fn basic_test_shape(mut shape: Span<PackedShapeItem>, mut fts: Span<FTSpec>,) {
        assert(shape.len() == 4, 'bad shape length');
        assert(fts.len() == 1, 'bad ft spec');
        assert(fts.at(0).token_id == @1, 'bad ft spec');
        assert(fts.at(0).qty == @4, 'bad ft spec');

        let shapeItem = *shape.pop_front().unwrap();
        assert(shapeItem.x_y_z == 0x200000003fffffffe, 'bad shape item');
        let shapeItem = *shape.pop_front().unwrap();
        assert(shapeItem.x_y_z == 0x300000003fffffffe, 'bad shape item');
        let shapeItem = *shape.pop_front().unwrap();
        assert(shapeItem.x_y_z == 0x400000003fffffffe, 'bad shape item');
        let shapeItem = *shape.pop_front().unwrap();
        assert(shapeItem.x_y_z == 0x500000003fffffffe, 'bad shape item');
    }
}
