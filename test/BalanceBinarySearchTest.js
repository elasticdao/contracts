// const { expect } = require('chai');
// const BigNumber = require('bignumber.js');
const ethers = require('ethers');
const hre = require('hardhat').ethers;

const { provider } = hre;

const SDK = require('@elastic-dao/sdk');
const generateEnv = require('./env');

describe('ElasticDAO: findByBlockNumber ', () => {
  let agent;
  let dao;
  let sdk;
  let summoner;
  let summoner1;
  let summoner2;

  // tokenRecord, tokenholderRecord, balance contract, elasticDAO, ecosystem
  beforeEach(async () => {
    const env = await generateEnv();
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
      0.1,
      0.02,
      100,
      1,
    );
  });

  it.only('intial data set, initial test', async () => {
    const ecosystemRecord = dao.ecosystem;
    const tokenRecord = await dao.token();
    const daoUuid = dao.uuid;
    console.log('5', ecosystemRecord, daoUuid, tokenRecord);
    const tokenHolderRecord = await sdk.models.TokenHolder.deserialize(
      daoUuid,
      ecosystemRecord,
      tokenRecord,
    );
    console.log('6');
    const firstBalanceRecord = await sdk.models.Balance.deserialize(
      1,
      ecosystemRecord,
      tokenRecord,
      tokenHolderRecord,
    );
    console.log('7');
    console.log('fBR: ', firstBalanceRecord.toString());
    // await dao.elasticDAO.seedSummoning({
    //   value: 1,
    // });

    // await sdk.ElasticDAO.summon(ONE_TENTH);

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
