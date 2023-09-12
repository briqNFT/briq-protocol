mod systems;
mod systems_erc721;

#[starknet::contract]
mod SetNft {
    use array::ArrayTrait;
    use option::OptionTrait;
    use starknet::{ContractAddress, ClassHash, get_caller_address, get_contract_address};
    use traits::{Into, TryInto};
    use zeroable::Zeroable;
    use serde::Serde;
    use clone::Clone;

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use dojo_erc::erc721::components::{
        ERC721Owner, ERC721OwnerTrait, BaseUri, BaseUriTrait, ERC721Balance, ERC721BalanceTrait,
        ERC721TokenApproval, ERC721TokenApprovalTrait, OperatorApproval, OperatorApprovalTrait
    };
    use dojo_erc::erc721::systems::{
        ERC721ApproveParams, ERC721SetApprovalForAllParams, ERC721TransferFromParams
    };

    use dojo_erc::erc165::interface::{IERC165, IERC165_ID};
    use dojo_erc::erc721::interface::{IERC721, IERC721Metadata, IERC721_ID, IERC721_METADATA_ID};

    use dojo_erc::erc_common::utils::{to_calldata, ToCallDataTrait, system_calldata};

    use briq_protocol::world_config::AdminTrait;
    use briq_protocol::upgradeable::{IUpgradeable, UpgradeableTrait};
    #[derive(Clone, Drop, Serde, PartialEq, starknet::Event)]
    struct Upgraded {
        class_hash: ClassHash,
    }

    use super::systems_erc721::ALL_BRIQ_SETS;


    #[storage]
    struct Storage {
        world: IWorldDispatcher,
        name_: felt252, // TODO : string
        symbol_: felt252, // TODO : string
    }

    #[derive(Clone, Drop, Serde, PartialEq, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256
    }

    #[derive(Clone, Drop, Serde, PartialEq, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        to: ContractAddress,
        token_id: u256
    }

    #[derive(Clone, Drop, Serde, PartialEq, starknet::Event)]
    struct ApprovalForAll {
        owner: ContractAddress,
        operator: ContractAddress,
        approved: bool
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
        ApprovalForAll: ApprovalForAll,
        Upgraded: Upgraded
    }

    #[starknet::interface]
    trait IERC721Events<ContractState> {
        fn on_transfer(ref self: ContractState, event: Transfer);
        fn on_approval(ref self: ContractState, event: Approval);
        fn on_approval_for_all(ref self: ContractState, event: ApprovalForAll);
    }

    //
    // Upgradable
    //

    #[external(v0)]
    impl Upgradable of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.world.read().only_admins(@get_caller_address());
            UpgradeableTrait::upgrade(new_class_hash);
            self.emit(Upgraded { class_hash: new_class_hash });
        }
    }

    //
    // Constructor
    //

    #[constructor]
    fn constructor(
        ref self: ContractState, world: IWorldDispatcher, name: felt252, symbol: felt252
    ) {
        self.world.write(world);
        self.name_.write(name);
        self.symbol_.write(symbol);
    }


    #[external(v0)]
    impl ERC165 of IERC165<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: u32) -> bool {
            interface_id == IERC165_ID
                || interface_id == IERC721_ID
                || interface_id == IERC721_METADATA_ID
        }
    }

    #[external(v0)]
    impl ERC721 of IERC721<ContractState> {
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            ERC721BalanceTrait::balance_of(self.world.read(), get_contract_address(), account)
                .into()
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            let owner = ERC721OwnerTrait::owner_of(
                self.world.read(), ALL_BRIQ_SETS(), token_id.try_into().unwrap()
            );
            assert(owner.is_non_zero(), 'ERC721: invalid token_id');
            owner
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            assert(self.owner_of(token_id).is_non_zero(), 'ERC721: invalid token_id');

            let token_id_felt: felt252 = token_id.try_into().unwrap();
            ERC721TokenApprovalTrait::get_approved(
                self.world.read(), get_contract_address(), token_id_felt
            )
        }

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            self
                .world
                .read()
                .execute(
                    'ERC721Approve',
                    system_calldata(
                        ERC721ApproveParams {
                            token: get_contract_address(),
                            caller: get_caller_address(),
                            token_id: token_id.try_into().unwrap(),
                            to
                        }
                    )
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
            self
                .world
                .read()
                .execute(
                    'ERC721SetApprovalForAll',
                    system_calldata(
                        ERC721SetApprovalForAllParams {
                            token: get_contract_address(),
                            owner: get_caller_address(),
                            operator,
                            approved
                        }
                    )
                );
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            self
                .world
                .read()
                .execute(
                    'ERC721TransferFrom',
                    system_calldata(
                        ERC721TransferFromParams {
                            token: get_contract_address(),
                            caller: get_caller_address(),
                            from,
                            to,
                            token_id: token_id.try_into().unwrap()
                        }
                    )
                );
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            // TODO: check if we should do it
            panic(array!['not implemented !']);
        }
    }

    #[external(v0)]
    impl ERC721Metadata of IERC721Metadata<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.name_.read()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self.symbol_.read()
        }

        fn token_uri(self: @ContractState, token_id: u256) -> felt252 {
            // TODO
            0
        }
    }

    #[external(v0)]
    impl ERC721EventEmitter of IERC721Events<ContractState> {
        fn on_transfer(ref self: ContractState, event: Transfer) {
            assert(get_caller_address() == self.world.read().executor(), 'ERC721: not authorized');
            self.emit(event);
        }
        fn on_approval(ref self: ContractState, event: Approval) {
            assert(get_caller_address() == self.world.read().executor(), 'ERC721: not authorized');
            self.emit(event);
        }
        fn on_approval_for_all(ref self: ContractState, event: ApprovalForAll) {
            assert(get_caller_address() == self.world.read().executor(), 'ERC721: not authorized');
            self.emit(event);
        }
    }

    use briq_protocol::types::{FTSpec, PackedShapeItem, AttributeItem};
    use briq_protocol::set_nft::systems::{AssemblySystemData, DisassemblySystemData};

    #[external(v0)]
    fn assemble(
        self: @ContractState,
        owner: ContractAddress,
        token_id_hint: felt252,
        name: Array<felt252>, // todo string
        description: Array<felt252>, // todo string
        fts: Array<FTSpec>,
        shape: Array<PackedShapeItem>,
        attributes: Array<AttributeItem>
    ) {
        let caller = get_caller_address();
        assert(caller == owner, 'Only owner');

        self
            .world
            .read()
            .execute(
                'set_nft_assembly',
                system_calldata(
                    AssemblySystemData {
                        caller: caller,
                        owner,
                        token_id_hint,
                        name,
                        description,
                        fts,
                        shape,
                        attributes
                    }
                )
            );
    }

    #[external(v0)]
    fn disassemble(
        self: @ContractState,
        owner: ContractAddress,
        token_id: ContractAddress,
        fts: Array<FTSpec>,
        attributes: Array<AttributeItem>
    ) {
        let caller = get_caller_address();
        assert(caller == owner, 'Only owner');

        self
            .world
            .read()
            .execute(
                'set_nft_disassembly',
                system_calldata(
                    DisassemblySystemData {
                        caller: caller,
                        owner,
                        token_id,
                        fts,
                        attributes
                    }
                )
            );
    }
}
