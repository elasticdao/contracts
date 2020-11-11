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
      args: [Ecosystem.address, TWO_HUNDREDTHS, HUNDRED, ONE],
    });

    ElasticDAOFactory = await deployments.get('ElasticDAOFactory');
  });

  it.only('Should allow a DAO to be deployed using the factory', async () => {
    elasticDAOFactory = new ethers.Contract(
      ElasticDAOFactory.address,
      ElasticDAOFactory.abi,
      agent,
    );
    const elasticDAOFactoryStatus = await elasticDAOFactory.deployDAOAndToken(
      [summoner._address, summoner1._address, summoner2._address],
      'Elastic DAO',
      3,
      'Elastic Governance Token',
      'EGT',
      ONE_TENTH,
    );
    console.log(elasticDAOFactoryStatus);
    expect(elasticDAOFactoryStatus).to.equal(true);
  });
});
