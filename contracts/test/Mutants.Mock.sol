// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import '../Mutants.sol';

contract MockMutants is Mutants {
    constructor(bytes32 secretHash_) Mutants(secretHash_) {}

    function requestRandomMegaMutant(uint256 tokenId) internal override {
        // bytes32 requestId = _requestRandomSeed();
        // _requestIdToMegaId[requestId] = tokenId; // signal that this is a request for the specific tokenId
    }
}
