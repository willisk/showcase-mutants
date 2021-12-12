//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NFTXXX is ERC721Enumerable, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    event StateUpdate(bool isActive);

    string public unrevealedURI = "ipfs://XXX";
    string public baseURI;

    bool public isActive;

    uint256 public constant PRICE = 0.03 ether;
    uint256 public constant PURCHASE_LIMIT = 10;
    uint256 public constant MAX_SUPPLY = 500;
    uint256 public reserveSupply = 100;

    mapping(address => bool) private whitelistUsed;

    constructor() ERC721("MyNFTXXX", "NFTXXX") {}

    // ------------- User Api -------------

    function publicMint(uint256 amount)
        external
        payable
        onlyWhenActive
        onlyPaid(amount)
        onlyHuman
    {
        _mintFor(msg.sender, amount);
    }

    function whitelistMint(uint256 amount, bytes memory signature)
        external
        payable
        onlyWhitelisted(signature)
        // onlyPaid(amount) // XXX
        onlyHuman
    {
        _mintFor(msg.sender, amount);
    }

    function mint(uint256 _amount) external payable onlyWhenActive onlyHuman {
        require(_amount <= PURCHASE_LIMIT, "Exceeds purchase limit");
        require(msg.value >= PRICE * _amount, "ETH amount insufficient");

        uint256 amountLeft = _amountLeft();
        _mintFor(msg.sender, amountLeft);

        if (_amount > amountLeft)
            payable(msg.sender).transfer(PRICE * (_amount - amountLeft));
    }

    // ------------- Internal -------------

    function _mintFor(address user, uint256 amount) internal {
        require(amount <= _amountLeft(), "No supply left");

        for (uint256 i = 0; i < amount; i++) _mint(user, totalSupply());
    }

    // ------------- Modifier -------------

    modifier onlyWhenActive() {
        require(isActive, "Sale is not active");
        _;
    }

    modifier onlyPaid(uint256 _amount) {
        // require(msg.value == PRICE, "Incorrect value supplied");
        require(msg.value == PRICE * _amount, "Incorrect value supplied");
        _;
    }

    modifier onlyHuman() {
        require(tx.origin == msg.sender, "Contract calls not allowed");
        _;
    }

    // await signer.signMessage(_ethers.utils.arrayify(_ethers.utils.keccak256(_ethers.utils.defaultAbiCoder.encode(['address', 'address'], ['<contract>', '<user>']))))
    modifier onlyWhitelisted(bytes memory signature) {
        bytes32 msgHash = keccak256(abi.encode(address(this), msg.sender));
        address signer = msgHash.toEthSignedMessageHash().recover(signature);
        require(signer == owner(), "Caller not whitelisted");
        require(!whitelistUsed[msg.sender], "Whitelist already used");
        whitelistUsed[msg.sender] = true;
        _;
    }

    // ------------- Admin -------------

    function setSaleState(bool active) external onlyOwner {
        isActive = active;
        emit StateUpdate(active);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setUnrevealedURI(string memory _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner {
        require(_amount <= reserveSupply, "Exceeds reserved supply");

        for (uint256 i; i < _amount; i++) _mint(_to, totalSupply());

        reserveSupply -= _amount;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function recoverToken(IERC20 _token) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        bool _success = _token.transfer(owner(), balance);
        require(_success, "Token could not be transferred");
    }

    // ------------- View -------------

    function _amountLeft() internal view returns (uint256) {
        return MAX_SUPPLY - totalSupply() - reserveSupply;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, "/", tokenId.toString(), ".json")
                )
                : unrevealedURI;
    }
}
