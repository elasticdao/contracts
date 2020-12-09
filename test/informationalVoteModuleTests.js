const { deployments } = require('hardhat');
const { expect } = require('chai');
const ethers = require('ethers');
const hre = require('hardhat').ethers;
const SDK = require('@elastic-dao/sdk');
const env = require('./env');
const {
  FIFTY,
  FIFTY_PERCENT,
  ONE,
  ONE_HUNDRED,
  ONE_TENTH,
  SIXTY_PERCENT,
  TEN,
  THIRTY_FIVE_PERCENT,
  TWO_HUNDREDTHS,
} = require('./constants');

describe('ElasticDAO: Informational Vote Module', () => {
  let agent;
  let Ballot;
  let Ecosystem;
  let elasticDAO;
  let ElasticDAO;
  let informationalVoteManager;
  let InformationalVoteManager;
  let Settings;
  let summoner;
  let summoner1;
  let summoner2;
  let Token;
  let Vote;

  beforeEach(async () => {
    [agent, summoner, summoner1, summoner2] = await hre.getSigners();

    await deployments.fixture();

    // setup needed contracts
    Ballot = await deployments.get('InformationalVoteBallot');
    Settings = await deployments.get('InformationalVoteSettings');
    Vote = await deployments.get('InformationalVote');
    Ecosystem = await deployments.get('Ecosystem');

    const { deploy } = deployments;

    await deploy('ElasticDAO', {
      from: agent.address,
      args: [
        Ecosystem.address,
        [summoner.address, summoner1.address, summoner2.address],
        'ElasticDAO',
        3,
      ],
    });
    ElasticDAO = await deployments.get('ElasticDAO');
    Token = await deployments.get('Token');

    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, agent);
    await elasticDAO
      .initializeToken(
        'Elastic Governance Token',
        'EGT',
        ONE_TENTH,
        TWO_HUNDREDTHS,
        ONE_HUNDRED,
        ethers.constants.WeiPerEther,
      )
      .catch((error) => {
        console.log(error);
      });

    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);
  });

  it('Should deploy and initialize InformationalVoteManager', async () => {
    const { deploy } = deployments;
    await deploy('InformationalVoteManager', {
      from: agent.address,
      args: [Ballot.address, Settings.address, Vote.address],
    });
    InformationalVoteManager = await deployments.get('InformationalVoteManager');

    const ecosystem = await elasticDAO.getEcosystem();
    const informationalVoteManagerContract = new ethers.Contract(
      InformationalVoteManager.address,
      InformationalVoteManager.abi,
      summoner,
    );
    await informationalVoteManagerContract.initialize(ecosystem.governanceTokenAddress, false, [
      THIRTY_FIVE_PERCENT, // approval
      ethers.constants.WeiPerEther, // maxSharesPerTokenHolder
      1000, // minBlocksForPenalty
      500, // minDurationInBlocks
      TWO_HUNDREDTHS, // minPenaltyInShares
      TWO_HUNDREDTHS, // minRewardInShares
      ethers.constants.WeiPerEther, // minSharesToCreate
      ONE_TENTH, // penalty
      FIFTY_PERCENT, // quoroum
      ONE_TENTH, // reward
    ]);
    const settingsContract = new ethers.Contract(Settings.address, Settings.abi, summoner);
    const settings = await settingsContract.deserialize(InformationalVoteManager.address);

    await expect(settings.votingTokenAddress).to.be.equal(ecosystem.governanceTokenAddress);
    await expect(settings.hasPenalty).to.be.equal(false);

    await expect(settings.approval).to.be.equal(THIRTY_FIVE_PERCENT);
    await expect(settings.maxSharesPerTokenHolder).to.be.equal(ethers.constants.WeiPerEther);
    await expect(settings.minBlocksForPenalty).to.be.equal(1000);
    await expect(settings.minDurationInBlocks).to.be.equal(500);
    await expect(settings.minPenaltyInShares).to.be.equal(TWO_HUNDREDTHS);
    await expect(settings.minRewardInShares).to.be.equal(TWO_HUNDREDTHS);
    await expect(settings.minSharesToCreate).to.be.equal(ethers.constants.WeiPerEther);
    await expect(settings.penalty).to.be.equal(ONE_TENTH);
    await expect(settings.quorum).to.be.equal(FIFTY_PERCENT);
    await expect(settings.reward).to.be.equal(ONE_TENTH);
  });

  describe('createVote(string memory _proposal, uint256 _endBlock)', () => {
    beforeEach(async () => {
      const { deploy } = deployments;

      InformationalVoteManager = await deploy('InformationalVoteManager', {
        from: agent.address,
        args: [Ballot.address, Settings.address, Vote.address],
      });

      informationalVoteManager = new ethers.Contract(
        InformationalVoteManager.address,
        InformationalVoteManager.abi,
        summoner,
      );
    });

    it('Should not create a vote if VoteManager is not initialized', async () => {
      await expect(
        informationalVoteManager.createVote('This proposal should fail', 1),
      ).to.be.revertedWith('ElasticDAO: InformationalVote Manager not initialized');
    });

    it('Should not create a vote if not enough shares to create a vote', async () => {
      const ecosystem = await elasticDAO.getEcosystem();

      await informationalVoteManager.initialize(ecosystem.governanceTokenAddress, true, [
        THIRTY_FIVE_PERCENT, // approval
        ethers.constants.WeiPerEther, // maxSharesPerTokenHolder
        1000, // minBlocksForPenalty
        500, // minDurationInBlocks
        TWO_HUNDREDTHS, // minPenaltyInShares
        TWO_HUNDREDTHS, // minRewardInShares
        ethers.constants.WeiPerEther, // minSharesToCreate
        ONE_TENTH, // penalty
        FIFTY_PERCENT, // quoroum
        ONE_TENTH, // reward
      ]);

      await expect(
        informationalVoteManager.createVote('This proposal should fail', 1),
      ).to.be.revertedWith('ElasticDAO: Not enough shares to create vote');
    });

    it('Should not create a vote if the duration is too short', async () => {
      const ecosystem = await elasticDAO.getEcosystem();

      await informationalVoteManager.initialize(ecosystem.governanceTokenAddress, true, [
        THIRTY_FIVE_PERCENT, // approval
        ethers.constants.WeiPerEther, // maxSharesPerTokenHolder
        1000, // minBlocksForPenalty
        500, // minDurationInBlocks
        TWO_HUNDREDTHS, // minPenaltyInShares
        TWO_HUNDREDTHS, // minRewardInShares
        ethers.constants.WeiPerEther, // minSharesToCreate
        ONE_TENTH, // penalty
        FIFTY_PERCENT, // quoroum
        ONE_TENTH, // reward
      ]);

      const tokenStorage = new ethers.Contract(Token.address, Token.abi, summoner);
      const token = await tokenStorage.deserialize(ecosystem.governanceTokenAddress, ecosystem);

      await elasticDAO.seedSummoning({ value: ethers.constants.WeiPerEther });
      await elasticDAO.summon(token.maxLambdaPurchase);

      await expect(
        informationalVoteManager.createVote('This proposal should fail', 100),
      ).to.be.revertedWith('ElasticDAO: InformationalVote period too short');
    });

    it('Should create a vote', async () => {
      const ecosystem = await elasticDAO.getEcosystem();

      await informationalVoteManager.initialize(ecosystem.governanceTokenAddress, true, [
        THIRTY_FIVE_PERCENT, // approval
        ethers.constants.WeiPerEther, // maxSharesPerTokenHolder
        1000, // minBlocksForPenalty
        500, // minDurationInBlocks
        TWO_HUNDREDTHS, // minPenaltyInShares
        TWO_HUNDREDTHS, // minRewardInShares
        ethers.constants.WeiPerEther, // minSharesToCreate
        ONE_TENTH, // penalty
        FIFTY_PERCENT, // quoroum
        ONE_TENTH, // reward
      ]);

      const settingsContract = new ethers.Contract(Settings.address, Settings.abi, summoner);
      const settings = await settingsContract.deserialize(InformationalVoteManager.address);

      elasticDAO.initializeModule(informationalVoteManager.address, 'informationalVoteManager');

      const tokenStorage = new ethers.Contract(Token.address, Token.abi, summoner);
      const token = await tokenStorage.deserialize(ecosystem.governanceTokenAddress, ecosystem);

      await elasticDAO.seedSummoning({ value: ethers.constants.WeiPerEther });
      await elasticDAO.summon(token.maxLambdaPurchase);

      await informationalVoteManager.functions.createVote('First vote should be created', 1000);
      await informationalVoteManager.functions.createVote('Second vote should be created', 1000);

      const voteStorage = new ethers.Contract(Vote.address, Vote.abi, summoner);

      expect(await voteStorage.exists(0, settings)).to.equal(true);
      expect(await voteStorage.exists(1, settings)).to.equal(true);

      const voteRecord1 = await voteStorage.deserialize(0, settings);
      const voteRecord2 = await voteStorage.deserialize(1, settings);
      expect(voteRecord1.proposal).to.equal('First vote should be created');
      expect(voteRecord2.proposal).to.equal('Second vote should be created');
    });
  });

  describe.skip('Factory', () => {
    it('Should deploy the Manager of the voteModule using the Factory', async () => {
      [agent, summoner, summoner1, summoner2] = await hre.getSigners();

      const { provider } = hre;

      console.log('env is', env);
      const sdk = SDK({
        account: agent.address,
        contract: ({ abi, address }) => new ethers.Contract(address, abi, agent),
        env,
        provider,
        signer: agent,
      });

      const dao = await sdk.elasticDAOFactory.deployDAOAndToken(
        [summoner.address, summoner1.address, summoner2.address],
        'Elastic DAO',
        3,
        'Elastic Governance Token',
        'EGT',
        ONE_TENTH,
        TWO_HUNDREDTHS,
        ONE_HUNDRED,
        ONE,
      );

      console.log('STUFF');
      console.log(
        env.elasticDAO.modules.informationalVote.ballotModelAddress,
        dao.address,
        env.elasticDAO.modules.informationalVote.settingsModelAddress,
        env.elasticDAO.modules.informationalVote.voteModelAddress,
        dao.ecosystem.governanceTokenAddress,
      );

      console.log([
        FIFTY_PERCENT, // approval
        ONE, // maxSharesPerTokenHolder
        FIFTY, // minBlocksForPenalty
        TEN, // minDurationInBlocks
        ONE_TENTH, // minPenaltyInShares
        ONE_TENTH, // minRewardInShares
        FIFTY_PERCENT, // minSharesToCreate
        ONE_TENTH, // penalty
        SIXTY_PERCENT, // quoroum
        ONE_TENTH, // reward
      ]);

      const ivManager = await sdk.modules.informationalVote.informationalVoteFactory.deployManager(
        env.elasticDAO.modules.informationalVote.ballotModelAddress,
        dao.address,
        env.elasticDAO.modules.informationalVote.settingsModelAddress,
        env.elasticDAO.modules.informationalVote.voteModelAddress,
        dao.ecosystem.governanceTokenAddress,
        true,

        [
          FIFTY_PERCENT, // approval
          ONE, // maxSharesPerTokenHolder
          FIFTY, // minBlocksForPenalty
          TEN, // minDurationInBlocks
          ONE_TENTH, // minPenaltyInShares
          ONE_TENTH, // minRewardInShares
          FIFTY_PERCENT, // minSharesToCreate
          ONE_TENTH, // penalty
          SIXTY_PERCENT, // quoroum
          ONE_TENTH, // reward
        ],
      );

      console.log('ivMANAGER', ivManager);
      console.log('ivMANAGER.address', ivManager.address);

      expect(ivManager.address).to.not.equal(undefined);
    });
  });
});
