#[system]
mod agm_briq_counter {
    use starknet::ContractAddress;

    use briq_protocol::world_config::{WorldConfig, AdminTrait};

    use briq_protocol::types::{PackedShapeItem, FTSpec};

    // check that there is at least attribute_id count of briq in set
    fn verify_briq_count(attribute_id: u64, shape: Span<PackedShapeItem>, fts: Span<FTSpec>) {
        assert(shape.len().into() >= attribute_id, 'not enought briq');

        let mut total = 0_u128;
        let mut fts = fts;
        loop {
            match fts.pop_front() {
                Option::Some(ft) => {
                    total += *ft.qty;
                },
                Option::None => {
                    break;
                }
            };
        };

        assert(total >= attribute_id.into(), 'not enought briq');
    }

    #[external(v0)]
    fn assign(
        ref self: ContractState,
        world: IWorldDispatcher,
        set_owner: ContractAddress,
        set_token_id: ContractAddress,
        attribute_group_id: u64,
        attribute_id: u64,
        shape: Array<PackedShapeItem>,
        fts: Array<FTSpec>,
    ) {
        verify_briq_count(attribute_id, shape.span(), fts.span());
    }

    #[external(v0)]
    fn remove(
        ref self: ContractState,
        world: IWorldDispatcher,
        set_owner: ContractAddress,
        set_token_id: ContractAddress,
        attribute_group_id: u64,
        attribute_id: u64
    ) {}
}
