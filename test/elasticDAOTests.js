const { expect } = require('chai');
const ethers = require('ethers');
const bre = require('@nomiclabs/buidler').ethers;
const { deployments } = require('@nomiclabs/buidler');

describe('ElasticDAO: Core', () => {
  let agent;
  let summoner;
  let summoner1;
  let summoner2;
  let Configurator;
  let Dao;
  let dao;
  let Ecosystem;
  let ElasticDAO;
  let elasticDAO;
  let ElasticModule;
  let Registrator;
  let TokenHolder;
  let Token;

  beforeEach(async () => {
    [agent, summoner, summoner1, summoner2] = await bre.getSigners();
    const { deploy } = deployments;

    await deployments.fixture();

    // setup needed contracts
    Configurator = await deployments.get('Configurator');
    Dao = await deployments.get('DAO');
    dao = new ethers.Contract(Dao.address, Dao.abi, agent);
    Ecosystem = await deployments.get('Ecosystem');
    ElasticModule = await deployments.get('ElasticModule');
    Registrator = await deployments.get('Registrator');
    TokenHolder = await deployments.get('TokenHolder');
    Token = await deployments.get('Token');

    await deploy('ElasticDAO', {
      from: agent._address,
      proxy: true,
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

  it('Should get module address by name', async () => {
    let ecosystemModelAddress = await elasticDAO.functions.getModuleAddress('Ecosystem');

    expect(ecosystemModelAddress).to.equal(Ecosystem.address);
  });
});
