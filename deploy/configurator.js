const { ethers } = require('ethers');

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const configurator = await deploy('Configurator', {
    from: agent,
    args: [],
  });

  if (configurator.newlyDeployed) {
    log(`##### ElasticDAO: Configurator has been deployed: ${configurator.address}`);
  }
};
module.exports.tags = ['Configurator'];
module.exports.dependencies = ['Ecosystem', 'DAO', 'Token'];
