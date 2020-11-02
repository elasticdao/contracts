module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const balanceMultipliersModel = await deploy('BalanceMultipliers', {
    from: agent,
    args: [],
  });

  if (balanceMultipliersModel.newlyDeployed) {
    log(
      `##### ElasticDAO: BalanceMultipliersModel has been deployed: ${balanceMultipliersModel.address}`,
    );
  }
};
module.exports.tags = ['BalanceMultipliers'];
