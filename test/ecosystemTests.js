const { expect } = require('chai');
const ethers = require('ethers');
const hre = require('hardhat').ethers;
const { deployments } = require('hardhat');

describe('ElasticDAO: Ecosystem Model', () => {
  let agent;
  let Ecosystem;
  let ecosystemStorage;

  beforeEach(async () => {
    [agent] = await hre.getSigners();

    // setup needed contracts
    Ecosystem = await deployments.get('Ecosystem');
    ecosystemStorage = new ethers.Contract(Ecosystem.address, Ecosystem.abi, agent);
  });

  it('Should look up and return ecosystem instance record by uuid address', async () => {
    const Configurator = await deployments.get('Configurator');
    const DAO = await deployments.get('DAO');
    const ElasticGovernanceToken = await deployments.get('ElasticGovernanceToken');
    const TokenHolder = await deployments.get('TokenHolder');
    const Token = await deployments.get('Token');

    const record = await ecosystemStorage.deserialize(ethers.constants.AddressZero);

    expect(record.configuratorAddress).to.equal(Configurator.address);
    expect(record.daoAddress).to.equal(ethers.constants.AddressZero);
    expect(record.daoModelAddress).to.equal(DAO.address);
    expect(record.ecosystemModelAddress).to.equal(Ecosystem.address);
    expect(record.governanceTokenAddress).to.equal(ElasticGovernanceToken.address);
    expect(record.tokenHolderModelAddress).to.equal(TokenHolder.address);
    expect(record.tokenModelAddress).to.equal(Token.address);
  });

  it('Should check to see if a instance record exists by daoAddress', async () => {
    const recordExists = await ecosystemStorage.exists(ethers.constants.AddressZero);

    expect(recordExists).to.equal(true);
  });
});
