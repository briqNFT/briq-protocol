// This contract is only declared, and call via LibraryDispatcher & class_hash
#[starknet::contract]
mod test_shape_1 {
    use array::{SpanTrait, ArrayTrait};
    use option::OptionTrait;
    use briq_protocol::types::{PackedShapeItem, FTSpec};
    use briq_protocol::attributes::attribute_manager::IShapeChecker;

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

    fn basic_test_shape(mut shape: Span<PackedShapeItem>, mut fts: Span<FTSpec>) {
        assert(shape.len() == 4, 'bad shape length');
        assert(fts.len() == 1, 'bad ft spec');
        assert(fts.at(0).token_id == @1, 'bad ft spec');
        assert(fts.at(0).qty == @4, 'bad ft spec');

        let shape_items: Array<felt252> = array![
            0x200000003fffffffe, 0x300000003fffffffe, 0x400000003fffffffe, 0x500000003fffffffe
        ];

        let mut i = 0;
        loop {
            if i == shape.len() {
                break;
            }

            let shape = *shape.at(i);
            assert(shape.x_y_z == *shape_items.at(i), 'bad shape item');
       
            i += 1;
        };
    }
}
