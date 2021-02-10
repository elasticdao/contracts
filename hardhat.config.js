/* eslint no-undef: 0 */
require('dotenv').config();

require('@nomiclabs/hardhat-waffle');
require('@nomiclabs/hardhat-ethers');
require('hardhat-gas-reporter');
require('@nomiclabs/hardhat-etherscan');
require('hardhat-deploy');
require('hardhat-contract-sizer');
require('solidity-coverage');

const ETHERSCAN_API_KEY = process.env.ETHERSCAN || '';
const TESTNET_SEED = process.env.TESTNET_SEED || '';

// Tasks
task('seed', 'Seed account with Buidler ETH')
  .addParam('account', "The account's address")
  .setAction(async (taskArgs) => {
    const accounts = await ethers.getSigners();

    await accounts[0].sendTransaction({
      to: taskArgs.account,
      value: ethers.utils.parseEther('1000.0'),
    });

    console.log(`ElasticDAO: Seeded ${taskArgs.account} with 1000 ETH`);
  });

// Config
module.exports = {
  defaultNetwork: 'hardhat',
  solidity: {
    version: '0.7.2',
    settings: {
      optimizer: {
        enabled: true,
      },
    },
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
  },
  networks: {
    hardhat: {
      gasPrice: 0,
      blockGasLimit: 100000000,
      allowUnlimitedContractSize: true,
    },
    coverage: {
      url: 'http://127.0.0.1:8555',
    },
    edaoTestnet: {
      url: 'https://node.edao.app',
      chainId: 420,
      accounts: {
        mnemonic: TESTNET_SEED,
        count: 10,
      },
    },
  },
  gasReporter: {
    src: 'src',
    artifactType: 'hardhat-v1',
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
    summoner1: {
      default: 1,
    },
    summoner2: {
      default: 2,
    },
    summoner3: {
      default: 3,
    },
  },
  mocha: {
    timeout: 60000,
  },
};
