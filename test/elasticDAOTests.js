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
  let Token;
  let tokenStorage;

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
    Token = await deployments.get('Token');
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

    const ecosystem = await elasticDAO.getEcosystem();

    expect(ecosystem.governanceTokenAddress).to.not.equal(ethers.constants.AddressZero);
  });

  it('Should not allow a token to be initialized if not a summoner', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, agent);

    await expect(
      elasticDAO.initializeToken(
        'Elastic Governance Token',
        'EGT',
        ethers.BigNumber.from('100000000000000000'),
        ethers.BigNumber.from('20000000000000000'),
        ethers.BigNumber.from('100000000000000000000'),
        ethers.BigNumber.from('1000000000000000000'),
      ),
    ).to.be.revertedWith('ElasticDAO: Only summoners');
  });

  it('Should not allow the DAO to be summoned before it has been seeded', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);

    await elasticDAO.initializeToken(
      'Elastic Governance Token',
      'EGT',
      ethers.BigNumber.from('100000000000000000'),
      ethers.BigNumber.from('20000000000000000'),
      ethers.BigNumber.from('100000000000000000000'),
      ethers.BigNumber.from('1000000000000000000'),
    );

    tokenStorage = new ethers.Contract(Token.address, Token.abi, summoner);
    const ecosystem = await elasticDAO.getEcosystem();
    const token = await tokenStorage.deserialize(ecosystem.governanceTokenAddress);

    await expect(elasticDAO.summon(token.maxLambdaPurchase)).to.be.revertedWith(
      'ElasticDAO: Please seed DAO with ETH to set ETH:EGT ratio',
    );
  });

  it.only('Should allow summoners to seed', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);

    await elasticDAO.initializeToken(
      'Elastic Governance Token',
      'EGT',
      ethers.BigNumber.from('100000000000000000'), // capitalDelta
      ethers.BigNumber.from('20000000000000000'), // elasticity
      ethers.BigNumber.from('100000000000000000000'), // k
      ethers.BigNumber.from('1000000000000000000'), // lambda
    );

    await elasticDAO.seedSummoning({ value: ethers.constants.WeiPerEther });

    expect(await elasticDAO.balance).to.equal(ethers.constants.WeiPerEther);
  });

  it('Should not allow summoners to seed before token has been initialized', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);

    await expect(elasticDAO.seedSummoning({ value: ethers.constants.One })).to.be.revertedWith(
      'ElasticDAO: Please call initializeToken first.',
    );
  });

  it('Should not allow the DAO to be summoned by a non-summoner', async () => {
    // tokenStorage = new ethers.Contract(Token.address, Token.abi, agent);
  });

  it('Should not allow non summoners to seed', async () => {});

  it('Should allow the DAO to be summoned after it has been seeded', async () => {});

  it('Should not allow a token to be initialized after summoning', async () => {});

  it('Should mint an appropriate number of tokens to the seeding summoner', async () => {});

  it('Should mint tokens to all summoner token balances based on deltaLambda', async () => {});
});
