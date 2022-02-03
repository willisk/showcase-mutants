// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
// import {ChainlinkConsumer} from './ChainlinkConsumer.sol';
// import {MockConsumerBase as VRFBase} from './VRFBase.sol';
// import {VRFBase} from './VRFBase.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
// import '@openzeppelin/contracts/security/Pausable.sol';
// import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import '@openzeppelin/contracts/utils/Strings.sol';
import './Serum.sol';
import './NFT.sol';

import './lib/ERC721X.sol';
import './lib/ShuffleArray.sol';
import './lib/VRFBase.sol';

// import './Serum.sol';

contract Mutants is ERC721X, Ownable, VRFBase {
    using Strings for uint256;
    using ShuffleArray for uint256[];

    string public unrevealedURI = 'unrevealedURI';
    string public baseURI = 'baseURI/';

    address private nftAddress;
    address private serumAddress;

    bool public publicSaleActive;
    bool public mutationsActive;

    bytes32 private _secretHash;
    bool public revealed;

    uint256 public constant price = 0.03 ether;
    uint256 public constant purchaseLimit = 10;

    uint256 public constant MAX_SUPPLY_PUBLIC = 1000;
    uint256 public constant MAX_SUPPLY_M = 1000;
    uint256 public constant MAX_SUPPLY_M3 = 10;

    uint256 private constant OFFSET_M1 = MAX_SUPPLY_PUBLIC;
    uint256 private constant OFFSET_M2 = OFFSET_M1 + MAX_SUPPLY_M;
    uint256 private constant OFFSET_M3 = OFFSET_M2 + MAX_SUPPLY_M;
    uint256 private constant MAX_ID = OFFSET_M3 + MAX_SUPPLY_M3;

    uint256 public numPublicMinted;
    // uint256 private numMutants; // XXX: this variable could be removed (saves 1 sstore on mutate())
    uint256 public numMegaMutants;

    uint256[] private _megaIdsLeft;

    mapping(uint256 => uint256) private _megaTokenIdFinal;
    mapping(bytes32 => uint256) private _requestIdToMegaId;

    constructor(bytes32 secretHash_) ERC721X('Mutants', 'MUTX') {
        for (uint256 i; i < MAX_SUPPLY_M3; i++) _megaIdsLeft.push(OFFSET_M3 + i);
        _secretHash = secretHash_;
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

    // ------------- Admin -------------

    // extra security for reveal:
    // the owner sets a hash of a secret seed
    // once chainlink randomness fulfills, the secret is revealed and shifts the secret seed set by chainlink
    // Why? The final randomness should come from a trusted third party,
    // however techies could read the code and grab the chainlink seed before the reveal.
    // There is a time-frame in which an unfair advantage is gained after the seed is set and before the metadata is revealed.
    // This eliminates any possibility of the team generating an unfair seed and any unfair advantage by snipers.
    function reveal(string memory _baseURI, bytes32 secretSeed_) external onlyOwner whenRandomSeedSet {
        require(!revealed, 'ALREADY_REVEALED');
        require(_secretHash == keccak256(abi.encode(secretSeed_)), 'SECRET_HASH_DOES_NOT_MATCH');
        _shiftRandomSeed(uint256(secretSeed_));
        revealed = true;
        baseURI = _baseURI;
    }

    // requires that the reveal is first done through chainlink vrf
    function setBaseURI(string memory _baseURI) external onlyOwner onceRevealed {
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
        payable(msg.sender).transfer(balance);
    }

    function recoverToken(IERC20 _token) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        bool _success = _token.transfer(owner(), balance);
        require(_success, 'TOKEN_TRANSFER_FAILED');
    }

    // function forceFulfillRandomness() external virtual onlyOwner whenRandomSeedUnset {}

    // emergency fail-safe
    function forceFulfillRandomMegaMutant(uint256 mutantId) external onlyOwner {
        require(OFFSET_M3 <= mutantId, 'INVALID_MEGA_ID');
        uint256 randomNumber = uint256(blockhash(block.number - 1));
        _setMegaTokenId(mutantId, randomNumber);
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
        if (!revealed) return unrevealedURI;

        uint256 metadataId = tokenId;

        // if (tokenId < MAX_SUPPLY_PUBLIC) metadataId = (tokenId + _randomSeed) % MAX_SUPPLY_PUBLIC;
        if (tokenId < MAX_SUPPLY_PUBLIC) ShuffleArray.getShuffledRangeAt(tokenId, MAX_SUPPLY_PUBLIC, _randomSeed);
        else if (tokenId >= OFFSET_M3) {
            metadataId = _megaTokenIdFinal[tokenId];
            if (metadataId == 0) return unrevealedURI; // chainlink hasn't revealed yet
        }

        return string(abi.encodePacked(baseURI, metadataId.toString(), '.json'));
    }

    // removed to save on gas
    // function totalSupply() external view returns (uint256) {
    //     return numPublicMinted + numMutants + numMegaMutants;
    // }

    function balanceOf(address owner) public view override returns (uint256) {
        return _balanceOfRange(owner, 0, MAX_ID);
    }

    function balanceOfM0(address owner) external view returns (uint256) {
        return _balanceOfRange(owner, 0, OFFSET_M1);
    }

    function balanceOfM1(address owner) external view returns (uint256) {
        return _balanceOfRange(owner, OFFSET_M1, OFFSET_M2);
    }

    function balanceOfM2(address owner) external view returns (uint256) {
        return _balanceOfRange(owner, OFFSET_M2, OFFSET_M3);
    }

    function balanceOfM3(address owner) external view returns (uint256) {
        return _balanceOfRange(owner, OFFSET_M3, MAX_ID);
    }

    function tokenIdsOf(address owner) external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](balanceOf(owner));
        for (uint256 i; i < MAX_ID; i++) if (owner == _owners[i]) ids[i] = i;
        return ids;
    }

    // function getMutantId(uint256 apeId, uint256 serumType) external view returns (uint256) {
    //     require(serumType < 3, 'INVALID_SERUM_TYPE');
    //     if (serumType == 0) return OFFSET_M1 + apeId;
    //     else if (serumType == 1) return OFFSET_M2 + apeId;
    //     else return OFFSET_M3 + numMegaMutants;
    // }

    // ------------- Internal -------------

    function _balanceOfRange(
        address owner,
        uint256 start,
        uint256 end
    ) private view returns (uint256) {
        require(owner != address(0), 'ERC721: balance query for the zero address');
        uint256 balance;
        for (uint256 i = start; i < end; i++) if (owner == _owners[i]) balance++;
        return balance;
    }

    // function _requestRandomSeed() internal virtual returns (bytes32) {}

    function requestRandomMegaMutant(uint256 tokenId) private {
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

    // ------------- Modifier -------------

    modifier onceRevealed() {
        require(revealed, 'NOT_REVEALED_YET');
        _;
    }

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
