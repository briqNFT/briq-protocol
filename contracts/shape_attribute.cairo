%lang starknet

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

