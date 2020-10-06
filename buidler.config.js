/* eslint no-undef: 0 */
require('dotenv').config();

usePlugin('@nomiclabs/buidler-waffle');
usePlugin('@nomiclabs/buidler-ethers');
usePlugin('buidler-gas-reporter');
usePlugin('@nomiclabs/buidler-etherscan');
usePlugin('buidler-deploy');
usePlugin('solidity-coverage');
usePlugin('buidler-contract-sizer');

const ETHERSCAN_API_KEY = process.env.ETHERSCAN || '';

module.exports = {
  defaultNetwork: 'buidlerevm',
  solc: {
    version: '0.7.2',
    optimizer: {
      runs: 1,
      enabled: true,
    },
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
  },
  networks: {
    buidlerevm: {
      gasPrice: 0,
      blockGasLimit: 100000000,
    },
    coverage: {
      url: 'http://127.0.0.1:8555',
    },
  },
  gasReporter: {
    src: 'src',
    artifactType: 'buidler-v1',
    coinmarketcap: 'a69aea8b-8dce-45e5-ab8e-0e4577f27efd',
    currency: 'USD',
    showTimeSpent: 'true',
    // enabled: (process.env.REPORT_GAS) ? true : false
  },
  etherscan: {
    url: 'https://api.etherscan.io/api',
    apiKey: ETHERSCAN_API_KEY,
  },
  paths: {
    deploy: 'deploy',
    deployments: 'deployments',
    sources: './src',
    tests: './test',
    cache: './cache',
    artifacts: './artifacts',
  },
  namedAccounts: {
    agent: {
      default: 0,
    },
    summoner: {
      default: 1,
    },
    summoner1: {
      default: 2,
    },
    summoner2: {
      default: 3,
    },
  },
};
