const { ethers } = require('ethers');
const { expect } = require('chai');

const { newDAO, signers, summonedDAO } = require('./helpers');

describe('ElasticDAO: Factory', () => {
  it('Should allow a DAO to be deployed using the factory', async () => {
    const dao = await newDAO();
    expect(dao.uuid).to.not.equal(ethers.constants.AddressZero);
    expect(dao.ecosystem.governanceTokenAddress).to.not.equal(ethers.constants.AddressZero);
  });

  it('Should updateFeeAddress', async () => {
    const dao = await summonedDAO();
    const { agent, summoner2 } = await signers();

    dao.sdk.changeSigner(agent);

    const tx = await dao.sdk.elasticDAOFactory.updateFeeAddress(summoner2.address);
    const logs = await tx.wait(1);

    expect(logs.events[0].event).to.equal('FeeAddressUpdated');
    expect(logs.events[0].args.feeReceiver).to.equal(summoner2.address);
  });

  it('Should not updateFeeAddress when caller is not deployer', async () => {
    const dao = await summonedDAO();
    const { summoner2 } = await signers();

    dao.sdk.changeSigner(summoner2);

    await expect(dao.sdk.elasticDAOFactory.updateFeeAddress(summoner2.address)).to.be.revertedWith(
      'ElasticDAO: Only deployer',
    );
  });

  it('Should collectFees to the feeAddress', async () => {
    const dao = await summonedDAO();
    const { agent } = await signers();

    dao.sdk.changeSigner(agent);

    await dao.sdk.elasticDAOFactory.updateFeeAddress(agent.address);

    const feeAmountToCollect = await agent.provider.getBalance(dao.sdk.elasticDAOFactory.address);

    const tx = await dao.sdk.elasticDAOFactory.collectFees();
    const logs = await tx.wait(1);

    expect(logs.events[0].event).to.equal('FeesCollected');
    expect(logs.events[0].args.treasuryAddress).to.equal(agent.address);
    expect(logs.events[0].args.amount).to.equal(feeAmountToCollect);
  });
});
