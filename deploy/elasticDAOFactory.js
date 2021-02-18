const { ethers } = require('ethers');
const hre = require('hardhat').ethers;

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const Ecosystem = await deployments.get('Ecosystem');

  const elasticDAOFactory = await deploy('ElasticDAOFactory', {
    from: agent,
    args: [],
    proxy: {
      proxyContract: "EIP173ProxyWithReceive"
    },
  });

  const factory = new ethers.Contract(
    elasticDAOFactory.address,
    elasticDAOFactory.abi,
    hre.provider.getSigner(agent),
  );
  await factory.initialize(Ecosystem.address);

  if (elasticDAOFactory.newlyDeployed) {
    log(`##### ElasticDAO: ElasticDAOFactory has been deployed: ${elasticDAOFactory.address}`);
  }
};
module.exports.tags = ['ElasticDAOFactory'];
module.exports.dependencies = ['Ecosystem'];
