%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from contracts.upgrades.upgradable_mixin import (
    getAdmin_,
    getImplementation_,
    upgradeImplementation_,
    setRootAdmin_,
)

from contracts.ecosystem.to_set import (
    getSetAddress_,
    setSetAddress_,
)

from contracts.attributes_registry.collections import (
    create_collection_,
    increase_attribute_balance_,
)

from contracts.attributes_registry.attributes import (
    assign_attribute,
    remove_attribute,
    has_attribute,
    total_balance,
    token_uri,
)
