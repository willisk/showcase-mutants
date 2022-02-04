//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import './lib/ERC721X.sol';
import './lib/VRFBase.sol';

contract NFT is ERC721X, Ownable, VRFBase {
    using ECDSA for bytes32;
    using Strings for uint256;

    event SaleStateUpdate(bool active);

    string public baseURI;
    // string public baseURI = 'ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/';
    string public unrevealedURI = 'ipfs://XXX';

    bool public publicSaleActive;
    bool public whitelistActive;
    bool public diamondlistActive;

    uint256 public totalSupply;
    uint256 public constant MAX_SUPPLY = 1000;

    uint256 public price = 0.03 ether;
    uint256 public purchaseLimit = 2;

    uint256 public whitelistPrice = 0.03 ether;
    uint256 public whitelistPurchaseLimit = 2;

    mapping(address => bool) private _whitelistUsed;
    mapping(address => bool) private _diamondlistUsed;

    address private _signerAddress = 0x68442589f40E8Fc3a9679dE62884c85C6E524888;

    uint256 private constant SIGNED_DATA_WHITELIST = 69;
    uint256 private constant SIGNED_DATA_DIAMONDLIST = 1337;

    constructor() ERC721X('MyNFTXXX', 'NFTXXX') {}

    // ------------- External -------------

    function mint(uint256 amount) external payable whenPublicSaleActive noContract {
        require(amount <= purchaseLimit, 'EXCEEDS_LIMIT');
        require(msg.value == price * amount, 'INCORRECT_VALUE');

        _mintBatch(msg.sender, amount);
    }

    function whitelistMint(uint256 amount, bytes memory signature)
        external
        payable
        whenWhitelistActive
        onlyWhitelisted(signature)
        noContract
    {
        require(amount <= whitelistPurchaseLimit, 'EXCEEDS_LIMIT');
        require(msg.value == whitelistPrice * amount, 'INCORRECT_VALUE');

        _mintBatch(msg.sender, amount);
    }

    function diamondlistMint(bytes memory signature)
        external
        payable
        whenDiamondlistActive
        onlyDiamondlisted(signature)
        noContract
    {
        _mintBatch(msg.sender, 1);
    }

    // ------------- Private -------------

    function _mintBatch(address to, uint256 amount) private {
        uint256 tokenId = totalSupply;
        require(tokenId + amount <= MAX_SUPPLY, 'MAX_SUPPLY_REACHED');
        require(amount > 0, 'MUST_BE_GREATER_0');

        for (uint256 i; i < amount; i++) _mint(to, tokenId + i);
        totalSupply += amount;
    }

    function _validSignature(bytes memory signature, bytes32 data) private view returns (bool) {
        bytes32 msgHash = keccak256(abi.encode(address(this), data, msg.sender));
        return msgHash.toEthSignedMessageHash().recover(signature) == _signerAddress;
    }

    // ------------- View -------------

    function metadataIdOf(uint256 tokenId) public view returns (uint256) {
        return ShuffleArray.getShuffledRangeAt(tokenId, MAX_SUPPLY, _randomSeed);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        if (!randomSeedSet() || bytes(baseURI).length == 0) return unrevealedURI;
        uint256 metadataId = metadataIdOf(tokenId);
        return string(abi.encodePacked(baseURI, metadataId.toString()));
        // XXX YYY ZZZ add back in
        // return string(abi.encodePacked(baseURI, metadataId.toString(), '.json'));
    }

    // ------------- Admin -------------

    function giveAway(address[] calldata accounts) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) _mintBatch(accounts[i], 1);
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setWhitelistPrice(uint256 price_) external onlyOwner {
        whitelistPrice = price_;
    }

    function setPurchaseLimit(uint256 limit) external onlyOwner {
        purchaseLimit = limit;
    }

    function setWhitelistPurchaseLimit(uint256 limit) external onlyOwner {
        whitelistPurchaseLimit = limit;
    }

    function setSignerAddress(address address_) external onlyOwner {
        _signerAddress = address_;
    }

    function setWhitelistActive(bool active) external onlyOwner {
        whitelistActive = active;
    }

    function setDiamondlistActive(bool active) external onlyOwner {
        diamondlistActive = active;
    }

    function setPublicSaleActive(bool active) external onlyOwner {
        publicSaleActive = active;
        emit SaleStateUpdate(active);
    }

    // function reveal(string memory _baseURI) external onlyOwner {
    //     baseURI = _baseURI;
    // }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setUnrevealedURI(string memory _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.call{value: balance}('');
    }

    function recoverToken(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
    }

    // ------------- Modifier -------------

    modifier whenDiamondlistActive() {
        require(diamondlistActive, 'DIAMONDLIST_NOT_ACTIVE');
        _;
    }

    modifier whenWhitelistActive() {
        require(whitelistActive, 'WHITELIST_NOT_ACTIVE');
        _;
    }

    modifier whenPublicSaleActive() {
        require(publicSaleActive, 'PUBLIC_SALE_NOT_ACTIVE');
        _;
    }

    modifier noContract() {
        require(tx.origin == msg.sender, 'CONTRACT_CALL');
        _;
    }

    modifier onlyDiamondlisted(bytes memory signature) {
        require(_validSignature(signature, bytes32(SIGNED_DATA_DIAMONDLIST)), 'NOT_WHITELISTED');
        require(!_diamondlistUsed[msg.sender], 'WHITELIST_USED');
        _diamondlistUsed[msg.sender] = true;
        _;
    }

    modifier onlyWhitelisted(bytes memory signature) {
        require(_validSignature(signature, bytes32(SIGNED_DATA_WHITELIST)), 'NOT_WHITELISTED');
        require(!_whitelistUsed[msg.sender], 'WHITELIST_USED');
        _whitelistUsed[msg.sender] = true;
        _;
    }

    // ------------- ERC721 -------------

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), 'ERC721: balance query for the zero address');
        uint256 count;
        for (uint256 i; i < totalSupply; ++i) if (owner == _owners[i]) count++;
        return count;
    }

    function tokenIdsOf(address owner) public view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](balanceOf(owner));
        uint256 count;
        for (uint256 i; i < totalSupply; ++i) if (owner == _owners[i]) tokenIds[count++] = i;
        return tokenIds;
    }
}
