%lang starknet

from contracts.upgrades.upgradable_mixin import (
    getAdmin_,
    getImplementation_,
    upgradeImplementation_,
    setRootAdmin_,
)

from contracts.shape.attribute import (
    assign_attribute,
    remove_attribute,
    balanceOf_,
    getShapeHash_,
    checkShape_,
)

from contracts.ecosystem.to_attributes_registry import (
    getAttributesRegistryAddress_,
    setAttributesRegistryAddress_,
)

