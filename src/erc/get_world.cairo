use dojo::world::IWorldDispatcher;
trait GetWorldTrait<ContractState> {
    fn world(self: @ContractState) -> IWorldDispatcher;
}
