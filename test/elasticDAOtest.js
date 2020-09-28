const { expect } = require('chai');
const ethers = require('ethers');
const bre = require('@nomiclabs/buidler').ethers;
const { deployments } = require('@nomiclabs/buidler');
const elasticStorageAbi = require('../artifacts/ElasticStorage.json').abi;

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
    elasticStorage = new ethers.Contract(elasticStorageAddress[0], elasticStorageAbi, agent);
  });

  it('Should initialize and store DAO state in ElasticStorage on deployment', async () => {
    const daoData = await elasticStorage.functions.getDAO();

    expect(daoData.dao.summoned).to.equal(false);
    expect(daoData.dao.name).to.equal('Elastic DAO');
    expect(daoData.dao.lambda).to.equal(ethers.BigNumber.from('0'));
  });

  it('Should not be able to join DAO if not summoned', async () => {
    await expect(
      elasticDAO.functions.joinDAO(ethers.BigNumber.from('1000000000000000000')),
    ).to.be.revertedWith('ElasticDAO: DAO must be summoned');
  });

  it('Should seed DAO with summoner ETH', async () => {
    await elasticDAO.functions.seedSummoning({
      value: 1,
    });

    const userBalance = await elasticDAO.functions.getAccountBalance(agent._address);

    console.log(userBalance[0]);

    expect(userBalance[0].counter).to.equal(ethers.BigNumber.from('0'));
    expect(userBalance[0].uuid).to.equal(agent._address);
    // expect(userBalance[0].t).to.equal(ethers.BigNumber.from('1000000000000000000'));
  });
});
