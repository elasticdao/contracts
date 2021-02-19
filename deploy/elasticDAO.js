module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const elasticDAO = await deploy('ElasticDAO', {
    from: agent,
    args: [],
  });

  if (elasticDAO.newlyDeployed) {
    log(`##### ElasticDAO: ElasticDAO has been deployed: ${elasticDAO.address}`);
  }
};
module.exports.tags = ['ElasticDAO'];
