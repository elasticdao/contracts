const { expect } = require('chai');
const ethers = require('ethers');
const hre = require('hardhat').ethers;
const { deployments } = require('hardhat');

const FIFTY = ethers.BigNumber.from('50000000000000000000');
const FIFTY_PERCENT = ethers.BigNumber.from('500000000000000000');
const HUNDRED = ethers.BigNumber.from('100000000000000000000');
const ONE = ethers.BigNumber.from('1000000000000000000');
const ONE_TENTH = ethers.BigNumber.from('100000000000000000');
const SIXTY_PERCENT = ethers.BigNumber.from('600000000000000000');
const TEN = ethers.BigNumber.from('10000000000000000000');
const TWO_HUNDREDTHS = ethers.BigNumber.from('20000000000000000');

describe('ElasticDAO: InformationalVoteModuleFactory', () => {
  let agent;
  let Ballot;
  let summoner;
  let summoner1;
  let summoner2;
  let InformationalVoteModuleFactory;
  let Settings;
  let Vote;

  beforeEach(async () => {
    [agent, summoner, summoner1, summoner2] = await hre.getSigners();
    const { deploy } = deployments;
    await deployments.fixture();

    // setup the needed contracts
    Ballot = await deployments.get('InformationalVoteBallot');
    // Ecosystem = await deployments.get('Ecosystem');
    Settings = await deployments.get('InformationalVoteSettings');
    Vote = await deployments.get('InformationalVote');
    await deploy('InformationalVoteModuleFactory', {
      from: agent.address,
      args: [],
    });

    InformationalVoteModuleFactory = await deployments.get('InformationalVoteModuleFactory');
  });

  it.skip('Should deploy the Manager of the voteModule using the Factory', async () => {
    const ballot = new ethers.Contract(Ballot.address, Ballot.abi, agent);
    const settings = new ethers.Contract(Settings.address, Settings.abi, agent);
    const vote = new ethers.Contract(Vote.address, Vote.abi, agent);

    const ElasticDAOFactory = await deployments.get('ElasticDAOFactory');
    const elasticDAOFactory = new ethers.Contract(
      ElasticDAOFactory.address,
      ElasticDAOFactory.abi,
      agent,
    );

    const daoDeployedFilter = { topics: [ethers.utils.id('DAODeployed(address)')] };
    const elasticGovernanceTokenDeployedFilter = {
      topics: [ethers.utils.id('ElasticGovernanceTokenDeployed(address)')],
    };

    const daoDeployedFilterPromise = new Promise((resolve, reject) => {
      agent.provider.on(daoDeployedFilter, (daoAddress) => resolve(daoAddress));
      setTimeout(() => reject(new Error('reject')), 9000000);
    });
    daoDeployedFilterPromise.catch((error) => {
      console.log(error);
    });

    const elasticGovernanceTokenDeployedFilterPromise = new Promise((resolve, reject) => {
      const handler = (tokenAddress) => resolve(tokenAddress);
      agent.provider.on(elasticGovernanceTokenDeployedFilter, handler);
      setTimeout(() => reject(new Error('reject')), 9000000);
    });
    elasticGovernanceTokenDeployedFilterPromise.catch((error) => {
      console.log(error);
    });

    await elasticDAOFactory.deployDAOAndToken(
      [summoner.address, summoner1.address, summoner2.address],
      'Elastic DAO',
      3,
      'Elastic Governance Token',
      'EGT',
      ONE_TENTH,
      TWO_HUNDREDTHS,
      HUNDRED,
      ONE,
    );
    const informationalVoteModuleFactory = new ethers.Contract(
      InformationalVoteModuleFactory.address,
      InformationalVoteModuleFactory.abi,
      agent,
    );

    const daoAddress = (await daoDeployedFilterPromise).address;
    const tokenAddress = (await elasticGovernanceTokenDeployedFilterPromise).address;

    const managerDeployedFilter = { topics: [ethers.utils.id('ManagerDeployed(address)')] };
    const managerDeployedFilterPromise = new Promise((resolve, reject) => {
      agent.provider.on(managerDeployedFilter, (managerAddress) => resolve(managerAddress));
      setTimeout(() => reject(new Error('reject')), 9000000);
    });

    managerDeployedFilterPromise.catch((error) => {
      console.log(error);
    });

    await informationalVoteModuleFactory.deployManager(
      ballot.address,
      daoAddress,
      settings.address,
      vote.address,
      tokenAddress,
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
  }).timeout(9000000);
});
