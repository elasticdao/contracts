module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const registrator = await deploy('Registrator', {
    from: agent,
    args: [],
  });

  if (registrator.newlyDeployed) {
    log(`##### ElasticDAO: Registrator has been deployed: ${registrator.address}`);
  }
};
module.exports.tags = ['Registrator'];
