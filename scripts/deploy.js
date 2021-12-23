const hre = require('hardhat');
const { ethers } = require('hardhat');

async function main() {
  const NFT = await ethers.getContractFactory('NFT');
  const MUTANTS = await ethers.getContractFactory('Mutants');
  const SERUM = await ethers.getContractFactory('Serum');

  nft = await NFT.deploy();
  mutants = await MUTANTS.deploy();
  serum = await SERUM.deploy();

  await mutants.setSerumAddress(serum.address);
  await mutants.setNFTAddress(nft.address);
  await serum.setMutantsAddress(mutants.address);

  console.log('NFT contract deployed to', nft.address);
  console.log('Mutant contract deployed to', mutants.address);
  console.log('Serum contract deployed to', serum.address);

  // contract.setBaseURI('ipfs://YYY');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
