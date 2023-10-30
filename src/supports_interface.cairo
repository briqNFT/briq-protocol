// Taken from OZ

const ISRC5_ID: felt252 = 0x3f918d17e5ee77373b56385708f855659a07f75997f365cf87748628532a055;


#[starknet::interface]
trait ISRC5<TState> {
    fn supports_interface(self: @TState, interface_id: felt252) -> bool;
}

#[starknet::interface]
trait ISRC5Camel<TState> {
    fn supportsInterface(self: @TState, interfaceId: felt252) -> bool;
}

const IERC721_ID: felt252 = 0x33eb2f84c309543403fd69f0d0f363781ef06ef6faeb0131ff16ea3175bd943;
const IERC721_METADATA_ID: felt252 = 0x6069a70848f907fa57668ba1875164eb4dcee693952468581406d131081bbd;
//const IERC721_RECEIVER_ID: felt252 = 0x3a0dff5f70d80458ad14ae37bb182a728e3c8cdda0402a5daa86620bdf910bc;

const IERC1155_ID: felt252 = 0xd9b67a26;
const IERC1155_METADATA_ID: felt252 = 0x0e89341c;

#[starknet::component]
mod SupportsERC721 {
    #[storage]
    struct Storage {}

    #[embeddable_as(SupportsERC721)]
    impl snake_case_impl<
        TContractState, +HasComponent<TContractState>
    > of super::ISRC5<ComponentState<TContractState>> {
        /// Returns whether the contract implements the given interface.
        fn supports_interface(
            self: @ComponentState<TContractState>, interface_id: felt252
        ) -> bool {
            if interface_id == super::ISRC5_ID {
                return true;
            }
            if interface_id == super::IERC721_ID {
                return true;
            }
            if interface_id == super::IERC721_METADATA_ID {
                return true;
            }
            return false;
        }
    }

    #[embeddable_as(SupportsERC721Camel)]
    impl CamelCaseImpl<
        TContractState, +HasComponent<TContractState>
    > of super::ISRC5Camel<ComponentState<TContractState>> {
        fn supportsInterface(self: @ComponentState<TContractState>, interfaceId: felt252) -> bool {
            self.supports_interface(interfaceId)
        }
    }
}

#[starknet::component]
mod SupportsERC1155 {
    #[storage]
    struct Storage {}

    #[embeddable_as(SupportsERC1155)]
    impl snake_case_impl<
        TContractState, +HasComponent<TContractState>
    > of super::ISRC5<ComponentState<TContractState>> {
        /// Returns whether the contract implements the given interface.
        fn supports_interface(
            self: @ComponentState<TContractState>, interface_id: felt252
        ) -> bool {
            if interface_id == super::ISRC5_ID {
                return true;
            }
            if interface_id == super::IERC1155_ID {
                return true;
            }
            if interface_id == super::IERC1155_METADATA_ID {
                return true;
            }
            return false;
        }
    }

    #[embeddable_as(SupportsERC1155Camel)]
    impl CamelCaseImpl<
        TContractState, +HasComponent<TContractState>
    > of super::ISRC5Camel<ComponentState<TContractState>> {
        fn supportsInterface(self: @ComponentState<TContractState>, interfaceId: felt252) -> bool {
            self.supports_interface(interfaceId)
        }
    }
}
