// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library ShuffleArray {
    function remove(uint256[] storage self, uint256 index) internal returns (uint256) {
        uint256 removedElement = self[index];
        self[index] = self[self.length - 1];
        self.pop();
        return removedElement;
    }

    function nextRandomElement(uint256[] storage self, uint256 randomNumber) internal returns (uint256) {
        uint256 randomIndex = randomNumber % self.length;
        return remove(self, randomIndex);
    }

    function getShuffledRangeAt(
        uint256 index,
        uint256 max,
        uint256 seed
    ) internal pure returns (uint256) {
        uint256[] memory shuffled = new uint256[](max);

        for (uint256 i; i < max; i++) shuffled[i] = i;

        for (uint256 i; i < max; i++) {
            uint256 j = uint256(keccak256(abi.encode(seed, i))) % max;
            (shuffled[i], shuffled[j]) = (shuffled[j], shuffled[i]);
        }

        return shuffled[index];
    }
}
