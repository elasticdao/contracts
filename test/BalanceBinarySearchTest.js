const { expect } = require('chai');
// const BigNumber = require('bignumber.js');
const ethers = require('ethers');
const hre = require('hardhat').ethers;

const { provider } = hre;

const SDK = require('@elastic-dao/sdk');
const env = require('./env');

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
      0.1,
      0.02,
      100,
      1,
    );
    sdk.account = summoner.address;
    sdk.contract = ({ abi, address }) => new ethers.Contract(address, abi, summoner);
    sdk.signer = summoner;
  });

  it.only('intial data set, initial test', async () => {
    // blocknumber 20
    console.log('test: InitialBlockNumber: ', await provider.getBlockNumber());

    // blocknumber 21
    await dao.elasticDAO.seedSummoning({
      value: 1,
    });
    // blocknumber 22
    await dao.elasticDAO.summon(0.1);

    console.log('test: postSummoningBlockNumber: ', await provider.getBlockNumber());

    const { ecosystem } = dao;
    const tokenRecord = await sdk.models.Token.deserialize(
      ecosystem.governanceTokenAddress,
      ecosystem,
    );

    const tokenHolderRecord = await sdk.models.TokenHolder.deserialize(
      summoner.address,
      ecosystem,
      tokenRecord,
    );
    const tokenHolderCounter = tokenHolderRecord.counter;
    console.log('test: tokenHolderCounter: ', tokenHolderCounter);

    // create an initial data set - >  two records

    /* blockNumber:  21    22
       lambda:       10    10.1
       index:         0     1
       numberOfRecords = 2
    */

    // create test using initial data set
    const atDeployBalanceRecord = await sdk.models.Balance.deserialize(
      20,
      ecosystem,
      tokenRecord,
      tokenHolderRecord,
    );
    // record - lambda = 0
    expect(atDeployBalanceRecord.lambda.toNumber()).to.equal(0);

    const atSeedBalanceRecord = await sdk.models.Balance.deserialize(
      21,
      ecosystem,
      tokenRecord,
      tokenHolderRecord,
    );
    // record - lambda = 10
    expect(atSeedBalanceRecord.lambda.toNumber()).to.equal(10);

    const atSummonBalanceRecord = await sdk.models.Balance.deserialize(
      22,
      ecosystem,
      tokenRecord,
      tokenHolderRecord,
    );
    // record - lambda = 10.1
    expect(atSummonBalanceRecord.lambda.toNumber()).to.equal(10.1);

    const postSummonBalanceRecord = await sdk.models.Balance.deserialize(
      30,
      ecosystem,
      tokenRecord,
      tokenHolderRecord,
    );
    // record - lambda = 10.1
    expect(postSummonBalanceRecord.lambda.toNumber()).to.equal(10.1);
  });
});
