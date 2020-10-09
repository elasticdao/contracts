const { expect } = require('chai');
const ethers = require('ethers');
const bre = require('@nomiclabs/buidler').ethers;
const { deployments } = require('@nomiclabs/buidler');

const ONE = ethers.BigNumber.from('1000000000000000000');
const ONE_HUNDRED = ethers.BigNumber.from('100000000000000000000');
// const ONE_HUNDRED_TEN = ethers.BigNumber.from('110000000000000000000');
const ONE_TENTH = ethers.BigNumber.from('100000000000000000');
// const TEN = ethers.BigNumber.from('10000000000000000000');
const TWO = ethers.BigNumber.from('2000000000000000000');
const TWO_HUNDREDTHS = ethers.BigNumber.from('20000000000000000');
const THIRTY_FIVE_PERCENT = ethers.BigNumber.from('350000000000000000');
const FIFTY_PERCENT = ethers.BigNumber.from('500000000000000000');
const FIVE = ethers.BigNumber.from('5000000000000000000');
const FOUR = ethers.BigNumber.from('4000000000000000000');

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
    [agent, summoner, summoner1, summoner2] = await bre.getSigners();
    const { deploy } = deployments;

    await deployments.fixture();

    // setup needed contracts
    Ballot = await deployments.get('InformationalVoteBallot');
    Settings = await deployments.get('InformationalVoteSettings');
    Vote = await deployments.get('InformationalVote');
    Ecosystem = await deployments.get('Ecosystem');

    await deploy('ElasticDAO', {
      from: agent._address,
      args: [
        Ecosystem.address,
        [summoner._address, summoner1._address, summoner2._address],
        'ElasticDAO',
        3,
      ],
    });
    ElasticDAO = await deployments.get('ElasticDAO');
    Token = await deployments.get('Token');

    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);
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
  });

  it('Should deploy and initialize InformationalVoteManager', async () => {
    const { deploy } = deployments;
    await deploy('InformationalVoteManager', {
      from: agent._address,
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
      THIRTY_FIVE_PERCENT,
      ethers.constants.WeiPerEther,
      1000,
      500,
      ONE_TENTH,
      ONE_TENTH,
      FIFTY_PERCENT,
      ONE_TENTH,
    ]);
    const settingsContract = new ethers.Contract(Settings.address, Settings.abi, summoner);
    const settings = await settingsContract.deserialize(InformationalVoteManager.address);

    await expect(settings.votingToken).to.be.equal(ecosystem.governanceTokenAddress);
    await expect(settings.hasPenalty).to.be.equal(false);

    await expect(settings.approval).to.be.equal(THIRTY_FIVE_PERCENT);
    await expect(settings.maxSharesPerTokenHolder).to.be.equal(ethers.constants.WeiPerEther);
    await expect(settings.minBlocksForPenalty).to.be.equal(1000);
    await expect(settings.minDurationInBlocks).to.be.equal(500);
    await expect(settings.minSharesToCreate).to.be.equal(ONE_TENTH);
    await expect(settings.penalty).to.be.equal(ONE_TENTH);
    await expect(settings.quorum).to.be.equal(FIFTY_PERCENT);
    await expect(settings.reward).to.be.equal(ONE_TENTH);
  });

  describe('createVote(string memory _proposal, uint256 _endBlock)', () => {
    beforeEach(async () => {
      const { deploy } = deployments;
      await deploy('InformationalVoteManager', {
        from: agent._address,
        args: [Ballot.address, Settings.address, Vote.address],
      });
      InformationalVoteManager = await deployments.get('InformationalVoteManager');

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
        TWO, // approval
        ONE, // maxSharesPerTokenHolder
        FOUR, // minBlocksForPenalty
        FIVE, // minDurationInBlocks
        ONE_TENTH, // minSharesToCreate
        THIRTY_FIVE_PERCENT, // penalty
        ONE_TENTH, // quorum
        FIFTY_PERCENT, // reward
      ]);

      await expect(
        informationalVoteManager.createVote('This proposal should fail', 1),
      ).to.be.revertedWith('ElasticDAO: Not enough shares to create vote');
    });
    it('Should not create a vote if the duration is too short', async () => {
      const ecosystem = await elasticDAO.getEcosystem();

      await informationalVoteManager.initialize(ecosystem.governanceTokenAddress, true, [
        TWO, // approval
        ONE, // maxSharesPerTokenHolder
        FOUR, // minBlocksForPenalty
        FIVE, // minDurationInBlocks
        ONE_TENTH, // minSharesToCreate
        THIRTY_FIVE_PERCENT, // penalty
        ONE_TENTH, // quorum
        FIFTY_PERCENT, // reward
      ]);

      const tokenStorage = new ethers.Contract(Token.address, Token.abi, summoner);
      const token = await tokenStorage.deserialize(ecosystem.governanceTokenAddress);

      await elasticDAO.seedSummoning({ value: ethers.constants.WeiPerEther });
      await elasticDAO.summon(token.maxLambdaPurchase);

      await expect(
        informationalVoteManager.createVote('This proposal should fail', ONE),
      ).to.be.revertedWith('ElasticDAO: InformationalVote period too short');
    });
    it('Should create a vote', async () => {
      const ecosystem = await elasticDAO.getEcosystem();

      await informationalVoteManager.initialize(ecosystem.governanceTokenAddress, true, [
        TWO, // approval
        ONE, // maxSharesPerTokenHolder
        FOUR, // minBlocksForPenalty
        FIVE, // minDurationInBlocks
        ONE_TENTH, // minSharesToCreate
        THIRTY_FIVE_PERCENT, // penalty
        ONE_TENTH, // quorum
        FIFTY_PERCENT, // reward
      ]);

      const tokenStorage = new ethers.Contract(Token.address, Token.abi, summoner);
      const token = await tokenStorage.deserialize(ecosystem.governanceTokenAddress);

      await elasticDAO.seedSummoning({ value: ethers.constants.WeiPerEther });
      await elasticDAO.summon(token.maxLambdaPurchase);

      const vote = await informationalVoteManager.functions.createVote(
        'This proposal should succeed',
        ONE_HUNDRED,
      );
      const vote2 = await informationalVoteManager.functions.createVote(
        'This proposal should succeed',
        ONE_HUNDRED,
      );

      const wait1 = await vote.wait();
      const wait2 = await vote2.wait();

      expect(wait1.events[0].args.id).to.equal(ethers.BigNumber.from('0'));
      expect(wait2.events[0].args.id).to.equal(ethers.BigNumber.from('1'));
    });
  });
});
