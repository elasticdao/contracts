module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const tokenModel = await deploy('Token', {
    from: agent,
    args: [],
  });

  if (tokenModel.newlyDeployed) {
    log(`##### ElasticDAO: Token Model has been deployed: ${tokenModel.address}`);
  }
};
module.exports.tags = ['Token'];
