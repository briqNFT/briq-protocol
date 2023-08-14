use array::ArrayTrait;
use option::OptionTrait;
use clone::Clone;
use array::ArrayTCloneImpl;
use starknet::{ ContractAddress, get_caller_address, get_contract_address };
use traits::{ Into, TryInto };
use zeroable::Zeroable;
use dojo::world::{ IWorldDispatcher, IWorldDispatcherTrait };

use dojo_erc::erc1155::erc1155 as dojo_erc1155;
use briq_protocol::erc::erc1155::components::{ OperatorApproval, Balance };

use starknet::event::EventEmitter;

trait HasWorld<T>
{
    fn get_world(self: @T) -> ContractAddress;
}

const UNLIMITED_ALLOWANCE: felt252 = 3618502788666131213697322783095070105623107215331596699973092056135872020480;

// Account
const IACCOUNT_ID: u32 = 0xa66bd575_u32;
// ERC 165 interface codes
const INTERFACE_ERC165: u32 = 0x01ffc9a7_u32;
const INTERFACE_ERC1155: u32 = 0xd9b67a26_u32;
const INTERFACE_ERC1155_METADATA: u32 = 0x0e89341c_u32;
const INTERFACE_ERC1155_RECEIVER: u32 = 0x4e2312e0_u32;
const ON_ERC1155_RECEIVED_SELECTOR: u32 = 0xf23a6e61_u32;
const ON_ERC1155_BATCH_RECEIVED_SELECTOR: u32 = 0xbc197c81_u32;

use dojo_erc1155::ERC1155::IERC1155TokenReceiver;
use dojo_erc1155::ERC1155::{IERC165DispatcherTrait, IERC165Dispatcher, IERC1155TokenReceiverDispatcher, IERC1155TokenReceiverDispatcherTrait};

use dojo_erc1155::ERC1155::{Event, TransferSingle, TransferBatch, ApprovalForAll};

fn _do_safe_transfer_acceptance_check(
    operator: ContractAddress,
    from: ContractAddress,
    to: ContractAddress,
    id: u256,
    amount: u256,
    data: Array<u8>
) {
    if (IERC165Dispatcher { contract_address: to }.supports_interface(INTERFACE_ERC1155_RECEIVER)) {
        assert(
            IERC1155TokenReceiverDispatcher { contract_address: to }.on_erc1155_received(
                operator, from, id, amount, data
            ) == ON_ERC1155_RECEIVED_SELECTOR,
        'ERC1155: ERC1155Receiver reject'
        );
        return ();
    }
    assert(
        IERC165Dispatcher { contract_address: to }.supports_interface( IACCOUNT_ID ),
        'Transfer to non-ERC1155Receiver'
    );
}

fn _do_safe_batch_transfer_acceptance_check(
    operator: ContractAddress,
    from: ContractAddress,
    to: ContractAddress,
    ids: Array<u256>,
    amounts: Array<u256>,
    data: Array<u8>
) {
    if (IERC165Dispatcher { contract_address: to }.supports_interface(INTERFACE_ERC1155_RECEIVER)) {
        assert(
            IERC1155TokenReceiverDispatcher { contract_address: to }.on_erc1155_batch_received(
                operator, from, ids, amounts, data
            ) == ON_ERC1155_BATCH_RECEIVED_SELECTOR,
        'ERC1155: ERC1155Receiver reject'
        );
        return ();
    }
    assert(
        IERC165Dispatcher { contract_address: to }.supports_interface( IACCOUNT_ID ),
        'Transfer to non-ERC1155Receiver'
    );
}

fn _as_singleton_array(element: u256) -> Array<u256> {
    let mut array = ArrayTrait::new();
    array.append(element);
    array
}

#[generate_trait]
impl PrivateFunctions<ContractState,
    impl THW: HasWorld<ContractState>,
    impl ETS: EventEmitter<ContractState, TransferSingle>,
    impl ETB: EventEmitter<ContractState, TransferBatch>,
    impl EAFA: EventEmitter<ContractState, ApprovalForAll>,
    impl TDrop: Drop<ContractState>,
