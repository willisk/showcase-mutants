const { expect } = require('chai');
const { BigNumber } = require('ethers');

provider = ethers.provider;

describe('NFT contract', function () {
  let NFT;
  let contract;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  let PRICE;
  let MAX_SUPPLY;
  let PURCHASE_LIMIT;

  beforeEach(async function () {
    NFT = await ethers.getContractFactory('NFTXXX');
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    contract = await NFT.deploy();

    PRICE = await contract.PRICE();
    MAX_SUPPLY = await contract.MAX_SUPPLY();
    PURCHASE_LIMIT = await contract.PURCHASE_LIMIT();
  });

  describe('Deployment', function () {
    it('Should set the right owner and pause sale', async function () {
      expect(await contract.owner()).to.equal(owner.address);
      expect(await contract.isActive()).to.equal(false);
    });
  });

  describe('Owner', function () {
    it('Correct function access rights', async function () {
      await expect(contract.connect(addr1).setSaleState(true)).to.be.revertedWith('Ownable: caller is not the owner');
      await expect(contract.connect(addr1).setSaleState(false)).to.be.revertedWith('Ownable: caller is not the owner');
      await expect(contract.connect(addr1).withdraw()).to.be.revertedWith('Ownable: caller is not the owner');

      await expect(contract.connect(addr1).setBaseURI('')).to.be.revertedWith('Ownable: caller is not the owner');
      await expect(contract.connect(addr1).giveAway(addr2.address, 0)).to.be.revertedWith(
        'Ownable: caller is not the owner'
      );

      await contract.setSaleState(true);
      await contract.setSaleState(false);
      await contract.withdraw();

      await contract.setBaseURI('');
      await contract.giveAway(addr1.address, 0);
    });
  });

  describe('Minting', function () {
    it('Correct sale logic and minting ability', async function () {
      // sale disabled
      await expect(contract.mint(1)).to.be.revertedWith('Sale is not active');
      await expect(contract.connect(addr1).mint(1)).to.be.revertedWith('Sale is not active');

      // start sale
      await contract.setSaleState(true);
      expect(await contract.isActive()).to.equal(true);

      await contract.mint(1, { value: PRICE });
      await contract.connect(addr1).mint(3, { value: PRICE.mul(BigNumber.from('3')) });

      expect(await contract.ownerOf(2)).to.equal(addr1.address);

      // stop sale
      await contract.setSaleState(false);
      expect(await contract.isActive()).to.equal(false);

      await expect(contract.mint(1)).to.be.revertedWith('Sale is not active');

      // start sale
      await contract.setSaleState(true);
      expect(await contract.isActive()).to.equal(true);

      await contract.mint(1, { value: PRICE.mul(BigNumber.from('1')) });
    });

    it('Should cost 0.03 eth per mint and have a maximum mint of 10 per transaction', async function () {
      await contract.setSaleState(true);

      for (const amount of [0, 2, PURCHASE_LIMIT]) {
        const addr1Bal = await provider.getBalance(addr1.address);
        const txValue = PRICE.mul(BigNumber.from(amount));
        const tx = await contract.connect(addr1).mint(amount, { value: txValue });
        const receipt = await tx.wait();
        const txGasValue = receipt.cumulativeGasUsed.mul(receipt.effectiveGasPrice);
        const effectivePaidValue = addr1Bal.sub(await provider.getBalance(addr1.address)).sub(txGasValue);

        expect(effectivePaidValue).to.equal(txValue);
      }

      await expect(contract.mint(PURCHASE_LIMIT + 1)).to.be.revertedWith('Exceeds purchase limit');
    });

    it('Correct total mintable supply and refund logic implemented', async function () {
      this.timeout(0);

      await contract.setSaleState(true);

      let reserveSupply = await contract.reserveSupply();

      // mint all
      for (let i = 0; i < MAX_SUPPLY - reserveSupply - 1; i++) await contract.mint(1, { value: PRICE });

      // test refund logic; minting 3 with only 1 left
      const amount = 3;
      const addr1Bal = await provider.getBalance(addr1.address);
      const txValue = PRICE.mul(BigNumber.from(amount));
      const tx = await contract.connect(addr1).mint(amount, { value: txValue });
      const receipt = await tx.wait();
      const txGasValue = receipt.cumulativeGasUsed.mul(receipt.effectiveGasPrice);
      const effectivePaidValue = addr1Bal.sub(await provider.getBalance(addr1.address)).sub(txGasValue);
      expect(effectivePaidValue).to.equal(PRICE);

      // none should be left
      await expect(contract.mint(1, { value: PRICE })).to.be.revertedWith('No supply left');

      await tx;
      expect(MAX_SUPPLY.sub(await contract.totalSupply())).to.equal(reserveSupply);
    });

    it('Correct reserve supply handling', async function () {
      let reserveSupply = await contract.reserveSupply();

      let amount = '5';
      await contract.giveAway(addr1.address, amount);

      expect(await contract.reserveSupply()).to.equal(reserveSupply.sub(BigNumber.from(amount)));

      // this shouldn't affect logic
      await contract.setSaleState(true);
      await contract.mint(PURCHASE_LIMIT, { value: PRICE.mul(PURCHASE_LIMIT) });
      //

      await contract.giveAway(addr1.address, reserveSupply - amount);

      expect(await contract.reserveSupply()).to.equal(BigNumber.from('0'));
      await expect(contract.giveAway(addr1.address, 1)).to.be.revertedWith('Exceeds reserved supply');
    });

    it('Correct maximum total supply', async function () {
      await contract.setSaleState(true);

      let reserveSupply = await contract.reserveSupply();

      for (let i = 0; i < MAX_SUPPLY - reserveSupply; i++) await contract.mint(1, { value: PRICE });

      await contract.giveAway(addr1.address, reserveSupply);

      expect(await contract.totalSupply()).to.equal(MAX_SUPPLY);
    });
  });
});
