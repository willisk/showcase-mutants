const fs = require('fs');
const { ethers, network } = require('hardhat');
const { contractAddress, whitelist } = require('../whitelist');
const { signWhitelist, promiseAllObj, objectMap } = require('./utility');

async function main() {
  const [owner] = await ethers.getSigners();

  console.log('signer address:', owner.address);

  const signatures = await promiseAllObj(
    objectMap(
      whitelist,
      async (phase, accounts) =>
        await promiseAllObj(
          Object.assign(
            {},
            ...accounts.map((address) => ({
              [address.toLowerCase()]: signWhitelist(owner, contractAddress, address, phase),
            }))
          )
        )
    )
  );

  console.log('signatures:');
  console.log(signatures);
  console.log('writing to file');
  fs.writeFileSync(
    'whitelistSignatures.js',
    'export const whitelist = ' + JSON.stringify(signatures, null, 2),
    console.log
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
