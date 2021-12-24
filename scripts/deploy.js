const hre = require('hardhat');
const { ethers } = require('hardhat');

async function main() {
  [owner] = await ethers.getSigners();

  // console.log(await owner.getTransactionCount());

  const NFT = await ethers.getContractFactory('NFT');
  const MUTANTS = await ethers.getContractFactory('Mutants');
  const SERUM = await ethers.getContractFactory('Serum');

  nft = await NFT.deploy();
  mutants = await MUTANTS.deploy();
  serum = await SERUM.deploy();

  (await mutants.setSerumAddress(serum.address)).wait();
  (await mutants.setNFTAddress(nft.address)).wait();
  (await serum.setMutantsAddress(mutants.address)).wait();

  console.log('NFTAddress:', `"${nft.address}",`);
  console.log('MutantAddress:', `"${mutants.address}",`);
  console.log('SerumAddress:', `"${serum.address}",`);

  // contract.setBaseURI('ipfs://YYY');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
