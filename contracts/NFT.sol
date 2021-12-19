//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// import "hardhat/console.sol";

import './ERC721X.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

contract NFT is ERC721X, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    enum PHASE {
        INITIAL,
        PRESALE,
        PUBLIC
    }

    event PhaseUpdate(PHASE phase);

    PHASE public phase;

    address private _signerAddress = 0x68442589f40E8Fc3a9679dE62884c85C6E524888;

    string public unrevealedURI = 'ipfs://XXX';
    string public baseURI;

    uint256 public constant MAX_SUPPLY = 500;

    uint256 public constant PRICE = 0.03 ether;
    uint256 public constant PURCHASE_LIMIT = 10;

    uint256 public constant WHITELIST_PRICE = 0.03 ether;
    uint256 public constant WHITELIST_PURCHASE_LIMIT = 2;

    mapping(address => bool) private _whitelistUsed;
    mapping(address => bool) private _diamondlistUsed;

    constructor() ERC721X('MyNFTXXX', 'NFTXXX') {}

    // ------------- User Api -------------

    function mint(uint256 amount) external payable onlyPublicSale onlyHuman {
        require(amount <= PURCHASE_LIMIT, 'EXCEEDS_LIMIT');
        require(msg.value == PRICE * amount, 'INCORRECT_VALUE');

        require(totalSupply() + amount < MAX_SUPPLY, 'MAX_SUPPLY_REACHED');

        for (uint256 i; i < amount; i++) _mintNextIdForSender();
    }

    function whitelistMint(uint256 amount, bytes memory signature) external payable onlyPresale onlyWhitelisted(signature) onlyHuman {
        require(amount <= WHITELIST_PURCHASE_LIMIT, 'EXCEEDS_LIMIT');
        require(msg.value == WHITELIST_PRICE * amount, 'INCORRECT_VALUE');

        require(totalSupply() + amount < MAX_SUPPLY, 'MAX_SUPPLY_REACHED');
        for (uint256 i; i < amount; i++) _mintNextIdForSender();
    }

    function diamondMint(bytes memory signature) external payable onlyInitialPhase onlyDiamondlisted(signature) onlyHuman {
        require(totalSupply() < MAX_SUPPLY, 'MAX_SUPPLY_REACHED');
        _mintNextIdForSender();
    }

    // ------------- Admin -------------

    function setSignerAddress(address _address) external onlyOwner {
        _signerAddress = _address;
    }

    function setSalePhase(PHASE _phase) external onlyOwner {
        phase = _phase;
        emit PhaseUpdate(_phase);
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
        require(_success, 'Token could not be transferred');
    }

    // ------------- View -------------

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json')) : unrevealedURI;
    }

    function presaleActive() external view returns (bool) {
        return phase == PHASE.PRESALE;
    }

    function publicSaleActive() external view returns (bool) {
        return phase == PHASE.PUBLIC;
    }

    // ------------- Internal -------------

    function _mintNextIdForSender() internal {
        _owners.push(msg.sender);
        emit Transfer(address(0), msg.sender, totalSupply());
    }

    // ------------- Modifier -------------

    modifier onlyInitialPhase() {
        require(phase == PHASE.INITIAL, 'INITIAL_PHASE_NOT_ACTIVE');
        _;
    }

    modifier onlyPresale() {
        require(phase == PHASE.PRESALE, 'PRESALE_NOT_ACTIVE');
        _;
    }

    modifier onlyPublicSale() {
        require(phase == PHASE.PUBLIC, 'PUBLIC_SALE_NOT_ACTIVE');
        _;
    }

    modifier onlyHuman() {
        require(tx.origin == msg.sender, 'CONTRACT_CALL');
        _;
    }

    // await signer.signMessage(_ethers.utils.arrayify(_ethers.utils.keccak256(_ethers.utils.defaultAbiCoder.encode(['address', 'address'], ['<contract>', '<user>']))))
    modifier onlyDiamondlisted(bytes memory signature) {
        bytes32 msgHash = keccak256(abi.encode(address(this), PHASE.INITIAL, msg.sender));
        address signer = msgHash.toEthSignedMessageHash().recover(signature);
        require(signer == _signerAddress, 'NOT_WHITELISTED');
        require(!_diamondlistUsed[msg.sender], 'WHITELIST_USED');
        _diamondlistUsed[msg.sender] = true;
        _;
    }

    modifier onlyWhitelisted(bytes memory signature) {
        bytes32 msgHash = keccak256(abi.encode(address(this), PHASE.PRESALE, msg.sender));
        address signer = msgHash.toEthSignedMessageHash().recover(signature);
        require(signer == _signerAddress, 'NOT_WHITELISTED');
        require(!_whitelistUsed[msg.sender], 'WHITELIST_USED');
        _whitelistUsed[msg.sender] = true;
        _;
    }
}
