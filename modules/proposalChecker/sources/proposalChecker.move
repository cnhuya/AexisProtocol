module deployer::proposalChecker {
   // use 0xc698c251041b826f1d3d4ea664a70674758e78918938d1b3b237418ff17b4020::governancev37;

    entry fun mock_executeProposal(
        address: &signer,
        _module: u32,
        _code: u16
    ) {
        // Call the `checkProposal` function from the governance module
        //governancev37::checkProposal(address, _module, _code);
    }

    public entry fun executeProposal(address: &signer, _module: u32, _code: u16) {
        mock_executeProposal(address, _module, _code);
    }
}