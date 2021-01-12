const { expect } = require('chai');
const BigNumber = require('bignumber.js');
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

  it('2 record dataset test', async () => {
    // create an initial data set - >  two records

    /* blockNumber:  21    22
       lambda:       10    10.1
       index:         0     1
       numberOfRecords = 2
    */

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

    // create test using initial data set
    const atDeployBalanceRecord = await sdk.models.Balance.deserialize(
      20,
      ecosystem,
      tokenRecord,
      tokenHolderRecord,
    );
    expect(atDeployBalanceRecord.lambda.toNumber()).to.equal(0);

    const atSeedBalanceRecord = await sdk.models.Balance.deserialize(
      21,
      ecosystem,
      tokenRecord,
      tokenHolderRecord,
    );
    expect(atSeedBalanceRecord.lambda.toNumber()).to.equal(10);

    const atSummonBalanceRecord = await sdk.models.Balance.deserialize(
      22,
      ecosystem,
      tokenRecord,
      tokenHolderRecord,
    );
    expect(atSummonBalanceRecord.lambda.toNumber()).to.equal(10.1);

    const postSummonBalanceRecord = await sdk.models.Balance.deserialize(
      30,
      ecosystem,
      tokenRecord,
      tokenHolderRecord,
    );
    expect(postSummonBalanceRecord.lambda.toNumber()).to.equal(10.1);
  });

  it('3 record dataset test', async () => {
    // create second data set - >  3 records
    /* blockNumber:  21    25     27
       lambda:       10    10.1   11.1
       index:         0     1      2
       numberOfRecords = 3
    */

    // blockNumber 20
    console.log('test: InitialBlockNumber: ', await provider.getBlockNumber());

    // blocknumber 21 - seedSummon the DAO
    await dao.elasticDAO.seedSummoning({
      value: 1,
    });
    console.log('test: afterSeedSummoningBlockNumber: ', await provider.getBlockNumber());

    // move the blockchain 21 -> 24
    await provider.send('evm_mine', []);
    await provider.send('evm_mine', []);
    await provider.send('evm_mine', []);
    console.log('test: movedBlockNumber: ', await provider.getBlockNumber());

    // blocknumber 25 - summon the dao
    await dao.elasticDAO.summon(0.1);
    console.log('test: afterSummonedBlockNumber: ', await provider.getBlockNumber());

    // move the blockchain - 25 -> 26
    await provider.send('evm_mine', []);
    await dao.refresh();

    console.log('dao-state: ', dao.summoned);

    // buy shares
    // 227672730700348763;
    const valueOfEth = BigNumber('0.227672730700348763');
    console.log('test: valueOfEth: ', valueOfEth.toString());
    await dao.elasticDAO.join(1, {
      value: valueOfEth,
    });

    // test by comparing expected v actual values
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
    const atDeployBalanceRecord = await sdk.models.Balance.deserialize(
      20,
      ecosystem,
      tokenRecord,
      tokenHolderRecord,
    );
    expect(atDeployBalanceRecord.lambda.toNumber()).to.equal(0);

    const atSeedBalanceRecord = await sdk.models.Balance.deserialize(
      21,
      ecosystem,
      tokenRecord,
      tokenHolderRecord,
    );
    expect(atSeedBalanceRecord.lambda.toNumber()).to.equal(10);

    const postSeedBalanceRecord = await sdk.models.Balance.deserialize(
      23,
      ecosystem,
      tokenRecord,
      tokenHolderRecord,
    );
    expect(postSeedBalanceRecord.lambda.toNumber()).to.equal(10);

    const atSummonBalanceRecord = await sdk.models.Balance.deserialize(
      25,
      ecosystem,
      tokenRecord,
      tokenHolderRecord,
    );
    expect(atSummonBalanceRecord.lambda.toNumber()).to.equal(10.1);

    const postSummonBalanceRecord = await sdk.models.Balance.deserialize(
      26,
      ecosystem,
      tokenRecord,
      tokenHolderRecord,
    );
    expect(postSummonBalanceRecord.lambda.toNumber()).to.equal(10.1);

    const atBuyingBalanceRecord = await sdk.models.Balance.deserialize(
      27,
      ecosystem,
      tokenRecord,
      tokenHolderRecord,
    );
    expect(atBuyingBalanceRecord.lambda.toNumber()).to.equal(11.1);

    const postBuyingBalanceRecord = await sdk.models.Balance.deserialize(
      29,
      ecosystem,
      tokenRecord,
      tokenHolderRecord,
    );
    expect(postBuyingBalanceRecord.lambda.toNumber()).to.equal(11.1);
  });

  it.only('5 record data set test', async () => {
    // create third data set - >  5 records
    /* blockNumber:  21    25     27    29      31
       lambda:       10    10.1   11.1   10.1    11.1
       index:         0     1      2       3      4
       numberOfRecords = 5
    */

    // blockNumber 20
    console.log('test: InitialBlockNumber: ', await provider.getBlockNumber());

    // blocknumber 21 - seedSummon the DAO
    await dao.elasticDAO.seedSummoning({
      value: 1,
    });

    // move the blockchain 21 -> 24
    await provider.send('evm_mine', []);
    await provider.send('evm_mine', []);
    await provider.send('evm_mine', []);

    // blocknumber 25 - summon the dao
    await dao.elasticDAO.summon(0.1);

    // move the blockchain - 25 -> 26
    await provider.send('evm_mine', []);
    await dao.refresh();

    // buy shares - 27
    const valueOfEth = BigNumber('0.227672730700348763');
    await dao.elasticDAO.join(1, {
      value: valueOfEth,
    });

    // move the blockchain - 27 -> 28
    await provider.send('evm_mine', []);

    //  use burnShares functionality on ElasticGovernanceToken
    // burnShares or exitDAO - 29
    const { elasticGovernanceToken } = dao;
    await elasticGovernanceToken.burnShares(summoner.address, 1);

    // move the blockchain 29 -> 30
    await provider.send('evm_mine', []);

    // buy shares - 31
    console.log('flag');
    await dao.elasticDAO.join(1, {
      value: valueOfEth,
    });
  });
});
