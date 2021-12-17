const { expect } = require('chai');
const { BigNumber } = require('ethers');

const BN = BigNumber.from;

provider = ethers.provider;

describe('NFT contract', function () {
  let NFT;
  let contract;
  let owner;
  let user1;
  let user2;
  let signers;

  let PRICE;
  let MAX_SUPPLY;
  let PURCHASE_LIMIT;

  beforeEach(async function () {
    NFT = await ethers.getContractFactory('NFT');
    [owner, user1, user2, ...signers] = await ethers.getSigners();

    contract = await NFT.deploy();

    PRICE = await contract.PRICE();
    MAX_SUPPLY = await contract.MAX_SUPPLY();
    PURCHASE_LIMIT = await contract.PURCHASE_LIMIT();

    // await contract.init(); // XXX: mints first to owner, initializes owner array
    await contract.setSignerAddress(owner.address);
    // console.log('signer address', owner.address);
  });

  describe('Minting', function () {
    it('Correct sale logic and minting ability', async function () {
      // await expect(contract.mint(1)).to.be.revertedWith('Sale is not active');
      // await expect(contract.connect(user1).mint(1)).to.be.revertedWith('Sale is not active');

      // start sale
      await contract.setSalePhase(2);
      expect(await contract.phase()).to.equal(2);

      await contract.mint(1, { value: PRICE.mul(BN('1')) });
      await contract.transferFrom(owner.address, user1.address, 0);
    });

    it('Correct whitelist guard', async function () {
      await contract.setSalePhase(0);
      expect(await contract.phase()).to.equal(0);

      const signedMsgPhase0 = await owner.signMessage(
        ethers.utils.arrayify(
          ethers.utils.keccak256(
            ethers.utils.defaultAbiCoder.encode(['address', 'uint8', 'address'], [contract.address, 0, user1.address])
          )
        )
      );

      await expect(contract.diamondMint(signedMsgPhase0)).to.be.revertedWith('NOT_WHITELISTED');
      await contract.connect(user1).diamondMint(signedMsgPhase0);
      await expect(contract.connect(user1).diamondMint(signedMsgPhase0)).to.be.revertedWith('WHITELIST_USED');

      const signedMsgPhase1 = await owner.signMessage(
        ethers.utils.arrayify(
          ethers.utils.keccak256(
            ethers.utils.defaultAbiCoder.encode(['address', 'uint8', 'address'], [contract.address, 1, user1.address])
          )
        )
      );

      await contract.setSalePhase(1);
      expect(await contract.phase()).to.equal(1);

      // incorrect phase in signature
      await expect(
        contract.connect(user1).whitelistMint(2, signedMsgPhase0, { value: PRICE.mul(BN('2')) })
      ).to.be.revertedWith('NOT_WHITELISTED');
      // correct phase, incorrect user address
      await expect(contract.whitelistMint(2, signedMsgPhase1, { value: PRICE.mul(BN('2')) })).to.be.revertedWith(
        'NOT_WHITELISTED'
      );
      await contract.connect(user1).whitelistMint(2, signedMsgPhase1, { value: PRICE.mul(BN('2')) });
      await expect(
        contract.connect(user1).whitelistMint(1, signedMsgPhase1, { value: PRICE.mul(BN('1')) })
      ).to.be.revertedWith('WHITELIST_USED');
    });
  });
});
