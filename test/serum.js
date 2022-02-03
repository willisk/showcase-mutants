const { expect } = require('chai');
const { BigNumber } = require('ethers');

const BN = BigNumber.from;

provider = ethers.provider;

const filterFirstEventArgs = (receipt, event) => receipt.events.filter((logs) => logs.event == event)[0].args;

describe('Serum contract', function () {
  let nft, mutants, serum;
  let user1, user2;
  let signers;

  let price;

  let MAX_SUPPLY_NFT, M2_CHANCE_PER_CENT, MAX_SUPPLY_M3;

  beforeEach(async function () {
    [owner, user1, user2, ...signers] = await ethers.getSigners();

    const NFT = await ethers.getContractFactory('NFT');
    const SERUM = await ethers.getContractFactory('Serum');
    // const MUTANTS = await ethers.getContractFactory('Mutants');

    nft = await NFT.deploy();
    serum = await SERUM.deploy();
    // mutants = await MUTANTS.deploy();

    await serum.setNFTAddress(nft.address);

    // MAX_SUPPLY = await nft.MAX_SUPPLY();
    MAX_SUPPLY_NFT = await serum.MAX_SUPPLY_NFT();
    MAX_SUPPLY_M3 = await serum.MAX_SUPPLY_M3();
    M2_CHANCE_PER_CENT = await serum.M2_CHANCE_PER_CENT();

    price = await nft.price();
  });

  describe('Deployment', function () {
    it('Should set the right owner', async function () {
      expect(await serum.owner()).to.equal(owner.address);
    });
  });

  describe('Claim', function () {
    beforeEach(async function () {
      await nft.setPublicSaleActive(true);
    });

    it('Able to set mega ids correctly', async function () {
      await expect(serum.connect(user1).setMegaSequence()).to.be.revertedWith('Ownable: caller is not the owner');
      await expect(serum.setMegaSequence()).to.be.revertedWith('RANDOM_SEED_NOT_SET');

      await serum.forceFulfillRandomness();
      await serum.setMegaSequence();

      serumTypes = await Promise.all([...Array(MAX_SUPPLY_NFT.toNumber())].map((_, i) => serum.tokenIdToSerumType(i)));
      serumTypes = serumTypes.map((serumType) => serumType.toNumber());

      serumsM1 = serumTypes.filter((serumType) => serumType === 0);
      serumsM2 = serumTypes.filter((serumType) => serumType === 1);
      serumsM3 = serumTypes.filter((serumType) => serumType === 2);

      expect(serumsM3.length).to.equal(MAX_SUPPLY_M3);
      expect(serumsM2.length / MAX_SUPPLY_NFT.toNumber()).to.be.closeTo(M2_CHANCE_PER_CENT.toNumber() / 100, 0.05);

      await expect(serum.setMegaSequence()).to.be.revertedWith('MEGA_IDS_SET');
    });

    it('Correct claim logic', async function () {
      await expect(serum.claimSerum(0)).to.be.revertedWith('ERC721: owner query for nonexistent token');

      await nft.mint(1, { value: price });

      await expect(serum.connect(user1).claimSerum(0)).to.be.revertedWith('NOT_CALLERS_NFT');
      await expect(serum.claimSerum(0)).to.be.revertedWith('MEGA_IDS_NOT_SET');

      await serum.forceFulfillRandomness();
      await serum.setMegaSequence();

      // check that a serum has been transfered
      tx = await serum.claimSerum(0);
      transferArgs = filterFirstEventArgs(await tx.wait(), 'TransferSingle');
      expect(transferArgs.id.toNumber()).to.be.below(3);
      expect(transferArgs.value.toNumber()).to.equal(1);

      await expect(serum.claimSerum(0)).to.be.revertedWith('SERUM_ALREADY_CLAIMED');
    });
  });
});
