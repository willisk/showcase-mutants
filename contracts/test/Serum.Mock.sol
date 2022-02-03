// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import '../Serum.sol';

contract MockSerum is Serum {
    // XXX: this is only used for testing and should be removed in production
    function mintBatchTest(uint256[] memory ids, uint256[] memory amounts) external onlyOwner {
        _mintBatch(owner(), ids, amounts, '');
    }
}
