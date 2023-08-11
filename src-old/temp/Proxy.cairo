mod Proxy {
    fn assert_only_admin() {
        assert(false, 'Not authorized');
    }
}
