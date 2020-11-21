const { expect } = require('chai');
const ethers = require('ethers');
const hre = require('hardhat').ethers;
const { deployments } = require('hardhat');

const HUNDRED = ethers.BigNumber.from('100000000000000000000');
const ONE = ethers.BigNumber.from('1000000000000000000');
const ONE_TENTH = ethers.BigNumber.from('100000000000000000');
const TWO_HUNDREDTHS = ethers.BigNumber.from('20000000000000000');

// const daoAbi = [
//   "function getDAO() public view returns (DAO.Instance memory)",
// ];

// const erc20 = [
//   "function decimals() view returns (uint256)",
//   "function name() view returns (string)",
//   "function symbol() view returns (string)",
// ];

describe('ElasticDAO: Factory', () => {
  let agent;
  let Ecosystem;
  let elasticDAOFactory;
  let ElasticDAOFactory;
  let summoner;
  let summoner1;
  let summoner2;

  beforeEach(async () => {
    [agent, summoner, summoner1, summoner2] = await hre.getSigners();
    const { deploy } = deployments;

    await deployments.fixture();

    // setup needed contract
    Ecosystem = await deployments.get('Ecosystem');

    await deploy('ElasticDAOFactory', {
      from: agent.address,
      args: [Ecosystem.address],
    });

    ElasticDAOFactory = await deployments.get('ElasticDAOFactory');
  });

  it('Should allow a DAO to be deployed using the factory', async () => {
    elasticDAOFactory = new ethers.Contract(
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
      setTimeout(() => reject(new Error('reject')), 60000);
    });
    daoDeployedFilterPromise.catch((error) => {
      console.log(error);
    });

    const elasticGovernanceTokenDeployedFilterPromise = new Promise((resolve, reject) => {
      const handler = (tokenAddress) => resolve(tokenAddress);
      agent.provider.on(elasticGovernanceTokenDeployedFilter, handler);
      setTimeout(() => reject(new Error('reject')), 60000);
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

    const daoAddress = (await daoDeployedFilterPromise).address;
    const tokenAddress = (await elasticGovernanceTokenDeployedFilterPromise).address;

    expect(daoAddress).to.not.equal(undefined);
    expect(tokenAddress).to.not.equal(undefined);
  }).timeout(60000);
});
