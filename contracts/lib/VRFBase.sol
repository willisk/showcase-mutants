// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@chainlink/contracts/src/v0.8/VRFConsumerBase.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './lib/ShuffleArray.sol';

contract VRFBase is VRFConsumerBase, Ownable {
    bytes32 private keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311; // Rinkeby
    // bytes32 private keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4; // Mumbai

    uint256 private fee = 0.1 * 10**18; // Rinkeby
    // uint256 private fee = 0.0001 * 10**18; // Mumbai

    // random number must leave this much space to max uint256 to safely calculate offsets
    uint256 private ceilGap = 100000;

    uint256 internal _randomSeed;

    constructor()
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Rinkeby
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK Rinkeby
            // 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Mumabi
            // 0x326C977E6efc84E512bB9C30f76E30c160eD06FB // LINK Mumbai
        )
    {}

    // ------------- Admin -------------

    function requestRandomSeed() external virtual onlyOwner whenRandomSeedUnset {
        _requestRandomSeed();
    }

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
        _shiftRandomSeed(randomNumber);
    }

    function _shiftRandomSeed(uint256 randomNumber) internal {
        randomNumber = uint256(keccak256(abi.encode(_randomSeed, randomNumber)));
        if (type(uint256).max - randomNumber < ceilGap) _randomSeed = randomNumber - ceilGap;
        else _randomSeed = randomNumber;
    }

    // ------------- View -------------

    function randomSeedSet() public view returns (bool) {
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
