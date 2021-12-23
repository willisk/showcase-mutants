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
}
