//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NFTXXX is ERC721, Ownable {
    using ECDSA for bytes32;

    event StateUpdate(bool isActive);

    string public baseURI;

    bool public isActive = false;

    uint256 public constant PRICE = 0.03 ether;
    uint256 public constant PURCHASE_LIMIT = 10;
    uint256 public constant MAX_SUPPLY = 500;
    uint256 public reserveSupply = 100;
    uint256 public totalSupply;

    mapping(address => bool) private whitelistUsed;

    constructor() ERC721("MyNFTXXX", "NFTXXX") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    modifier onlyWhenActive() {
        require(isActive, "Sale is not active");
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
        require(signer == owner(), "Sender is not whitelisted");
        require(!whitelistUsed[msg.sender], "Whitelist already used");
        whitelistUsed[msg.sender] = true;
        _;
    }

    function mint(uint256 _amount) external payable onlyWhenActive onlyHuman {
        uint256 amountLeft = MAX_SUPPLY - totalSupply - reserveSupply;

        require(amountLeft > 0, "No supply left");
        require(_amount <= PURCHASE_LIMIT, "Exceeds purchase limit");
        require(msg.value >= PRICE * _amount, "ETH amount insufficient");

        for (uint256 i = 0; i < _amount; i++) {
            if (amountLeft > i) {
                _mint(msg.sender, totalSupply);
                totalSupply++;
            }
        }

        if (_amount > amountLeft)
            payable(msg.sender).transfer(PRICE * (_amount - amountLeft));
    }

    function whitelistMint(uint256 _amount, bytes memory signature)
        external
        payable
        onlyWhitelisted(signature)
        onlyHuman
    {
        uint256 amountLeft = MAX_SUPPLY - totalSupply - reserveSupply;

        require(amountLeft > 0, "No supply left");
        require(_amount <= PURCHASE_LIMIT, "Exceeds purchase limit");
        require(msg.value >= PRICE * _amount, "ETH amount insufficient");

        for (uint256 i = 0; i < _amount; i++) {
            if (amountLeft > i) {
                _mint(msg.sender, totalSupply);
                totalSupply++;
            }
        }

        if (_amount > amountLeft)
            payable(msg.sender).transfer(PRICE * (_amount - amountLeft));
    }

    // ------------- Admin -------------

    function setSaleState(bool active) external onlyOwner {
        isActive = active;
        emit StateUpdate(active);
    }

    function setBaseURI(string memory _baseURIString) external onlyOwner {
        baseURI = _baseURIString;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner {
        require(_amount <= reserveSupply, "Exceeds reserved supply");

        for (uint256 i; i < _amount; i++) {
            _mint(_to, totalSupply);
            totalSupply++;
        }

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
}
