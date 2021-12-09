const hre = require('hardhat');
const { ethers } = require('hardhat');

async function main() {
  const NFTXXX = await ethers.getContractFactory('NFTXXX');
  const contract = await NFTXXX.deploy('');

  await contract.deployed();

  console.log('Contract deployed to:', contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