> of PrivateFunctionsTrait<ContractState> {
    // NOTE: temporary, until we have inline commands outside of systems
    fn world(self: @ContractState) -> IWorldDispatcher {
        IWorldDispatcher { contract_address: self.get_world() }
    }

    fn _balance_of(self: @ContractState, account: ContractAddress, id: u256) -> u256 {
        let token = get_contract_address();
        let mut keys = ArrayTrait::new();
        let id_felt: felt252 = id.try_into().unwrap();
        keys.append(token.into());
        keys.append(account.into());
        keys.append(id_felt.into());
        let mut balance_raw = self.world().entity('Balance', keys.span(), 0, 0);     
        let balance = serde::Serde::<Balance>::deserialize(ref balance_raw).unwrap();
        balance.amount.into()
    }

    fn _is_approved_for_all(self: @ContractState, account: ContractAddress, operator: ContractAddress) -> bool {
        let token = get_contract_address();
        let mut keys = ArrayTrait::new();
        keys.append(token.into());
        keys.append(account.into());
        keys.append(operator.into());
        let mut approval_raw = self.world().entity('OperatorApproval', keys.span(), 0, 0);
        serde::Serde::<OperatorApproval>::deserialize(ref approval_raw).unwrap().approved
    }

    fn _update( 
        ref self: ContractState,
        from: ContractAddress,
        to: ContractAddress,
        ids: Array<u256>,
        amounts: Array<u256>,
        data: Array<u8>
    ) {
        assert(ids.len() == amounts.len(), 'ERC1155: invalid length');

        let operator = get_caller_address();
        let token = get_contract_address();
        let mut calldata = ArrayTrait::new();
        calldata.append(token.into());
        calldata.append(operator.into());
        calldata.append(from.into());
        calldata.append(to.into());
        calldata.append(ids.len().into());

        // cloning becasue loop takes ownership
        let ids_clone = ids.clone();
        let amounts_clone = ids.clone();
        let data_clone = data.clone();

        let mut index = 0;
        loop {
            if index == ids.len() {
                break();
            }
            let id: felt252 = (*ids.at(index)).try_into().unwrap();
            calldata.append(id);
            index+=1;
        };
        calldata.append(amounts.len().into());
        let mut index = 0;
        loop {
            if index == amounts.len() {
                break();
            }
            let amount: felt252 = (*amounts.at(index)).try_into().unwrap();
            calldata.append(amount);
            index+=1;
        };
        calldata.append(data.len().into());
        let mut index = 0;
        loop {
            if index == data.len() {
                break();
            }
            let data_cell: felt252 = (*data.at(index)).into();
            calldata.append(data_cell);
            index += 1;
        };
        self.world().execute('ERC1155Update'.into(), calldata);

        if (ids_clone.len() == 1) {
            let id = *ids_clone.at(0);
            let amount = *amounts_clone.at(0);

            ETS::emit(ref self, TransferSingle {operator, from, to, id, value: amount});

            if (to.is_non_zero()) {
                _do_safe_transfer_acceptance_check(
                    operator,
                    from,
                    to,
                    id,
                    amount,
                    data_clone
                );
            } else {
                ETB::emit(ref self, TransferBatch {
                    operator: operator,
                    from: from,
                    to: to,
                    ids: ids_clone.clone(),
                    values: amounts_clone.clone()
                });
                if (to.is_non_zero()) {
                    _do_safe_batch_transfer_acceptance_check(
                        operator,
                        from,
                        to,
                        ids_clone,
                        amounts_clone,
                        data_clone
                    );
                }
            }
        }
    }

    fn _safe_transfer_from(
        ref self: ContractState,
        from: ContractAddress,
        to: ContractAddress,
        id: u256,
        amount: u256,
        data: Array<u8>
    ) {
        assert(to.is_non_zero(), 'ERC1155: invalid receiver');
        assert(from.is_non_zero(), 'ERC1155: invalid sender');

        let ids = _as_singleton_array(id);
        let amounts = _as_singleton_array(amount);
        self._update(from, to, ids, amounts, data);
    }

    fn _safe_batch_transfer_from(
        ref self: ContractState,
        from: ContractAddress,
        to: ContractAddress,
        ids: Array<u256>,
        amounts: Array<u256>,
        data: Array<u8>
    ) {
        assert(to.is_non_zero(), 'ERC1155: invalid receiver');
        assert(from.is_non_zero(), 'ERC1155: invalid sender');
        self._update(from, to, ids, amounts, data);
    }

    fn _set_uri(ref self: ContractState, uri: felt252) {
        let token = get_contract_address();
        let mut calldata = ArrayTrait::new();
        calldata.append(token.into());
        calldata.append(uri);
        self.world().execute('ERC1155SetUri'.into(), calldata);
    }

    fn _mint(ref self: ContractState, to: ContractAddress, id: u256, amount: u256, data: Array<u8>) {
        assert(to.is_non_zero(), 'ERC1155: invalid receiver');

        let ids = _as_singleton_array(id);
        let amounts = _as_singleton_array(amount);
        self._update(Zeroable::zero(), to, ids, amounts, data);
    }

    fn _mint_batch(ref self: ContractState, to: ContractAddress, ids: Array<u256>, amounts: Array<u256>, data: Array<u8>) {
        assert(to.is_non_zero(), 'ERC1155: invalid receiver');
        self._update(Zeroable::zero(), to, ids, amounts, data)
    }

    fn _burn(ref self: ContractState, from: ContractAddress, id: u256, amount: u256, data: Array<u8>) {
        assert(from.is_non_zero(), 'ERC1155: invalid sender');

        let ids = _as_singleton_array(id);
        let amounts = _as_singleton_array(amount);
        self._update(from, Zeroable::zero(), ids, amounts, data);
    }

    fn _burn_batch(ref self: ContractState, from: ContractAddress, ids: Array<u256>, amounts: Array<u256>, data: Array<u8>) {
        assert(from.is_non_zero(), 'ERC1155: invalid sender');
        self._update(from, Zeroable::zero(), ids, amounts, data);
    }

    fn _set_approval_for_all(ref self: ContractState, owner: ContractAddress, operator: ContractAddress, approved: bool) {
        assert(owner != operator, 'ERC1155: wrong approval');
        let token = get_contract_address();
        let mut calldata: Array<felt252> = ArrayTrait::new();
        calldata.append(token.into());
        calldata.append(owner.into());
        calldata.append(operator.into());
        if approved {
            calldata.append(1);
        } else {
            calldata.append(0);
        }
        self.world().execute('ERC1155SetApprovalForAll'.into(), calldata);

        EAFA::emit(ref self, ApprovalForAll { owner, operator, approved});
    }
}

