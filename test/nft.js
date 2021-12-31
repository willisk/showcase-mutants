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
  let WHITELIST_PRICE;
  let MAX_SUPPLY;
  let PURCHASE_LIMIT;

  beforeEach(async function () {
    NFT = await ethers.getContractFactory('NFT');
    [owner, user1, user2, ...signers] = await ethers.getSigners();

    contract = await NFT.deploy();

    PRICE = await contract.PRICE();
    WHITELIST_PRICE = await contract.WHITELIST_PRICE();
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
      await expect(contract.connect(user1).setPublicSaleActive(false)).to.be.revertedWith(
        'Ownable: caller is not the owner'
      );
      await expect(contract.connect(user1).withdraw()).to.be.revertedWith('Ownable: caller is not the owner');
      await expect(contract.connect(user1).setBaseURI('')).to.be.revertedWith('Ownable: caller is not the owner');
      // await expect(contract.connect(user1).giveAway(user2.address, 1)).to.be.revertedWith(
      //   'Ownable: caller is not the owner'
      // );

      await contract.withdraw();
      await contract.setBaseURI('');
      await contract.setPublicSaleActive(true);

      expect(await contract.publicSaleActive()).to.equal(true);
    });
  });

  describe('Public Mint', function () {
    beforeEach(async function () {
      await contract.setPublicSaleActive(true);
    });

    it('Correct sale logic and minting ability', async function () {
      await contract.mint(1, { value: PRICE });
      await contract.connect(user2).mint(2, { value: PRICE.mul(BigNumber.from('2')) });
      await expect(contract.mint(PURCHASE_LIMIT + 1)).to.be.revertedWith('EXCEEDS_LIMIT');

      expect(await contract.ownerOf(0)).to.equal(owner.address);
      expect(await contract.ownerOf(1)).to.equal(user2.address);
      expect(await contract.ownerOf(2)).to.equal(user2.address);

      // stop sale
      await contract.setPublicSaleActive(false);
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
      await contract.setPublicSaleActive(false);
    });

    it('Correct whitelist guard', async function () {
      // incorrect address (1st param)
      const invalidSig1 = await owner.signMessage(
        ethers.utils.arrayify(
          ethers.utils.keccak256(
            ethers.utils.defaultAbiCoder.encode(['address', 'uint256', 'address'], [owner.address, 69, user1.address])
          )
        )
      );

      // incorrect signer
      const invalidSig2 = await user1.signMessage(
        ethers.utils.arrayify(
          ethers.utils.keccak256(
            ethers.utils.defaultAbiCoder.encode(
              ['address', 'uint256', 'address'],
              [contract.address, 69, user1.address]
            )
          )
        )
      );

      const whitelistSig = await owner.signMessage(
        ethers.utils.arrayify(
          ethers.utils.keccak256(
            ethers.utils.defaultAbiCoder.encode(
              ['address', 'uint256', 'address'],
              [contract.address, 69, user1.address]
            )
          )
        )
      );

      const diamondlistSig = await owner.signMessage(
        ethers.utils.arrayify(
          ethers.utils.keccak256(
            ethers.utils.defaultAbiCoder.encode(
              ['address', 'uint256', 'address'],
              [contract.address, 1337, user1.address]
            )
          )
        )
      );

      // whitelist not active
      await expect(contract.whitelistMint(1, whitelistSig)).to.be.revertedWith('WHITELIST_NOT_ACTIVE');
      await expect(contract.diamondlistMint(diamondlistSig)).to.be.revertedWith('DIAMONDLIST_NOT_ACTIVE');

      await contract.setWhitelistActive(true);
      await contract.setDiamondlistActive(true);

      // signed for incorrect user
      await expect(contract.whitelistMint(1, whitelistSig)).to.be.revertedWith('NOT_WHITELISTED');
      await expect(contract.diamondlistMint(diamondlistSig)).to.be.revertedWith('NOT_WHITELISTED');

      // invalid signatures
      await expect(contract.connect(user1).whitelistMint(1, invalidSig1)).to.be.revertedWith('NOT_WHITELISTED');
      await expect(contract.connect(user1).diamondlistMint(invalidSig2)).to.be.revertedWith('NOT_WHITELISTED');

      await contract.connect(user1).whitelistMint(1, whitelistSig, { value: WHITELIST_PRICE });
      await contract.connect(user1).diamondlistMint(diamondlistSig);

      await expect(contract.connect(user1).whitelistMint(1, whitelistSig)).to.be.revertedWith('WHITELIST_USED');
      await expect(contract.connect(user1).diamondlistMint(diamondlistSig)).to.be.revertedWith('WHITELIST_USED');
    });
  });
});
