const ethers = require("ethers");
const bre = require("@nomiclabs/buidler").ethers;

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const storageLib = await deploy("StorageLib", {
    from: agent,
    libraries: {
      StorageLib: storageLib.address,
    },
  });

  if (
    storageLib.newlyDeployed &&
  ) {
    log(`##### PanDAO: StorageHelper has been deployed: ${storageLib.address}`);
  }
};
module.exports.tags = ["Libraries"];
