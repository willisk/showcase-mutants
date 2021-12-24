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
  });

  describe('Deployment', function () {
    it('Should set the right owner and pause sale', async function () {
      expect(await contract.owner()).to.equal(owner.address);
      expect(await contract.publicSaleActive()).to.equal(false);
    });
  });

  describe('Owner', function () {
    it('Correct function access rights', async function () {
      await expect(contract.connect(user1).setSaleState(0)).to.be.revertedWith('Ownable: caller is not the owner');
      await expect(contract.connect(user1).withdraw()).to.be.revertedWith('Ownable: caller is not the owner');
      await expect(contract.connect(user1).setBaseURI('')).to.be.revertedWith('Ownable: caller is not the owner');
      // await expect(contract.connect(user1).giveAway(user2.address, 1)).to.be.revertedWith(
      //   'Ownable: caller is not the owner'
      // );

      await contract.setSaleState(1);
      await contract.withdraw();
      await contract.setBaseURI('');
    });
  });

  describe('Public Mint', function () {
    beforeEach(async function () {
      await contract.setSaleState(2);
      expect(await contract.publicSaleActive()).to.equal(true);
    });

    it('Correct sale logic and minting ability', async function () {
      await contract.mint(1, { value: PRICE });
      await contract.connect(user2).mint(2, { value: PRICE.mul(BigNumber.from('2')) });
      await expect(contract.mint(PURCHASE_LIMIT + 1)).to.be.revertedWith('EXCEEDS_LIMIT');

      expect(await contract.ownerOf(0)).to.equal(owner.address);
      expect(await contract.ownerOf(1)).to.equal(user2.address);
      expect(await contract.ownerOf(2)).to.equal(user2.address);

      // stop sale
      await contract.setSaleState(0);
      expect(await contract.publicSaleActive()).to.equal(false);

      await expect(contract.mint(1)).to.be.revertedWith('PUBLIC_SALE_NOT_ACTIVE');
      await expect(contract.connect(user1).mint(1)).to.be.revertedWith('PUBLIC_SALE_NOT_ACTIVE');
    });

    // it('Correct total mintable supply and refund logic implemented', async function () {
    //   this.timeout(0);

    //   // mint all
    //   let tx;
    //   for (let i = 0; i < MAX_SUPPLY; i++) tx = await contract.mint(1, { value: PRICE });
    //   await tx.wait();

    //   await expect(contract.mint(1, { value: PRICE })).to.be.revertedWith('MAX_SUPPLY_REACHED');
    // });
  });

  describe('Whitelist', function () {
    beforeEach(async function () {
      await contract.setSignerAddress(owner.address);
      await contract.setSaleState(0);
    });

    it('Correct whitelist guard', async function () {
      const signedMsgState0 = await owner.signMessage(
        ethers.utils.arrayify(
          ethers.utils.keccak256(
            ethers.utils.defaultAbiCoder.encode(['address', 'uint8', 'address'], [contract.address, 0, user1.address])
          )
        )
      );

      // signed for incorrect address
      await expect(contract.diamondMint(signedMsgState0)).to.be.revertedWith('NOT_WHITELISTED');

      await contract.connect(user1).diamondMint(signedMsgState0);
      await expect(contract.connect(user1).diamondMint(signedMsgState0)).to.be.revertedWith('WHITELIST_USED');

      const signedMsgState1 = await owner.signMessage(
        ethers.utils.arrayify(
          ethers.utils.keccak256(
            ethers.utils.defaultAbiCoder.encode(['address', 'uint8', 'address'], [contract.address, 1, user1.address])
          )
        )
      );

      await contract.setSaleState(1);

      // using incorrect state0 signed message
      await expect(contract.connect(user1).whitelistMint(1, signedMsgState0, { value: PRICE })).to.be.revertedWith(
        'NOT_WHITELISTED'
      );
      // correct state, incorrect user address
      await expect(contract.whitelistMint(1, signedMsgState1, { value: PRICE })).to.be.revertedWith('NOT_WHITELISTED');

      await contract.connect(user1).whitelistMint(2, signedMsgState1, { value: PRICE.mul(BN('2')) });
      await expect(contract.connect(user1).whitelistMint(1, signedMsgState1, { value: PRICE })).to.be.revertedWith(
        'WHITELIST_USED'
      );
    });
  });
});
