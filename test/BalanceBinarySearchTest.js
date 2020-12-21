// const { expect } = require('chai');
// const BigNumber = require('bignumber.js');
const ethers = require('ethers');
const hre = require('hardhat').ethers;

const { provider } = hre;

const SDK = require('@elastic-dao/sdk');
const env = require('./env');
const { ONE, ONE_HUNDRED, ONE_TENTH, TWO_HUNDREDTHS } = require('./constants');

describe('ElasticDAO: findByBlockNumber ', () => {
  let agent;
  let dao;
  let sdk;
  let summoner;
  let summoner1;
  let summoner2;

  // tokenRecord, tokenholderRecord, balance contract, elasticDAO, ecosystem
  beforeEach(async () => {
    [agent, summoner, summoner1, summoner2] = await hre.getSigners();

    // agent is the deployer
    sdk = SDK({
      account: agent.address,
      contract: ({ abi, address }) => new ethers.Contract(address, abi, agent),
      env: await env(),
      provider,
      signer: agent,
    });

    dao = await sdk.elasticDAOFactory.deployDAOAndToken(
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
    sdk.account = summoner.address;
    sdk.contract = ({ abi, address }) => new ethers.Contract(address, abi, summoner);
    sdk.signer = summoner;
  });

  it.only('intial data set, initial test', async () => {
    const firstBlockNumber = await provider.getBlockNumber();
    console.log('InitialBlockNumber: ', firstBlockNumber);

    await dao.elasticDAO.seedSummoning({
      value: 1,
    });
    await dao.elasticDAO.summon(ONE_TENTH);

    const secondBlockNumber = await provider.getBlockNumber();
    console.log('SecondBlockNumber: ', secondBlockNumber);

    const { ecosystem } = dao;
    console.log(ecosystem);
    const tokenRecord = await sdk.models.Token.deserialize(
      ecosystem.governanceTokenAddress,
      ecosystem,
    );
    console.log(tokenRecord.toObject());

    const tokenHolderRecord = await sdk.models.TokenHolder.deserialize(
      summoner.address,
      ecosystem,
      tokenRecord,
    );
    console.log(tokenHolderRecord.toObject());

    // create an initial data set - >  two records
    // create test using initial data set
    const initialBalanceRecord = await sdk.models.Balance.deserialize(
      20,
      ecosystem,
      tokenRecord,
      tokenHolderRecord,
    );
    console.log(initialBalanceRecord);
  });
});
