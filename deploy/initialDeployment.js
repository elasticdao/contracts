const { ethers } = require('ethers');
const bre = require('@nomiclabs/buidler').ethers;

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { log } = deployments;
  const { agent } = await getNamedAccounts();

  const Configurator = await deployments.get('Configurator');
  const DAO = await deployments.get('DAO');
  const Ecosystem = await deployments.get('Ecosystem');
  const ecosystem = new ethers.Contract(
    Ecosystem.address,
    Ecosystem.abi,
    bre.provider.getSigner(agent),
  );
  const Registrator = await deployments.get('Registrator');
  const Token = await deployments.get('Token');

  const ecosystemStruct = {
    uuid: '0x0000000000000000000000000000000000000000',
    configuratorAddress: Configurator.address,
    daoModelAddress: DAO.address,
    ecosystemModelAddress: Ecosystem.address,
    registratorAddress: Registrator.address,
    tokenModelAddress: Token.address,
  };

  ecosystem.functions.serialize(ecosystemStruct, { from: agent._address });

  log('##### ElasticDAO: Initialization Complete');
};

module.exports.dependencies = ['Ecosystem', 'DAO', 'Token', 'Configurator', 'Registrator'];
