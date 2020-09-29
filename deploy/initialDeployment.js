const { ethers } = require('ethers');

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { agent } = await getNamedAccounts();

  const Configurator = await deployments.get('Configurator');
  const DAO = await deployments.get('DAO');
  const Ecosystem = await deployments.get('Ecosystem');
  const ecosystem = new ethers.Contract(
    Ecosystem.address,
    Ecosystem.abi,
    bre.provider.getSigner(agent),
  );
  const Token = await deployments.get('Token');

  const ecosystemStruct = {
    uuid: '0x0000000000000000000000000000000000000000',
    daoModelAddress: DAO.address,
    ecosystemModelAddress: Ecosystem.address,
    tokenModelAddress: Token.address,
    configuratorAddress: Configurator.address,
  };

  ecosystem.functions.serialize(ecosystemStruct, { from: agent });

  log(`##### ElasticDAO: Initialization Complete`);
};

module.exports.dependencies = ['Ecosystem', 'DAO', 'Token', 'Configurator'];
