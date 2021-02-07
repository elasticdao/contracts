const { expect } = require('chai');
const ethers = require('ethers');
const hre = require('hardhat').ethers;
const { deployments } = require('hardhat');

describe('ElasticDAO: Ecosystem Model', () => {
  let agent;
  let Configurator;
  let Dao;
  let Ecosystem;
  let ecosystemStorage;
  let TokenHolder;
  let Token;

  beforeEach(async () => {
    [agent] = await hre.getSigners();

    // setup needed contracts
    Configurator = await deployments.get('Configurator_Implementation');
    Dao = await deployments.get('DAO_Implementation');
    Ecosystem = await deployments.get('Ecosystem_Implementation');
    ecosystemStorage = new ethers.Contract(Ecosystem.address, Ecosystem.abi, agent);
    TokenHolder = await deployments.get('TokenHolder_Implementation');
    Token = await deployments.get('Token_Implementation');
  });

  it('Should look up and return ecosystem instance record by uuid address', async () => {
    const record = await ecosystemStorage.deserialize(ethers.constants.AddressZero);

    expect(record.configuratorAddress).to.equal(Configurator.address);
    expect(record.daoAddress).to.equal(ethers.constants.AddressZero);
    expect(record.daoModelAddress).to.equal(Dao.address);
    expect(record.ecosystemModelAddress).to.equal(Ecosystem.address);
    expect(record.governanceTokenAddress).to.equal(ethers.constants.AddressZero);
    expect(record.tokenHolderModelAddress).to.equal(TokenHolder.address);
    expect(record.tokenModelAddress).to.equal(Token.address);
  });

  it('Should check to see if a instance record exists by daoAddress', async () => {
    const recordExists = await ecosystemStorage.exists(ethers.constants.AddressZero);

    expect(recordExists).to.equal(true);
  });
});
