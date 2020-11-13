const { expect } = require('chai');
const ethers = require('ethers');
const hre = require('hardhat').ethers;
const { deployments } = require('hardhat');
const elasticGovernanceTokenArtifact = require('../artifacts/src/tokens/ElasticGovernanceToken.sol/ElasticGovernanceToken.json');

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
    [agent, summoner, summoner1, summoner2] = await hre.getSigners();

    await deployments.fixture();

    // setup needed contracts
    Ecosystem = await deployments.get('Ecosystem');
    Token = await deployments.get('Token');

    const { deploy } = deployments;

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
  });

  it('Should allow a token to be initialized', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, agent);

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

  it('Should not allow a token to be initialized if not the deployer', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);

    await expect(
      elasticDAO.initializeToken(
        'Elastic Governance Token',
        'EGT',
        ONE_TENTH,
        TWO_HUNDREDTHS,
        ONE_HUNDRED,
        ethers.constants.WeiPerEther,
      ),
    ).to.be.revertedWith('ElasticDAO: Only deployer can initialize the Token');
  });

  it('Should not allow the DAO to be summoned before it has been seeded', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, agent);

    await elasticDAO.initializeToken(
      'Elastic Governance Token',
      'EGT',
      ONE_TENTH,
      TWO_HUNDREDTHS,
      ONE_HUNDRED,
      ethers.constants.WeiPerEther,
    );

    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);

    tokenStorage = new ethers.Contract(Token.address, Token.abi, summoner);
    const ecosystem = await elasticDAO.getEcosystem();
    const token = await tokenStorage.deserialize(ecosystem.governanceTokenAddress, ecosystem);

    await expect(elasticDAO.summon(token.maxLambdaPurchase)).to.be.revertedWith(
      'ElasticDAO: Please seed DAO with ETH to set ETH:EGT ratio',
    );
  });

  it('Should allow summoners to seed', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, agent);

    await elasticDAO.initializeToken(
      'Elastic Governance Token',
      'EGT',
      ONE_TENTH, // capitalDelta
      TWO_HUNDREDTHS, // elasticity
      ONE_HUNDRED, // k
      ethers.constants.WeiPerEther, // lambda
    );

    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);

    const ecosystem = await elasticDAO.getEcosystem();

    const tokenContract = new ethers.Contract(
      ecosystem.governanceTokenAddress,
      elasticGovernanceTokenArtifact.abi,
      hre.provider,
    );

    await elasticDAO.seedSummoning({ value: ethers.constants.WeiPerEther });

    const balance = await hre.provider.getBalance(ElasticDAO.address);
    expect(balance).to.equal(ethers.constants.WeiPerEther);
    /// signers token balance is correct
    expect(await tokenContract.balanceOf(summoner.address)).to.equal(TEN);
    /// get balance at block
    await hre.provider.send('evm_mine');
    const blockNumber = await hre.provider.getBlockNumber();
    await tokenContract.balanceOfAt(summoner.address, blockNumber);

    expect(await tokenContract.balanceOfAt(summoner.address, blockNumber)).to.equal(TEN);
  });

  it('Should not allow summoners to seed before token has been initialized', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);

    await expect(
      elasticDAO.seedSummoning({ value: ethers.constants.WeiPerEther }),
    ).to.be.revertedWith('ElasticDAO: Please call initializeToken first');
  });

  it('Should not allow non summoners to seed', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, agent);

    await elasticDAO.initializeToken(
      'Elastic Governance Token',
      'EGT',
      ONE_TENTH, // capitalDelta
      TWO_HUNDREDTHS, // elasticity
      ONE_HUNDRED, // k
      ethers.constants.WeiPerEther, // lambda
    );

    await expect(
      elasticDAO.seedSummoning({ value: ethers.constants.WeiPerEther }),
    ).to.be.revertedWith('ElasticDAO: Only summoners');
  });

  it('Should not allow the DAO to be summoned by a non-summoner', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, agent);
    const elasticDAOSummoner = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);

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
    const token = await tokenStorage.deserialize(ecosystem.governanceTokenAddress, ecosystem);

    await elasticDAOSummoner.seedSummoning({ value: ethers.constants.WeiPerEther });

    await expect(elasticDAO.summon(token.maxLambdaPurchase)).to.be.revertedWith(
      'ElasticDAO: Only summoners',
    );
  });

  it('Should allow the DAO to be summoned after it has been seeded', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, agent);

    await elasticDAO.initializeToken(
      'Elastic Governance Token',
      'EGT',
      ONE_TENTH,
      TWO_HUNDREDTHS,
      ONE_HUNDRED,
      ethers.constants.WeiPerEther,
    );

    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);
    tokenStorage = new ethers.Contract(Token.address, Token.abi, summoner);
    const ecosystem = await elasticDAO.getEcosystem();
    const token = await tokenStorage.deserialize(ecosystem.governanceTokenAddress, ecosystem);

    await elasticDAO.seedSummoning({ value: ethers.constants.WeiPerEther });
    await elasticDAO.summon(token.maxLambdaPurchase);

    const dao = await elasticDAO.getDAO();
    expect(dao.summoned).to.equal(true);

    const tokenContract = new ethers.Contract(
      ecosystem.governanceTokenAddress,
      elasticGovernanceTokenArtifact.abi,
      hre.provider,
    );
    const summoner0balance = await tokenContract.balanceOf(summoner.address);
    const summoner1balance = await tokenContract.balanceOf(summoner1.address);
    const summoner2balance = await tokenContract.balanceOf(summoner2.address);
    expect(summoner0balance).to.equal(ONE_HUNDRED_TEN);
    expect(summoner1balance).to.equal(ONE_HUNDRED);
    expect(summoner2balance).to.equal(ONE_HUNDRED);
  });

  it('Should not allow a token to be initialized after summoning', async () => {
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, agent);

    await elasticDAO.initializeToken(
      'Elastic Governance Token',
      'EGT',
      ONE_TENTH,
      TWO_HUNDREDTHS,
      ONE_HUNDRED,
      ethers.constants.WeiPerEther,
    );

    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);
    tokenStorage = new ethers.Contract(Token.address, Token.abi, summoner);
    const ecosystem = await elasticDAO.getEcosystem();
    const token = await tokenStorage.deserialize(ecosystem.governanceTokenAddress, ecosystem);

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
