//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// import "hardhat/console.sol";

import './ERC721X.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

contract Bushido is ERC721X, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    bool public saleIsActive;

    string public unrevealedURI = 'ipfs://QmeYGuHZTAu4WbuJ23r1R7NEfiRW5FM3wUWRmfw7qwbyd2/prereveal.json';
    string public baseURI = 'ipfs://QmX1rWmYRNua7jpV5cQwkAzATu8Z7d5cyCCZUrUDVaaCoc/';

    uint256 public constant MAX_SUPPLY = 7077;

    uint256 public constant PRICE = 0.08 ether;
    uint256 public constant PURCHASE_LIMIT = 10;

    uint256 public constant PRICE_MOST = 0.06 ether;

    constructor() ERC721X('Bushido7077', 'SHIDO') {
        _mintBatch(100);
    }

    // ------------- User Api -------------

    function mint(uint256 amount) external payable whenSaleActive onlyHuman {
        require(amount <= PURCHASE_LIMIT, 'EXCEEDS_LIMIT');
        require(msg.value == PRICE * amount, 'INCORRECT_VALUE');

        require(totalSupply() + amount < MAX_SUPPLY, 'MAX_SUPPLY_REACHED');

        _mintBatch(amount);
    }

    // ------------- Admin -------------

    function setSaleState(bool _active) external onlyOwner {
        saleIsActive = _active;
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

    // ------------- Internal -------------

    function _mintBatch(uint256 amount) internal {
        uint256 startIndex = totalSupply();
        for (uint256 i; i < amount; i++) {
            _owners.push(msg.sender);
            emit Transfer(address(0), msg.sender, startIndex + i);
        }
    }

    // ------------- Modifier -------------

    modifier whenSaleActive() {
        require(saleIsActive, 'PUBLIC_SALE_NOT_ACTIVE');
        _;
    }

    modifier onlyHuman() {
        require(tx.origin == msg.sender, 'CONTRACT_CALL');
        _;
    }
}
