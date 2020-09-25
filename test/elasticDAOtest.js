const { expect } = require('chai');
const ethers = require('ethers');
const bre = require('@nomiclabs/buidler').ethers;
const { deployments } = require('@nomiclabs/buidler');

describe('ElasticDAO: Elastic Storage Contract', () => {
  let ElasticStorage;
  let elasticStorage;

  let agent;
  let address1;
  let address2;

  beforeEach(async () => {
    [agent, address1, address2] = await bre.getSigners();

    await deployments.fixture();

    // setup needed contracts
    ElasticStorage = await deployments.get('ElasticStorage');
    elasticStorage = new ethers.Contract(ElasticStorage.address, ElasticStorage.abi, agent);
  });
});
