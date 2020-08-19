require("dotenv").config();

usePlugin("@nomiclabs/buidler-waffle");
usePlugin("@nomiclabs/buidler-ethers");
usePlugin("@nomiclabs/buidler-etherscan");
usePlugin("buidler-deploy");
usePlugin("solidity-coverage");

const ETHERSCAN_API_KEY = process.env.ETHERSCAN || "";

module.exports = {
  defaultNetwork: "buidlerevm",
  solc: {
    version: "0.6.10",
    optimizer: {
      runs: 1,
      enabled: true,
    },
  },
  networks: {
    buidlerevm: {
      gasPrice: 0,
      blockGasLimit: 100000000,
      allowUnlimitedContractSize: false,
    },
    coverage: {
      url: "http://127.0.0.1:8555", // Coverage launches its own ganache-cli client
    },
  },
  etherscan: {
    url: "https://api.etherscan.io/api",
    apiKey: ETHERSCAN_API_KEY,
  },
  paths: {
    deploy: "deploy",
    deployments: "deployments",
    sources: "./src",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  namedAccounts: {
    agent: {
      default: 0,
    },
    finance: {
      default: 2,
    },
  },
};
