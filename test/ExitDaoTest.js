const { expect } = require('chai');
// const BigNumber = require('bignumber.js');
const ethers = require('ethers');
const hre = require('hardhat').ethers;

const { provider } = hre;

const SDK = require('@elastic-dao/sdk');
const env = require('./env');

describe('ElasticDAO: exitDAO ', () => {
  let agent;
  let dao;
  let sdk;
  let summoner;
  let summoner1;
  let summoner2;

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

    // blocknumber 21
    await dao.elasticDAO.seedSummoning({
      value: 1,
    });

    // blocknumber 22
    await dao.elasticDAO.summon(0.1);

    // refresh
    await dao.elasticDAO.getDAO();
  });

  it.only('should allow to exit with 1 share and corresponding eth', async () => {
    // summoner exits one share -> should have 9.1 shares and ( 1 * CapitalDelta ) eth

    const elasticGovernanceToken = await dao.elasticGovernanceToken;
    const postSummonBalanceOf = await elasticGovernanceToken.balanceOf(summoner.address);

    console.log('test: postSummonBalanceOf:', postSummonBalanceOf.toNumber());
    expect(postSummonBalanceOf.toNumber()).to.equal(1010);

    // post exit dao
    // blockNumber 23
    await dao.elasticDAO.exitDAO(1);
    console.log('test: postExitBlockNumber: ', await provider.getBlockNumber());

    const atExitBalanceRecord = await elasticGovernanceToken.balanceOf(summoner.address);
    console.log(atExitBalanceRecord.toNumber());
    expect(atExitBalanceRecord.toNumber()).to.equal(910);
  });
});
