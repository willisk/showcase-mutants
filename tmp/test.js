const { expect } = require('chai');
const { BigNumber } = require('ethers');

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
    NFT = await ethers.getContractFactory('NFTXXX');
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
      await expect(contract.connect(user1).setSaleState(true)).to.be.revertedWith('Ownable: caller is not the owner');
      await expect(contract.connect(user1).setSaleState(false)).to.be.revertedWith('Ownable: caller is not the owner');
      await expect(contract.connect(user1).withdraw()).to.be.revertedWith('Ownable: caller is not the owner');

      await expect(contract.connect(user1).setBaseURI('')).to.be.revertedWith('Ownable: caller is not the owner');
      await expect(contract.connect(user1).giveAway(user2.address, 1)).to.be.revertedWith(
        'Ownable: caller is not the owner'
      );

      await contract.setSaleState(true);
      await contract.setSaleState(false);
      await contract.withdraw();

      await contract.setBaseURI('');
      await contract.giveAway(user1.address, 1);
    });
  });

  describe('Minting', function () {
    it('Correct sale logic and minting ability', async function () {
      // sale disabled
      await expect(contract.mint(1)).to.be.revertedWith('Sale is not active');
      await expect(contract.connect(user1).mint(1)).to.be.revertedWith('Sale is not active');

      // start sale
      await contract.setSaleState(true);
      expect(await contract.publicSaleActive()).to.equal(true);

      await contract.mint(1, { value: PRICE });
      await contract.giveAway(user1.address, 2);
      await contract.connect(user2).mint(1, { value: PRICE.mul(BigNumber.from('1')) });

      // expect(await contract.ownerOf(0)).to.equal(owner.address);
      // expect(await contract.ownerOf(1)).to.equal(user1.address);
      // expect(await contract.ownerOf(2)).to.equal(user1.address);
      // expect(await contract.ownerOf(3)).to.equal(user2.address);
      // expect(await contract.ownerOf(4)).to.equal(user2.address);
      // expect(await contract.ownerOf(5)).to.equal(user2.address);

      // // stop sale
      // await contract.setSaleState(false);
      // expect(await contract.publicSaleActive()).to.equal(false);

      // await expect(contract.mint(1)).to.be.revertedWith('Sale is not active');

      // // start sale
      // await contract.setSaleState(true);
      // expect(await contract.publicSaleActive()).to.equal(true);

      // await contract.mint(1, { value: PRICE.mul(BigNumber.from('1')) });
    });

    // it('Should have correct cost for minting', async function () {
    //   await contract.setSaleState(true);

    //   for (const amount of [0, 2, PURCHASE_LIMIT]) {
    //     const user1Bal = await provider.getBalance(user1.address);
    //     const txValue = PRICE.mul(BigNumber.from(amount));
    //     const tx = await contract.connect(user1).mint(amount, { value: txValue });
    //     const receipt = await tx.wait();
    //     const txGasValue = receipt.cumulativeGasUsed.mul(receipt.effectiveGasPrice);
    //     const effectivePaidValue = user1Bal.sub(await provider.getBalance(user1.address)).sub(txGasValue);

    //     expect(effectivePaidValue).to.equal(txValue);
    //   }

    //   await expect(contract.mint(PURCHASE_LIMIT + 1)).to.be.revertedWith('Exceeds purchase limit');
    // });

    // // it('Should implement correct whitelist logic', async () => {
    // //   await contract.whitelist([user1.address, user2.address]);
    // //   await contract.connect(user1).whitelistMint({ value: PRICE });
    // //   await expect(contract.connect(user1).whitelistMint({ value: PRICE })).to.be.revertedWith(
    // //     'Caller not whitelisted'
    // //   );
    // // });

    // it('Correct total mintable supply and refund logic implemented', async function () {
    //   this.timeout(0);

    //   await contract.setSaleState(true);

    //   let reserveSupply = await contract.reserveSupply();

    //   // mint all
    //   for (let i = 0; i < MAX_SUPPLY - reserveSupply - 1; i++) await contract.mint(1, { value: PRICE });

    //   // test refund logic; minting 3 with only 1 left
    //   const amount = 3;
    //   const user1Bal = await provider.getBalance(user1.address);
    //   const txValue = PRICE.mul(BigNumber.from(amount));
    //   const tx = await contract.connect(user1).mint(amount, { value: txValue });
    //   const receipt = await tx.wait();
    //   const txGasValue = receipt.cumulativeGasUsed.mul(receipt.effectiveGasPrice);
    //   const effectivePaidValue = user1Bal.sub(await provider.getBalance(user1.address)).sub(txGasValue);
    //   expect(effectivePaidValue).to.equal(PRICE);

    //   // none should be left
    //   await expect(contract.mint(1, { value: PRICE })).to.be.revertedWith('No supply left');

    //   await tx;
    //   expect(MAX_SUPPLY.sub(await contract.totalSupply())).to.equal(reserveSupply);
    // });

    // it('Correct reserve supply handling', async function () {
    //   let reserveSupply = await contract.reserveSupply();

    //   let amount = '5';
    //   await contract.giveAway(user1.address, amount);

    //   expect(await contract.reserveSupply()).to.equal(reserveSupply.sub(BigNumber.from(amount)));

    //   // this shouldn't affect logic
    //   await contract.setSaleState(true);
    //   await contract.mint(PURCHASE_LIMIT, { value: PRICE.mul(PURCHASE_LIMIT) });

    //   await contract.giveAway(user1.address, reserveSupply - amount);

    //   expect(await contract.reserveSupply()).to.equal(BigNumber.from('0'));
    //   await expect(contract.giveAway(user1.address, 1)).to.be.revertedWith('Exceeds reserved supply');
    // });

    // it('Correct maximum total supply', async function () {
    //   await contract.setSaleState(true);

    //   let reserveSupply = await contract.reserveSupply();

    //   for (let i = 0; i < MAX_SUPPLY - reserveSupply; i++) await contract.mint(1, { value: PRICE });

    //   await contract.giveAway(user1.address, reserveSupply);

    //   expect(await contract.totalSupply()).to.equal(MAX_SUPPLY);
    // });
  });
});
