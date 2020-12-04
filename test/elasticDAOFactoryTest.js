const { expect } = require('chai');
const { SDK } = require('@elastic-dao/sdk');
const ethers = require('ethers');
const hre = require('hardhat').ethers;
const { deployments } = require('hardhat');
const { env } = require('./env');

const HUNDRED = ethers.BigNumber.from('100000000000000000000');
const ONE = ethers.BigNumber.from('1000000000000000000');
const ONE_TENTH = ethers.BigNumber.from('100000000000000000');
const TWO_HUNDREDTHS = ethers.BigNumber.from('20000000000000000');

describe('ElasticDAO: Factory', () => {
  let agent;
  let summoner;
  let summoner1;
  let summoner2;

  it('Should allow a DAO to be deployed using the factory', async () => {
    [agent, summoner, summoner1, summoner2] = await hre.getSigners();
    const provider = await hre.provider;
    const sdk = new SDK({
      account: agent.address,
      contract: ({ abi, address }) => new ethers.Contract(address, abi, agent),
      env,
      provider,
      signer: agent,
    });

    await deployments.fixture();

    const dao = await sdk.elasticDAOFactory.deployDAOAndToken(
      [summoner.address, summoner1.address, summoner2.address],
      'Elastic DAO',
      3,
      'Elastic Governance Token',
      'EGT',
      ONE_TENTH,
      TWO_HUNDREDTHS,
      HUNDRED,
      ONE,
    );

    expect(dao.uuid).to.not.equal(undefined);
    expect(dao.ecosystem.governanceTokenAddress).to.not.equal(undefined);
  });
});
