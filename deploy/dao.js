module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const daoModel = await deploy('DAO', {
    from: agent,
    args: [],
    proxy: true,
  });

  if (daoModel.newlyDeployed) {
    log(`##### ElasticDAO: DAO Model has been deployed: ${daoModel.address}`);
  }
};
module.exports.tags = ['DAO'];
