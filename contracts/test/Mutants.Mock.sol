// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import '../ShinobiMutantBunny.sol';

contract MockMutants is Mutants {
    function requestRandomMegaMutant(uint256 tokenId) internal override {
        // bytes32 requestId = _requestRandomSeed();
        // _requestIdToMegaId[requestId] = tokenId; // signal that this is a request for the specific tokenId
    }
}
