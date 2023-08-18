#[starknet::contract]
mod test_shape_1 {
    use array::{SpanTrait, ArrayTrait};
    use option::OptionTrait;
    use briq_protocol::types::{ShapeItem, FTSpec};
    use briq_protocol::check_shape::IShapeChecker;

    #[storage]
    struct Storage {}

    use debug::PrintTrait;

    #[external(v0)]
    impl ShapeChecker of IShapeChecker<ContractState>
    {
        fn verify_shape(self: @ContractState, token_id: felt252, shape: Span<ShapeItem>, fts: Span<FTSpec>)
        {
            if token_id == 1 {
                basic_test_shape(shape, fts);
            }
        }
    }

    fn basic_test_shape(
        mut shape: Span<ShapeItem>,
        mut fts: Span<FTSpec>,
    ) {
        assert(shape.len() == 4, 'bad shape length');
        assert(fts.len() == 1, 'bad ft spec');
        assert(fts.at(0).token_id == @1, 'bad ft spec');
        assert(fts.at(0).qty == @4, 'bad ft spec');

        let shapeItem = *shape.pop_front().unwrap();
        assert(shapeItem.x == 1, 'bad shape item');
        assert(shapeItem.y == 4, 'bad shape item');
        assert(shapeItem.z == -2, 'bad shape item');
        let shapeItem = *shape.pop_front().unwrap();
        assert(shapeItem.x == 2, 'bad shape item');
        assert(shapeItem.y == 4, 'bad shape item');
        assert(shapeItem.z == -2, 'bad shape item');
        let shapeItem = *shape.pop_front().unwrap();
        assert(shapeItem.x == 3, 'bad shape item');
        assert(shapeItem.y == 4, 'bad shape item');
        assert(shapeItem.z == -2, 'bad shape item');
        let shapeItem = *shape.pop_front().unwrap();
        assert(shapeItem.x == 4, 'bad shape item');
        assert(shapeItem.y == 4, 'bad shape item');
        assert(shapeItem.z == -2, 'bad shape item');
    }

    fn check_basic_test_shape(
        mut shape: Span<ShapeItem>,
        mut fts: Span<FTSpec>,
    ) {
        assert(shape.len() == 3, 'bad shape length');
        assert(fts.len() == 2, 'bad ft spec');
        assert(fts.at(0).token_id == @0, 'bad ft spec');
        assert(fts.at(1).token_id == @1, 'bad ft spec');
        assert(fts.at(0).qty == @2, 'bad ft spec');
        assert(fts.at(1).qty == @1, 'bad ft spec');

        let shapeItem = *shape.pop_front().unwrap();
        assert(shapeItem.x == 0, 'bad shape item');
        assert(shapeItem.y == 0, 'bad shape item');
        assert(shapeItem.z == 0, 'bad shape item');
        let shapeItem = *shape.pop_front().unwrap();
        assert(shapeItem.x == 0, 'bad shape item');
        assert(shapeItem.y == 2, 'bad shape item');
        assert(shapeItem.z == 0, 'bad shape item');
        let shapeItem = *shape.pop_front().unwrap();
        assert(shapeItem.material == 1, 'bad shape item');
        assert(shapeItem.x == 0, 'bad shape item');
        assert(shapeItem.y == 2, 'bad shape item');
        assert(shapeItem.z == 2, 'bad shape item');
    }
}
