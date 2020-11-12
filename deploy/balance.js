module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const balanceModel = await deploy('Balance', {
    from: agent,
    args: [],
  });

  if (balanceModel.newlyDeployed) {
    log(`##### ElasticDAO: BalanceModel has been deployed: ${balanceModel.address}`);
  }
};
module.exports.tags = ['Balance'];
