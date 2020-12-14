const { expect } = require('chai');
const ethers = require('ethers');
const hre = require('hardhat').ethers;
const SDK = require('@elastic-dao/sdk');

const { ONE, ONE_HUNDRED, ONE_TENTH, TWO_HUNDREDTHS } = require('./constants');
const generateEnv = require('./env');

describe('ElasticDAO: Factory', () => {
  let agent;
  let summoner;
  let summoner1;
  let summoner2;

  it('Should allow a DAO to be deployed using the factory', async () => {
    [agent, summoner, summoner1, summoner2] = await hre.getSigners();
    const { provider } = hre;
    const env = await generateEnv();
    const sdk = SDK({
      account: agent.address,
      contract: ({ abi, address }) => new ethers.Contract(address, abi, agent),
      env,
      provider,
      signer: agent,
    });

    const dao = await sdk.elasticDAOFactory.deployDAOAndToken(
      [summoner.address, summoner1.address, summoner2.address],
      'Elastic DAO',
      3,
      'Elastic Governance Token',
      'EGT',
      ONE_TENTH,
      TWO_HUNDREDTHS,
      ONE_HUNDRED,
      ONE,
    );

    expect(dao.uuid).to.not.equal(undefined);
    expect(dao.ecosystem.governanceTokenAddress).to.not.equal(undefined);
  });
});
