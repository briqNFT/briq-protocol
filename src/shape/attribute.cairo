
#[contract]
mod ShapeAttribute {
    use array::ArrayTrait;
    use array::SpanTrait;
    use traits::TryInto;
    use traits::Into;
    use option::OptionTrait;

    use briq_protocol::types::ShapeItem;
    use briq_protocol::types::FTSpec;
    use briq_protocol::ecosystem::to_attributes_registry::toAttributesRegistry::_onlyAttributesRegistry;

    use briq_protocol::utils::check_gas;
    use briq_protocol::utils;

    use briq_protocol::shape::shape_store::_initialize_qty;
    use briq_protocol::shape::shape_store::_check_qty_are_correct;
    use briq_protocol::shape::shape_store::_decrement_ft_qty;
    use briq_protocol::shape::shape_store::shape_;

    struct Storage {
        _shape_hash: LegacyMap<felt252, felt252>,
    }

    #[external]
    fn assign_attribute(
        owner: felt252,
        set_token_id: felt252,
        attribute_id: felt252,
        shape: Array<ShapeItem>,
        fts: Array<FTSpec>,
        nfts: Array<felt252>,
    ) {
        _onlyAttributesRegistry();

        //with_attr error_message("Shape cannot be empty") {
        assert(shape.len() > 0, 'Shape is empty');

        let qty = _initialize_qty(fts.span(), ArrayTrait::<felt252>::new());
        let hash = _check_shape_and_hash(0, shape.span(), fts.span(), qty, nfts.span());

        _shape_hash::write(set_token_id, hash);
    }

    #[external]
    fn remove_attribute(owner: felt252, set_token_id: felt252, attribute_id: felt252) {
        _onlyAttributesRegistry();
        _shape_hash::write(set_token_id, 0);
    }

    #[view]
    fn balanceOf_(token_id: felt252) -> bool {
        _shape_hash::read(token_id) != 0
    }

    #[view]
    fn getShapeHash_(token_id: felt252) -> felt252 {
        let shape_hash = _shape_hash::read(token_id);
        //with_attr error_message("Unknown token ID - set shape hash is not stored.") {
        assert(shape_hash != 0, 'Unknown token ID');
        shape_hash
    }


    #[view]
    fn checkShape_(token_id: felt252, shape: Array<ShapeItem>) -> bool {
        let shape_hash = _shape_hash::read(token_id);
        //with_attr error_message("Unknown token ID - set shape hash is not stored.") {
        assert(shape_hash != 0, 'Unknown token ID');

        let hash = _rec_hash(0, shape);
        hash == shape_hash
    }

    fn _rec_hash(hash: felt252, mut shape: Array<ShapeItem>) -> felt252 {
        check_gas();
        if shape.len() == 0 {
            return hash;
        }

        let shapeItem = shape.pop_front().unwrap();
        let hash = pedersen(hash, shapeItem.color_nft_material);
        let hash = pedersen(hash, shapeItem.x_y_z);
        _rec_hash(hash, shape)
    }

    ////////////////////////////////////////////////
    ////////////////////////////////////////////////

    fn _check_shape_and_hash(
        hash: felt252,
        mut shape: Span<ShapeItem>,
        mut fts: Span<FTSpec>,
        mut qty: Array<felt252>,
        mut nfts: Span<felt252>,
    ) -> felt252 {
        check_gas();
        if shape.len() == 0 {
            _check_qty_are_correct(qty);
            assert(nfts.len() == 0, 'wrong nb nft');
            return hash;
        }

        let shapeItem = *(shape.pop_front().unwrap());

        let hash = pedersen(hash, shapeItem.color_nft_material);
        let hash = pedersen(hash, shapeItem.x_y_z);

        let is_nft = shapeItem.color_nft_material & 0x100000000000000000000000000000000;
        if is_nft != 0 {
            assert(false, 'NOT DONE');
            return _check_shape_and_hash(hash, shape, fts, qty, nfts);
        } else {
            let mat = shapeItem.color_nft_material & 0xffffffffffffffff; // bitwise_and(shape[0].color_nft_material, 2 ** 64 - 1);
            assert(mat != 0, 'bad shape item');
            let qty = _decrement_ft_qty(fts, mat, qty, ArrayTrait::<felt252>::new());
            return _check_shape_and_hash(hash, shape, fts, qty, nfts);
        }
    }
}