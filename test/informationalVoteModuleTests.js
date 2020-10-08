const { expect } = require('chai');
const ethers = require('ethers');
const bre = require('@nomiclabs/buidler').ethers;
const { deployments } = require('@nomiclabs/buidler');

const ONE_HUNDRED = ethers.BigNumber.from('100000000000000000000');
// const ONE_HUNDRED_TEN = ethers.BigNumber.from('110000000000000000000');
const ONE_TENTH = ethers.BigNumber.from('100000000000000000');
// const TEN = ethers.BigNumber.from('10000000000000000000');
const TWO_HUNDREDTHS = ethers.BigNumber.from('20000000000000000');
const THIRTY_FIVE_PERCENT = ethers.BigNumber.from('350000000000000000');
const FIFTY_PERCENT = ethers.BigNumber.from('500000000000000000');

describe('ElasticDAO: Informational Vote Module', () => {
  let agent;
  let Ballot;
  let Ecosystem;
  let elasticDAO;
  let ElasticDAO;
  // let Manager;
  let Settings;
  let summoner;
  let summoner1;
  let summoner2;
  let Token;
  // let tokenStorage;
  let Vote;

  beforeEach(async () => {
    [agent, summoner, summoner1, summoner2] = await bre.getSigners();
    const { deploy } = deployments;

    await deployments.fixture();

    // setup needed contracts
    Ballot = await deployments.get('InformationalVoteBallot');
    Settings = await deployments.get('InformationalVoteSettings');
    Vote = await deployments.get('InformationalVote');
    Ecosystem = await deployments.get('Ecosystem');

    await deploy('ElasticDAO', {
      from: agent._address,
      args: [
        Ecosystem.address,
        [summoner._address, summoner1._address, summoner2._address],
        'ElasticDAO',
        3,
      ],
    });
    ElasticDAO = await deployments.get('ElasticDAO');
    Token = await deployments.get('Token');

    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);
    await elasticDAO
      .initializeToken(
        'Elastic Governance Token',
        'EGT',
        ONE_TENTH,
        TWO_HUNDREDTHS,
        ONE_HUNDRED,
        ethers.constants.WeiPerEther,
      )
      .catch((error) => {
        console.log(error);
      });
  });

  it.only('Should deploy and initialize InformationalVoteManager', async () => {
    const { deploy } = deployments;
    await deploy('InformationalVoteManager', {
      from: agent._address,
      args: [Ballot.address, Settings.address, Vote.address],
    });
    const InformationalVoteManager = await deployments.get('InformationalVoteManager');

    const ecosystem = await elasticDAO.getEcosystem();
    const informationalVoteManagerContract = new ethers.Contract(
      InformationalVoteManager.address,
      InformationalVoteManager.abi,
      summoner,
    );
    informationalVoteManagerContract.initialize(ecosystem.governanceTokenAddress, false, [
      THIRTY_FIVE_PERCENT,
      ethers.constants.WeiPerEther,
      1000,
      500,
      ONE_TENTH,
      ONE_TENTH,
      FIFTY_PERCENT,
      ONE_TENTH,
    ]);
    const settingsContract = new ethers.Contract(Settings.address, Settings.abi, summoner);
    const settings = settingsContract.deserialize(InformationalVoteManager.address);

    await expect(settings.approval).to.be.equal(THIRTY_FIVE_PERCENT);
  });
});
