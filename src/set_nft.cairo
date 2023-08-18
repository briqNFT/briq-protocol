mod systems;

use starknet::ContractAddress;
use briq_protocol::types::{FTSpec, ShapeItem};

#[starknet::interface]
trait ISetNft<ContractState> {
    fn assemble_(
        ref self: ContractState,
        owner: ContractAddress,
        token_id_hint: felt252,
        name: Array<felt252>, // TODO string
        description: Array<felt252>, // TODO string
        fts: Array<FTSpec>,
        shape: Array<ShapeItem>,
        attributes: Array<felt252>
    ) -> felt252;
    fn disassemble_(
        ref self: ContractState,
        owner: ContractAddress,
        token_id: felt252,
        fts: Array<FTSpec>,
        attributes: Array<felt252>
    );
}

#[starknet::contract]
mod SetNft {
    use array::ArrayTrait;
    use option::OptionTrait;
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use traits::{Into, TryInto};
    use zeroable::Zeroable;
    use clone::Clone;

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use dojo_erc::erc721::components::{
        ERC721Owner, ERC721OwnerTrait, BaseUri, BaseUriTrait, ERC721Balance, ERC721BalanceTrait,
        ERC721TokenApproval, ERC721TokenApprovalTrait, OperatorApproval, OperatorApprovalTrait
    };
    use dojo_erc::erc721::interface::IERC721;
    use dojo_erc::erc_common::utils::{to_calldata, ToCallDataTrait};

    use briq_protocol::types::{FTSpec, ShapeItem};
    use briq_protocol::world_config::{WorldConfig, SYSTEM_CONFIG_ID};

