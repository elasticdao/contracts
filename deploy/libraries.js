const ethers = require("ethers");
const bre = require("@nomiclabs/buidler").ethers;

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const storageLib = await deploy("StorageLib", {
    from: agent,
  });

  if (storageLib.newlyDeployed) {
    log(`##### ElasticDAO: StorageLib has been deployed: ${storageLib.address}`);
  }
};
module.exports.tags = ["Libraries"];
