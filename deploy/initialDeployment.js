const { ethers } = require('ethers');
const hre = require('hardhat').ethers;

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { log } = deployments;
  const { agent } = await getNamedAccounts();

  const Configurator = await deployments.get('Configurator_Implementation');
  const Dao = await deployments.get('DAO_Implementation');
  const Ecosystem = await deployments.get('Ecosystem_Implementation');
  const ecosystemStorage = new ethers.Contract(
    Ecosystem.address,
    Ecosystem.abi,
    hre.provider.getSigner(agent),
  );
  const Token = await deployments.get('Token_Implementation');
  const TokenHolder = await deployments.get('TokenHolder_Implementation');

  const ecosystemStructArray = [
    ethers.constants.AddressZero,
    // Models
    Dao.address,
    Ecosystem.address,
    TokenHolder.address,
    Token.address,
    // Services
    Configurator.address,
    // Tokens
    ethers.constants.AddressZero,
  ];

  await ecosystemStorage.functions.serialize(ecosystemStructArray);

  log('##### ElasticDAO: Initialization Complete');
};
module.exports.tags = ['initialDeployment'];
module.exports.dependencies = [
  'Configurator',
  'DAO',
  'Ecosystem',
  'ElasticDAOFactory',
  'ReentryProtection',
  'Token',
  'TokenHolder',
];
