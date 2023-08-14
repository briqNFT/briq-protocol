use starknet::ContractAddress;

const SYSTEM_CONFIG_ID: u32 = 1;

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct WorldConfig {
    #[key]
    config_id: u32,

    super_admin: ContractAddress,

    briq: ContractAddress,
    set: ContractAddress,
    booklet: ContractAddress,
    box: ContractAddress,
}

#[generate_trait]
impl AdminTraitImpl of AdminTrait {
    fn is_admin(self: @WorldConfig, addr: @ContractAddress) -> bool {
        self.super_admin == addr
    }
}

#[system]
mod SetupWorld {
    use starknet::ContractAddress;
    use array::ArrayTrait;
    use traits::Into;

    use dojo::world::Context;
    use super::WorldConfig;
    use super::SYSTEM_CONFIG_ID;

    fn execute(ctx: Context, super_admin: ContractAddress, briq: ContractAddress, set: ContractAddress, booklet: ContractAddress, box: ContractAddress) {
        set !(
            ctx.world, (WorldConfig {
                config_id: SYSTEM_CONFIG_ID,
                super_admin,
                briq,
                set,
                booklet,
                box
            } )
        );
        return ();
    }
}
