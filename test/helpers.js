const { default: BigNumber } = require('bignumber.js');
const { ethers } = require('ethers');
const { SDK } = require('@elastic-dao/sdk');
const hre = require('hardhat').ethers;
const generateEnv = require('./env');

const contract = ({ abi, address, signer }) => new ethers.Contract(address, abi, signer);

const ethBalance = async (address) => {
  const balance = (await provider().getBalance(address)).toString();
  return BigNumber(balance)
    .dividedBy(10 ** 18)
    .dp(18);
};

const newDAO = async () => {
  const { elasticDAOFactory } = await sdk();
  return elasticDAOFactory.deployDAOAndToken(
    await summoners(),
    'Elastic DAO',
    'Elastic Governance Token',
    'EGT',
    0.1,
    0.02,
    100,
    1,
  );
};

const provider = () => hre.provider;

const sdk = async (overrides = {}) => {
  const { agent } = await signers();

  return new SDK({
    account: agent.address,
    contract: (args) => contract({ ...args, signer: agent }),
    env: await generateEnv(),
    provider: provider(),
    signer: agent,
    ...overrides,
  });
};

const seededDAO = async () => {
  const { summoner1 } = await signers();

  const dao = await newDAO();
  dao.sdk.contract = (args) => contract({ ...args, signer: summoner1 });
  return dao.elasticDAO.seedSummoning({ value: 1 });
};

const signers = async () => {
  const [agent, summoner1, summoner2, summoner3] = await hre.getSigners();
  return { agent, summoner1, summoner2, summoner3 };
};

const summonedDAO = async () => {
  const dao = await seededDAO();
  return dao.elasticDAO.summon(0.1);
};

const summoners = async () => {
  const { summoner1, summoner2, summoner3 } = await signers();
  return [summoner1.address, summoner2.address, summoner3.address];
};

module.exports = {
  contract,
  ethBalance,
  newDAO,
  provider,
  SDK: sdk,
  seededDAO,
  signers,
  summonedDAO,
  summoners,
};
