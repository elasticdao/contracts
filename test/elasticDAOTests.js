const { expect } = require('chai');
const { ethers } = require('ethers');
const { deployments } = require('hardhat');
const hre = require('hardhat').ethers;
const { ethBalance, SDK, signers, summoners, summonedDAO } = require('./helpers');

describe('ElasticDAO: Core', () => {
  let dao;

  describe('before summoning', () => {
    beforeEach(async () => {
      const sdk = await SDK();
      const { summoner1 } = await signers();
      const args = [
        sdk.env.elasticDAO.ecosystemModelAddress,
        summoner1.address,
        await summoners(),
        'ElasticDAO',
        3,
      ];

      const ElasticDAO = await hre.getContractFactory('ElasticDAO');
      const elasticDAO = await ElasticDAO.deploy(...args);

      dao = await sdk.models.DAO.deserialize(elasticDAO.address);
    });

    it('Should allow a token to be initialized', async () => {
      await dao.elasticDAO.contract.initializeToken(
        'Elastic Governance Token',
        'EGT',
        dao.toEthersBigNumber(0.1, 18),
        dao.toEthersBigNumber(0.02, 18),
        dao.toEthersBigNumber(100, 18),
        ethers.constants.WeiPerEther,
      );

      await dao.ecosystem.refresh();

      expect(dao.ecosystem.governanceTokenAddress).to.not.equal(ethers.constants.AddressZero);
    });

    it('Should not allow a token to be initialized if not the deployer', async () => {
      const { summoner1 } = await signers();
      dao.sdk.changeSigner(summoner1);

      await expect(
        dao.elasticDAO.contract.initializeToken(
          'Elastic Governance Token',
          'EGT',
          dao.toEthersBigNumber(0.1, 18),
          dao.toEthersBigNumber(0.02, 18),
          dao.toEthersBigNumber(100, 18),
          ethers.constants.WeiPerEther,
        ),
      ).to.be.revertedWith('ElasticDAO: Only deployer');
    });

    it('Should not allow the DAO to be summoned before it has been seeded', async () => {
      await dao.elasticDAO.contract.initializeToken(
        'Elastic Governance Token',
        'EGT',
        dao.toEthersBigNumber(0.1, 18),
        dao.toEthersBigNumber(0.02, 18),
        dao.toEthersBigNumber(100, 18),
        ethers.constants.WeiPerEther,
      );

      const { summoner1 } = await signers();
      dao.sdk.changeSigner(summoner1);
      const token = await dao.token();

      await expect(
        dao.elasticDAO.contract.summon(dao.toEthersBigNumber(token.maxLambdaPurchase, 18)),
      ).to.be.revertedWith('ElasticDAO: Please seed DAO with ETH to set ETH:EGT ratio');
    });

    it('Should allow summoners to seed', async () => {
      await dao.elasticDAO.contract.initializeToken(
        'Elastic Governance Token',
        'EGT',
        dao.toEthersBigNumber(0.1, 18),
        dao.toEthersBigNumber(0.02, 18),
        dao.toEthersBigNumber(100, 18),
        ethers.constants.WeiPerEther, // lambda
      );

      const { summoner1 } = await signers();
      dao.sdk.changeSigner(summoner1);
      dao = await dao.refresh();
      await dao.elasticDAO.seedSummoning({ value: 1 });
      const balance = await ethBalance(dao.uuid);
      expect(balance.toNumber()).to.equal(1);
      /// signers token balance is correct

      const summoner1Balance = await dao.elasticGovernanceToken.balanceOf(summoner1.address);
      const summoner1Shares = await dao.elasticGovernanceToken.balanceOfInShares(summoner1.address);
      expect(summoner1Balance.toNumber()).to.equal(1000);
      expect(summoner1Shares.toNumber()).to.equal(10);

      /// get balance after a block
      await hre.provider.send('evm_mine');
      const newBalance = await dao.elasticGovernanceToken.balanceOf(summoner1.address);
      expect(newBalance.toNumber()).to.equal(1000);
    });

    it('Should not allow summoners to seed before token has been initialized', async () => {
      const { summoner1 } = await signers();
      dao.sdk.changeSigner(summoner1);

      await expect(
        dao.elasticDAO.contract.seedSummoning({ value: ethers.constants.WeiPerEther }),
      ).to.be.revertedWith('ElasticDAO: Please call initializeToken first');
    });

    it('Should not allow non summoners to seed', async () => {
      await dao.elasticDAO.contract.initializeToken(
        'Elastic Governance Token',
        'EGT',
        dao.toEthersBigNumber(0.1, 18),
        dao.toEthersBigNumber(0.02, 18),
        dao.toEthersBigNumber(100, 18),
        ethers.constants.WeiPerEther, // lambda
      );

      await expect(
        dao.elasticDAO.contract.seedSummoning({ value: ethers.constants.WeiPerEther }),
      ).to.be.revertedWith('ElasticDAO: Only summoners');
    });

    it('Should not allow the DAO to be summoned by a non-summoner', async () => {
      await dao.elasticDAO.contract.initializeToken(
        'Elastic Governance Token',
        'EGT',
        dao.toEthersBigNumber(0.1, 18),
        dao.toEthersBigNumber(0.02, 18),
        dao.toEthersBigNumber(100, 18),
        ethers.constants.WeiPerEther,
      );

      const { agent, summoner1 } = await signers();
      dao.sdk.changeSigner(summoner1);

      await dao.elasticDAO.seedSummoning({ value: 1 });

      dao.sdk.changeSigner(agent);

      await expect(dao.elasticDAO.summon(1)).to.be.revertedWith('ElasticDAO: Only summoners');
    });

    it('Should allow the DAO to be summoned after it has been seeded', async () => {
      await dao.elasticDAO.contract.initializeToken(
        'Elastic Governance Token',
        'EGT',
        dao.toEthersBigNumber(0.1, 18),
        dao.toEthersBigNumber(0.02, 18),
        dao.toEthersBigNumber(100, 18),
        ethers.constants.WeiPerEther,
      );

      const { summoner1, summoner2, summoner3 } = await signers();
      dao.sdk.changeSigner(summoner1);

      await dao.elasticDAO.seedSummoning({ value: 1 });
      await dao.elasticDAO.summon(1);

      expect(dao.summoned).to.equal(true);

      const summoner1balance = await dao.elasticGovernanceToken.balanceOf(summoner1.address);
      const summoner2balance = await dao.elasticGovernanceToken.balanceOf(summoner2.address);
      const summoner3balance = await dao.elasticGovernanceToken.balanceOf(summoner3.address);

      expect(summoner1balance.toNumber()).to.equal(1100);
      expect(summoner2balance.toNumber()).to.equal(100);
      expect(summoner3balance.toNumber()).to.equal(100);
    });

    it('Should getDAO', async () => {
      const getDAO = await dao.elasticDAO.contract.getDAO();

      expect(getDAO.uuid.toLowerCase()).to.equal(dao.id);
    });

    it('Should getEcosystem', async () => {
      const getEcosystem = await dao.elasticDAO.contract.getEcosystem();

      expect(getEcosystem.daoAddress.toLowerCase()).to.equal(dao.id);
    });

    it('Should check to see if a instance record exists by daoAddress', async () => {
      const { agent } = await signers();
      const DAOModel = await deployments.get('DAO_Implementation');
      const DAOModelStorage = new ethers.Contract(DAOModel.address, DAOModel.abi, agent);
      const ecosystem = await dao.elasticDAO.contract.getEcosystem();
      const recordDoesntExist = await DAOModelStorage.exists(
        ethers.constants.AddressZero,
        ecosystem,
      );
      const recordExists = await DAOModelStorage.exists(dao.uuid, ecosystem);

      expect(recordDoesntExist).to.equal(false);
      expect(recordExists).to.equal(true);
    });
  });

  describe('after summoning', () => {
    beforeEach(async () => {
      dao = await summonedDAO();
    });

    it('Should not allow a token to be initialized after summoning', async () => {
      await expect(
        dao.elasticDAO.contract.initializeToken(
          'Elastic Governance Token',
          'EGT',
          dao.toEthersBigNumber(0.1, 18),
          dao.toEthersBigNumber(0.02, 18),
          dao.toEthersBigNumber(100, 18),
          ethers.constants.WeiPerEther,
        ),
      ).to.be.revertedWith('ElasticDAO: DAO must not be summoned');
    });

    it('Should not allow the caller to setController if not controller', async () => {
      const { summoner1 } = await signers();
      dao.sdk.changeSigner(summoner1);

      await expect(dao.elasticDAO.contract.setController(summoner1.address)).to.be.revertedWith(
        'ElasticDAO: Only controller',
      );
    });

    it('Should allow the controller to setController', async () => {
      const { summoner1, agent } = await signers();
      dao.sdk.changeSigner(agent);

      await dao.elasticDAO.contract.setController(summoner1.address);

      const controller = await dao.elasticDAO.getController();
      expect(controller).to.equal(summoner1.address);
    });

    it('Should allow the controller to setMaxVotingLambda', async () => {
      const { agent } = await signers();
      dao.sdk.changeSigner(agent);

      await dao.elasticDAO.contract.setMaxVotingLambda(dao.toEthersBigNumber(5, 18));

      const maxVotingLambda = await dao.elasticDAO.getMaxVotingLambda();
      expect(maxVotingLambda).to.equal(dao.toEthersBigNumber(5, 18));
    });

    it('Should not allow the caller to setMaxVotingLambda if not controller', async () => {
      const { summoner1 } = await signers();
      dao.sdk.changeSigner(summoner1);

      await expect(
        dao.elasticDAO.contract.setMaxVotingLambda(dao.toEthersBigNumber(5, 18)),
      ).to.be.revertedWith('ElasticDAO: Only controller');
    });

    it('Should allow to exit with 1 share and corresponding eth', async () => {
      const { summoner1 } = await signers();

      const postSummonBalanceOf = await dao.elasticGovernanceToken.balanceOf(summoner1.address);

      expect(postSummonBalanceOf.toNumber()).to.equal(1010);

      await dao.elasticDAO.exit(1);

      const atExitBalanceRecord = await dao.elasticGovernanceToken.balanceOf(summoner1.address);
      expect(atExitBalanceRecord.toNumber()).to.equal(910);
    });
  });
});
