use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;

use starknet::testing::{set_caller_address, set_contract_address};
use starknet::ContractAddress;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use briq_protocol::world_config::{WorldConfig, SYSTEM_CONFIG_ID};
use briq_protocol::tests::test_utils::{
    WORLD_ADMIN, DEFAULT_OWNER, DefaultWorld, deploy_default_world, mint_briqs, impersonate
};

use dojo_erc::erc721::interface::IERC721DispatcherTrait;
use dojo_erc::erc1155::interface::IERC1155DispatcherTrait;

use briq_protocol::attributes::collection::CreateCollectionData;
use briq_protocol::shape_verifier::RegisterShapeVerifierData;
use briq_protocol::types::{FTSpec, ShapeItem, ShapePacking, PackedShapeItem};

use debug::PrintTrait;

use briq_protocol::tests::test_set_nft::convenience_for_testing::{assemble, disassemble};


