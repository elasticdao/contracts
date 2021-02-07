module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const ecosystemModel = await deploy('Ecosystem', {
    from: agent,
    args: [],
    proxy: true,
  });

  if (ecosystemModel.newlyDeployed) {
    log(`##### ElasticDAO: Ecosystem Model has been deployed: ${ecosystemModel.address}`);
  }
};
module.exports.tags = ['Ecosystem'];
