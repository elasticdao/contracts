module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const tokenHolder = await deploy('TokenHolder', {
    from: agent,
    args: [],
  });

  if (tokenHolder.newlyDeployed) {
    log(`##### ElasticDAO: Elastic Module Model has been deployed: ${tokenHolder.address}`);
  }
};
module.exports.tags = ['TokenHolder'];
