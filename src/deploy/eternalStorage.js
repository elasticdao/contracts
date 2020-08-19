module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const StorageLibraryDeployment = await deployments.get("StorageHelper");

  const storage = await deploy("EternalStorage", {
    from: agent,
    args: [],
    libraries: {
      StorageLib: StorageLibraryDeployment.address,
    },
  });

  if (storage.newlyDeployed) {
    log(`##### ElasticDAO: STORAGE has been deployed: ${storage.address}`);
  }
};
module.exports.tags = ["EternalStorage"];
module.exports.dependencies = ["Libraries"];
