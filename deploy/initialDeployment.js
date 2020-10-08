const { ethers } = require('ethers');
const bre = require('@nomiclabs/buidler').ethers;

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { log } = deployments;
  const { agent } = await getNamedAccounts();

  const BalanceChange = await deployments.get('BalanceChange');
  const Configurator = await deployments.get('Configurator');
  const Dao = await deployments.get('DAO');
  const Ecosystem = await deployments.get('Ecosystem');
  const ecosystemStorage = new ethers.Contract(
    Ecosystem.address,
    Ecosystem.abi,
    bre.provider.getSigner(agent),
  );
  const ElasticModule = await deployments.get('ElasticModule');
  const Registrator = await deployments.get('Registrator');
  const Token = await deployments.get('Token');
  const TokenHolder = await deployments.get('TokenHolder');

  const ecosystemStructArray = [
    ethers.constants.AddressZero,
    // Models
    BalanceChange.address,
    Dao.address,
    Ecosystem.address,
    ElasticModule.address,
    TokenHolder.address,
    Token.address,
    // Services
    Configurator.address,
    Registrator.address,
    // Tokens
    ethers.constants.AddressZero,
  ];

  await ecosystemStorage.functions.serialize(ecosystemStructArray);

  log('##### ElasticDAO: Initialization Complete');
};
module.exports.tags = ['initialDeployment'];
module.exports.dependencies = [
  'BalanceChange',
  'Configurator',
  'DAO',
  'Ecosystem',
  'ElasticModule',
  'InformationalVote',
  'Registrator',
  'Token',
  'TokenHolder',
];
