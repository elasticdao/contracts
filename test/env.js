const env = {
  blocknative: {
    dappId: 'ded3dba9-5677-4c6f-9e12-2cd58ff163a1',
    networkId: 1,
  },
  etherscan: {
    apiKey: '9I14Q5JKW8N86ZP87PEVREQGFDGIZK7QG5',
  },
  elasticDAO: {
    balanceModelAddress: '0x5FbDB2315678afecb367f032d93F642f64180aa3',
    balanceMultipliersModelAddress: '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512',
    daoModelAddress: '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9',
    ecosystemModelAddress: '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9',
    elasticModuleModelAddress: '0x0165878A594ca255338adfa4d48449f69242Eb8F',
    factoryAddress: '0x5FC8d32690cc91D4c39d9d3abcBD16989F875707',
    tokenModelAddress: '0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0',
    tokenHolderModelAddress: '0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82',

    modules: {
      informationalVote: {
        ballotModelAddress: '0xa513E6E4b8f2a923D98304ec87F64353C4D5C853',
        factoryAddress: '0x610178dA211FEF7D417bC0e6FeD39F05609AD788',
        settingsModelAddress: '0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6',
        voteModelAddress: '0x8A791620dd6260079BF849Dc5567aDC3F2FdC318',
      },
      transactionalVote: {
        ballotModelAddress: '0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e',
        factoryAddress: '0x9A676e781A523b5d0C0e43731313A708CB607508',
        settingsModelAddress: '0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0',
        voteModelAddress: '0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82',
      },
    },
  },
  fees: {
    deploy: '0.25',
  },
};

module.exports = env;
