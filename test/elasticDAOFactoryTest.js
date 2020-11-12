const { expect } = require('chai');
const ethers = require('ethers');
const bre = require('@nomiclabs/buidler').ethers;
const { deployments } = require('@nomiclabs/buidler');

const HUNDRED = ethers.BigNumber.from('100000000000000000000');
const ONE = ethers.BigNumber.from('1000000000000000000');
const ONE_TENTH = ethers.BigNumber.from('100000000000000000');
const TWO_HUNDREDTHS = ethers.BigNumber.from('20000000000000000');

describe('ElasticDAO: Factory', () => {
  let agent;
  let Ecosystem;
  let elasticDAO;
  let elasticDAOFactory;
  let ElasticDAOFactory;
  let eventListener1;
  let eventListener2;
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

  it.only('Should allow a DAO to be deployed using the factory', async () => {
    elasticDAOFactory = new ethers.Contract(
      ElasticDAOFactory.address,
      ElasticDAOFactory.abi,
      agent,
    );
    elasticDAO = new ethers.Contract(ElasticDAOFactory.address, ElasticDAOFactory.abi, agent);

    const txPromise = elasticDAOFactory.deployDAOAndToken(
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
    // console.log(elasticDAOFactoryStatus);
    // expect(elasticDAOFactoryStatus).to.equal(true);
    await expect(txPromise).to.emit(elasticDAOFactory, 'DAODeployed');
    await expect(txPromise).to.emit(elasticDAO, 'ElasticGovernanceTokenDeployed');
  });
});
