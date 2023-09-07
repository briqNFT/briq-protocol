#[system]
mod agm_briq_counter {
    use zeroable::Zeroable;
    use dojo::world::Context;
    use traits::{Into, TryInto};
    use array::{ArrayTrait, SpanTrait};
    use briq_protocol::world_config::{WorldConfig, AdminTrait};
    use briq_protocol::attributes::attributes::{
        AttributeHandlerData, AttributeAssignData, AttributeRemoveData,
    };
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

    fn execute(ctx: Context, data: AttributeHandlerData) {
        match data {
            AttributeHandlerData::Assign(d) => {
                let AttributeAssignData{set_owner,
                set_token_id,
                attribute_group_id,
                attribute_id,
                shape,
                fts } =
                    d;

                verify_briq_count(attribute_id, shape.span(), fts.span());
            },
            AttributeHandlerData::Remove(d) => { // do nothing ? 
            },
        }
    }
}
