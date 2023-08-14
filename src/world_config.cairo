use starknet::ContractAddress;

const SYSTEM_CONFIG_ID: u32 = 1;

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct WorldConfig {
    #[key]
    config_id: u32,

    briq: ContractAddress,
    set: ContractAddress,
    booklet: ContractAddress,
    box: ContractAddress,
}
