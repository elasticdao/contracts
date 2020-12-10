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
      env,
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
  });

  it.only('intial data set, initial test', async () => {
    const firstBlockNumber = await sdk.models.Balance.blockNumber;
    console.log('InitialBlockNumber: ', firstBlockNumber);

    await dao.elasticDAO.seedSummoning({
      value: 1,
    });

    await sdk.ElasticDAO.summon(ONE_TENTH);
    const secondBlockNumber = await sdk.models.blockNumber;
    console.log('SecondBlockNumber: ', secondBlockNumber);

    // create an initial data set - >  two records
    // create test using initial data set
    // const initialBalanceRecord = await balanceModel.deserialize(
    //   2,
    //   ecosystem,
    //   tokenRecord,
    //   tokenHolderRecord,
    // );
  });
});
