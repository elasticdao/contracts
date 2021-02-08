const { expect } = require('chai');

const { signers, summonedDAO } = require('./helpers');

describe('ElasticDAO: TokenHolder Model', () => {
  it('Should check to see if a token holder record exists by account address', async () => {
    const dao = await summonedDAO();
    const { summoner1 } = await signers();
    const { TokenHolder } = dao.sdk.models;
    const token = await dao.token();

    const recordExists = await TokenHolder.exists(summoner1.address, token);
    expect(recordExists).to.equal(true);
  });
});
