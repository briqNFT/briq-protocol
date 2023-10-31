
#[starknet::interface]
trait IERC1155Metadata<TState> {
    fn name(self: @TState) -> felt252;
    fn symbol(self: @TState) -> felt252;
    fn uri(self: @TState, token_id: u256) -> Array<felt252>; // TODO: update this to something else?
}
