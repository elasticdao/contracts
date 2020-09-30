const { expect } = require('chai');
const ethers = require('ethers');
const bre = require('@nomiclabs/buidler').ethers;
const { deployments } = require('@nomiclabs/buidler');

describe('ElasticDAO: Ecosystem Model', () => {
  let agent;
  let Configurator;
  let Dao;
  let Ecosystem;
  let ecosystemStorage;
  let ElasticModule;
  let Registrator;
  let TokenHolder;
  let Token;

  beforeEach(async () => {
    [agent] = await bre.getSigners();

    await deployments.fixture();

    // setup needed contracts
    Configurator = await deployments.get('Configurator');
    Dao = await deployments.get('DAO');
    Ecosystem = await deployments.get('Ecosystem');
    ecosystemStorage = new ethers.Contract(Ecosystem.address, Ecosystem.abi, agent);
    ElasticModule = await deployments.get('ElasticModule');
    Registrator = await deployments.get('Registrator');
    TokenHolder = await deployments.get('TokenHolder');
    Token = await deployments.get('Token');
  });

  it('Should look up and return ecosystem instance record by uuid address', async () => {
    let record = await ecosystemStorage.deserialize(ethers.constants.AddressZero);

    expect(record.uuid).to.equal(ethers.constants.AddressZero);
    expect(record.daoModelAddress).to.equal(Dao.address);
    expect(record.ecosystemModelAddress).to.equal(Ecosystem.address);
    expect(record.elasticModuleModelAddress).to.equal(ElasticModule.address);
    expect(record.tokenModelAddress).to.equal(Token.address);
    expect(record.tokenHolderModelAddress).to.equal(TokenHolder.address);
    expect(record.configuratorAddress).to.equal(Configurator.address);
    expect(record.registratorAddress).to.equal(Registrator.address);
    expect(record.governanceTokenAddress).to.equal(ethers.constants.AddressZero);
  });

  it('Should check to see if a instance record exists by uuid', async () => {
    let recordExists = await ecosystemStorage.exists(ethers.constants.AddressZero);

    expect(recordExists).to.equal(true);
  });
});
