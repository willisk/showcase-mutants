const { expect } = require('chai');
const { BigNumber } = require('ethers');

const BN = BigNumber.from;

provider = ethers.provider;

const filterFirstEventArgs = (receipt, event) => receipt.events.filter((logs) => logs.event == event)[0].args;

describe('Mutants contract', function () {
  let nft, mutants, serum;
  let user1, user2;
  let signers;

  let PRICE;
  let PURCHASE_LIMIT;

  let MAX_SUPPLY_PUBLIC;
  let MAX_SUPPLY_M;
  let MAX_SUPPLY_M3;

  let OFFSET_M1, OFFSET_M2, OFFSET_M3;
  // let MAX_TOTAL_SUPPLY;

  const secretPass = ethers.utils.formatBytes32String('pass1234');
  const secretHash = ethers.utils.keccak256(secretPass);

  beforeEach(async function () {
    [owner, user1, user2, ...signers] = await ethers.getSigners();

    const NFT = await ethers.getContractFactory('NFT');
    const MUTANTS = await ethers.getContractFactory('Mutants');
    const SERUM = await ethers.getContractFactory('Serum');

    nft = await NFT.deploy();
    mutants = await MUTANTS.deploy(secretHash);
    serum = await SERUM.deploy();

    await mutants.setSerumAddress(serum.address);
    await mutants.setNFTAddress(nft.address);
    await serum.setMutantsAddress(mutants.address);

    PRICE = await mutants.PRICE();
    PURCHASE_LIMIT = await mutants.PURCHASE_LIMIT();

    MAX_SUPPLY_PUBLIC = await mutants.MAX_SUPPLY_PUBLIC();
    MAX_SUPPLY_M = await mutants.MAX_SUPPLY_M();
    MAX_SUPPLY_M3 = await mutants.MAX_SUPPLY_M3();

    OFFSET_M1 = MAX_SUPPLY_PUBLIC;
    OFFSET_M2 = OFFSET_M1.add(MAX_SUPPLY_M);
    OFFSET_M3 = OFFSET_M2.add(MAX_SUPPLY_M);
    // MAX_TOTAL_SUPPLY = await mutants.MAX_TOTAL_SUPPLY();
  });

  describe('Deployment', function () {
    it('Should set the right owner and pause sale', async function () {
      expect(await mutants.owner()).to.equal(owner.address);
      expect(await mutants.publicSaleActive()).to.equal(false);
    });
  });

  describe('Owner', function () {
    it('Correct function access rights', async function () {
      await expect(mutants.connect(user1).setPublicSaleActive(0)).to.be.revertedWith(
        'Ownable: caller is not the owner'
      );
      await expect(mutants.connect(user1).withdraw()).to.be.revertedWith('Ownable: caller is not the owner');
      await expect(mutants.connect(user1).setBaseURI('')).to.be.revertedWith('Ownable: caller is not the owner');
      // await expect(mutants.connect(user1).giveAway(user2.address, 1)).to.be.revertedWith(
      //   'Ownable: caller is not the owner'
      // );

      await mutants.setPublicSaleActive(true);
      await mutants.withdraw();
      // await mutants.setBaseURI('');
    });
  });

  describe('Public Mint', function () {
    beforeEach(async function () {
      await mutants.setPublicSaleActive(true);
      expect(await mutants.publicSaleActive()).to.equal(true);
    });

    it('Correct sale logic and minting ability', async function () {
      await mutants.mint(1, { value: PRICE });
      await mutants.connect(user2).mint(2, { value: PRICE.mul(BigNumber.from('2')) });
      await expect(mutants.mint(PURCHASE_LIMIT + 1)).to.be.revertedWith('EXCEEDS_LIMIT');

      expect(await mutants.ownerOf(0)).to.equal(owner.address);
      expect(await mutants.ownerOf(1)).to.equal(user2.address);
      expect(await mutants.ownerOf(2)).to.equal(user2.address);

      // stop sale
      await mutants.setPublicSaleActive(false);
      expect(await mutants.publicSaleActive()).to.equal(false);

      await expect(mutants.mint(1)).to.be.revertedWith('PUBLIC_SALE_NOT_ACTIVE');
      await expect(mutants.connect(user1).mint(1)).to.be.revertedWith('PUBLIC_SALE_NOT_ACTIVE');
    });

    // it('Correct total mintable supply', async function () {
    //   // mint all
    //   let tx;
    //   for (let i = 0; i < MAX_SUPPLY_PUBLIC.toNumber(); i++) tx = await mutants.mint(1, { value: PRICE });
    //   await tx.wait();

    //   await expect(mutants.mint(1, { value: PRICE })).to.be.revertedWith('MAX_SUPPLY_REACHED');
    // });
  });

  describe('Mutation', function () {
    beforeEach(async function () {
      await nft.giveAway(owner.address, 10);
      await nft.giveAway(user1.address, 3);

      await serum.mintBatch([0, 1, 2], [MAX_SUPPLY_M + 1, MAX_SUPPLY_M + 1, MAX_SUPPLY_M3 + 1]);

      // console.log(await serum.balanceOf(owner.address, 0));
      // console.log(await serum.balanceOf(owner.address, 1));
      // console.log(await serum.balanceOf(owner.address, 2));

      await mutants.setMutationsActive(true);
    });

    it('Can mutate correctly', async function () {
      await expect(mutants.mutate(11, 0)).to.be.revertedWith('NOT_CALLERS_TOKEN');

      // not mutated yet
      mutantId = OFFSET_M1.add(1); // mutate id 1 with serum type 0
      await expect(mutants.ownerOf(mutantId)).to.be.revertedWith('ERC721: owner query for nonexistent token');

      // successful mutation
      tx = await mutants.mutate(1, 0);
      tokenId = filterFirstEventArgs(await tx.wait(), 'Transfer').tokenId;

      expect(tokenId).to.equal(mutantId);
      expect(await mutants.ownerOf(mutantId)).to.equal(owner.address);

      // already mutated
      await expect(mutants.mutate(1, 0)).to.be.revertedWith('ERC721: token already minted');

      // user1 doesn't have serum
      await expect(mutants.connect(user1).mutate(11, 1)).to.be.revertedWith('ERC1155: burn amount exceeds balance');
      await expect(mutants.connect(user1).mutate(11, 2)).to.be.revertedWith('ERC1155: burn amount exceeds balance');

      // transfer serum to user1
      await serum.safeTransferFrom(owner.address, user1.address, 1, 1, 0x0);
      await serum.safeTransferFrom(owner.address, user1.address, 2, 1, 0x0);

      balBefore1 = await serum.balanceOf(user1.address, 1);
      balBefore2 = await serum.balanceOf(user1.address, 1);

      // let user1 mutate id 11 with serumType 1 and id 12 with serumType 2
      mutantId1 = OFFSET_M2.add(11);
      mutantId2 = OFFSET_M3.add(0); // mega mutant ids are minted in succession
      tx1 = await mutants.connect(user1).mutate(11, 1);
      tx2 = await mutants.connect(user1).mutate(12, 2); // XXX: needs requestRandomMegaMutant to be disabled when testing
      tokenId1 = filterFirstEventArgs(await tx1.wait(), 'Transfer').tokenId;
      tokenId2 = filterFirstEventArgs(await tx2.wait(), 'Transfer').tokenId;
      expect(tokenId1).to.equal(mutantId1);
      expect(tokenId2).to.equal(mutantId2);
      expect(await mutants.ownerOf(mutantId1)).to.equal(user1.address);
      expect(await mutants.ownerOf(mutantId2)).to.equal(user1.address);

      // check that serum is burned
      balAfter1 = await serum.balanceOf(user1.address, 1);
      balAfter2 = await serum.balanceOf(user1.address, 2);
      expect(balBefore1.sub(balAfter1)).to.equal(1);
      expect(balBefore2.sub(balAfter2)).to.equal(1);

      await expect(mutants.connect(user1).mutate(11, 1)).to.be.revertedWith('ERC721: token already minted');
    });
  });

  describe('Reveal', function () {
    beforeEach(async function () {
      await nft.giveAway(owner.address, 10);
      await serum.mintBatch([0, 1, 2], [MAX_SUPPLY_M + 1, MAX_SUPPLY_M + 1, MAX_SUPPLY_M3 + 1]);
      await mutants.setMutationsActive(true);
      await mutants.setPublicSaleActive(true);
    });

    it('Reveal can only happen once by owner', async function () {
      await expect(mutants.connect(user1).forceFulfillRandomness()).to.be.revertedWith(
        'Ownable: caller is not the owner'
      );
      await mutants.forceFulfillRandomness();
      await expect(mutants.forceFulfillRandomness()).to.be.revertedWith('RANDOM_SEED_SET');

      mutantId = OFFSET_M3.add(0);
      await mutants.mutate(7, 2);

      await expect(mutants.connect(user1).forceFulfillRandomMegaMutant(mutantId)).to.be.revertedWith(
        'Ownable: caller is not the owner'
      );
      await mutants.forceFulfillRandomMegaMutant(mutantId);
      await expect(mutants.forceFulfillRandomMegaMutant(mutantId)).to.be.revertedWith('MEGA_ID_ALREADY_SET');
    });

    it('Public reveal logic is correct', async function () {
      await mutants.mint(1, { value: PRICE });
      expect(await mutants.tokenURI(0)).to.equal('unrevealedURI');
      await expect(mutants.setBaseURI('xxx')).to.be.revertedWith('NOT_REVEALED_YET');

      await expect(mutants.reveal('revealedURI/', secretPass)).to.be.revertedWith('RANDOM_SEED_NOT_SET');

      await mutants.forceFulfillRandomness();

      expect(await mutants.tokenURI(0)).to.equal('unrevealedURI');

      const invalidSecretPass = ethers.utils.formatBytes32String('abc');

      await expect(mutants.reveal('revealedURI/', invalidSecretPass)).to.be.revertedWith('SECRET_HASH_DOES_NOT_MATCH');
      await mutants.reveal('revealedURI/', secretPass);
      await expect(mutants.reveal('revealedURI/', secretPass)).to.be.revertedWith('ALREADY_REVEALED');

      expect(await mutants.tokenURI(0)).to.include('revealedURI/');
      expect(await mutants.tokenURI(0)).to.not.equal('revealedURI/0.json'); // hard to check for a random assignment
    });

    it('Mutants reveal correctly', async function () {
      mutantId = OFFSET_M1.add(0);
      await mutants.mutate(0, 0);
      expect(await mutants.tokenURI(mutantId)).to.equal(`baseURI/${mutantId}.json`);

      mutantId = OFFSET_M1.add(1);
      await mutants.mutate(1, 0);
      expect(await mutants.tokenURI(mutantId)).to.equal(`baseURI/${mutantId}.json`);

      mutantId = OFFSET_M2.add(2);
      await mutants.mutate(2, 1);
      expect(await mutants.tokenURI(mutantId)).to.equal(`baseURI/${mutantId}.json`);

      mutantId = OFFSET_M2.add(3);
      await mutants.mutate(3, 1);
      expect(await mutants.tokenURI(mutantId)).to.equal(`baseURI/${mutantId}.json`);
    });

    it('Mega Mutants reveal correctly', async function () {
      mutantId = OFFSET_M3;
      await mutants.mutate(3, 2);
      expect(await mutants.tokenURI(mutantId)).to.equal('unrevealedURI');

      await mutants.forceFulfillRandomMegaMutant(mutantId);
      expect(await mutants.tokenURI(mutantId)).to.include('baseURI/30'); // will point to a random id.json
    });
  });
});
