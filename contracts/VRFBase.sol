// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@chainlink/contracts/src/v0.8/VRFConsumerBase.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './lib/ShuffleArray.sol';

contract MockConsumerBase is Ownable {
    uint256 internal _randomSeed;

    function requestRandomness(bytes32 keyHash, uint256 fee) external onlyOwner {}

    function fulfillRandomness(bytes32 requestId, uint256 randomness) external onlyOwner {
        _randomSeed = 1337;
    }

    function _randomSeedSet() internal view returns (bool) {
        return _randomSeed > 0;
    }
}

contract VRFBase is VRFConsumerBase, Ownable {
    bytes32 private keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
    uint256 private fee = 0.1 * 10**18;

    // random number must leave this much space to max uint256 to safely calculate offsets
    uint256 private ceilGap = 100000;

    uint256 internal _randomSeed;

    constructor()
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            // 0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK Rinkeby
        )
    {}

    // ------------- Admin -------------

    // this function should not be needed and is just an emergency fail-safe if
    // for some reason chainlink is not able to fulfill the randomness callback
    function forceFulfillRandomness() external virtual onlyOwner {
        uint256 randomNumber = uint256(blockhash(block.number - 1));
        _setRandomSeed(randomNumber);
    }

    // ------------- Internal -------------

    // NOTE: this function is not guarded by whenRandomSeedUnset, even though the
    // callback would fail. Why? Because fulfillRandomness logic can be overriden.
    function _requestRandomSeed() internal virtual returns (bytes32) {
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal virtual override {
        _setRandomSeed(randomNumber);
    }

    function _setRandomSeed(uint256 randomNumber) internal whenRandomSeedUnset {
        if (type(uint256).max - randomNumber < ceilGap) _randomSeed = randomNumber - ceilGap;
        else _randomSeed = randomNumber;
    }

    // ------------- View -------------

    function randomSeedSet() internal view returns (bool) {
        return _randomSeed > 0;
    }

    // ------------- Modifier -------------

    modifier whenRandomSeedSet() {
        require(randomSeedSet(), 'RANDOM_SEED_NOT_SET');
        _;
    }

    modifier whenRandomSeedUnset() {
        require(!randomSeedSet(), 'RANDOM_SEED_SET');
        _;
    }
}
