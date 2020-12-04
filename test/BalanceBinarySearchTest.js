const BigNumber = require('bignumber.js');
const { expect } = require('chai');
const ethers = require('ethers');
const hre = require('hardhat').ethers;
const { deployments } = require('hardhat');

const ONE = ethers.BigNumber.from('1000000000000000000');
const ONE_HUNDRED = ethers.BigNumber.from('100000000000000000000');
const ONE_TENTH = ethers.BigNumber.from('100000000000000000');
const TWO_HUNDREDTHS = ethers.BigNumber.from('20000000000000000');

describe('ElasticDAO: findByBlockNumber ', () => {
  let agent;
  let balanceModel;
  let BalanceModel;
  let ecosystem;
  let Ecosystem;
  let elasticDAO;
  let ElasticDAO;
  let summoner;
  let summoner1;
  let summoner2;
  let tokenHolderModel;
  let TokenHolderModel;
  let tokenRecord;
  let tokenHolderRecord;
  let tokenModel;
  let TokenModel;
  let jsonRpcProvider;

  // tokenRecord, tokenholderRecord, balance contract, elasticDAO, ecosystem
  beforeEach(async () => {
    [agent, summoner, summoner1, summoner2] = await hre.getSigners();
    await deployments.fixture();

    // required contracts
    Ecosystem = await deployments.get('Ecosystem');
    // ecosystem = new ethers.Contract(Ecosystem.address, Ecosystem.abi, agent);
    // - why didnt this work?

    const { deploy } = deployments;
    await deployments.fixture();
    BalanceModel = await deployments.get('Balance');
    balanceModel = new ethers.Contract(BalanceModel.address, BalanceModel.abi, agent);
    TokenModel = await deployments.get('Token');
    tokenModel = new ethers.Contract(TokenModel.address, TokenModel.abi, summoner);
    TokenHolderModel = await deployments.get('TokenHolder');
    tokenHolderModel = new ethers.Contract(
      TokenHolderModel.address,
      TokenHolderModel.abi,
      summoner,
    );
    // agent is the deployer
    await deploy('ElasticDAO', {
      from: agent.address,
      args: [
        Ecosystem.address,
        [summoner.address, summoner1.address, summoner2.address],
        'ElasticDAO',
        3,
      ],
    });

    ElasticDAO = await deployments.get('ElasticDAO');
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, agent);

    await elasticDAO
      .initializeToken(
        'Elastic Governance Token',
        'EGT',
        ONE_TENTH, // eByl value
        TWO_HUNDREDTHS, // elasticity
        ONE_HUNDRED, // k
        ethers.constants.WeiPerEther, // max lambda purchase
      )
      .catch((error) => {
        console.log(error);
      });

    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);
    ecosystem = await elasticDAO.getEcosystem();

    await elasticDAO.seedSummoning({
      value: ONE,
    });

    await elasticDAO.summon(ONE_TENTH);
    tokenRecord = await tokenModel.deserialize(ecosystem.governanceTokenAddress, ecosystem);
    tokenHolderRecord = await tokenHolderModel.deserialize(
      summoner1.address,
      ecosystem,
      tokenRecord,
    );
  });

  it.only('intial data set, initial test', async () => {
    jsonRpcProvider = new ethers.providers.JsonRpcProvider();
    const blockNumber = await jsonRpcProvider.blockNumber;
    // const blockNumber = await ethers.eth.blockNumber;
    console.log(blockNumber);
    // create an initial data set - >  two records
    // create test using initial data set
    const initialBalanceRecord = await balanceModel.deserialize(
      2,
      ecosystem,
      tokenRecord,
      tokenHolderRecord,
    );
    console.log(tokenHolderRecord.lambda.toString());
    console.log(initialBalanceRecord.lambda.toString());
  });
});
