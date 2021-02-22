module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const elasticGovernanceToken = await deploy('ElasticGovernanceToken', {
    from: agent,
    args: [],
  });

  if (elasticGovernanceToken.newlyDeployed) {
    log(
      `##### ElasticDAO: ElasticGovernanceToken has been deployed: ${elasticGovernanceToken.address}`,
    );
  }
};
module.exports.tags = ['ElasticGovernanceToken'];
