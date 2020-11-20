const BigNumber = require('bignumber.js');
const { expect } = require('chai');
const ethers = require('ethers');
const hre = require('hardhat').ethers;
const { deployments } = require('hardhat');
const elasticGovernanceTokenArtifact = require('../artifacts/src/tokens/ElasticGovernanceToken.sol/ElasticGovernanceToken.json');

const ONE = ethers.BigNumber.from('1000000000000000000');
const ONE_TENTH = ethers.BigNumber.from('100000000000000000');
const TWO_HUNDREDTHS = ethers.BigNumber.from('20000000000000000');

describe('ElasticDAO: CapitalDelta value of a token', () => {
  let agent;
  let Ecosystem;
  let ElasticDAO;
  let elasticDAO;
  let TokenModel;
  let tokenModel;
  let summoner;
  let summoner1;
  let summoner2;

  beforeEach(async () => {
    [agent, summoner, summoner1, summoner2] = await hre.getSigners();
    await deployments.fixture();

    // required contracts
    Ecosystem = await deployments.get('Ecosystem');

    const { deploy } = deployments;
    await deployments.fixture();

    TokenModel = await deployments.get('Token');
    tokenModel = new ethers.Contract(TokenModel.address, TokenModel.abi, summoner);

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

    // can use .connect method too
    elasticDAO = new ethers.Contract(ElasticDAO.address, ElasticDAO.abi, summoner);

    await elasticDAO.seedSummoning({
      value: ONE,
    });

    await elasticDAO.summon(ONE_TENTH);
  });

  it('Should return a mismatch in the values of capital delta', async () => {
    const ecosystem = await elasticDAO.getEcosystem();
    // summoner is sending, but here any random address would do too

    await summoner.sendTransaction({
      to: ElasticDAO.address,
      value: ONE,
    });

    const tokenInstance = await tokenModel.deserialize(ecosystem.governanceTokenAddress, ecosystem);

    const tokenInstanceContract = new ethers.Contract(
      tokenInstance.uuid,
      elasticGovernanceTokenArtifact.abi,
      summoner,
    );

    // get the eth balance of elasticDAO
    const ethBalanceElasticDAO = await hre.provider.getBalance(elasticDAO.address);

    // get the T value of the token
    const totalSupplyOfToken = await tokenInstanceContract.totalSupply();

    // calculate capital Delta
    const capitalDelta = BigNumber(ethBalanceElasticDAO.toString()).dividedBy(
      totalSupplyOfToken.toString(),
    );

    // calculate deltaE using capital Delta to buy ONE_TENTH shares
    // deltaE = capitalDelta * k  * ( (lambdaDash*mDash*revamp) - (lambda*m) )
    const elasticity = BigNumber(tokenInstance.elasticity.toString()).dividedBy(10 ** 18);
    const k = BigNumber(tokenInstance.k.toString()).dividedBy(10 ** 18);
    const lambda = BigNumber(tokenInstance.lambda.toString()).dividedBy(10 ** 18);
    const m = BigNumber(tokenInstance.m.toString()).dividedBy(10 ** 18);
    const lambdaDash = lambda.plus(0.1);
    const revamp = elasticity.plus(1);
    const mDash = m.multipliedBy(lambdaDash.dividedBy(lambda));
    const a = lambdaDash.multipliedBy(mDash).multipliedBy(revamp);
    const b = lambda.multipliedBy(m);
    const c = a.minus(b);
    const deltaE = capitalDelta.multipliedBy(k).multipliedBy(c);
    const eByl = BigNumber(tokenInstance.eByl.toString()).dividedBy(10 ** 18);

    console.log('test: elasticity: ', elasticity.toString());
    console.log('test: k: ', k.toString());
    console.log('test: lambda: ', lambda.toString());
    console.log('test: m: ', m.toString());
    console.log('test: lambdaDash: ', lambdaDash.toString());
    console.log('test: revamp: ', revamp.toString());
    console.log('test: mDash: ', mDash.toString());
    console.log('test: a: ', a.toString());
    console.log('test: b: ', b.toString());
    console.log('test: c: ', c.toString());
    console.log('test: ethBalanceElasticDAO:', ethBalanceElasticDAO.toString());
    console.log('test: totalSupplyOfToken:', totalSupplyOfToken.toString());
    console.log('test: CapitalDelta: ', capitalDelta.toString());
    console.log('test: deltaE: ', deltaE.toString());
    console.log('test: ebyl: ', eByl.toString());

    // send that value of deltaE to joinDAO to buy ONE_TENTH shares
    const value = deltaE.multipliedBy(10 ** 18).toFixed(0);
    console.log('Value: ', value);
    const tx = elasticDAO.join(ONE_TENTH, {
      value,
    });

    // transaction reverts with 'ElasticDAO: Incorrect ETH amount'
    await expect(tx).to.be.revertedWith('ElasticDAO: Incorrect ETH amount');
  });

  it.only('Should return a match in the values of capital delta', async () => {
    const ecosystem = await elasticDAO.getEcosystem();
    // summoner is sending, but here any random address would do too

    const tokenInstance = await tokenModel.deserialize(ecosystem.governanceTokenAddress, ecosystem);

    const tokenInstanceContract = new ethers.Contract(
      tokenInstance.uuid,
      elasticGovernanceTokenArtifact.abi,
      summoner,
    );

    // get the eth balance of elasticDAO
    const ethBalanceElasticDAOBeforeJoin = await hre.provider.getBalance(elasticDAO.address);

    // get the T value of the token
    const totalSupplyOfToken = await tokenInstanceContract.totalSupply();
    console.log('ethBalanceElasticDAO:', ethBalanceElasticDAOBeforeJoin.toString());
    console.log('totalSupplyOfToken:', totalSupplyOfToken.toString());

    // calculate capital Delta
    const capitalDelta = BigNumber(ethBalanceElasticDAOBeforeJoin.toString()).dividedBy(
      totalSupplyOfToken.toString(),
    );
    console.log('CapitalDelta: ', capitalDelta.toString());

    // calculate deltaE using capital Delta to buy ONE_TENTH shares
    // deltaE = capitalDelta * k  * ( (lambdaDash*mDash*revamp) - (lambda*m) )
    const elasticity = BigNumber(tokenInstance.elasticity.toString()).dividedBy(10 ** 18);
    const k = BigNumber(tokenInstance.k.toString()).dividedBy(10 ** 18);
    const lambda = BigNumber(tokenInstance.lambda.toString()).dividedBy(10 ** 18);
    const m = BigNumber(tokenInstance.m.toString()).dividedBy(10 ** 18);
    const lambdaDash = lambda.plus(0.1);
    const revamp = elasticity.plus(1);
    const mDash = m.multipliedBy(lambdaDash.dividedBy(lambda));
    const a = lambdaDash.multipliedBy(mDash).multipliedBy(revamp);
    const b = lambda.multipliedBy(m);
    const c = a.minus(b);
    const deltaE = capitalDelta.multipliedBy(k).multipliedBy(c);

    console.log('test: deltaE: ', deltaE.toString());
    console.log('test: elasticity: ', elasticity.toString());
    console.log('test: k: ', k.toString());
    console.log('test: lambda: ', lambda.toString());
    console.log('test: m: ', m.toString());
    console.log('test: lambdaDash: ', lambdaDash.toString());
    console.log('test: revamp: ', revamp.toString());
    console.log('test: mDash: ', mDash.toString());
    console.log('test: a: ', a.toString());
    console.log('test: b: ', b.toString());
    console.log('test: c: ', c.toString());
    console.log('test: ONE_TENTH: ', ONE_TENTH.toString());

    // send that value of deltaE to joinDAO to buy ONE_TENTH shares
    const value = deltaE.multipliedBy(10 ** 18).toFixed(0);
    console.log('Value: ', value);
    await elasticDAO.join(ONE_TENTH, {
      value,
    });

    // post join check the following values:
    // check the m value- after join,previous mDash should be current m

    const tokenInstanceAfterJoin = await tokenModel.deserialize(
      ecosystem.governanceTokenAddress,
      ecosystem,
    );
    console.log(
      'mAfterJoin',
      BigNumber(tokenInstanceAfterJoin.m.toString())
        .dividedBy(10 ** 18)
        .toString(),
    );
    console.log('mDash: ', mDash.toString());

    console.log(
      'lambdaAfterJoin',
      BigNumber(tokenInstanceAfterJoin.lambda.toString())
        .dividedBy(10 ** 18)
        .toString(),
    );
    console.log('lambdaDash: ', lambdaDash.toString());

    // const m = BigNumber(tokenInstance.m.toString()).dividedBy(10 ** 18);
    const mAfterJoin = BigNumber(tokenInstanceAfterJoin.m.toString()).dividedBy(10 ** 18);
    await expect(mAfterJoin).to.equal(mDash);

    console.log('check');

    // check the lambda value- after join,previous lambdaDash should be current lambda
    const lambdaAfterJoin = BigNumber(tokenInstanceAfterJoin.lambda.toString()).dividedBy(10 ** 18);
    await expect(lambdaAfterJoin).to.equal(lambdaDash);

    // check the the total eth - which should be initial eth, plus delta e
    const ethBalanceElasticDAOAfterJoin = await hre.provider.getBalance(elasticDAO.address);
    const expectedEthInElasticDAOAfterJoin = deltaE.plus(ethBalanceElasticDAOBeforeJoin);
    await expect(ethBalanceElasticDAOAfterJoin).to.equal(expectedEthInElasticDAOAfterJoin);
  });
});
