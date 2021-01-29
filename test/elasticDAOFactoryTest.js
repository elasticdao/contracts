const { ethers } = require('ethers');
const { expect } = require('chai');
const { newDAO } = require('./helpers');

describe('ElasticDAO: Factory', () => {
  it('Should allow a DAO to be deployed using the factory', async () => {
    const dao = await newDAO();
    expect(dao.uuid).to.not.equal(ethers.constants.AddressZero);
    expect(dao.ecosystem.governanceTokenAddress).to.not.equal(ethers.constants.AddressZero);
  });
});
