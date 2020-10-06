module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const balanceChangeModel = await deploy('BalanceChange', {
    from: agent,
    args: [],
  });

  if (balanceChangeModel.newlyDeployed) {
    log(`##### ElasticDAO: BalanceChange Model has been deployed: ${balanceChangeModel.address}`);
  }
};
module.exports.tags = ['BalanceChange'];
