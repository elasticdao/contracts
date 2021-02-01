const { expect } = require('chai');
// const { ethers } = require('ethers');

const { signers, summonedDAO } = require('./helpers');

describe('ElasticDAO: Elastic Governance Token', () => {
  let dao;

  beforeEach(async () => {
    dao = await summonedDAO();
  });

  it('Should approve 1 EGT and check the allowance', async () => {
    const { summoner1, summoner2 } = await signers();
    await dao.elasticGovernanceToken.approve(summoner2.address, 1);

    const allowance = await dao.elasticGovernanceToken.allowance(
      summoner1.address,
      summoner2.address,
    );

    expect(allowance.toFixed()).to.equal('1');
  });
  it('Should get balance of votable shares for user', async () => {
    const { summoner1 } = await signers();
    const balanceOfVoting = await dao.elasticGovernanceToken.balanceOfVoting(summoner1.address);
    expect(balanceOfVoting.toFixed()).to.equal('100');
  });
  it('Should get token decimals', async () => {
    const decimals = await dao.elasticGovernanceToken.decimals();

    expect(decimals).to.equal('18');
  });
  it('Should increase allowance', async () => {
    const { summoner1, summoner2 } = await signers();
    await dao.elasticGovernanceToken.increaseAllowance(summoner2.address, '1000000000000000000');

    const allowance = await dao.elasticGovernanceToken.allowance(
      summoner1.address,
      summoner2.address,
    );

    expect(allowance.toFixed()).to.equal('1');
  });
  it('Should decrease allowance', async () => {
    const { summoner1, summoner2 } = await signers();
    await dao.elasticGovernanceToken.increaseAllowance(summoner2.address, '2000000000000000000');
    await dao.elasticGovernanceToken.decreaseAllowance(summoner2.address, '1000000000000000000');

    const allowance = await dao.elasticGovernanceToken.allowance(
      summoner1.address,
      summoner2.address,
    );

    expect(allowance.toFixed()).to.equal('1');
  });
  it('Should mint tokens', async () => {
    const { agent, summoner1 } = await signers();
    dao.sdk.changeSigner(agent);

    await dao.elasticGovernanceToken.mint(summoner1.address, 1);
    const balance = await dao.elasticGovernanceToken.balanceOf(summoner1.address);
    expect(balance.toFixed()).to.equal('1011');
  });
  it('Should burn tokens', async () => {
    const { agent, summoner1 } = await signers();

    dao.sdk.changeSigner(agent);

    await dao.elasticGovernanceToken.burn(summoner1.address, 1);
    const balance = await dao.elasticGovernanceToken.balanceOf(summoner1.address);

    expect(balance.toFixed()).to.equal('1009');
  });
  it('Should get token name', async () => {
    const name = await dao.elasticGovernanceToken.name();

    expect(name).to.equal('Elastic Governance Token');
  });
  it('Should get token symbol', async () => {
    const name = await dao.elasticGovernanceToken.symbol();

    expect(name).to.equal('EGT');
  });
  it('Should get number of token holders', async () => {
    const numberOfTokenHolders = await dao.elasticGovernanceToken.numberOfTokenHolders();

    expect(numberOfTokenHolders).to.equal('3');
  });
  it('Should get total supply in shares', async () => {
    const totalSupplyInShares = await dao.elasticGovernanceToken.totalSupplyInShares();

    expect(totalSupplyInShares.toFixed()).to.equal('10.3');
  });
  it('should transfer tokens a to b', async () => {
    const { summoner2 } = await signers();

    let balance = await dao.elasticGovernanceToken.balanceOf(summoner2.address);
    expect(balance.toFixed()).to.equal('10');

    await dao.elasticGovernanceToken.transfer(summoner2.address, 1);

    balance = await dao.elasticGovernanceToken.balanceOf(summoner2.address);
    expect(balance.toFixed()).to.equal('11');
  });

  it('should transfer tokens on behalf of a to b', async () => {
    const { summoner2, summoner1, agent } = await signers();

    let balance = await dao.elasticGovernanceToken.balanceOf(summoner2.address);
    expect(balance.toFixed()).to.equal('10');

    await dao.elasticGovernanceToken.approve(agent.address, 1);
    dao.sdk.changeSigner(agent);
    await dao.elasticGovernanceToken.transferFrom(summoner1.address, summoner2.address, 1);

    balance = await dao.elasticGovernanceToken.balanceOf(summoner2.address);
    expect(balance.toFixed()).to.equal('11');
  });
});
