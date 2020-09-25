const { expect } = require('chai');
const ethers = require('ethers');
const bre = require('@nomiclabs/buidler').ethers;
const { deployments } = require('@nomiclabs/buidler');
const elasticStorageAbi = require('../artifacts/ElasticStorage.json');

describe('ElasticDAO: Elastic Storage Contract', () => {
  let ElasticDAO;
  let elasticDAO;
  let elasticStorage;
  let agent;

  beforeEach(async () => {
    [agent] = await bre.getSigners();

    await deployments.fixture();

    // setup needed contracts
    ElasticDAO = await deployments.get('ElasticDAO');
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, agent);
    const elasticStorageAddress = await elasticDAO.functions.getElasticStorage();
    elasticStorage = new ethers.Contract(elasticStorageAddress, elasticStorageAbi, agent);
  });

  it('Should setup and store DAO information in ElasticStorage on deployment', async () => {
    const daoData = await elasticStorage.functions.getDAO();
    console.log('elasticStorage', daoData);
  });

  it('Should always setup and store DAO information in ElasticStorage on deployment', async () => {
    // const daoData = await elasticStorage.functions.getDAO();
  });
});
