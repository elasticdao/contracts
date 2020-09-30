const { expect } = require('chai');
const ethers = require('ethers');
const bre = require('@nomiclabs/buidler').ethers;
const { deployments } = require('@nomiclabs/buidler');

describe('ElasticDAO: Core', () => {
  let agent;
  let summoner;
  let summoner1;
  let summoner2;
  let Dao;
  let dao;
  let Ecosystem;
  let ElasticDAO;
  let elasticDAO;

  beforeEach(async () => {
    [agent, summoner, summoner1, summoner2] = await bre.getSigners();
    const { deploy } = deployments;

    await deployments.fixture();

    // setup needed contracts
    Dao = await deployments.get('DAO');
    dao = new ethers.Contract(Dao.address, Dao.abi, agent);

    // this function is hanging, syntax appears right to my tired eyes
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
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, agent);
  });

  it('Should allow a token to be initialized', async () => {});

  it('Should create a new ElasticGovernanceToken contract when token is initialized', async () => {});

  it('Should not allow a token to be initialized after summoning', async () => {});

  it('Should allow summoners to seed', async () => {});

  it('Should mint an appropriate number of tokens to the seeding summoner', async () => {});

  it('Should not allow non summoners to seed', async () => {});

  it('Should allow the dao to be summoned after it has been seeded', async () => {});

  it('Should not allow the dao to be summoned before it has been seeded', async () => {});

  it('Should mint tokens to all summoner token balances based on deltaLambda', async () => {});
});
