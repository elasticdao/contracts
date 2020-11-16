const { expect } = require('chai');
const ethers = require('ethers');
const hre = require('hardhat').ethers;
const { deployments } = require('hardhat');

const ONE_ETH = 1;
const HUNDRED = ethers.BigNumber.from('100000000000000000000');
const ONE = ethers.BigNumber.from('1000000000000000000');
const ONE_TENTH = ethers.BigNumber.from('100000000000000000');
const TWO_HUNDREDTHS = ethers.BigNumber.from('20000000000000000');

describe('ElasticDAO: CapitalDelta value of a token', () => {
  let agent;
  let elasticGovernanceToken;
  let ElasticGovernanceToken;
  let elasticDAOFactory;
  let ElasticDAOFactory;
  let summoner;
  let summoner1;
  let summoner2;
  let token;
  let Token;

  beforeEach(async () => {
    [agent, summoner, summoner1, summoner2] = await hre.getSigners();
    const { deploy } = deployments;
    await deployments.fixture();

    // setup needed contracts
    ElasticDAOFactory = await deployments.get('ElasticDAOFactory');
    elasticDAOFactory = new ethers.Contract(
      ElasticDAOFactory.address,
      ElasticDAOFactory.abi,
      agent,
    );
  });

  it('Should match the value of capital delta', async () => {
    // deploy the dao and token via the daoFactory and get the addresses of the DAO and the token
    const daoDeployedFilter = { topics: [ethers.utils.id('DAODeployed(address)')] };
    const elasticGovernanceTokenDeployedFilter = {
      topics: [ethers.utils.id('ElasticGovernanceTokenDeployed(address)')],
    };

    const daoDeployedFilterPromise = new Promise((resolve, reject) => {
      agent.provider.on(daoDeployedFilter, (daoAddress) => resolve(daoAddress));
      setTimeout(reject, 10000);
    });

    const elasticGovernanceTokenDeployedFilterPromise = new Promise((resolve, reject) => {
      const handler = (tokenAddress) => resolve(tokenAddress);
      agent.provider.on(elasticGovernanceTokenDeployedFilter, handler);
      setTimeout(reject, 10000);
    });

    await elasticDAOFactory.deployDAOAndToken(
      [summoner.address, summoner1.address, summoner2.address],
      'Elastic DAO',
      3,
      'Elastic Governance Token',
      'EGT',
      ONE_TENTH, // capitalDelta
      TWO_HUNDREDTHS,
      HUNDRED,
      ONE,
    );

    const daoAddress = (await daoDeployedFilterPromise).address;
    const tokenAddress = (await elasticGovernanceTokenDeployedFilterPromise).address;

    // take the token, send it some more eth
    await summoner.sendTransaction({
      to: tokenAddress,
      value: ONE,
    });

    // check capital delta
    // token.capitaldelta != ()
  });
});
