module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const Ecosystem = await deployments.get('Ecosystem');

  const elasticDAOFactory = await deploy('ElasticDAOFactory', {
    from: agent,
    args: [Ecosystem.address],
    proxy: true,
  });

  if (elasticDAOFactory.newlyDeployed) {
    log(`##### ElasticDAO: ElasticDAOFactory has been deployed: ${elasticDAOFactory.address}`);
  }
};
module.exports.tags = ['ElasticDAOFactory'];
module.exports.dependencies = ['Ecosystem'];
