const { expect } = require('chai');
const ethers = require('ethers');
const hre = require('hardhat').ethers;
const { deployments } = require('hardhat');
const FIFTY_PERCENT = ethers.BigNumber.from('500000000000000000');
const SIXTY_PERCENT = ethers.BigNumber.from('600000000000000000');
const TEN = ethers.BigNumber.from('10000000000000000000');
const ONE = ethers.BigNumber.from('1000000000000000000');
const ONE_TENTH = ethers.BigNumber.from('100000000000000000');
const FIFTY = ethers.BigNumber.from('50000000000000000000');

describe('ElasticDAO: InformationalVoteModuleFactory', () => {
  let agent;
  let ballot;
  let Ballot;
  let Ecosystem;
  let elasticDAO;
  let ElasticDAO;
  let summoner;
  let summoner1;
  let summoner2;
  let elasticGovernanceToken;
  let ElasticGovernanceToken;
  let informationalVoteModuleFactory;
  let InformationalVoteModuleFactory;
  let settings;
  let Settings;
  let vote;
  let Vote;

  beforeEach(async () => {
    [agent, summoner, summoner1, summoner2] = await hre.getSigners();
    const { deploy } = deployments;
    await deployments.fixture();

    // setup the needed contracts
    Ballot = await deployments.get('InformationalVoteBallot');
    Ecosystem = await deployments.get('Ecosystem');
    Settings = await deployments.get('InformationalVoteSettings');
    Vote = await deployments.get('InformationalVote');
    await deploy('InformationalVoteModuleFactory', {
      from: agent.address,
      args: [],
    });
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
    await deploy('ElasticGovernanceToken', {
      from: agent.address,
      args: [ElasticDAO.address, Ecosystem.address],
    });

    InformationalVoteModuleFactory = await deployments.get('InformationalVoteModuleFactory');
  });

  it('Should deploy the Manager of the voteModule using the Factory', async () => {
    ballot = new ethers.Contract(Ballot.address, Ballot.abi, agent);
    elasticDAO = new ethers.Contract(ElasticDAO.address, elasticDAO.abi, agent);
    elasticGovernanceToken = new ethers.Contract(
      ElasticGovernanceToken.address,
      ElasticGovernanceToken.abi,
      agent,
    );
    settings = new ethers.Contract(Settings.address, settings.abi, agent);
    vote = new ethers.Contract(Vote.address, Vote.abi, agent);

    informationalVoteModuleFactory = new ethers.Contract(
      InformationalVoteModuleFactory.address,
      InformationalVoteModuleFactory.abi,
      agent,
    );

    const managerDeployedFilter = { topics: [ethers.utils.id('ManagerDeployed(address)')] };
    const managerDeployedFilterPromise = new Promise((resolve, reject) => {
      agent.provider.on(managerDeployedFilter, (managerAddress) => resolve(managerAddress));
      setTimeout(reject, 10000);
    });

    await informationalVoteModuleFactory.deployManager(
      ballot.address,
      elasticDAO.address,
      settings.address,
      vote.address,
      elasticGovernanceToken.address,
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

    const managerAddress = (await managerDeployedFilterPromise).address;

    expect(managerAddress).to.not.equal(undefined);
  });
});
