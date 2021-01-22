const { deployments } = require('hardhat');
const { expect } = require('chai');
const ethers = require('ethers');
const hre = require('hardhat').ethers;
const SDK = require('@elastic-dao/sdk');
const generateEnv = require('./env');
const {
  FIFTY_PERCENT,
  ONE_HUNDRED,
  ONE_TENTH,
  THIRTY_FIVE_PERCENT,
  TWO_HUNDREDTHS,
} = require('./constants');

describe('ElasticDAO: Informational Vote Module', () => {
  let agent;
  let Ecosystem;
  let env;
  let Ballot;
  let ecosystem;
  let elasticDAO;
  let ElasticDAO;
  let informationalVoteManager;
  let InformationalVoteManager;
  let provider;
  let Settings;
  let sdk;
  let summoner;
  let summoner1;
  let summoner2;
  let Token;
  let Vote;

  beforeEach(async () => {
    [agent, summoner, summoner1, summoner2] = await hre.getSigners();
    provider = hre.provider;
    env = await generateEnv();
    sdk = SDK({
      account: agent.address,
      contract: ({ abi, address }) => new ethers.Contract(address, abi, agent),
      env,
      provider,
      signer: agent,
    });

    await deployments.fixture();

    // setup needed contracts
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
    ecosystem = await elasticDAO.getEcosystem();
    Ballot = await deployments.get('InformationalVoteBallot');
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

  it('Should deploy and initialize InformationalVoteManager', async () => {
    await informationalVoteManager.initialize(ecosystem.governanceTokenAddress, false, [
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
    it('Should not create a vote if VoteManager is not initialized', async () => {
      await expect(
        informationalVoteManager.createVote('This proposal should fail', 1),
      ).to.be.revertedWith('ElasticDAO: InformationalVote Manager not initialized');
    });

    it('Should not create a vote if not enough shares to create a vote', async () => {
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

  describe('Factory', () => {
    it('Should deploy the Manager of the voteModule using the Factory', async () => {
      const ivManager = await sdk.modules.informationalVote.informationalVoteFactory.deployManager(
        env.elasticDAO.modules.informationalVote.ballotModelAddress,
        elasticDAO.address,
        env.elasticDAO.modules.informationalVote.settingsModelAddress,
        env.elasticDAO.modules.informationalVote.voteModelAddress,
        ecosystem.governanceTokenAddress,
        true,
        [
          0.5, // approval
          1, // maxSharesPerTokenHolder
          50, // minBlocksForPenalty
          10, // minDurationInBlocks
          0.1, // minPenaltyInShares
          0.1, // minRewardInShares
          0.5, // minSharesToCreate
          0.1, // penalty
          0.6, // quoroum
          0.1, // reward
        ],
      );

      expect(ivManager.address).to.not.equal(undefined);
    });
  });
});
