const { expect } = require('chai');
const { deployments } = require('hardhat');

const { capitalDelta, deltaE, mDash } = require('@elastic-dao/sdk');
const BigNumber = require('bignumber.js');
const { ONE } = require('./constants');

const { ethBalance, signers, summonedDAO } = require('./helpers');

describe('ElasticDAO: CapitalDelta value of a token', () => {
  let dao;
  let token;

  it('Should return a mismatch in the values of capital delta', async () => {
    await deployments.fixture();
    dao = await summonedDAO();
    token = await dao.token();

    const { agent } = await signers();

    // get the eth balance of elasticDAO
    const ethBalanceElasticDAO = await ethBalance(dao.uuid);

    // sending a random amount of new ETH to throw the numbers off
    await agent.sendTransaction({ to: dao.uuid, value: ONE });

    // get the T value of the token
    const totalSupplyOfToken = await dao.elasticGovernanceToken.totalSupply();

    // calculate capital Delta
    const cDelta = capitalDelta(ethBalanceElasticDAO, totalSupplyOfToken);

    // calculate deltaE using capital Delta to buy ONE_TENTH shares
    // deltaE = capitalDelta * k  * ( (lambdaDash*mDash*revamp) - (lambda*m) )
    const dE = deltaE(0.1, cDelta, token.k, token.elasticity, token.lambda, token.m);

    // send that value of deltaE to joinDAO to buy ONE_TENTH shares
    const tx = dao.elasticDAO.join(0.1, { value: dE });

    // transaction reverts with 'ElasticDAO: Incorrect ETH amount'
    await expect(tx).to.be.revertedWith('ElasticDAO: Incorrect ETH amount');
  });

  it('Should return a match in the values of capital delta', async () => {
    dao = await summonedDAO();
    token = await dao.token();
    // get the eth balance of elasticDAO
    const ethBalanceElasticDAOBeforeJoin = await ethBalance(dao.uuid);

    // get the T value of the token
    const totalSupplyOfToken = await dao.elasticGovernanceToken.totalSupply();

    // calculate capital Delta
    const cDelta = capitalDelta(ethBalanceElasticDAOBeforeJoin, totalSupplyOfToken);

    // calculate deltaE using capital Delta to buy ONE_TENTH shares
    // deltaE = capitalDelta * k  * ( (lambdaDash*mDash*revamp) - (lambda*m) )
    const deltaLambda = BigNumber(0.1);
    const lambdaDash = token.lambda.plus(deltaLambda);
    const dE = deltaE(deltaLambda, cDelta, token.k, token.elasticity, token.lambda, token.m);
    const mD = mDash(lambdaDash, token.lambda, token.m);

    // send that value of deltaE to joinDAO to buy ONE_TENTH shares
    await dao.elasticDAO.join(deltaLambda, { value: dE });
    await token.refresh();

    // post join check the following values:
    // check the m value- after join,previous mDash should be current m
    await expect(token.m.toString()).to.equal(mD.toString());
    await expect(token.lambda.toString()).to.equal(lambdaDash.toString());

    // check the the total eth - which should be initial eth, plus delta e
    const ethBalanceElasticDAOAfterJoin = await ethBalance(dao.uuid);

    const expectedEthInElasticDAOAfterJoin = ethBalanceElasticDAOBeforeJoin.plus(dE);
    await expect(ethBalanceElasticDAOAfterJoin.toString()).to.equal(
      expectedEthInElasticDAOAfterJoin.toString(),
    );
  });
});
