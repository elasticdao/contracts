const { expect } = require('chai');
const ethers = require('ethers');
const bre = require('@nomiclabs/buidler').ethers;
const { deployments } = require('@nomiclabs/buidler');

// [
//   ethers.BigNumber.from('100000000000000000000'), // k
//   ethers.BigNumber.from('100000000000000000'), // capitalDelta
//   ethers.BigNumber.from('20000000000000000'), // elasticity
//   ethers.BigNumber.from('1000000000000000000'), // initialShares
//   ethers.BigNumber.from('600000000000000000'), // approval
//   ethers.BigNumber.from('1000000000000000000'), // maxLambdaPurchase
//   ethers.BigNumber.from('120'), // contractVoteTypeMinBlocks
//   ethers.BigNumber.from('180'), // financeVoteTypeMinBlocks
//   ethers.BigNumber.from('60'), // informationVoteTypeMinBlocks
//   ethers.BigNumber.from('240'), // minBlocksForPenalty
//   ethers.BigNumber.from('90'), // permissionVoteTypeMinBlocks
//   ethers.BigNumber.from('1000000000000000000'), // minSharesToCreate
//   ethers.BigNumber.from('50000000000000000'), // penalty
//   ethers.BigNumber.from('500000000000000000'), // quorum
//   ethers.BigNumber.from('100000000000000000'), // reward
// ]

describe('ElasticDAO: Core', () => {
  let agent;
  let summoner;
  let summoner1;
  let summoner2;
  let Ecosystem;
  let ElasticDAO;
  let elasticDAO;

  beforeEach(async () => {
    [agent, summoner, summoner1, summoner2] = await bre.getSigners();
    const { deploy } = deployments;

    await deployments.fixture();

    // setup needed contracts
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
  });

  it('Should allow a token to be initialized', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);

    await elasticDAO
      .initializeToken(
        'Elastic Governance Token',
        'EGT',
        ethers.BigNumber.from('100000000000000000'),
        ethers.BigNumber.from('20000000000000000'),
        ethers.BigNumber.from('100000000000000000000'),
        ethers.BigNumber.from('1000000000000000000'),
      )
      .catch((error) => {
        console.log(error);
      });

    let ecosystem = await elasticDAO.getEcosystem();

    expect(ecosystem.governanceTokenAddress).to.not.equal(ethers.constants.AddressZero);
  });

  it('Should create a new ElasticGovernanceToken contract when token is initialized', async () => {});

  it('Should not allow a token to be initialized after summoning', async () => {});

  it('Should allow summoners to seed', async () => {});

  it('Should mint an appropriate number of tokens to the seeding summoner', async () => {});

  it('Should not allow non summoners to seed', async () => {});

  it('Should allow the dao to be summoned after it has been seeded', async () => {});

  it('Should not allow the dao to be summoned before it has been seeded', async () => {});

  it('Should mint tokens to all summoner token balances based on deltaLambda', async () => {});
});
