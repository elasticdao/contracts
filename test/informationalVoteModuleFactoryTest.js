const { expect } = require('chai');
const ethers = require('ethers');
const SDK = require('@elastic-dao/sdk');
const hre = require('hardhat').ethers;
const { deployments } = require('hardhat');
const { env } = require('./env');

console.log('SDK', SDK);

const FIFTY = ethers.BigNumber.from('50000000000000000000');
const FIFTY_PERCENT = ethers.BigNumber.from('500000000000000000');
const HUNDRED = ethers.BigNumber.from('100000000000000000000');
const ONE = ethers.BigNumber.from('1000000000000000000');
const ONE_TENTH = ethers.BigNumber.from('100000000000000000');
const SIXTY_PERCENT = ethers.BigNumber.from('600000000000000000');
const TEN = ethers.BigNumber.from('10000000000000000000');
const TWO_HUNDREDTHS = ethers.BigNumber.from('20000000000000000');

describe('ElasticDAO: InformationalVoteModuleFactory', () => {
  let agent;
  let summoner;
  let summoner1;
  let summoner2;

  it.only('Should deploy the Manager of the voteModule using the Factory', async () => {
    [agent, summoner, summoner1, summoner2] = await hre.getSigners();

    await deployments.fixture();

    const provider = await hre.provider;
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
      HUNDRED,
      ONE,
    );

    console.log('STUFF');
    console.log(
      env.elasticDAO.modules.informationalVote.ballotModelAddress,
      dao.address,
      env.elasticDAO.modules.informationalVote.settingsModelAddress,
      env.elasticDAO.modules.informationalVote.voteModelAddress,
      dao.ecosystem.governanceTokenAddress,
    );

    console.log([
      FIFTY_PERCENT, // approval
      ONE, // maxSharesPerTokenHolder
      FIFTY, // minBlocksForPenalty
      TEN, // minDurationInBlocks
      ONE_TENTH, // minPenaltyInShares
      ONE_TENTH, // minRewardInShares
      FIFTY_PERCENT, // minSharesToCreate
      ONE_TENTH, // penalty
      SIXTY_PERCENT, // quoroum
      ONE_TENTH, // reward
    ]);

    const ivManager = await sdk.modules.informationalVote.informationalVoteFactory.deployManager(
      env.elasticDAO.modules.informationalVote.ballotModelAddress,
      dao.address,
      env.elasticDAO.modules.informationalVote.settingsModelAddress,
      env.elasticDAO.modules.informationalVote.voteModelAddress,
      dao.ecosystem.governanceTokenAddress,
      true,

      [
        FIFTY_PERCENT, // approval
        ONE, // maxSharesPerTokenHolder
        FIFTY, // minBlocksForPenalty
        TEN, // minDurationInBlocks
        ONE_TENTH, // minPenaltyInShares
        ONE_TENTH, // minRewardInShares
        FIFTY_PERCENT, // minSharesToCreate
        ONE_TENTH, // penalty
        SIXTY_PERCENT, // quoroum
        ONE_TENTH, // reward
      ],
    );

    expect(ivManager.address).to.not.equal(undefined);
  });
});
