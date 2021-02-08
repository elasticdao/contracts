module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const reentryProtection = await deploy('ReentryProtection', {
    from: agent,
    args: [],
    proxy: true,
  });

  if (reentryProtection.newlyDeployed) {
    log(`##### ElasticDAO: Reentry Protectionl has been deployed: ${reentryProtection.address}`);
  }
};
module.exports.tags = ['ReentryProtection'];
