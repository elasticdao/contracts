const { ethers } = require('ethers');
const hre = require('hardhat').ethers;

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { log } = deployments;
  const { agent } = await getNamedAccounts();

  const Configurator = await deployments.get('Configurator');
  const Dao = await deployments.get('DAO');
  const Ecosystem = await deployments.get('Ecosystem');
  const ecosystemStorage = new ethers.Contract(
    Ecosystem.address,
    Ecosystem.abi,
    hre.provider.getSigner(agent),
  );
  const ElasticGovernanceToken = await deployments.get('ElasticGovernanceToken');
  const Token = await deployments.get('Token');
  const TokenHolder = await deployments.get('TokenHolder');

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
    ElasticGovernanceToken.address,
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
  'ElasticGovernanceToken',
  'Token',
  'TokenHolder',
];
