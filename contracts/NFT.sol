//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// import "hardhat/console.sol";

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import './ERC721X.sol';

contract NFT is ERC721X, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 private constant STATE_INITIAL = 0;
    uint256 private constant STATE_PRESALE = 1;
    uint256 private constant STATE_PUBLIC = 2;

    event StateUpdate(uint256 state);

    uint256 public state;

    address private _signerAddress = 0x68442589f40E8Fc3a9679dE62884c85C6E524888;

    string public unrevealedURI = 'ipfs://XXX';
    string public baseURI;

    uint256 public totalSupply;
    uint256 public constant MAX_SUPPLY = 1000;

    uint256 public constant PRICE = 0.03 ether;
    uint256 public constant PURCHASE_LIMIT = 10;

    uint256 public constant WHITELIST_PRICE = 0.03 ether;
    uint256 public constant WHITELIST_PURCHASE_LIMIT = 2;

    mapping(address => bool) private _whitelistUsed;
    mapping(address => bool) private _diamondlistUsed;

    constructor() ERC721X('MyNFTXXX', 'NFTXXX') {}

    // ------------- External -------------

    function mint(uint256 amount) external payable whenPublicSaleActive onlyHuman {
        require(amount <= PURCHASE_LIMIT, 'EXCEEDS_LIMIT');
        require(msg.value == PRICE * amount, 'INCORRECT_VALUE');

        _mintBatchTo(msg.sender, amount);
    }

    function whitelistMint(uint256 amount, bytes memory signature)
        external
        payable
        whenPresaleActive
        onlyWhitelisted(signature)
        onlyHuman
    {
        require(amount <= WHITELIST_PURCHASE_LIMIT, 'EXCEEDS_LIMIT');
        require(msg.value == WHITELIST_PRICE * amount, 'INCORRECT_VALUE');

        _mintBatchTo(msg.sender, amount);
    }

    function diamondMint(bytes memory signature)
        external
        payable
        whenInitialState
        onlyDiamondlisted(signature)
        onlyHuman
    {
        uint256 tokenId = totalSupply;
        require(tokenId < MAX_SUPPLY, 'MAX_SUPPLY_REACHED');
        _mintTo(msg.sender);
    }

    // ------------- Admin -------------

    function giveAway(address to, uint256 amount) external onlyOwner {
        _mintBatchTo(to, amount); // XXX: maybe safemint?
    }

    function setSignerAddress(address _address) external onlyOwner {
        _signerAddress = _address;
    }

    function setSaleState(uint256 _state) external onlyOwner {
        state = _state;
        emit StateUpdate(_state);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setUnrevealedURI(string memory _uri) external onlyOwner {
        unrevealedURI = _uri;
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

    // ------------- View -------------

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, '/', tokenId.toString(), '.json'))
                : unrevealedURI;
    }

    function presaleActive() external view returns (bool) {
        return state == STATE_PRESALE;
    }

    function publicSaleActive() external view returns (bool) {
        return state == STATE_PUBLIC;
    }

    // ------------- Internal -------------

    function _mintTo(address to) internal {
        uint256 tokenId = totalSupply;
        require(tokenId < MAX_SUPPLY, 'MAX_SUPPLY_REACHED');

        _mint(to, tokenId);
        totalSupply++;
    }

    function _mintBatchTo(address to, uint256 amount) internal {
        uint256 tokenId = totalSupply;
        require(tokenId + amount <= MAX_SUPPLY, 'MAX_SUPPLY_REACHED');

        for (uint256 i; i < amount; i++) _mint(to, tokenId + i); // could use unchecked
        totalSupply += amount;
    }

    function _validSignature(bytes memory signature, uint256 _state) internal view returns (bool) {
        bytes32 msgHash = keccak256(abi.encode(address(this), _state, msg.sender));
        return msgHash.toEthSignedMessageHash().recover(signature) == _signerAddress;
    }

    // ------------- Modifier -------------

    modifier whenInitialState() {
        require(state == STATE_INITIAL, 'INITIAL_STATE_NOT_ACTIVE');
        _;
    }

    modifier whenPresaleActive() {
        require(state == STATE_PRESALE, 'PRESALE_NOT_ACTIVE');
        _;
    }

    modifier whenPublicSaleActive() {
        require(state == STATE_PUBLIC, 'PUBLIC_SALE_NOT_ACTIVE');
        _;
    }

    modifier onlyHuman() {
        require(tx.origin == msg.sender, 'CONTRACT_CALL');
        _;
    }

    // await signer.signMessage(_ethers.utils.arrayify(_ethers.utils.keccak256(_ethers.utils.defaultAbiCoder.encode(['address', 'address'], ['<contract>', '<user>']))))
    modifier onlyDiamondlisted(bytes memory signature) {
        require(_validSignature(signature, STATE_INITIAL), 'NOT_WHITELISTED');
        require(!_diamondlistUsed[msg.sender], 'WHITELIST_USED');
        _diamondlistUsed[msg.sender] = true;
        _;
    }

    modifier onlyWhitelisted(bytes memory signature) {
        require(_validSignature(signature, STATE_PRESALE), 'NOT_WHITELISTED');
        require(!_whitelistUsed[msg.sender], 'WHITELIST_USED');
        _whitelistUsed[msg.sender] = true;
        _;
    }
}