#[starknet::contract]
mod ERC1155 {
    use array::ArrayTrait;
    use option::OptionTrait;
    use clone::Clone;
    use array::ArrayTCloneImpl;
    use starknet::{ ContractAddress, get_caller_address, get_contract_address };
    use traits::{ Into, TryInto };
    use zeroable::Zeroable;
    use dojo::world::{ IWorldDispatcher, IWorldDispatcherTrait };

    use dojo_erc::erc1155::erc1155 as dojo_erc1155;
    use briq_protocol::erc::erc1155::components::{ OperatorApproval, Balance };

    // impl Pt = dojo_erc1155::ERC1155::PrivateFunctions;
    // use dojo_erc1155::ERC1155::PrivateFunctionsTrait;
    use super::{HasWorld, PrivateFunctions};
    impl totoro of HasWorld<ContractState>
    {
        fn get_world(self: @ContractState) -> ContractAddress {
            self.world_address.read()
        }
    }

    impl Pt = PrivateFunctions<ContractState, totoro>;

    #[storage]
    struct Storage {
        world_address: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, world: ContractAddress) {
        self.world_address.write(world);
    }

    fn toto(self: @ContractState) {
        Pt::world(self);
    }

    #[external(v0)]
    impl ERC1155 of super::IERC1155<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: u32) -> bool {
            interface_id == INTERFACE_ERC165 ||
            interface_id == INTERFACE_ERC1155 ||
            interface_id == INTERFACE_ERC1155_METADATA
        }

        //
        // ERC1155Metadata
        //
        fn uri(self: @ContractState, token_id: u256) -> felt252 {
            ''
        }

        //
        // ERC1155
        //
        fn balance_of(self: @ContractState, account: ContractAddress, id: u256) -> u256 {
            Pt::_balance_of(self, account, id)
        }

        fn balance_of_batch(self: @ContractState, accounts: Array<ContractAddress>, ids: Array<u256>) -> Array<u256> {
            assert(ids.len() == accounts.len(), 'ERC1155: invalid length');

            let mut batch_balances = ArrayTrait::new();
            let mut index = 0;
            loop {
                if index == ids.len() {
                    break batch_balances.clone();
                }
                batch_balances.append(self._balance_of(*accounts.at(index), *ids.at(index)));
                index += 1;
            }
        }

        fn is_approved_for_all(self: @ContractState, account: ContractAddress, operator: ContractAddress) -> bool {
            self._is_approved_for_all(account, operator)
        }

        fn set_approval_for_all(ref self: ContractState, operator: ContractAddress, approved: bool) {
            let caller = get_caller_address();
            self._set_approval_for_all(caller, operator, approved);
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            id: u256,
            amount: u256,
            data: Array<u8>
        ) {
            let caller = get_caller_address();
            assert(caller == from || self._is_approved_for_all(from, caller),
                'ERC1155: insufficient approval'
            );
            self._safe_transfer_from(from, to, id, amount, data);
        }

        fn safe_batch_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            ids: Array<u256>,
            amounts: Array<u256>,
            data: Array<u8>
        ) {
            let caller = get_caller_address();
            assert(caller == from || self._is_approved_for_all(from, caller),
                'ERC1155: insufficient approval'
            );
            self._safe_batch_transfer_from(from, to, ids, amounts, data);
        }
    }
}