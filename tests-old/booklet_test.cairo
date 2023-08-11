use briq_protocol::booklet_nft::BookletNFT;
use debug::PrintTrait;

#[test]
#[available_gas(999999)]
fn test_storage_conflict() {
    BookletNFT::setAttributesRegistryAddress_(345678);
    let toto = BookletNFT::getBoxAddress_();
    assert(toto == 0, 'toto should be 0');
}
