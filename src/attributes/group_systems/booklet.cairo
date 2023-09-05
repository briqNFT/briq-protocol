#[system]
mod agm_booklet {
    use zeroable::Zeroable;
    use clone::Clone;
    use traits::Into;
    use array::{ArrayTrait, SpanTrait};
    use dojo::world::{Context};
    use dojo_erc::erc1155::components::ERC1155BalanceTrait;
    use briq_protocol::world_config::{WorldConfig, AdminTrait, get_world_config};
    use briq_protocol::attributes::attributes::{
        AttributeHandlerData, AttributeAssignData, AttributeRemoveData,
    };
    use briq_protocol::attributes::attribute_group::{AttributeGroupTrait};

    use briq_protocol::attributes::attribute_manager::{
        AttributeManager, AttributeManagerTrait, AttributeManagerImpl, assert_valid_caller
    };


    use debug::PrintTrait;

    // should panic if check fails, or no manager found
    fn assign_check(ctx: Context, data: AttributeAssignData) {
        let AttributeAssignData{set_owner,
        set_token_id,
        attribute_group_id,
        attribute_id,
        shape,
        fts } =
            data;

        let attribute_manager: AttributeManager = get!(
            ctx.world, (attribute_group_id, attribute_id), AttributeManager
        );
        // check if there is an AttributeManager registered for attribute_group_id/attribute_id
        if (attribute_manager.class_hash.is_non_zero()) {
            attribute_manager
                .assign_attribute(
                    ctx.world,
                    set_owner,
                    set_token_id,
                    attribute_group_id,
                    attribute_id,
                    @shape,
                    @fts
                );
        } else {
            panic(array!['should not happen']);
        }
    }

    fn remove_check(ctx: Context, data: AttributeRemoveData) {
        let AttributeRemoveData{set_owner, set_token_id, attribute_group_id, attribute_id } = data;
        let attribute_manager: AttributeManager = get!(
            ctx.world, (attribute_group_id, attribute_id), AttributeManager
        );
        // check if there is an AttributeManager registered for attribute_group_id/attribute_id
        if (attribute_manager.class_hash.is_non_zero()) {
            attribute_manager
                .remove_attribute(
                    ctx.world, set_owner, set_token_id, attribute_group_id, attribute_id
                );
        } else {
            panic(array!['should not happen']);
        }
    }

    fn execute(ctx: Context, data: AttributeHandlerData) {
        assert_valid_caller(ctx);

        match data {
            AttributeHandlerData::Assign(d) => {
                let AttributeAssignData{set_owner,
                set_token_id,
                attribute_group_id,
                attribute_id,
                shape,
                fts } =
                    d;

                assign_check(
                    ctx,
                    AttributeAssignData {
                        set_owner,
                        set_token_id,
                        attribute_group_id,
                        attribute_id,
                        shape: shape.clone(),
                        fts: fts.clone()
                    }
                );

                // find booklet collection related to this attribute group
                let attribute_group = AttributeGroupTrait::get_attribute_group(
                    ctx.world, attribute_group_id
                );
                assert(
                    attribute_group.booklet_contract_address.is_non_zero(),
                    'invalid booklet_address'
                );

                // TODO : use update that sends events
                // Transfer booklet with corresponding attribute_id from set_owner to set_token_id
                ERC1155BalanceTrait::unchecked_transfer_tokens(
                    ctx.world,
                    attribute_group.booklet_contract_address,
                    set_owner,
                    set_token_id,
                    array![attribute_id.into()].span(),
                    array![1].span()
                );
            },
            AttributeHandlerData::Remove(d) => {
                let AttributeRemoveData{set_owner,
                set_token_id,
                attribute_group_id,
                attribute_id } =
                    d;

                remove_check(
                    ctx,
                    AttributeRemoveData {
                        set_owner, set_token_id, attribute_group_id, attribute_id
                    }
                );

                // find booklet collection related to this attribute group
                let attribute_group = AttributeGroupTrait::get_attribute_group(
                    ctx.world, attribute_group_id
                );
                assert(
                    attribute_group.booklet_contract_address.is_non_zero(),
                    'invalid booklet_address'
                );

                // TODO : use update that sends events
                // Transfer booklet with corresponding attribute_id from set_token_id to set_owner
                ERC1155BalanceTrait::unchecked_transfer_tokens(
                    ctx.world,
                    attribute_group.booklet_contract_address,
                    set_token_id,
                    set_owner,
                    array![attribute_id.into()].span(),
                    array![1].span()
                );
            },
        }
    }
}
