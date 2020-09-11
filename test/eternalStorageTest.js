const { expect } = require("chai");
const ethers = require("ethers");
const bre = require("@nomiclabs/buidler").ethers;
const { deployments } = require("@nomiclabs/buidler");

const storageFormat = require("./utils/storageFormat").storageFormat;

describe("ElasticDAO: Eternal Storage Contract", () => {
  let EternalStorage;
  let eternalStorage;

  let agent;
  let address1;
  let address2;

  beforeEach(async () => {
    [agent, address1, address2] = await bre.getSigners();

    await deployments.fixture();

    StorageLib = await deployments.get("StorageLib");
    storageLib = new ethers.Contract(StorageLib.address, StorageLib.abi, agent);

    // setup needed contracts
    EternalStorage = await deployments.get("EternalStorage");
    eternalStorage = new ethers.Contract(EternalStorage.address, EternalStorage.abi, agent);
  });
});
