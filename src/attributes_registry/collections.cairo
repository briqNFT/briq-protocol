
use starknet::StorageAccess;
use starknet::StorageBaseAddress;
use starknet::storage_address_from_base_and_offset;

use starknet::SyscallResult;
use starknet::syscalls::storage_read_syscall;
use starknet::syscalls::storage_write_syscall;

impl StorageAccessTupleFelt of StorageAccess::<(felt252, felt252)> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult<(felt252, felt252)> {
        SyscallResult::<(felt252, felt252)>::Ok(
            (
                storage_read_syscall(address_domain, storage_address_from_base_and_offset(base, 0_u8))?,
                storage_read_syscall(address_domain, storage_address_from_base_and_offset(base, 1_u8))?
            )
        )
    }

    #[inline(always)]
    fn write(
        address_domain: u32, base: StorageBaseAddress, value: (felt252, felt252)
    ) -> SyscallResult<()> {
        let (first, second) = value;
        storage_write_syscall(address_domain, storage_address_from_base_and_offset(base, 0_u8), first)?;
        storage_write_syscall(address_domain, storage_address_from_base_and_offset(base, 1_u8), second)?;
        SyscallResult::Ok(())
    }
}


#[contract]
mod Collections {
    use super::StorageAccessTupleFelt;

    const EXISTS_BIT: felt252 = 1; // This bit is always toggled for a collection that exists.
    const CONTRACT_BIT: felt252 = 2;

    const COLLECTION_ID_MASK: felt252 = 0xffffffffffffffffffffffffffffffffffffffffffffffff; // 2**192 - 1;


    struct Storage {
        _collection_data: LegacyMap<felt252, (felt252, felt252)>, // (collection_id: felt) -> (parameters__admin_or_contract: (felt, felt))
    }

    #[event]
    fn CollectionCreated(collection_id: felt252, contract: felt252, admin: felt252, params: felt252) {
    }

    use traits::BitAnd;
    use traits::Into;

    fn _OnCollectionCreated(collection_id: felt252) {
        let (admin, contract) = _get_admin_or_contract(collection_id);
        let (parameters, admin_or_contract) = _collection_data::read(collection_id);
        CollectionCreated(collection_id, contract, admin, parameters);
    }

    ////////////////////

    use briq_protocol::utilities::authorization::Auth::_onlyAdmin;
    use briq_protocol::utilities::authorization::Auth::_only;

    use traits::TryInto;
    use option::OptionTrait;
    use starknet::ContractAddress;
    use starknet::Felt252TryIntoContractAddress;

    //@external
    fn create_collection_(collection_id: felt252, params: felt252, admin_or_contract: felt252) {
        _onlyAdmin();

        //with_attr error_message("Collection already exists") {
        //    let (existing_collec_params) = _collection_data.read(collection_id);
        //    assert existing_collec_params[0] = 0;
        //}
        let (existing_collec_params, _) = _collection_data::read(collection_id);
        assert(existing_collec_params == 0, 'Collec already exists');
        
        //let (existence_bit_toggled) = bitwise_and(params, EXISTS_BIT);
        //with_attr error_message("Invalid bits in collection parameters.") {
        //    assert existence_bit_toggled = 0;
        //    assert_lt_felt(params, 2**250);
        //}
        // Probably indicates an error, fail.
        // Todo: remove into()s once felt bitwise is supported
        let existence_bit_toggled = params.into() & EXISTS_BIT.into();
        assert(existence_bit_toggled == 0.into(), 'Invalid bits');
        assert(params.into() < 0x400000000000000000000000000000000000000000000000000000000000000.into(), 'Invalid bits');

        // Toggle existence bit.
        _collection_data::write(collection_id, (params + EXISTS_BIT, admin_or_contract));
        _OnCollectionCreated(collection_id);
    }

    //@external
    fn increase_attribute_balance_(attribute_id: felt252, initial_balance: felt252) {
        let collection_id = _get_collection_id(attribute_id);
        let (admin, contract) = _get_admin_or_contract(collection_id);
    //    with_attr error_message("Balance can only be increased on non-delegating collections") {
    //        assert contract = 0;
    //    }
        assert(contract == 0, 'NO: non-del collec');
    //    with_attr error_message("Cannot increase the balance of a collection without an admin") {
    //        assert_not_zero(admin);
    //    }
        assert(admin != 0, 'NO: no admin');
        _only(admin.try_into().unwrap()); // I think the conversion makes the above assert redundant
    //    ERC1155_balance._increaseBalance(0, attribute_id, initial_balance);
    }

    ////////////////////

    fn _get_collection_id(attribute_id: felt252) -> felt252 {
        let collection_id = attribute_id.into() & COLLECTION_ID_MASK.into();
        return collection_id.low.into() + collection_id.high.into() * 0x100000000000000000000000000000000; // 2**128
    }

    fn _has_contract(collection_id: felt252) -> bool {
        let (parameters, admin_or_contract) = _collection_data::read(collection_id);
        return (parameters.into() & CONTRACT_BIT.into()) > 0.into();
    }

    // returns Admin or Contract, only one is non-zero
    fn _get_admin_or_contract(collection_id: felt252) -> (felt252, felt252) {
        let (parameters, admin_or_contract) = _collection_data::read(collection_id);
        // TODO: remove into()s once felt bitwise is supported
        let has_contract = parameters.into() & CONTRACT_BIT.into();
        if has_contract == CONTRACT_BIT.into() {
            return (0, admin_or_contract);
        } else {
            return (admin_or_contract, 0);
        }
    }
}