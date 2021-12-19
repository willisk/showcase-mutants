// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './NFT.sol';
import './ERC721Y.sol';

// import './Serum.sol';

contract Mutants is ERC721Y, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;

    string public unrevealedURI = 'ipfs://XXX';
    string public baseURI;

    uint256 public constant MAX_PUBLIC_SUPPLY = 1000;
    uint256 public constant MAX_SUPPLY = 2000;

    uint256 public constant PRICE = 0.03 ether;
    uint256 public constant PURCHASE_LIMIT = 10;

    uint256 private numMutated;
    uint256 private numPublicMinted;

    constructor() ERC721Y('Mutants', 'MUTX', MAX_SUPPLY) {}

    // ------------- User Api -------------

    function mint(uint256 amount) external payable whenNotPaused onlyHuman {
        require(amount <= PURCHASE_LIMIT, 'EXCEEDS_LIMIT');
        require(msg.value == PRICE * amount, 'INCORRECT_VALUE');

        uint256 tokenId = numPublicMinted;
        require(tokenId + amount < MAX_PUBLIC_SUPPLY, 'MAX_SUPPLY_REACHED');

        for (uint256 i; i < amount; i++) _mint(tokenId + i);
    }

    function mutate(uint256 id, uint256 serumType) external onlyHuman {}

    // function getCurrentAuctionPrice() public view returns (uint256) {
    //     if (block.timestamp <= _auctionStartTime) return _auctionStartPrice;
    //     if (_auctionEndTime <= block.timestamp) return _auctionEndPrice;
    //     uint256 price = _auctionStartPrice + (block.timestamp - _auctionStartTime) / ()
    // }

    // ------------- Admin -------------

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

    function _mint(uint256 tokenId) internal {
        _owners[tokenId] = msg.sender;
        emit Transfer(address(0), msg.sender, tokenId);
    }

    // ------------- Modifier -------------

    modifier onlyHuman() {
        require(tx.origin == msg.sender, 'CONTRACT_CALL');
        _;
    }
}
