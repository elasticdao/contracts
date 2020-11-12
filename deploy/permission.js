module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const permissionModel = await deploy('Permission', {
    from: agent,
    args: [],
  });

  if (permissionModel.newlyDeployed) {
    log(`##### ElasticDAO: Permission Model has been deployed: ${permissionModel.address}`);
  }
};
module.exports.tags = ['Permission'];
