const { ethers } = require('ethers');
const bre = require('@nomiclabs/buidler').ethers;

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { log } = deployments;
  const { agent } = await getNamedAccounts();

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
    Dao.address,
    Ecosystem.address,
    ElasticModule.address,
    Token.address,
    TokenHolder.address,
    Configurator.address,
    Registrator.address,
    ethers.constants.AddressZero,
  ];

  await ecosystemStorage.functions.serialize(ecosystemStructArray);

  log('##### ElasticDAO: Initialization Complete');
};

module.exports.dependencies = [
  'Ecosystem',
  'DAO',
  'Token',
  'Configurator',
  'Registrator',
  'TokenHolder',
  'ElasticModule',
];
