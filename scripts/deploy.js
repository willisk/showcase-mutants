const hre = require('hardhat');
const { ethers } = require('hardhat');

const erc20Interface = ['function transfer(address to, uint256 amount)'];
// const linkToken = new ethers.Contract('0x326C977E6efc84E512bB9C30f76E30c160eD06FB', erc20Interface); // Mumbai
const linkToken = new ethers.Contract('0x01BE23585060835E02B77ef475b0Cc51aA1e0709', erc20Interface); // Rinkeby

async function main() {
  [owner] = await ethers.getSigners();

  // console.log(await owner.getTransactionCount());

  const NFT = await ethers.getContractFactory('NFT');
  const MUTANTS = await ethers.getContractFactory('Mutants');
  const SERUM = await ethers.getContractFactory('Serum');

  const nft = await NFT.deploy();
  const mutants = await MUTANTS.deploy();
  const serum = await SERUM.deploy();

  await mutants.setSerumAddress(serum.address);
  await mutants.setNFTAddress(nft.address);
  await serum.setNFTAddress(nft.address);
  await serum.setMutantsAddress(mutants.address);

  // const nft = await NFT.attach('0x2af1bD945B025F901b9eD0Ec40400804b39d1320');
  // const mutants = await MUTANTS.attach('0x8409B1A5CC281c21d6232b46555C5C587698A9e7');
  // const serum = await SERUM.attach('0x1cFb131661e2e1e09047319fA9408fF1Cae0F985');

  console.log('NFTAddress:', `"${nft.address}",`);
  console.log('MutantsAddress:', `"${mutants.address}",`);
  console.log('SerumAddress:', `"${serum.address}",`);

  await linkToken.connect(owner).transfer(serum.address, ethers.utils.parseEther('1'));
  await linkToken.connect(owner).transfer(mutants.address, ethers.utils.parseEther('1'));

  console.log('transferred Link');

  console.log('XXX', 'make sure correct link hash set');
  console.log('XXX', 'make sure enough link is in the contract');
  console.log('XXX', 'add in .json ending to tokenURI (nft, mutants, serum)');
  console.log('XXX', 'remove -> 69 serum');

  // contract.setBaseURI('ipfs://YYY');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
