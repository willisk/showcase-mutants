// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
// import {ChainlinkConsumer} from './ChainlinkConsumer.sol';
// import {MockConsumerBase as VRFBase} from './VRFBase.sol';
// import {VRFBase} from './VRFBase.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import '@openzeppelin/contracts/utils/Strings.sol';
import './Serum.sol';
import './ShinobiBunny.sol';

import './lib/ERC721X.sol';
import './lib/ShuffleArray.sol';
import './lib/VRFBase.sol';

contract Mutants is ERC721X, Ownable, VRFBase {
    using Strings for uint256;
    using ShuffleArray for uint256[];

    // string public baseURI = 'https://boredapeyachtclub.com/api/mutants/';

    string public baseURI = 'ipfs://QmPRaSqJw8MayGd3VhLGFPJHTXZbUEmDtEBRkEnjTTQYu9/';
    string public unrevealedURI = 'QmPkpXpasMVtpeZB3nTvKkMHuRyJQ6ozbnbkbUU8YsLVDB/nrc3.json';

    address private nftAddress;
    address private serumAddress;

    bool public publicSaleActive;
    bool public mutationsActive;

    uint256 public constant price = 0.03 ether;
    uint256 public constant purchaseLimit = 10;

    uint256 public constant MAX_SUPPLY_PUBLIC = 10000;
    uint256 public constant MAX_SUPPLY_M = 10000;
    uint256 public constant MAX_SUPPLY_M3 = 10;

    uint256 private constant OFFSET_M1 = MAX_SUPPLY_PUBLIC;
    uint256 private constant OFFSET_M2 = OFFSET_M1 + MAX_SUPPLY_M;
    uint256 private constant OFFSET_M3 = OFFSET_M2 + MAX_SUPPLY_M;
    uint256 private constant MAX_ID = OFFSET_M3 + MAX_SUPPLY_M3;

    uint256 public numPublicMinted;
    uint256 public numMegaMutants;

    uint256[] private _megaIdsLeft;

    mapping(uint256 => uint256) private _megaTokenIdFinal;
    mapping(bytes32 => uint256) private _requestIdToMegaId;

    constructor() ERC721X('Shinobi Mutant Bunny', 'SNBM') {
        for (uint256 i; i < MAX_SUPPLY_M3; i++) _megaIdsLeft.push(OFFSET_M3 + i);
    }

    // ------------- External -------------

    function mint(uint256 amount) external payable whenPublicSaleActive noContract {
        require(amount <= purchaseLimit, 'EXCEEDS_LIMIT');
        require(msg.value == price * amount, 'INCORRECT_VALUE');

        uint256 tokenId = numPublicMinted;
        require(tokenId + amount <= MAX_SUPPLY_PUBLIC, 'MAX_SUPPLY_REACHED');

        numPublicMinted += amount;
        for (uint256 i; i < amount; i++) _mint(msg.sender, tokenId + i);
    }

    // quirks:
    // - number of mutants are not limited in code, but in the serum supply
    // - nfts can mutate multiple times with M3 serum
    // - mutants can be resurrected once burned
    // - total amount is only bound by number of available serums
    function mutate(uint256 nftId, uint256 serumType) external whenMutationsActive noContract {
        require(NFT(nftAddress).ownerOf(nftId) == msg.sender, 'NOT_CALLERS_TOKEN');
        require(serumType < 3, 'INVALID_SERUM_TYPE');
        uint256 tokenId;
        if (serumType == 0) {
            tokenId = OFFSET_M1 + nftId;
            // numMutants++;
        } else if (serumType == 1) {
            tokenId = OFFSET_M2 + nftId;
            // numMutants++;
        } else {
            tokenId = OFFSET_M3 + numMegaMutants;
            numMegaMutants++;
        }
        _mint(msg.sender, tokenId);
        Serum(serumAddress).burnSerumOf(msg.sender, serumType);
        if (serumType == 2) requestRandomMegaMutant(tokenId);
    }

    // ------------- View -------------

    // assumes proper input, view only
    function canMutate(uint256 nftId, uint256 serumType) external view returns (bool) {
        uint256 tokenId;
        if (serumType == 0) tokenId = OFFSET_M1 + nftId;
        else if (serumType == 1) tokenId = OFFSET_M2 + nftId;
        else tokenId = OFFSET_M3 + numMegaMutants;
        return !_exists(tokenId);
    }

    // public mint and mega ids are reshuffled
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        if (!randomSeedSet() || bytes(baseURI).length == 0) return unrevealedURI;

        uint256 metadataId = tokenId;

        if (tokenId < MAX_SUPPLY_PUBLIC)
            metadataId = ShuffleArray.getShuffledRangeAt(tokenId, MAX_SUPPLY_PUBLIC, _randomSeed);
        else if (tokenId >= OFFSET_M3) {
            metadataId = _megaTokenIdFinal[tokenId];
            if (metadataId == 0) return unrevealedURI; // chainlink hasn't revealed yet
        } else {
            uint256 offset = tokenId >= OFFSET_M2 ? OFFSET_M2 : OFFSET_M1;
            uint256 nftId = tokenId - offset;
            metadataId = NFT(nftAddress).metadataIdOf(nftId) + offset; // shuffled metadataId
        }

        return string(abi.encodePacked(baseURI, metadataId.toString()));
        // XXX YYY ZZZ add back in
        // return string(abi.encodePacked(baseURI, metadataId.toString(), '.json'));
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), 'ERC721: balance query for the zero address');
        uint256 balance;
        for (uint256 i; i < MAX_ID; i++) if (owner == _owners[i]) balance++;
        return balance;
    }

    function tokenIdsOf(address owner) external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](balanceOf(owner));
        uint256 count;
        for (uint256 i; i < MAX_ID; i++) if (owner == _owners[i]) ids[count++] = i;
        return ids;
    }

    // ------------- Internal -------------

    // function _requestRandomSeed() internal virtual returns (bytes32) {}

    function requestRandomMegaMutant(uint256 tokenId) internal virtual {
        bytes32 requestId = _requestRandomSeed();
        _requestIdToMegaId[requestId] = tokenId; // signal that this is a request for the specific tokenId
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        uint256 tokenId = _requestIdToMegaId[requestId];
        if (tokenId == 0) _setRandomSeed(randomNumber);
        else _setMegaTokenId(tokenId, randomNumber);
    }

    function _setMegaTokenId(uint256 tokenId, uint256 randomNumber) private {
        require(_exists(tokenId), 'MEGA_ID_NOT_FOUND');
        require(_megaTokenIdFinal[tokenId] == 0, 'MEGA_ID_ALREADY_SET');
        _megaTokenIdFinal[tokenId] = _megaIdsLeft.nextRandomElement(randomNumber);
    }

    // ------------- Owner -------------

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setUnrevealedURI(string memory _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function setPublicSaleActive(bool active) external onlyOwner {
        publicSaleActive = active;
    }

    function setMutationsActive(bool active) external onlyOwner {
        mutationsActive = active;
    }

    function setNFTAddress(address _address) external onlyOwner {
        nftAddress = _address;
    }

    function setSerumAddress(address _address) external onlyOwner {
        serumAddress = _address;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.call{value: balance}('');
    }

    function recoverToken(IERC20 _token) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        _token.transfer(msg.sender, balance);
    }

    // function forceFulfillRandomness() external virtual onlyOwner whenRandomSeedUnset {}

    // emergency fail-safe
    function forceFulfillRandomMegaMutant(uint256 mutantId) external onlyOwner {
        require(OFFSET_M3 <= mutantId, 'INVALID_MEGA_ID');
        uint256 randomNumber = uint256(blockhash(block.number - 1));
        _setMegaTokenId(mutantId, randomNumber);
    }

    // ------------- Modifier -------------

    modifier whenPublicSaleActive() {
        require(publicSaleActive, 'PUBLIC_SALE_NOT_ACTIVE');
        _;
    }

    modifier whenMutationsActive() {
        require(mutationsActive, 'MUTATIONS_NOT_ACTIVE');
        _;
    }

    modifier noContract() {
        require(tx.origin == msg.sender, 'CONTRACT_CALL');
        _;
    }
}
