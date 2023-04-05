
use briq_protocol::utilities::authorization::Auth::_onlyAdmin;
//from contracts.utilities.authorization import _onlyAdmin

#[derive(Drop)]
struct Storj {
    address: felt252,
}

use starknet::storage_access::StorageAccess;
use starknet::storage_access::StorageBaseAddress;
use starknet::SyscallResult;
//use starknet::syscalls::storage_read_syscall;
//use starknet::syscalls::storage_write_syscall;

impl toto of StorageAccess::<Storj> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult<Storj> {
        let address = StorageAccess::<felt252>::read(
            address_domain, base
        )?;
        SyscallResult::<Storj>::Ok(Storj { address })
    }

    #[inline(always)]
    fn write(address_domain: u32, base: StorageBaseAddress, value: Storj) -> SyscallResult<()> {
        starknet::StorageAccess::write(address_domain, base, value.address)
    }
}


trait Accessor<T> {
    #[external]
    fn get(self: T) -> T;
}

impl StorjAccess of Accessor::<Storj> {
    #[external]
    fn get(self: Storj) -> Storj {
        self
    }
}

//@storage_var
//func _set_address() -> (address: felt) {
//}

//@view
//func getSetAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
//    address: felt
//) {
//    let (value) = _set_address.read();
//    return (value,);
//}
//
//@external
//func setSetAddress_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//    address: felt
//) {
//    _onlyAdmin();
//    _set_address.write(address);
//    return ();
//}
