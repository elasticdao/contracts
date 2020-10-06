module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const elasticModule = await deploy('ElasticModule', {
    from: agent,
    args: [],
  });

  if (elasticModule.newlyDeployed) {
    log(`##### ElasticDAO: Elastic Module Model has been deployed: ${elasticModule.address}`);
  }
};
module.exports.tags = ['ElasticModule'];
