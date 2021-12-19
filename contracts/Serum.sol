// SPDX-License-Identifier: MIT
// https://etherscan.io/address/0x22c36bfdcef207f9c0cc941936eff94d4246d14a#code
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Serum is ERC1155, Ownable {
    using Strings for uint256;

    event SetBaseURI(string indexed _baseURI);

    string public baseURI = 'ipfs://XXX/';
    address private mutationContract;

    mapping(uint256 => bool) public validIds;

    constructor() ERC1155(baseURI) {
        validIds[0] = true;
        validIds[1] = true;
        validIds[69] = true;
        emit SetBaseURI(baseURI);
    }

    // ------------- Restricted -------------

    function burnSerumForAddress(uint256 id, address from) external {
        require(msg.sender == mutationContract, 'CALLER_NOT_ALLOWED');
        _burn(from, id, 1);
    }

    // ------------- Admin -------------

    function mintBatch(uint256[] memory ids, uint256[] memory amounts) external onlyOwner {
        _mintBatch(owner(), ids, amounts, '');
    }

    function setMutationContractAddress(address mutationContractAddress) external onlyOwner {
        mutationContract = mutationContractAddress;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // ------------- View -------------

    function uri(uint256 id) public view override returns (string memory) {
        require(validIds[id], 'INVALID_ID');
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString(), '.json')) : baseURI;
    }
}
