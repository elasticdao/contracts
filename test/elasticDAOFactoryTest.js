const { expect } = require('chai');
const ethers = require('ethers');
const bre = require('@nomiclabs/buidler').ethers;
const { deployments } = require('@nomiclabs/buidler');

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
    [agent, summoner, summoner1, summoner2] = await bre.getSigners();
    const { deploy } = deployments;

    await deployments.fixture();

    // setup needed contract
    Ecosystem = await deployments.get('Ecosystem');

    await deploy('ElasticDAOFactory', {
      from: agent._address,
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
      setTimeout(reject, 10000);
    });

    const elasticGovernanceTokenDeployedFilterPromise = new Promise((resolve, reject) => {
      const handler = (tokenAddress) => resolve(tokenAddress);
      agent.provider.on(elasticGovernanceTokenDeployedFilter, handler);
      setTimeout(reject, 10000);
    });

    await elasticDAOFactory.deployDAOAndToken(
      [summoner._address, summoner1._address, summoner2._address],
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

    // console.log('here', daoAddress, tokenAddress);
    // const tokenContract = new ethers.Contract(tokenAddress, erc20, agent);

    // console.log(1);
    // expect(await tokenContract.functions.decimals()).to.equal(18);
    // console.log(2);
    // expect(await tokenContract.functions.name()).to.equal('ElasticGovernanceToken');
    // console.log(3);
    // expect(await tokenContract.functions.symbol()).to.equal('EGT');

    // console.log(4);
    // const daoContract = new ethers.Contract(daoAddress, daoAbi, agent);
    // console.log(5);
    // const daoData = await daoContract.functions.getDAO();
    // console.log(6);
    // expect(daoData.name).to.equal('Elastic DAO');
    // console.log(7);
  });
});