    #[derive(Clone, Drop, Serde, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256
    }

    #[derive(Clone, Drop, Serde, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        to: ContractAddress,
        token_id: u256
    }

    #[derive(Clone, Drop, Serde, starknet::Event)]
    struct ApprovalForAll {
        owner: ContractAddress,
        operator: ContractAddress,
        approved: bool
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
        ApprovalForAll: ApprovalForAll
    }

    #[starknet::interface]
    trait IERC721EventEmitter<ContractState> {
        fn on_transfer(ref self: ContractState, event: Transfer);
        fn on_approval(ref self: ContractState, event: Approval);
        fn on_approval_for_all(ref self: ContractState, event: ApprovalForAll);
    }


    #[storage]
    struct Storage {
        world: IWorldDispatcher
    }

    //
    // Constructor
    //

    #[constructor]
    fn constructor(ref self: ContractState, world: ContractAddress) {
        self.world.write(IWorldDispatcher { contract_address: world });
    }

    #[external(v0)]
    impl ERC721 of IERC721<ContractState> {
        fn owner(self: @ContractState) -> ContractAddress {
            get!(self.world.read(), (SYSTEM_CONFIG_ID), WorldConfig).super_admin
        }

        fn name(self: @ContractState) -> felt252 {
            'briq Set'
        }

        fn symbol(self: @ContractState) -> felt252 {
            'B7'
        }

        fn token_uri(self: @ContractState, token_id: u256) -> felt252 {
            // TODO
            ''
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            ERC721BalanceTrait::balance_of(self.world.read(), get_contract_address(), account)
                .into()
        }

        fn exists(self: @ContractState, token_id: u256) -> bool {
            self.owner_of(token_id).is_non_zero()
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            ERC721OwnerTrait::owner_of(
                self.world.read(), get_contract_address(), token_id.try_into().unwrap()
            )
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            assert(self.exists(token_id), 'ERC721: invalid token_id');

            let token_id_felt: felt252 = token_id.try_into().unwrap();
            ERC721TokenApprovalTrait::get_approved(
                self.world.read(), get_contract_address(), token_id_felt
            )
        }

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let token = get_contract_address();
            let caller = get_caller_address();
            let token_id_felt: felt252 = token_id.try_into().unwrap();

            self
                .world
                .read()
                .execute(
                    'ERC721Approve',
                    to_calldata(token).plus(caller).plus(token_id_felt).plus(to).data
                );
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            OperatorApprovalTrait::is_approved_for_all(
                self.world.read(), get_contract_address(), owner, operator
            )
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            let owner = get_caller_address();

            assert(owner != operator, 'ERC1155: wrong approval');

            self
                .world
                .read()
                .execute(
                    'ERC721SetApprovalForAll',
                    to_calldata(get_contract_address())
                        .plus(owner)
                        .plus(operator)
                        .plus(approved)
                        .data
                );
        }


        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            let token_id_felt: felt252 = token_id.try_into().unwrap();

            self
                .world
                .read()
                .execute(
                    'ERC721TransferFrom',
                    to_calldata(get_contract_address())
                        .plus(get_caller_address())
                        .plus(from)
                        .plus(to)
                        .plus(token_id_felt)
                        .data
                );
        }


        fn transfer(ref self: ContractState, to: ContractAddress, token_id: u256) {
            self.transfer_from(get_caller_address(), to, token_id);
        }

        fn mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            assert(false==true, 'not usable');
            //let token = get_contract_address();
            //let mut calldata: Array<felt252> = ArrayTrait::new();
            //calldata.append(token.into());
            //calldata.append(u256_into_felt252(token_id));
            //calldata.append(to.into());
            //self.world.read().execute('erc721_mint'.into(), calldata);
            //self.emit(Transfer { from: Zeroable::zero(), to, token_id });
        }

        fn burn(ref self: ContractState, token_id: u256) {
            assert(false==true, 'not usable');
            //let token = get_contract_address();
            //let caller = get_caller_address();
            //let mut calldata: Array<felt252> = ArrayTrait::new();
            //calldata.append(token.into());
            //calldata.append(caller.into());
            //calldata.append(u256_into_felt252(token_id));
            //self.world.read().execute('erc721_burn'.into(), calldata);
            //self.emit(Transfer { from: get_caller_address(), to: Zeroable::zero(), token_id });
        }
    }

    use briq_protocol::set_nft::systems::hash_token_id;
    use briq_protocol::set_nft::systems::AssemblySystemData;
    use briq_protocol::set_nft::systems::DisassemblySystemData;
    use serde::Serde;

    #[external(v0)]
    fn assemble_(
        ref self: ContractState,
        owner: ContractAddress,
        token_id_hint: felt252,
        name: Array<felt252>, // TODO string
        description: Array<felt252>, // TODO string
        fts: Array<FTSpec>,
        shape: Array<ShapeItem>,
        attributes: Array<felt252>
    ) -> felt252 {
        // The name/description is unused except to have them show up in calldata.

        let nb_briq = shape.len();

        let mut calldata: Array<felt252> = ArrayTrait::new();
        AssemblySystemData {
            caller: get_caller_address(),
            owner,
            token_id_hint,
            fts,
            shape,
            attributes
        }.serialize(ref calldata);
        self.world.read().execute('set_nft_assembly', calldata);

        let token_id = hash_token_id(owner, token_id_hint, nb_briq);
        self.emit(Transfer { from: Zeroable::zero(), to: owner, token_id: token_id.into() });
        token_id
    }

    #[external(v0)]
    fn disassemble_(
        ref self: ContractState,
        owner: ContractAddress,
        token_id: felt252,
        fts: Array<FTSpec>,
        attributes: Array<felt252>
    ) {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        DisassemblySystemData {
            caller: get_caller_address(),
            owner,
            token_id,
            fts,
            attributes
        }.serialize(ref calldata);
        self.world.read().execute('set_nft_disassembly', calldata);

        self.emit(Transfer { from: owner, to: Zeroable::zero(), token_id: token_id.into() });
    }

    use traits::Default;

    fn concat<T, impl TSerde: Serde<T>>(ref into: Array<felt252>, data: @T) {
        let mut serialized_data: Array<felt252> = Default::default();
        data.serialize(ref serialized_data);
        let mut index = 0;
        loop {
            if index == serialized_data.len() {
                break ();
            }
            into.append(*serialized_data.at(index));
            index += 1;
        };
    }

    fn u256_into_felt252(val: u256) -> felt252 {
        val.try_into().unwrap()
    }
}
