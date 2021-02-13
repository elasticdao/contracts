const { ethers } = require('ethers');
const { expect } = require('chai');

const { newDAO, SDK, signers, summoners } = require('./helpers');

describe('ElasticDAO: Factory', () => {
  let sdk;

  beforeEach(async () => {
    sdk = await SDK();
  });

  it('Should allow a DAO to be deployed using the factory', async () => {
    const dao = await newDAO();
    const token = await dao.token();

    expect(token.symbol).to.equal('EGT');
    expect(dao.ecosystem.governanceTokenAddress).to.not.equal(ethers.constants.AddressZero);
  });

  it('Should allow the fee to be updated by the manager', async () => {
    const { agent } = await signers();

    sdk.changeSigner(agent);

    const originalFee = await sdk.elasticDAOFactory.contract.fee();
    const newFee = sdk.elasticDAOFactory.toEthersBigNumber(1, 18);
    const tx = await sdk.elasticDAOFactory.contract.updateFee(newFee);
    const logs = await tx.wait(1);

    expect(logs.events[0].event).to.equal('FeeUpdated');
    expect(logs.events[0].args.amount.toString()).to.equal(newFee.toString());

    await sdk.elasticDAOFactory.contract.updateFee(originalFee);
  });

  it('Should not allow the fee to be updated by a non-manager', async () => {
    const { summoner2 } = await signers();

    sdk.changeSigner(summoner2);

    await expect(sdk.elasticDAOFactory.contract.updateFee(0)).to.be.revertedWith(
      'ElasticDAO: Only manager',
    );
  });

  it('Should not allow the DAO to be deployed without the correct fee', async () => {
    const { agent } = await signers();

    sdk.changeSigner(agent);

    await expect(
      sdk.elasticDAOFactory.contract.deployDAOAndToken(
        await summoners(),
        'Elastic DAO',
        'Elastic Governance Token',
        'EGT',
        sdk.elasticDAOFactory.toEthersBigNumber(0.1, 18),
        sdk.elasticDAOFactory.toEthersBigNumber(0.02, 18),
        sdk.elasticDAOFactory.toEthersBigNumber(100, 18),
        sdk.elasticDAOFactory.toEthersBigNumber(1, 18),
        sdk.elasticDAOFactory.toEthersBigNumber(1, 18),
        { value: 0 },
      ),
    ).to.be.revertedWith('ElasticDAO: A fee is required to deploy a DAO');
  });

  it('Should updateFeeAddress', async () => {
    const { agent, summoner2 } = await signers();

    sdk.changeSigner(agent);

    const tx = await sdk.elasticDAOFactory.contract.updateFeeAddress(summoner2.address);
    const logs = await tx.wait(1);

    expect(logs.events[0].event).to.equal('FeeAddressUpdated');
    expect(logs.events[0].args.feeReceiver).to.equal(summoner2.address);
  });

  it('Should not updateFeeAddress when caller is not the manager', async () => {
    const { summoner2 } = await signers();

    sdk.changeSigner(summoner2);

    await expect(
      sdk.elasticDAOFactory.contract.updateFeeAddress(summoner2.address),
    ).to.be.revertedWith('ElasticDAO: Only manager');
  });

  it('Should updateManager', async () => {
    const { agent, summoner2 } = await signers();

    sdk.changeSigner(agent);

    const tx = await sdk.elasticDAOFactory.contract.updateManager(summoner2.address);
    const logs = await tx.wait(1);

    expect(logs.events[0].event).to.equal('ManagerUpdated');
    expect(logs.events[0].args.newManager).to.equal(summoner2.address);

    sdk.changeSigner(summoner2);

    await sdk.elasticDAOFactory.contract.updateManager(agent.address);
  });

  it('Should not updateManager when caller is not the manager', async () => {
    const { summoner2 } = await signers();

    sdk.changeSigner(summoner2);

    await expect(
      sdk.elasticDAOFactory.contract.updateManager(summoner2.address),
    ).to.be.revertedWith('ElasticDAO: Only manager');
  });

  it('Should collectFees to the feeAddress', async () => {
    const { agent } = await signers();

    sdk.changeSigner(agent);

    await sdk.elasticDAOFactory.contract.updateFeeAddress(agent.address);

    const feeAmountToCollect = await agent.provider.getBalance(sdk.elasticDAOFactory.address);

    const tx = await sdk.elasticDAOFactory.collectFees();
    const logs = await tx.wait(1);

    expect(logs.events[0].event).to.equal('FeesCollected');
    expect(logs.events[0].args.treasuryAddress).to.equal(agent.address);
    expect(logs.events[0].args.amount).to.equal(feeAmountToCollect);
  });
});
