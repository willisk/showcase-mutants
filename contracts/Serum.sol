// SPDX-License-Identifier: MIT
// https://etherscan.io/address/0x22c36bfdcef207f9c0cc941936eff94d4246d14a#code
pragma solidity 0.8.11;

// import {ChainlinkConsumer} from './ChainlinkConsumer.sol';
// import {MockConsumerBase as VRFBase} from './VRFBase.sol';
import './VRFBase.sol';

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './Mutants.sol';
import './NFT.sol';

contract Serum is ERC1155, Ownable, VRFBase {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY_NFT = 1000;
    uint256 public constant MAX_SUPPLY_M3 = 10;

    uint256 public constant M2_CHANCE_PER_CENT = 33;

    string public baseURI = 'ipfs://XXX/';

    address private mutantsAddress;
    address private nftAddress;

    mapping(uint256 => bool) public claimed;
    mapping(uint256 => bool) private megaIds;

    bool public megaIdsSet;

    constructor() ERC1155(baseURI) {}

    // ------------- External -------------

    function claimSerum(uint256 tokenId) public whenNFTAddressSet {
        require(NFT(nftAddress).ownerOf(tokenId) == msg.sender, 'NOT_CALLERS_NFT');
        require(!claimed[tokenId], 'SERUM_ALREADY_CLAIMED');
        claimed[tokenId] = true;

        uint256 serumType = tokenIdToSerumType(tokenId);

        _mint(msg.sender, serumType, 1, '');
    }

    function claimSerumBatch(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) claimSerum(tokenIds[i]);
    }

    // ------------- Restricted -------------

    function burnSerumOf(address owner, uint256 id) external whenMutantsAddressSet {
        require(msg.sender == mutantsAddress, 'CALLER_NOT_ALLOWED');
        _burn(owner, id, 1);
    }

    // ------------- Admin -------------

    function setMegaSequence() public onlyOwner whenRandomSeedSet whenMegaIdsUnset {
        uint256 counter;
        for (uint256 i; i < MAX_SUPPLY_M3; i++) {
            uint256 nextMegaId;
            do {
                nextMegaId = uint256(keccak256(abi.encode(_randomSeed, counter))) % MAX_SUPPLY_NFT;
                counter++;
            } while (megaIds[nextMegaId]);
            megaIds[nextMegaId] = true;
        }
        megaIdsSet = true;
    }

    function setNFTAddress(address _address) external onlyOwner {
        nftAddress = _address;
    }

    function setMutantsAddress(address _address) external onlyOwner {
        mutantsAddress = _address;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // // XXX: this ability should be removed
    // function mintBatch(uint256[] memory ids, uint256[] memory amounts) external onlyOwner {
    //     _mintBatch(owner(), ids, amounts, '');
    // }

    // // functions from VRFBase:
    // function forceFulfillRandomness() external virtual onlyOwner {}
    // function requestRandomSeed() public virtual onlyOwner returns (bytes32) {}

    // ------------- View -------------

    function tokenIdToSerumType(uint256 tokenId) public view whenMegaIdsSet returns (uint256) {
        if (megaIds[tokenId]) return 2;
        uint256 randomNumber = uint256(keccak256(abi.encode(_randomSeed, tokenId))) % 100;
        if (randomNumber < M2_CHANCE_PER_CENT) return 1;
        return 0;
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(id < 3, 'INVALID_ID');
        return string(abi.encodePacked(baseURI, id.toString(), '.json'));
    }

    function claimActive() external view returns (bool) {
        return nftAddress != address(0) && megaIdsSet;
    }

    // ------------- Modifier -------------

    modifier whenMegaIdsSet() {
        require(megaIdsSet, 'MEGA_IDS_NOT_SET');
        _;
    }

    modifier whenMegaIdsUnset() {
        require(!megaIdsSet, 'MEGA_IDS_SET');
        _;
    }

    modifier whenMutantsAddressSet() {
        require(mutantsAddress != address(0), 'MUTANTS_ADDRESS_NOT_SET');
        _;
    }

    modifier whenNFTAddressSet() {
        require(nftAddress != address(0), 'NFT_ADDRESS_NOT_SET');
        _;
    }
}
