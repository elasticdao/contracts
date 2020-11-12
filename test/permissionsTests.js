const { expect } = require('chai');
const ethers = require('ethers');
const bre = require('@nomiclabs/buidler').ethers;
const { deployments } = require('@nomiclabs/buidler');

describe('ElasticDAO: Permission Model', () => {
  let agent;
  let Dao;
  let Ecosystem;
  let ecosystemStorage;
  let Permission;
  let permissionStorage;

  beforeEach(async () => {
    [agent] = await bre.getSigners();

    await deployments.fixture();

    // setup needed contracts
    Dao = await deployments.get('DAO');
    Ecosystem = await deployments.get('Ecosystem');
    ecosystemStorage = new ethers.Contract(Ecosystem.address, Ecosystem.abi, agent);
    Permission = await deployments.get('Permission');
    permissionStorage = new ethers.Contract(Permission.address, Permission.abi, agent);
  });

  it('Should do something', async () => {
    expect(true).to.equal(true);
  });

  it('Should do something else', async () => {
    expect(Dao).to.equal(Dao);
    expect(ecosystemStorage).to.equal(ecosystemStorage);
    expect(Permission).to.equal(Permission);
    expect(permissionStorage).to.equal(permissionStorage);
  });
});
