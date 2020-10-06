const { expect } = require('chai');
const ethers = require('ethers');
const bre = require('@nomiclabs/buidler').ethers;
const { deployments } = require('@nomiclabs/buidler');
const elasticGovernanceTokenArtifact = require('../artifacts/ElasticGovernanceToken.json');

const ONE_HUNDRED = ethers.BigNumber.from('100000000000000000000');
const ONE_HUNDRED_TEN = ethers.BigNumber.from('110000000000000000000');
const ONE_TENTH = ethers.BigNumber.from('100000000000000000');
const TEN = ethers.BigNumber.from('10000000000000000000');
const TWO_HUNDREDTHS = ethers.BigNumber.from('20000000000000000');

describe('ElasticDAO: Core', () => {
  let agent;
  let Ecosystem;
  let elasticDAO;
  let ElasticDAO;
  let summoner;
  let summoner1;
  let summoner2;
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
        ONE_TENTH,
        TWO_HUNDREDTHS,
        ONE_HUNDRED,
        ethers.constants.WeiPerEther,
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
        ONE_TENTH,
        TWO_HUNDREDTHS,
        ONE_HUNDRED,
        ethers.constants.WeiPerEther,
      ),
    ).to.be.revertedWith('ElasticDAO: Only summoners');
  });

  it('Should not allow the DAO to be summoned before it has been seeded', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);

    await elasticDAO.initializeToken(
      'Elastic Governance Token',
      'EGT',
      ONE_TENTH,
      TWO_HUNDREDTHS,
      ONE_HUNDRED,
      ethers.constants.WeiPerEther,
    );

    tokenStorage = new ethers.Contract(Token.address, Token.abi, summoner);
    const ecosystem = await elasticDAO.getEcosystem();
    const token = await tokenStorage.deserialize(ecosystem.governanceTokenAddress);

    await expect(elasticDAO.summon(token.maxLambdaPurchase)).to.be.revertedWith(
      'ElasticDAO: Please seed DAO with ETH to set ETH:EGT ratio',
    );
  });

  it('Should allow summoners to seed', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);

    await elasticDAO.initializeToken(
      'Elastic Governance Token',
      'EGT',
      ONE_TENTH, // capitalDelta
      TWO_HUNDREDTHS, // elasticity
      ONE_HUNDRED, // k
      ethers.constants.WeiPerEther, // lambda
    );

    const ecosystem = await elasticDAO.getEcosystem();

    const tokenContract = new ethers.Contract(
      ecosystem.governanceTokenAddress,
      elasticGovernanceTokenArtifact.abi,
      bre.provider,
    );

    await elasticDAO.seedSummoning({ value: ethers.constants.WeiPerEther });

    const balance = await bre.provider.getBalance(ElasticDAO.address);
    expect(balance).to.equal(ethers.constants.WeiPerEther);
    /// signers token balance is correct
    expect(await tokenContract.balanceOf(summoner._address)).to.equal(TEN);
    /// get balance at block
    const blockNumber = await bre.provider.getBlockNumber();
    expect(await tokenContract.balanceOfAt(summoner._address, blockNumber)).to.equal(TEN);
  });

  it('Should not allow summoners to seed before token has been initialized', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);

    await expect(
      elasticDAO.seedSummoning({ value: ethers.constants.WeiPerEther }),
    ).to.be.revertedWith('ElasticDAO: Please call initializeToken first');
  });

  it('Should not allow non summoners to seed', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);
    const elasticDAONonSummoner = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, agent);

    await elasticDAO.initializeToken(
      'Elastic Governance Token',
      'EGT',
      ONE_TENTH, // capitalDelta
      TWO_HUNDREDTHS, // elasticity
      ONE_HUNDRED, // k
      ethers.constants.WeiPerEther, // lambda
    );

    await expect(
      elasticDAONonSummoner.seedSummoning({ value: ethers.constants.WeiPerEther }),
    ).to.be.revertedWith('ElasticDAO: Only summoners');
  });

  it('Should not allow the DAO to be summoned by a non-summoner', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);
    const elasticDAONonSummoner = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, agent);

    await elasticDAO.initializeToken(
      'Elastic Governance Token',
      'EGT',
      ONE_TENTH,
      TWO_HUNDREDTHS,
      ONE_HUNDRED,
      ethers.constants.WeiPerEther,
    );

    tokenStorage = new ethers.Contract(Token.address, Token.abi, summoner);
    const ecosystem = await elasticDAO.getEcosystem();
    const token = await tokenStorage.deserialize(ecosystem.governanceTokenAddress);

    await elasticDAO.seedSummoning({ value: ethers.constants.WeiPerEther });

    await expect(elasticDAONonSummoner.summon(token.maxLambdaPurchase)).to.be.revertedWith(
      'ElasticDAO: Only summoners',
    );
  });

  it('Should allow the DAO to be summoned after it has been seeded', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);

    await elasticDAO.initializeToken(
      'Elastic Governance Token',
      'EGT',
      ONE_TENTH,
      TWO_HUNDREDTHS,
      ONE_HUNDRED,
      ethers.constants.WeiPerEther,
    );

    tokenStorage = new ethers.Contract(Token.address, Token.abi, summoner);
    const ecosystem = await elasticDAO.getEcosystem();
    const token = await tokenStorage.deserialize(ecosystem.governanceTokenAddress);

    await elasticDAO.seedSummoning({ value: ethers.constants.WeiPerEther });
    await elasticDAO.summon(token.maxLambdaPurchase);

    const dao = await elasticDAO.getDAO();
    expect(dao.summoned).to.equal(true);

    const tokenContract = new ethers.Contract(
      ecosystem.governanceTokenAddress,
      elasticGovernanceTokenArtifact.abi,
      bre.provider,
    );
    const summoner0balance = await tokenContract.balanceOf(summoner._address);
    const summoner1balance = await tokenContract.balanceOf(summoner1._address);
    const summoner2balance = await tokenContract.balanceOf(summoner2._address);
    expect(summoner0balance).to.equal(ONE_HUNDRED_TEN);
    expect(summoner1balance).to.equal(ONE_HUNDRED);
    expect(summoner2balance).to.equal(ONE_HUNDRED);
  });

  it('Should not allow a token to be initialized after summoning', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);

    await elasticDAO.initializeToken(
      'Elastic Governance Token',
      'EGT',
      ONE_TENTH,
      TWO_HUNDREDTHS,
      ONE_HUNDRED,
      ethers.constants.WeiPerEther,
    );

    tokenStorage = new ethers.Contract(Token.address, Token.abi, summoner);
    const ecosystem = await elasticDAO.getEcosystem();
    const token = await tokenStorage.deserialize(ecosystem.governanceTokenAddress);

    await elasticDAO.seedSummoning({ value: ethers.constants.WeiPerEther });
    await elasticDAO.summon(token.maxLambdaPurchase);

    await expect(
      elasticDAO.initializeToken(
        'Elastic Governance Token',
        'EGT',
        ONE_TENTH,
        TWO_HUNDREDTHS,
        ONE_HUNDRED,
        ethers.constants.WeiPerEther,
      ),
    ).to.be.revertedWith('ElasticDAO: DAO must not be summoned');
  });
});
