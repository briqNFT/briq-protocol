use starknet::ClassHash;
use zeroable::Zeroable;
use result::ResultTrait;
use starknet::{SyscallResult, SyscallResultTrait};


#[starknet::interface]
trait IUpgradeable<TState> {
    fn upgrade(ref self: TState, new_class_hash: ClassHash);
}

trait UpgradeableTrait {
    fn upgrade(new_class_hash: ClassHash);
}

impl UpgradeableTraitImpl of UpgradeableTrait {
    fn upgrade(new_class_hash: ClassHash) {
        assert(!new_class_hash.is_zero(), 'Class hash cannot be zero');
        starknet::replace_class_syscall(new_class_hash).unwrap_syscall();
    }
}
