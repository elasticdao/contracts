const { expect } = require('chai');
const { signers, summonedDAO } = require('./helpers');

describe('ElasticDAO: Exit', () => {
  it('Should allow to exit with 1 share and corresponding eth', async () => {
    const dao = await summonedDAO();
    const { summoner1 } = await signers();

    const postSummonBalanceOf = await dao.elasticGovernanceToken.balanceOf(summoner1.address);

    expect(postSummonBalanceOf.toNumber()).to.equal(1010);

    await dao.elasticDAO.exit(1);

    const atExitBalanceRecord = await dao.elasticGovernanceToken.balanceOf(summoner1.address);
    expect(atExitBalanceRecord.toNumber()).to.equal(910);
  });
});
